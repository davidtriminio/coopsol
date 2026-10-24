using CoopSol.Application.Abstractions;
using CoopSol.Application.Auth;
using CoopSol.Domain.Enums;
using CoopSol.Infrastructure.Security;
using Microsoft.Extensions.Options;

namespace CoopSol.Tests.Unit;

public class AuthServiceTests
{
    private readonly InMemoryStore _store = new();
    private readonly TestClock _clock = new();
    private readonly AuthService _sut;

    public AuthServiceTests()
    {
        var jwt = new JwtOptions
        {
            Issuer = "test-issuer",
            Audience = "test-audience",
            Secret = new string('s', 64),
            AccessTokenMinutes = 15,
            RefreshTokenDays = 7
        };

        _sut = new AuthService(
            _store, _store, _store,
            new FakePasswordHasser(),
            new JwtTokenService(Options.Create(jwt), _clock),
                jwt,
                _clock
            );
    }

    private async Task<AuthResponse> RegisterAndLoginAsync(string email = "socio@test.com",
        string password = "Password-123")
    {
        var register = await _sut.RegisterAsync(new RegisterRequest(email, password, "Socio Prueba"),
            TestContext.Current.CancellationToken);
        Assert.True(register.IsSuccess);

        var login = await _sut.LoginAsync(new LoginRequest(email, password), TestContext.Current.CancellationToken);
        Assert.True(login.IsSuccess);
        return login.Value;
    }

    [Fact]
    public async Task Register_CreatesSocio_WithNormalizedEmail()
    {
        var result = await _sut.RegisterAsync(
            new RegisterRequest("  Ana.Lopez@Test.COM ", "Password-123", "Ana López"), TestContext.Current.CancellationToken);

        Assert.True(result.IsSuccess);
        Assert.Equal("ana.lopez@test.com", result.Value.Email);
        Assert.Equal(nameof(UserRole.Socio), result.Value.Role);
    }


    [Fact]
    public async Task Register_DuplicateEmail_DifferentCase_ReturnsConflict()
    {
        await RegisterAndLoginAsync("dup@test.com");

        var second = await _sut.RegisterAsync(new RegisterRequest("DUP@test.com", "Password-123", "Otro"), TestContext.Current.CancellationToken);

        Assert.False(second.IsSuccess);
        Assert.Equal(ErrorType.Conflict, second.Error!.Type);
    }

    [Fact]
    public async Task Register_WhenSaveHitsUniqueViolation_ReturnsConflict()
    {
        _store.ThrowOnSave = new UniqueConstraintViolationException(new Exception("23505"));

        var result = await _sut.RegisterAsync(
            new RegisterRequest("carrera@test.com", "Password-123", "Socio Carrera"), TestContext.Current.CancellationToken);

        Assert.False(result.IsSuccess);
        Assert.Equal(AuthErrors.EmailTaken, result.Error);
    }

    [Fact]
    public async Task Register_WhenSaveFailsForAnotherReason_PropagatesTheException()
    {
        _store.ThrowOnSave = new InvalidOperationException("fallo de BD");

        await Assert.ThrowsAsync<InvalidOperationException>(() => _sut.RegisterAsync(
            new RegisterRequest("otro@test.com", "Password-123", "Socio Otro"), TestContext.Current.CancellationToken));
    }

    [Fact]
    public async Task Register_InvalidInput_ReturnsFieldErrors()
    {
        var result = await _sut.RegisterAsync(new RegisterRequest("no-es-email", "corta", "X"), TestContext.Current.CancellationToken);

        Assert.False(result.IsSuccess);
        Assert.Equal(ErrorType.Validation, result.Error!.Type);
        Assert.Contains("email", result.Error.Details!.Keys);
        Assert.Contains("password", result.Error.Details.Keys);
        Assert.Contains("fullName", result.Error.Details.Keys);
    }

    [Fact]
    public async Task Login_WrongPassword_And_UnknownEmail_ReturnSameError()
    {
        await RegisterAndLoginAsync("real@test.com");

        var wrongPassword = await _sut.LoginAsync(new LoginRequest("real@test.com", "Otra-Clave-999"), TestContext.Current.CancellationToken);
        var unknownEmail = await _sut.LoginAsync(new LoginRequest("fantasma@test.com", "Password-123"), TestContext.Current.CancellationToken);

        Assert.Equal(AuthErrors.InvalidCredentials, wrongPassword.Error);
        Assert.Equal(AuthErrors.InvalidCredentials, unknownEmail.Error);
    }

