using Microsoft.Extensions.Options;

namespace CoopSol.Api.Endpoints;

public class RefreshCookie
{
    public const string Name = "coopsol_refresh";
    public const string CookiePath = "/api/auth";
    public const string ModeHeader = "X-Auth-Mode";
    public const string CookieMode = "cookie";

    public static bool IsRequested(HttpRequest request) =>
        string.Equals(request.Headers[ModeHeader], CookieMode, StringComparison.OrdinalIgnoreCase);

    public static string? Read(HttpRequest request) =>
        request.Cookies.TryGetValue(Name, out var value) ? value : null;

    public static void Write(HttpResponse response, string token, DateTimeOffset expiresAt) =>
        response.Cookies.Append(Name, token, Options(expiresAt));

    public static void Clear(HttpResponse response) =>
        response.Cookies.Delete(Name, Options(null));

    private static CookieOptions Options(DateTimeOffset? expiresAt) => new()
    {
        HttpOnly = true,
        Secure = true,
        SameSite = SameSiteMode.Strict,
        Path = CookiePath,
        Expires = expiresAt
    };
}