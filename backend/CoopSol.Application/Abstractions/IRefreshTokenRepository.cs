using CoopSol.Domain.Entities;

namespace CoopSol.Application.Abstractions;

public interface IRefreshTokenRepository
{
    Task<RefreshToken?> GetByHashAsync(string tokenHash, CancellationToken ct = default);
    Task<IReadOnlyList<RefreshToken>> GetActiveByUserAsync(Guid userId, DateTime nowUtc, CancellationToken ct = default);
    void Add(RefreshToken token);
}