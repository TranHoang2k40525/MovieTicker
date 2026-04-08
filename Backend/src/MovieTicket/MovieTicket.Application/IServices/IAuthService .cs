
using MovieTicket.Application.DTOs.Auth;

namespace MovieTicket.Application.IServices
{
    public interface IAuthService
    {
        Task<(bool Success, string Message)> RegisterAsync(RegisterDto request);
        Task<(bool Success, string Message)> VerifyRegistrationOtpAsync(OTPDto request);
        Task<(bool Success, string Message)> CancelRegistrationAsync(CancelOtpRequest request);

        Task<(bool Success, LoginResponseDto? Response, string Message)> LoginAsync(
            LoginDto request,
            string ipAddress,
            string deviceInfo
        );
        Task<(bool Success, string Message)> ForgotPasswordAsync(ForgotPasswordRequestDto request);
        Task<(bool Success, string Message)> ResetPasswordAsync(ResetPasswordRequestDto request);

        Task<(bool Success, string Message)> ChangePasswordAsync(
            int accountId,
            ChangePasswordRequestDto request
        );
        Task<(bool Success, LoginResponseDto? Response, string Message)> RefreshTokenAsync(
            RefreshTokenRequestDto request
        );
        Task<(bool Success, string Message)> LogoutAsync(string refreshToken);
        Task<(bool Success, string Message)> LogoutAllDevicesAsync(int accountId);

        // Account management APIs
        Task<(bool Success, string Message)> CreateEmployeeAsync(CreateEmployeeDto request, List<string> currentRoles);
        Task<(bool Success, string Message)> ChangeAccountStatusAsync(int targetAccountId, Domain.Entities.Status status, List<string> currentRoles);
        Task<(bool Success, string Message)> DeleteAccountAsync(int targetAccountId, List<string> currentRoles);
    }
}
