using CoopSol.Application.Auth;

namespace CoopSol.Api.Extensions;

public static class ResultExtensions
{
    public static IResult ToHttp<T>(this Result<T> result, Func<T, IResult> onSuccess) =>
        result.IsSuccess ? onSuccess(result.Value) : ToProblem(result.Error!);

    public static IResult ToHttp(this Result result, Func<IResult> onSuccess) =>
    result.IsSuccess ? onSuccess() : ToProblem(result.Error!);

    private static IResult ToProblem(Error error) => error.Type switch
    {
        ErrorType.Validation => Results.ValidationProblem(
            error.Details!.ToDictionary(kv => kv.Key, kv => kv.Value),
            title: error.Message,
            type: error.Code),
        ErrorType.Unauthorized => Results.Problem(
            statusCode: StatusCodes.Status401Unauthorized, title: error.Message, type: error.Code),
        ErrorType.Conflict => Results.Problem(
            statusCode: StatusCodes.Status409Conflict, title: error.Message, type: error.Code),
        ErrorType.NotFound => Results.Problem(
            statusCode: StatusCodes.Status404NotFound, title: error.Message, type: error.Code),
        _ => Results.Problem(statusCode: StatusCodes.Status500InternalServerError)
    };
}