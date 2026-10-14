using System.Net.Mail;
using CoopSol.Domain.Enums;

namespace CoopSol.Application.Auth;

public static class AuthValidator
{
    public const int MinPasswordLength = 8;
    public const int MaxPasswordLength = 128;

    public static Dictionary<string, string[]> ValidateCredentials(
        string? email, string? password, string? fullName = null, bool checkFullName = false)
    {
        var errors = new Dictionary<string, string[]>();

        if (!IsValidEmail(email))
            errors["email"] = ["El correo no tiene un formato válido."];

        if (string.IsNullOrEmpty(password) || password.Length < MinPasswordLength || password.Length > MaxPasswordLength)
            errors["password"] = [$"La contraseña debe tener entre {MinPasswordLength} y {MaxPasswordLength} caracteres"];

        if (checkFullName)
        {
            var name = fullName?.Trim();
            if (string.IsNullOrEmpty(name) || name.Length < 2 || name.Length > 150)
            {
                errors["fullName"] = ["El nombre debe tener entre 2 y 150 caracteres"];

            }
        }
            return (errors);
    }

    public static bool TryParseRole(string? value, out UserRole role)
    {
        role = default;
        if (string.IsNullOrWhiteSpace(value)) return false;

        foreach (var name in Enum.GetNames<UserRole>())
        {
            if (string.Equals(name, value.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                role = Enum.Parse<UserRole>(name);
                return true;
            }
        }
        return false;
    }

    private static bool IsValidEmail(string? email)
    {
        if (string.IsNullOrWhiteSpace(email) || email.Length > 254) return false;
        var trimmed = email.Trim();
        return MailAddress.TryCreate(trimmed, out var parsed) && parsed.Address == trimmed;
    }
}