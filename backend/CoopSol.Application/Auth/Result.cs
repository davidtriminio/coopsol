namespace CoopSol.Application.Auth;

public enum ErrorType
{
    Validation,
    Unauthorized,
    Conflict,
    NotFound,
}

public sealed record Error(
    ErrorType Type,
    string Code,
    string Message,
    IReadOnlyDictionary<string, string[]>? Details = null);

public class Result
{
    protected Result(Error? error) => Error = error;
    public Error? Error { get; }
    public bool IsSuccess => Error is null;

    public static Result Success() => new(null);
    public static Result Failure(Error error) => new(error);
}

public class Result<T> : Result
{
    private readonly T? _value;

    private Result(T value): base(null) =>_value = value;
    private Result(Error error): base(error) { }

    public T Value => _value ?? throw new InvalidOperationException("El resultado es un fallo; no tiene valor.");

    public static Result<T> Success(T value) => new(value);
    public new static Result<T> Failure(Error error) => new(error);
}

public static class AuthErrors
{
    public static readonly Error InvalidCredentials =
        new(ErrorType.Unauthorized, "auth.invalid_credentials", "Credenciales inválidas");

    public static readonly Error InvalidRefreshToken =
        new(ErrorType.Unauthorized, "auth.invalid_refresh_token", "El refresh token no existe, es inválido o fue revocado.");

    public static readonly Error EmailTaken =
    new(ErrorType.Conflict, "auth.email_taken", "Ya existe un usuario con ese correo.");

    public static readonly Error UserNotFound =
    new(ErrorType.NotFound, "auth.user_not_found", "Usuario no encontrado.");

    public static Error Validation(IReadOnlyDictionary<string, string[]> details) =>
        new(ErrorType.Validation, "auth.validation", "Uno o más campos son inválidos.", details);
}