using CoopSol.Domain.Entities;

namespace CoopSol.Application.Abstractions;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<User?> GetByEmailAsync(string normalizedEmail, CancellationToken ct = default);
    Task<bool> ExistsByEmailAsync(string normalizedEmail, CancellationToken ct = default);
    void Add(User user);
}