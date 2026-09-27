using System.Text;
using CoopSol.Application.Auth;
using CoopSol.Domain.Entities;
using CoopSol.Domain.Enums;
using CoopSol.Infrastructure.Security;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace CoopSol.Tests.Unit;

public class BCryptPasswordHasherTests
{
    private readonly BCryptPasswordHasher _sut = new();
    [Fact]
    public void Hash_ThenVerify_Succeeds_AndWrongPasswordFails()
    {
        var hash = _sut.Hash("Password-123");

        Assert.True(_sut.Verify("Password-123", hash));
        Assert.False(_sut.Verify("password-123", hash));
    }

    [Fact]
    public void Hash_SamePasswordTwice_ProducesDifferentHashes_BecauseOfSalt()
    {
        Assert.NotEqual(_sut.Hash("Password-123"), _sut.Hash("Password-123"));
    }

    [Fact]
    public void Verify_DetectsDifferencesBeyondByte72()
    {
        var prefix = new string('a', 80);
        var hash = _sut.Hash(prefix + "X");

        Assert.False(_sut.Verify(prefix + "Y", hash));
    }

    [Fact]
    public void DummyHash_IsAValidHash_ThatNoRealPasswordMatches()
    {
        Assert.False(_sut.Verify("Password-123", _sut.DummyHash));
    }
}

public class JwtTokenServiceTests
{
    private static readonly JwtOptions Options = new()
    {
        Issuer = "test-issuer",
        Audience = "test-audience",
        Secret = new string('k', 64),
        AccessTokenMinutes = 15,
        RefreshTokenDays = 7
    };

    private readonly JwtTokenService _sut = new(Microsoft.Extensions.Options.Options.Create(Options), TimeProvider.System);

    private static User NewUser() =>
        User.Create("gerente@test.com", "hash", "Gerente Prueba", UserRole.Gerente, DateTime.UtcNow);

    private static TokenValidationParameters Parameters(string secret) => new()
    {
        ValidIssuer = Options.Issuer,
        ValidAudience = Options.Audience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret)),
        ClockSkew = TimeSpan.Zero,
    };

    [Fact]
    public async Task AccessToken_IsValid_AndCarriesSubEmailAndRole()
    {
        var user = NewUser();

        var token = _sut.CreateAccessToken(user);
        var result = await new JsonWebTokenHandler().ValidateTokenAsync(token.Value, Parameters(Options.Secret));

        Assert.True(result.IsValid);
        Assert.Equal(user.Id.ToString(), result.Claims["sub"]);
        Assert.Equal("gerente@test.com", result.Claims["email"]);
        Assert.Equal("Gerente", result.Claims["role"]);
        Assert.False(result.Claims.ContainsKey("passwordHash"));
    }

    [Fact]
    public async Task AccessToken_SignedWithAnotherKey_IsRejected()
    {
        var token = _sut.CreateAccessToken(NewUser());

        var result = await new JsonWebTokenHandler().ValidateTokenAsync(token.Value, Parameters(new string('x', 64)));

        Assert.False(result.IsValid);
    }

    [Fact]
    public void RefreshToken_IsRandom_AndHashIsSha256Hex()
    {
        var a = _sut.GenerateRefreshToken();
        var b = _sut.GenerateRefreshToken();

        Assert.NotEqual(a, b);
        Assert.Equal(64, _sut.HashRefreshToken(a).Length);
        Assert.Equal(_sut.HashRefreshToken(a), _sut.HashRefreshToken(a));
        Assert.NotEqual(_sut.HashRefreshToken(a), _sut.HashRefreshToken(b));
    }
}

public class AuthValidatorTests
{[Theory]
    [InlineData("ana@coopsol.hn", true)]
    [InlineData("no-es-email", false)]
    [InlineData("Ana <ana@coopsol.hn>", false)]
    [InlineData("", false)]
    public void Email_Validation(string email, bool valid)
    {
        var errors = AuthValidator.ValidateCredentials(email, "Password-123");

        Assert.Equal(valid, !errors.ContainsKey("email"));
    }

    [Theory]
    [InlineData(7, false)]
    [InlineData(8, true)]
    [InlineData(128, true)]
    [InlineData(129, false)]
    public void Password_LengthBoundaries(int length, bool valid)
    {
        var errors = AuthValidator.ValidateCredentials("ana@coopsol.hn", new string('a', length));

        Assert.Equal(valid, !errors.ContainsKey("password"));
    }
}