namespace AllInFit.Shared.Result;

public sealed class Error : IEquatable<Error>
{
    public string Code { get; }
    public string Description { get; }
    public ErrorType Type { get; }
    public Dictionary<string, object>? Metadata { get; }

    private Error(string code, string description, ErrorType type, Dictionary<string, object>? metadata = null)
    {
        Code = code;
        Description = description;
        Type = type;
        Metadata = metadata;
    }

    public static readonly Error None = new(string.Empty, string.Empty, ErrorType.Failure);
    public static readonly Error NullValue = new("Error.NullValue", "A null value was provided where a non-null value was expected.", ErrorType.Failure);

    public static Error NotFound(string code = "NotFound", string description = "The requested resource was not found.") =>
        new(code, description, ErrorType.NotFound);

    public static Error Validation(string code = "ValidationError", string description = "A validation error occurred.", Dictionary<string, object>? metadata = null) =>
        new(code, description, ErrorType.Validation, metadata);

    public static Error Conflict(string code = "Conflict", string description = "A conflict occurred with the current state of the resource.") =>
        new(code, description, ErrorType.Conflict);

    public static Error Unauthorized(string code = "Unauthorized", string description = "You are not authorized to perform this action.") =>
        new(code, description, ErrorType.Unauthorized);

    public static Error Forbidden(string code = "Forbidden", string description = "You do not have permission to access this resource.") =>
        new(code, description, ErrorType.Forbidden);

    public static Error Internal(string code = "InternalError", string description = "An internal server error occurred.") =>
        new(code, description, ErrorType.Internal);

    public static Error BadRequest(string code = "BadRequest", string description = "The request was invalid.") =>
        new(code, description, ErrorType.BadRequest);

    public override string ToString() => $"{Code}: {Description}";

    public bool Equals(Error? other)
    {
        if (other is null) return false;
        if (ReferenceEquals(this, other)) return true;
        return Code == other.Code && Description == other.Description && Type == other.Type;
    }

    public override bool Equals(object? obj) => ReferenceEquals(this, obj) || (obj is Error other && Equals(other));

    public override int GetHashCode() => HashCode.Combine(Code, Description, (int)Type);

    public static bool operator ==(Error? left, Error? right) => left?.Equals(right) ?? right is null;
    public static bool operator !=(Error? left, Error? right) => !(left == right);
}

public enum ErrorType
{
    Failure = 0,
    Validation = 1,
    NotFound = 2,
    Conflict = 3,
    Unauthorized = 4,
    Forbidden = 5,
    Internal = 6,
    BadRequest = 7
}