    [Fact]
    public async Task Refresh_RotatesToken_AndOldTokenIsRevoked()
    {
        var first = await RegisterAndLoginAsync();

        var rotated = await _sut.RefreshAsync(new RefreshTokenRequest(first.RefreshToken), TestContext.Current.CancellationToken);

        Assert.True(rotated.IsSuccess);
        Assert.NotEqual(first.RefreshToken, rotated.Value.RefreshToken);
        Assert.Equal(1, _store.Tokens.Count(t => t.IsRevoked));
        Assert.Equal(1, _store.Tokens.Count(t => !t.IsRevoked));
    }

    [Fact]
    public async Task Refresh_ReusingRevokedToken_RevokesEveryActiveSession()
    {
        var first = await RegisterAndLoginAsync();
        var rotated = await _sut.RefreshAsync(new RefreshTokenRequest(first.RefreshToken), TestContext.Current.CancellationToken);

        var replay = await _sut.RefreshAsync(new RefreshTokenRequest(first.RefreshToken), TestContext.Current.CancellationToken);

        Assert.Equal(AuthErrors.InvalidRefreshToken, replay.Error);
        Assert.All(_store.Tokens, t => Assert.True(t.IsRevoked));

        var legit = await _sut.RefreshAsync(new RefreshTokenRequest(rotated.Value.RefreshToken), TestContext.Current.CancellationToken);
        Assert.False(legit.IsSuccess);
    }

    [Fact]
    public async Task Refresh_ExpiredToken_IsRejected()
    {
        var first = await RegisterAndLoginAsync();

        _clock.Advance(TimeSpan.FromDays(7) + TimeSpan.FromSeconds(1));
        var result = await _sut.RefreshAsync(new RefreshTokenRequest(first.RefreshToken), TestContext.Current.CancellationToken);

        Assert.Equal(AuthErrors.InvalidRefreshToken, result.Error);
    }

    [Fact]
    public async Task Refresh_UnknownOrEmptyToken_IsRejected()
    {
        var unknown = await _sut.RefreshAsync(new RefreshTokenRequest("no-existe"), TestContext.Current.CancellationToken);
        var empty = await _sut.RefreshAsync(new RefreshTokenRequest(""), TestContext.Current.CancellationToken);

        Assert.Equal(AuthErrors.InvalidRefreshToken, unknown.Error);
        Assert.Equal(AuthErrors.InvalidRefreshToken, empty.Error);
    }

    [Fact]
    public async Task Logout_RevokesToken_AndIsIdempotent()
    {
        var first = await RegisterAndLoginAsync();

        var logout1 = await _sut.LogoutAsync(new RefreshTokenRequest(first.RefreshToken), TestContext.Current.CancellationToken);
        var logout2 = await _sut.LogoutAsync(new RefreshTokenRequest(first.RefreshToken), TestContext.Current.CancellationToken);
        var logoutUnknown = await _sut.LogoutAsync(new RefreshTokenRequest("no-existe"), TestContext.Current.CancellationToken);
        var refreshAfter = await _sut.RefreshAsync(new RefreshTokenRequest(first.RefreshToken), TestContext.Current.CancellationToken);

        Assert.True(logout1.IsSuccess);
        Assert.True(logout2.IsSuccess);
        Assert.True(logoutUnknown.IsSuccess);
        Assert.False(refreshAfter.IsSuccess);
    }

    [Theory]
    [InlineData("Cajero", true)]
    [InlineData("gerente", true)]
    [InlineData("3", false)]
    [InlineData("SuperAdmin", false)]
    [InlineData("", false)]
    public async Task CreateUser_ValidatesRoleByName(string role, bool expectedSuccess)
    {
        var result = await _sut.CreateUserAsync(
            new CreateUserRequest("staff@test.com", "Password-123", "Personal Staff", role), TestContext.Current.CancellationToken);

        Assert.Equal(expectedSuccess, result.IsSuccess);
    }
}