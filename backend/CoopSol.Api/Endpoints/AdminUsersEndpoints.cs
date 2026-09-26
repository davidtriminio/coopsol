using CoopSol.Api.Extensions;
using CoopSol.Application.Auth;
using CoopSol.Domain.Enums;

namespace CoopSol.Api.Endpoints;

public static class AdminUsersEndpoints
{
 public static IEndpointRouteBuilder MapAdminUsersEndpoints(this IEndpointRouteBuilder app)
 {
  var group = app.MapGroup("/api/admin/users")
   .WithTags("Admin")
   .RequireAuthorization(policy => policy.RequireRole(nameof(UserRole.Admin)));

  group.MapPost("/", async (CreateUserRequest request, AuthService auth, CancellationToken ct) =>
   (await auth.CreateUserAsync(request, ct))
   .ToHttp(user => Results.Json(user, statusCode: StatusCodes.Status201Created)));
  return app;
 }
}