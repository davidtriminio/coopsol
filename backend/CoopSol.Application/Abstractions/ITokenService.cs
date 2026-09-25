using CoopSol.Domain.Entities;

namespace CoopSol.Application.Abstractions;

public sealed record AccessToken(string Value, DateTime ExpiresAtUtc);

public interface ITokenService
{
    AccessToken CreateAccessToken(User user);
    string GenerateRefreshToken();
    string HashRefreshToken(string refreshToken);
}