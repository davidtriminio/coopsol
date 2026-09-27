using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using CoopSol.Application.Auth;

namespace CoopSol.Tests.Integration;

[Collection(ApiCollection.Name)]
public class AuthApiTests(ApiFactory factory)
{
    private const string Password = "Password-123";
    private readonly HttpClient _client = factory.CreateClient();
    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static string NewEmail() => $"{Guid.NewGuid():N}@coopsol.test";

    private async Task<string> RegisterAsync(string? email = null)
    {
        email ??= NewEmail();
        var response = await _client.PostAsJsonAsync("/api/auth/register",
            new RegisterRequest(email, Password, "Socio de Prueba"), Ct);

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return email;
    }
    private async Task<AuthResponse> LoginAsync(string email, string password = Password)
    {
        var response = await _client.PostAsJsonAsync("/api/auth/login", new LoginRequest(email, password), Ct);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return (await response.Content.ReadFromJsonAsync<AuthResponse>(Ct))!;
    }

    private HttpRequestMessage Authorized(HttpMethod method, string url, string accessToken, object? body = null)
    {
        var request = new HttpRequestMessage(method, url);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        if (body is not null) request.Content = JsonContent.Create(body);
        return request;
    }

    [Fact]
    public async Task Register_Login_Me_HappyPath()
    {
        var email = await RegisterAsync();
        var auth = await LoginAsync(email);

        var me = await _client.SendAsync(Authorized(HttpMethod.Get, "/api/auth/me", auth.AccessToken), Ct);

        Assert.Equal(HttpStatusCode.OK, me.StatusCode);
        var user = await me.Content.ReadFromJsonAsync<UserDto>(Ct);
        Assert.Equal(email, user!.Email);
        Assert.Equal("Socio", user.Role);
    }

    [Fact]
    public async Task Register_IgnoresRoleField_SoNobodyCanSelfPromote()
    {
        var email = NewEmail();

        var response = await _client.PostAsJsonAsync("/api/auth/register",
            new { email, password = Password, fullName = "Intruso", role = "Admin" }, Ct);

        var user = await response.Content.ReadFromJsonAsync<UserDto>(Ct);
        Assert.Equal("Socio", user!.Role);
    }

    [Fact]
    public async Task Register_DuplicateEmail_Returns409()
    {
        var email = await RegisterAsync();

        var response = await _client.PostAsJsonAsync("/api/auth/register",
            new RegisterRequest(email.ToUpperInvariant(), Password, "Duplicado"), Ct);

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
    }

    [Fact]
    public async Task Register_InvalidBody_Returns400ProblemDetails()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/register",
            new RegisterRequest("no-es-email", "corta", "X"), Ct);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        Assert.Equal("application/problem+json", response.Content.Headers.ContentType?.MediaType);
    }

    [Fact]
    public async Task Login_WrongPassword_Returns401()
    {
        var email = await RegisterAsync();

        var response = await _client.PostAsJsonAsync("/api/auth/login", new LoginRequest(email, "Clave-Incorrecta-1"), Ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Me_WithoutToken_Returns401()
    {
        var response = await _client.GetAsync("/api/auth/me", Ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Me_WithTamperedToken_Returns401()
    {
        var auth = await LoginAsync(await RegisterAsync());

        var response = await _client.SendAsync(Authorized(HttpMethod.Get, "/api/auth/me", auth.AccessToken + "x"), Ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Refresh_RotatesToken_AndReuseOfOldTokenIsRejected()
    {
        var first = await LoginAsync(await RegisterAsync());

        var refresh1 = await _client.PostAsJsonAsync("/api/auth/refresh", new RefreshTokenRequest(first.RefreshToken), Ct);
        Assert.Equal(HttpStatusCode.OK, refresh1.StatusCode);
        var second = (await refresh1.Content.ReadFromJsonAsync<AuthResponse>(Ct))!;

        var replay = await _client.PostAsJsonAsync("/api/auth/refresh", new RefreshTokenRequest(first.RefreshToken), Ct);
        Assert.Equal(HttpStatusCode.Unauthorized, replay.StatusCode);

        var afterReplay = await _client.PostAsJsonAsync("/api/auth/refresh", new RefreshTokenRequest(second.RefreshToken), Ct);
        Assert.Equal(HttpStatusCode.Unauthorized, afterReplay.StatusCode);
    }

    [Fact]
    public async Task Logout_RevokesRefreshToken()
    {
        var auth = await LoginAsync(await RegisterAsync());

        var logout = await _client.PostAsJsonAsync("/api/auth/logout", new RefreshTokenRequest(auth.RefreshToken), Ct);
        var refresh = await _client.PostAsJsonAsync("/api/auth/refresh", new RefreshTokenRequest(auth.RefreshToken), Ct);

        Assert.Equal(HttpStatusCode.NoContent, logout.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, refresh.StatusCode);
    }

    [Fact]
    public async Task AdminUsers_AsSocio_Returns403()
    {
        var socio = await LoginAsync(await RegisterAsync());

        var response = await _client.SendAsync(Authorized(HttpMethod.Post, "/api/admin/users", socio.AccessToken,
            new CreateUserRequest(NewEmail(), Password, "Cajero Nuevo", "Cajero")), Ct);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task AdminUsers_WithoutToken_Returns401()
    {
        var response = await _client.PostAsJsonAsync("/api/admin/users",
            new CreateUserRequest(NewEmail(), Password, "Cajero Nuevo", "Cajero"), Ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task AdminUsers_AsSeededAdmin_CreatesCajero_WhoCanLogin()
    {
        var admin = await LoginAsync(ApiFactory.AdminEmail, ApiFactory.AdminPassword);
        var cajeroEmail = NewEmail();

        var create = await _client.SendAsync(Authorized(HttpMethod.Post, "/api/admin/users", admin.AccessToken,
            new CreateUserRequest(cajeroEmail, Password, "Cajero Nuevo", "Cajero")), Ct);
        Assert.Equal(HttpStatusCode.Created, create.StatusCode);

        var cajero = await LoginAsync(cajeroEmail);
        Assert.Equal("Cajero", cajero.User.Role);
    }
}