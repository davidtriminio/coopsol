namespace CoopSol.Application.Auth;

public sealed record RegisterRequest(string Email, string Password, string FullName);

public sealed record CreateUserRequest(string Email, string Password, string FullName, string Role);

public sealed record LoginRequest(string Email, string Password);

public sealed record RefreshTokenRequest(string RefreshToken);

public sealed record UserDto(Guid Id, string Email, string FullName, string Role, bool IsActive);

public sealed record AuthResponse(string AccessToken, string RefreshToken, int ExpiresInSeconds, UserDto User);