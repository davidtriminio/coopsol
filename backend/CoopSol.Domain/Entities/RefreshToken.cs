namespace CoopSol.Domain.Entities;

public sealed class RefreshToken
{
    private RefreshToken(){}

    public Guid Id { get; private set; }
    public Guid UserId { get; private set; }
    public string TokenHash { get; private set; } = string.Empty;
    public DateTime CreatedAtUtc { get; private set; }
    public DateTime ExpiresAtUtc { get; private set; }
    public DateTime? RevokedAtUtc { get; private set; }
    public Guid? ReplaceByTokenId { get; private set; }

    public bool IsRevoked => RevokedAtUtc.HasValue;
    public bool IsExpired(DateTime nowUtc) => nowUtc >= ExpiresAtUtc;
    public bool IsActive(DateTime nowUtc) => !IsRevoked && !IsExpired(nowUtc);

    public static RefreshToken Create(Guid userId, string tokenHash, DateTime nowUtc, TimeSpan lifetime)
    {
        return new RefreshToken
        {
            Id = Guid.CreateVersion7(),
            UserId = userId,
            TokenHash = tokenHash,
            CreatedAtUtc = nowUtc,
            ExpiresAtUtc = nowUtc.Add(lifetime)
        };
    }

    public void Revoke(DateTime nowUtc, Guid? replaceByTokenId = null)
    {
        if (IsRevoked) return;
        RevokedAtUtc = nowUtc;
        ReplaceByTokenId = replaceByTokenId;
    }

}