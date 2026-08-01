using System.Diagnostics;
using AllInFit.Shared.Result;
using AllInFit.Shared.Security;
using Xunit;

namespace AllInFit.Tests.Unit;

public sealed class ResultAndPasswordHasherTests
{
    [Fact]
    public void SuccessResult_ExposesValue()
    {
        var result = Result.Success("ok");

        Assert.True(result.IsSuccess);
        Assert.Equal("ok", result.Value);
    }

    [Fact]
    public void FailureResult_ExposesError()
    {
        var error = new Error("Test.Error", "Failure", ErrorType.Validation);

        var result = Result.Failure<string>(error);

        Assert.True(result.IsFailure);
        Assert.Equal(error.Code, result.Error.Code);
        Assert.Equal(error.Message, result.Error.Message);
    }

    [Fact]
    public void FailedResultValueAccess_Throws()
    {
        var result = Result.Failure<string>(new Error("Test.Error", "Failure", ErrorType.Validation));

        Assert.Throws<InvalidOperationException>(() => _ = result.Value);
    }

    [Fact]
    public void PasswordHasher_RoundTripsPassword()
    {
        var hash = PasswordHasher.HashPassword("Str0ng!Pass123");

        Assert.True(PasswordHasher.VerifyPassword("Str0ng!Pass123", hash));
        Assert.False(PasswordHasher.VerifyPassword("wrong-password", hash));
    }
}