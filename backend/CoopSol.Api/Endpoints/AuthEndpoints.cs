using System.Security.Claims;
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

        publicGroup.MapPost("/login", async (LoginRequest request, AuthService auth, CancellationToken ct) =>
            (await auth.LoginAsync(request, ct)).ToHttp(Results.Ok));

        publicGroup.MapPost("/refresh", async (RefreshTokenRequest request, AuthService auth, CancellationToken ct) =>
            (await auth.RefreshAsync(request, ct)).ToHttp(Results.Ok));

        publicGroup.MapPost("/logout", async (RefreshTokenRequest request, AuthService auth, CancellationToken ct) =>
            (await auth.LogoutAsync(request, ct)).ToHttp(() => Results.NoContent()));

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
}