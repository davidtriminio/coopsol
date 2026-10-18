using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using CoopSol.Application.Auth;
using Microsoft.AspNetCore.Mvc.Testing;

namespace CoopSol.Tests.Integration;

[Collection(ApiCollection.Name)]
public class CookieAuthApiTests(ApiFactory factory)
{
    private const string Password = "Password-123";
    private const string CookieName = "coopsol_refresh";
    private const string WebOrigin = "http://localhost:4200";

    private readonly HttpClient _client = factory.CreateClient(new WebApplicationFactoryClientOptions
    {
        HandleCookies = false
    });

    private static CancellationToken Ct => TestContext.Current.CancellationToken;

    private static string NewEmail() => $"{Guid.NewGuid():N}@coopsol.test";

    private static HttpRequestMessage Post(
        string url, string? cookie = null, bool cookieMode = true, HttpContent? content = null)
    {
        var request = new HttpRequestMessage(HttpMethod.Post, url)
        {
            Content = content
        };
        if (cookieMode)
            request.Headers.Add("X-Auth-Mode", "cookie");
        if (cookie is not null)
            request.Headers.Add("Cookie", $"{CookieName}={cookie}");
        return request;
    }

    private static string? SetCookieHeader(HttpResponseMessage response) =>
        response.Headers.TryGetValues("Set-Cookie", out var values)
            ? values.FirstOrDefault(v => v.StartsWith($"{CookieName}=", StringComparison.Ordinal))
            : null;

    private static string CookieValue(HttpResponseMessage response)
    {
        var header = SetCookieHeader(response);
        Assert.NotNull(header);
        var value = header.Split(';')[0][(CookieName.Length + 1)..];
        Assert.NotEmpty(value);
        return value;
    }

    private static void AssertCookieCleared(HttpResponseMessage response)
    {
        var header = SetCookieHeader(response);
        Assert.NotNull(header);
        Assert.StartsWith($"{CookieName}=;", header, StringComparison.Ordinal);
        Assert.Contains("1970", header, StringComparison.Ordinal);
    }

