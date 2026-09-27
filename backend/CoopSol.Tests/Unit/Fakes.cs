using CoopSol.Application.Abstractions;
using CoopSol.Domain.Entities;

namespace CoopSol.Tests.Unit;

internal sealed class TestClock : TimeProvider
{
    private DateTimeOffset _now = new(2026, 1, 1, 12, 0, 0, TimeSpan.Zero);

    public override DateTimeOffset GetUtcNow() => _now;

    public void Advance(TimeSpan time) => _now += time;
}

internal sealed class FakePasswordHasser : IPasswordHasher
{
    public string DummyHash => "hash:__dummy";
    public string Hash(string password) => "hash:" + password;

    public bool Verify(string password, string hash) => hash == "hash:" + password;
}

internal sealed class InMemoryStore : IUserRepository, IRefreshTokenRepository, IUnitOfWork
{
    public List<User> Users { get; } = [];
    public List<RefreshToken> Tokens { get; } = [];

    public Task<User?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
    Task.FromResult(Users.FirstOrDefault(u => u.Id == id));

    public Task<User?> GetByEmailAsync(string normalizedEmail, CancellationToken ct = default) =>
    Task.FromResult(Users.FirstOrDefault(u => u.Email == normalizedEmail));

    public Task<bool> ExistsByEmailAsync(string normalizedEmail, CancellationToken ct = default) =>
    Task.FromResult(Users.Any(u => u.Email == normalizedEmail));

    public void Add(User user)=>  Users.Add(user);

    public Task<RefreshToken?> GetByHashAsync(string tokenHash, CancellationToken ct = default) =>
    Task.FromResult(Tokens.FirstOrDefault(t => t.TokenHash == tokenHash));

    public Task<IReadOnlyList<RefreshToken>> GetActiveByUserAsync(Guid userId, DateTime nowUtc, CancellationToken ct = default) =>
    Task.FromResult<IReadOnlyList<RefreshToken>>(Tokens.Where(t => t.UserId == userId && t.IsActive(nowUtc)).ToList());

    public void Add(RefreshToken token) => Tokens.Add(token);

    public Task<int> SaveChangesAsync(CancellationToken ct = default) =>
    Task.FromResult(0);
}