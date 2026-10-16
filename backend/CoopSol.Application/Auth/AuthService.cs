using CoopSol.Application.Abstractions;
using CoopSol.Domain.Entities;
using CoopSol.Domain.Enums;

namespace CoopSol.Application.Auth;

public sealed class AuthService(
    IUserRepository users,
    IRefreshTokenRepository refreshTokens,
    IUnitOfWork unitOfWork,
    IPasswordHasher hasher,
    ITokenService tokens,
    JwtOptions jwtOptions,
    TimeProvider clock)
{
    public Task<Result<UserDto>> RegisterAsync(RegisterRequest request, CancellationToken ct = default) =>
        CreateUserInternalAsync(request.Email, request.Password, request.FullName, UserRole.Socio, ct);

    public async Task<Result<UserDto>> CreateUserAsync(CreateUserRequest request, CancellationToken ct = default)
    {
        if (!AuthValidator.TryParseRole(request.Role, out var role))
        {
            return Result<UserDto>.Failure(AuthErrors.Validation(new Dictionary<string, string[]>
            {
                ["role"] = [$"Rol inválido. Valores permitidos: {string.Join(", ", Enum.GetNames<UserRole>())}."]
            }));
        }
        return await CreateUserInternalAsync(request.Email, request.Password, request.FullName, role, ct);
    }

    public async Task<Result<AuthResponse>> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        if (AuthValidator.ValidateCredentials(request.Email, request.Password).Count > 0)
            return Result<AuthResponse>.Failure(AuthErrors.InvalidCredentials);

        var user = await users.GetByEmailAsync(User.NormalizeEmail(request.Email), ct);

        var passwordOk = hasher.Verify(request.Password, user?.PasswordHash ?? hasher.DummyHash);

        if (user is null || !passwordOk || !user.IsActive)
            return Result<AuthResponse>.Failure(AuthErrors.InvalidCredentials);

        var (response, _) = IssueTokens(user);
        await unitOfWork.SaveChangesAsync(ct);
        return Result<AuthResponse>.Success(response);
    }

    public async Task<Result<AuthResponse>> RefreshAsync(RefreshTokenRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
            return Result<AuthResponse>.Failure(AuthErrors.InvalidRefreshToken);

        var now = clock.GetUtcNow().UtcDateTime;
        var stored = await refreshTokens.GetByHashAsync(tokens.HashRefreshToken(request.RefreshToken), ct);

        if (stored is null)
            return Result<AuthResponse>.Failure(AuthErrors.InvalidRefreshToken);
        if (stored.IsRevoked)
        {
            foreach (var active in await refreshTokens.GetActiveByUserAsync(stored.UserId, now, ct))
                active.Revoke(now);

            await unitOfWork.SaveChangesAsync(ct);
            return Result<AuthResponse>.Failure(AuthErrors.InvalidRefreshToken);
        }

        if (stored.IsExpired(now))
            return Result<AuthResponse>.Failure(AuthErrors.InvalidRefreshToken);

        var user = await users.GetByIdAsync(stored.UserId, ct);
        if (user is null || !user.IsActive)
            return Result<AuthResponse>.Failure(AuthErrors.InvalidRefreshToken);

        var (response, newTokenId) = IssueTokens(user);
        stored.Revoke(now, newTokenId);

        await unitOfWork.SaveChangesAsync(ct);
        return Result<AuthResponse>.Success(response);
    }

    public async Task<Result> LogoutAsync(RefreshTokenRequest request, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
            return Result.Success();

        var now = clock.GetUtcNow().UtcDateTime;
        var stored = await refreshTokens.GetByHashAsync(tokens.HashRefreshToken(request.RefreshToken), ct);

        if (stored is not null && stored.IsActive(now))
        {
            stored.Revoke(now);
            await unitOfWork.SaveChangesAsync(ct);
        }
        return Result.Success();
    }

    public async Task<Result<UserDto>> GetProfileAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await users.GetByIdAsync(userId, ct);
        return user is null || !user.IsActive
            ? Result<UserDto>.Failure(AuthErrors.UserNotFound)
            : Result<UserDto>.Success(ToDto(user));
    }

    private async Task<Result<UserDto>> CreateUserInternalAsync(
        string email, string password, string fullName, UserRole role, CancellationToken ct)
    {
        var errors = AuthValidator.ValidateCredentials(email, password, fullName, checkFullName: true);
        if (errors.Count > 0)
            return Result<UserDto>.Failure(AuthErrors.Validation(errors));

        var normalizedEmail = User.NormalizeEmail(email);
        if (await users.ExistsByEmailAsync(normalizedEmail, ct))
            return Result<UserDto>.Failure(AuthErrors.EmailTaken);

        var user = User.Create(normalizedEmail, hasher.Hash(password), fullName, role, clock.GetUtcNow().UtcDateTime);
        users.Add(user);
        try
        {
            await unitOfWork.SaveChangesAsync(ct);
        }
        catch (UniqueConstraintViolationException)
        {
            return Result<UserDto>.Failure(AuthErrors.EmailTaken);
        }

        return Result<UserDto>.Success(ToDto(user));
    }

    private (AuthResponse Response, Guid NewTokenId) IssueTokens(User user)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var access = tokens.CreateAccessToken(user);
        var rawRefresh = tokens.GenerateRefreshToken();

        var entity = RefreshToken.Create(
            user.Id,
            tokens.HashRefreshToken(rawRefresh),
            now,
            TimeSpan.FromDays(jwtOptions.RefreshTokenDays));
        refreshTokens.Add(entity);

        var expiresIn = (int)(access.ExpiresAtUtc - now).TotalSeconds;
        return (new AuthResponse(access.Value, rawRefresh, expiresIn, ToDto(user)), entity.Id);
    }

    private static UserDto ToDto(User user) =>
        new(user.Id, user.Email, user.FullName, user.Role.ToString(), user.IsActive);
}