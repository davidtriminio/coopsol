using System.Security.Claims;
using System.Text.Json;
using CoopSol.Api.Extensions;
using CoopSol.Application.Auth;

namespace CoopSol.Api.Endpoints;

public static class AuthEndpoints
{
    public static IEndpointRouteBuilder MapAuthEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth").WithTags("Auth");

        var publicGroup = group.MapGroup(string.Empty)
            .RequireRateLimiting(AuthServiceCollectionExtensions.AuthRateLimitPolicy);

        publicGroup.MapPost("/register", async (RegisterRequest request, AuthService auth, CancellationToken ct) =>
            (await auth.RegisterAsync(request, ct))
            .ToHttp(user => Results.Json(user, statusCode:StatusCodes.Status201Created)));

        publicGroup.MapPost("/login", async (
                LoginRequest request, HttpContext http, AuthService auth, JwtOptions jwt, TimeProvider clock, CancellationToken ct) =>
            (await auth.LoginAsync(request, ct)).ToHttp(response => RespondWithSession(http, response, jwt, clock)));

        publicGroup.MapPost("/refresh",
            async (HttpContext http, AuthService auth, JwtOptions jwt, TimeProvider clock, CancellationToken ct) =>
            {
                var result = await auth.RefreshAsync(new RefreshTokenRequest(await ReadRefreshTokenAsync(http, ct)), ct);
                if (!result.IsSuccess && RefreshCookie.IsRequested(http.Request))
                    RefreshCookie.Clear(http.Response);
                return result.ToHttp(response => RespondWithSession(http, response, jwt, clock));
            });

        publicGroup.MapPost("/logout", async (HttpContext http, AuthService auth, CancellationToken ct) =>
        {
            var result = await auth.LogoutAsync(new RefreshTokenRequest(await ReadRefreshTokenAsync(http, ct)), ct);
            if (RefreshCookie.IsRequested(http.Request))
                RefreshCookie.Clear(http.Response);

            return result.ToHttp(() => Results.NoContent());
        });

        group.MapGet("/me", async (ClaimsPrincipal principal, AuthService auth, CancellationToken ct) =>
            {
                var sub = principal.FindFirstValue("sub");
                if (!Guid.TryParse(sub, out var userId))
                    return Results.Unauthorized();

                return (await auth.GetProfileAsync(userId, ct)).ToHttp(Results.Ok);
            })
            .RequireAuthorization();

        return app;
    }

    private static async Task<string> ReadRefreshTokenAsync(HttpContext http, CancellationToken ct)
    {
        if (RefreshCookie.IsRequested(http.Request))
            return RefreshCookie.Read(http.Request) ?? string.Empty;

        if (!http.Request.HasJsonContentType())
            return string.Empty;
        try
        {
            var body = await http.Request.ReadFromJsonAsync<RefreshTokenRequest>(ct);
            return body?.RefreshToken ?? string.Empty;
        }
        catch (JsonException)
        {
            return string.Empty;
        }
    }
    private static IResult RespondWithSession(
        HttpContext http, AuthResponse response, JwtOptions jwt, TimeProvider clock)
    {
        if (!RefreshCookie.IsRequested(http.Request))
            return Results.Ok(response);

        RefreshCookie.Write(http.Response, response.RefreshToken, clock.GetUtcNow().AddDays(jwt.RefreshTokenDays));
        return Results.Ok(new SessionResponse(response.AccessToken, response.ExpiresInSeconds, response.User));
    }

}