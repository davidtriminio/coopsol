namespace CoopSol.Application.Abstractions;

public sealed class UniqueConstraintViolationException(Exception innerException)
: Exception("Se violó una restricción de unicidad.", innerException);