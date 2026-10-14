using CoopSol.Domain.Enums;

namespace CoopSol.Domain.Entities;

public sealed class User
{
    private User()
    {
    }

    public Guid Id { get; private set; }
    public string Email { get; private set; } = string.Empty;
    public string PasswordHash { get; private set; } = string.Empty;
    public string FullName { get; private set; } = string.Empty;
    public UserRole Role { get; private set; }
    public bool IsActive { get; private set; }
    public DateTime CreatedAtUtc { get; private set; }

    public static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();

    public static User Create(string email, string passwordHash, string fullName, UserRole role, DateTime nowUtc)
    {
        return new User
        {
            Id = Guid.CreateVersion7(),
            Email = NormalizeEmail(email),
            PasswordHash = passwordHash,
            FullName = fullName.Trim(),
            Role = role,
            IsActive = true,
            CreatedAtUtc = nowUtc
        };
    }
}