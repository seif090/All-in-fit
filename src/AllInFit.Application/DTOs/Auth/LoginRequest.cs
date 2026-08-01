namespace AllInFit.Application.DTOs.Auth;

public record LoginRequest(string Email, string Password, string? DeviceId = null, string? DeviceName = null);
public record RegisterRequest(string Email, string Password, string? FirstName, string? LastName, string? PhoneNumber);
public record TokenResponse(string AccessToken, string RefreshToken, DateTime ExpiresAt);
public record RefreshTokenRequest(string AccessToken, string RefreshToken);
public record ForgotPasswordRequest(string Email);
public record ResetPasswordRequest(string Email, string Token, string NewPassword);
public record VerifyEmailRequest(string Email, string Token);
public record OtpRequest(string PhoneNumber);
public record OtpVerifyRequest(string PhoneNumber, string Code);