    private static async Task<bool> BodyHasRefreshTokenAsync(HttpResponseMessage response)
    {
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync(Ct));
        return document.RootElement.TryGetProperty("refreshToken", out _);
    }

    private async Task<string> RegisterAsync()
    {
        var email = NewEmail();
        var response = await _client.PostAsJsonAsync("/api/auth/register",
            new RegisterRequest(email, Password, "Socio de Prueba"), Ct);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        return email;
    }

    private async Task<(HttpResponseMessage Response, string Cookie)> LoginWithCookieAsync(string email)
    {
        var response = await _client.SendAsync(
            Post("/api/auth/login", content: JsonContent.Create(new LoginRequest(email, Password))), Ct);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        return (response, CookieValue(response));
    }

    [Fact]
    public async Task Login_CookieMode_SetsHardenedCookie_AndOmitsRefreshTokenFromBody()
    {
        var email = await RegisterAsync();

        var (response, _) = await LoginWithCookieAsync(email);

        var setCookie = SetCookieHeader(response)!;
        Assert.Contains("httponly", setCookie, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("secure", setCookie, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("samesite=strict", setCookie, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("path=/api/auth", setCookie, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("expires=", setCookie, StringComparison.OrdinalIgnoreCase);
        Assert.False(await BodyHasRefreshTokenAsync(response));

        var session = await response.Content.ReadFromJsonAsync<SessionResponse>(Ct);
        Assert.False(string.IsNullOrEmpty(session!.AccessToken));
        Assert.Equal(email, session.User.Email);
    }

    [Fact]
    public async Task Login_WithoutModeHeader_ReturnsRefreshTokenInBody_AndNoCookie()
    {
        var email = await RegisterAsync();

        var response = await _client.SendAsync(
            Post("/api/auth/login", cookieMode: false, content: JsonContent.Create(new LoginRequest(email, Password))),
            Ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Null(SetCookieHeader(response));
        var auth = await response.Content.ReadFromJsonAsync<AuthResponse>(Ct);
        Assert.False(string.IsNullOrEmpty(auth!.RefreshToken));
    }

    [Fact]
    public async Task Refresh_CookieMode_RotatesTheCookie_AndIssuesAWorkingAccessToken()
    {
        var (_, cookie1) = await LoginWithCookieAsync(await RegisterAsync());

        var refreshed = await _client.SendAsync(Post("/api/auth/refresh", cookie1), Ct);

        Assert.Equal(HttpStatusCode.OK, refreshed.StatusCode);
        Assert.NotEqual(cookie1, CookieValue(refreshed));
        Assert.False(await BodyHasRefreshTokenAsync(refreshed));

        var session = await refreshed.Content.ReadFromJsonAsync<SessionResponse>(Ct);
        var me = new HttpRequestMessage(HttpMethod.Get, "/api/auth/me");
        me.Headers.Authorization = new AuthenticationHeaderValue("Bearer", session!.AccessToken);
        Assert.Equal(HttpStatusCode.OK, (await _client.SendAsync(me, Ct)).StatusCode);
    }

    [Fact]
    public async Task Refresh_CookieMode_WorksWhenTheRequestHasAFormContentTypeAndNoBody()
    {
        var (_, cookie) = await LoginWithCookieAsync(await RegisterAsync());
        var empty = new StringContent(string.Empty, Encoding.UTF8, "application/x-www-form-urlencoded");

        var refreshed = await _client.SendAsync(Post("/api/auth/refresh", cookie, content: empty), Ct);

        Assert.Equal(HttpStatusCode.OK, refreshed.StatusCode);
    }

    [Fact]
    public async Task Refresh_CookieMode_ReusingAnOldCookie_Returns401_ClearsTheCookie_AndRevokesTheSession()
    {
        var (_, cookie1) = await LoginWithCookieAsync(await RegisterAsync());
        var cookie2 = CookieValue(await _client.SendAsync(Post("/api/auth/refresh", cookie1), Ct));

        var replay = await _client.SendAsync(Post("/api/auth/refresh", cookie1), Ct);

        Assert.Equal(HttpStatusCode.Unauthorized, replay.StatusCode);
        AssertCookieCleared(replay);

        var legitimate = await _client.SendAsync(Post("/api/auth/refresh", cookie2), Ct);
        Assert.Equal(HttpStatusCode.Unauthorized, legitimate.StatusCode);
    }

    [Fact]
    public async Task Refresh_CookieMode_WithoutCookie_Returns401_AndClearsTheCookie()
    {
        var response = await _client.SendAsync(Post("/api/auth/refresh"), Ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        AssertCookieCleared(response);
    }

    [Fact]
    public async Task Refresh_CookieMode_IgnoresATokenSentInTheBody()
    {
        var email = await RegisterAsync();
        var bodyLogin = await _client.SendAsync(
            Post("/api/auth/login", cookieMode: false, content: JsonContent.Create(new LoginRequest(email, Password))),
            Ct);
        var auth = (await bodyLogin.Content.ReadFromJsonAsync<AuthResponse>(Ct))!;

        var response = await _client.SendAsync(
            Post("/api/auth/refresh", content: JsonContent.Create(new RefreshTokenRequest(auth.RefreshToken))), Ct);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Refresh_BodyMode_StillWorksAndReturnsTheTokenInTheBody()
    {
        var email = await RegisterAsync();
        var bodyLogin = await _client.SendAsync(
            Post("/api/auth/login", cookieMode: false, content: JsonContent.Create(new LoginRequest(email, Password))),
            Ct);
        var auth = (await bodyLogin.Content.ReadFromJsonAsync<AuthResponse>(Ct))!;

        var response = await _client.SendAsync(
            Post("/api/auth/refresh", cookieMode: false,
                content: JsonContent.Create(new RefreshTokenRequest(auth.RefreshToken))), Ct);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Null(SetCookieHeader(response));
        var rotated = await response.Content.ReadFromJsonAsync<AuthResponse>(Ct);
        Assert.NotEqual(auth.RefreshToken, rotated!.RefreshToken);
    }

    [Fact]
    public async Task Logout_CookieMode_RevokesTheToken_AndClearsTheCookie()
    {
        var (_, cookie) = await LoginWithCookieAsync(await RegisterAsync());

        var logout = await _client.SendAsync(Post("/api/auth/logout", cookie), Ct);
        var refreshAfter = await _client.SendAsync(Post("/api/auth/refresh", cookie), Ct);

        Assert.Equal(HttpStatusCode.NoContent, logout.StatusCode);
        AssertCookieCleared(logout);
        Assert.Equal(HttpStatusCode.Unauthorized, refreshAfter.StatusCode);
    }

    [Fact]
    public async Task Logout_CookieMode_WithoutCookie_IsIdempotent()
    {
        var logout = await _client.SendAsync(Post("/api/auth/logout"), Ct);

        Assert.Equal(HttpStatusCode.NoContent, logout.StatusCode);
        AssertCookieCleared(logout);
    }

    [Fact]
    public async Task Preflight_FromTheWebOrigin_AllowsCredentialsAndTheModeHeader()
    {
        var request = new HttpRequestMessage(HttpMethod.Options, "/api/auth/refresh");
        request.Headers.Add("Origin", WebOrigin);
        request.Headers.Add("Access-Control-Request-Method", "POST");
        request.Headers.Add("Access-Control-Request-Headers", "x-auth-mode");

        var response = await _client.SendAsync(request, Ct);

        Assert.Equal(WebOrigin, response.Headers.GetValues("Access-Control-Allow-Origin").Single());
        Assert.Equal("true", response.Headers.GetValues("Access-Control-Allow-Credentials").Single());
        Assert.Contains("X-Auth-Mode",
            string.Join(",", response.Headers.GetValues("Access-Control-Allow-Headers")),
            StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task Preflight_FromAnotherOrigin_IsNotAllowed()
    {
        var request = new HttpRequestMessage(HttpMethod.Options, "/api/auth/refresh");
        request.Headers.Add("Origin", "https://evil.example");
        request.Headers.Add("Access-Control-Request-Method", "POST");
        request.Headers.Add("Access-Control-Request-Headers", "x-auth-mode");

        var response = await _client.SendAsync(request, Ct);

        Assert.False(response.Headers.Contains("Access-Control-Allow-Origin"));
        Assert.False(response.Headers.Contains("Access-Control-Allow-Credentials"));
    }
}