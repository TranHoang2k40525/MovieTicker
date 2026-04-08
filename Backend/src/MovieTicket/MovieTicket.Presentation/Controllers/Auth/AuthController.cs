using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieTicket.Application.DTOs.Auth;
using MovieTicket.Application.IServices;
using System.Security.Claims;

namespace MovieTicket.Presentation.Controllers.Auth
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly ILogger<AuthController> _logger;

        public AuthController(IAuthService authService, ILogger<AuthController> logger)
        {
            _authService = authService;
            _logger = logger;
        }

        /// <summary>
        /// Đăng ký tài khoản mới
        /// </summary>
        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] RegisterDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Input không hợp lệ" });

                var (success, message) = await _authService.RegisterAsync(request);

                if (!success)
                    return BadRequest(new { success = false, message });

                return Ok(new { success = true, message });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi đăng ký: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra, vui lòng thử lại" });
            }
        }

        /// <summary>
        /// Xác thực OTP
        /// </summary>
        [HttpPost("verify-otp")]
        [AllowAnonymous]
        public async Task<IActionResult> VerifyOtp([FromBody] OTPDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Input không hợp lệ" });

                var (success, message) = await _authService.VerifyRegistrationOtpAsync(request);

                if (!success)
                    return BadRequest(new { success = false, message });

                return Ok(new { success = true, message });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi xác thực OTP: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra, vui lòng thử lại" });
            }
        }

        /// <summary>
        /// Hủy bỏ quá trình đăng ký & Xóa OTP
        /// </summary>
        [HttpPost("cancel-registration")]
        [AllowAnonymous]
        public async Task<IActionResult> CancelRegistration([FromBody] CancelOtpRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Input không hợp lệ" });

                var (success, message) = await _authService.CancelRegistrationAsync(request);

                if (!success)
                    return BadRequest(new { success = false, message });

                return Ok(new { success = true, message });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi hủy OTP: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra, vui lòng thử lại" });
            }
        }

        /// <summary>
        /// Đăng nhập
        /// </summary>
        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] LoginDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Input không hợp lệ" });

                string ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "Unknown";
                string deviceInfo = Request.Headers["User-Agent"].ToString();

                var (success, response, message) = await _authService.LoginAsync(request, ipAddress, deviceInfo);

                if (!success)
                    return Unauthorized(new { success = false, message });

                return Ok(new { success = true, data = response, message });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi đăng nhập: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra, vui lòng thử lại" });
            }
        }

        /// <summary>
        /// Quên mật khẩu
        /// </summary>
        [HttpPost("forgot-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequestDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Input không hợp lệ" });

                var (success, message) = await _authService.ForgotPasswordAsync(request);
                return Ok(new { success, message });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi quên mật khẩu: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra, vui lòng thử lại" });
            }
        }

        /// <summary>
        /// Reset mật khẩu
        /// </summary>
        [HttpPost("reset-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequestDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Input không hợp lệ" });

                var (success, message) = await _authService.ResetPasswordAsync(request);

                if (!success)
                    return BadRequest(new { success = false, message });

                return Ok(new { success = true, message });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi reset mật khẩu: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra, vui lòng thử lại" });
            }
        }

        /// <summary>
        /// Đổi mật khẩu (cần auth)
        /// </summary>
        [HttpPost("change-password")]
        [Authorize]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequestDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Input không hợp lệ" });

                var accountIdClaim = User.FindFirst("accountId")?.Value;
                if (!int.TryParse(accountIdClaim, out int accountId))
                    return Unauthorized(new { success = false, message = "Token không hợp lệ" });

                var (success, message) = await _authService.ChangePasswordAsync(accountId, request);

                if (!success)
                    return BadRequest(new { success = false, message });

                return Ok(new { success = true, message });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi đổi mật khẩu: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra, vui lòng thử lại" });
            }
        }

        /// <summary>
        /// Cấp lại Access Token
        /// </summary>
        [HttpPost("refresh-token")]
        [AllowAnonymous]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequestDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Input không hợp lệ" });

                var (success, response, message) = await _authService.RefreshTokenAsync(request);

                if (!success)
                    return Unauthorized(new { success = false, message });

                return Ok(new { success = true, data = response, message });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi cấp lại token: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra, vui lòng thử lại" });
            }
        }

        /// <summary>
        /// Đăng xuất
        /// </summary>
        [HttpPost("logout")]
        [AllowAnonymous]
        public async Task<IActionResult> Logout([FromBody] RefreshTokenRequestDto request)
        {
            try
            {
                if (string.IsNullOrEmpty(request.RefreshToken))
                    return BadRequest(new { success = false, message = "Refresh token không được để trống" });

                var (success, message) = await _authService.LogoutAsync(request.RefreshToken);

                if (!success)
                    return BadRequest(new { success = false, message });

                return Ok(new { success = true, message });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi đăng xuất: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra, vui lòng thử lại" });
            }
        }

        /// <summary>
        /// Đăng xuất tất cả thiết bị
        /// </summary>
        [HttpPost("logout-all")]
        [Authorize]
        public async Task<IActionResult> LogoutAllDevices()
        {
            try
            {
                var accountIdClaim = User.FindFirst("accountId")?.Value;
                if (!int.TryParse(accountIdClaim, out int accountId))
                    return Unauthorized(new { success = false, message = "Token không hợp lệ" });

                var (success, message) = await _authService.LogoutAllDevicesAsync(accountId);

                if (!success)
                    return BadRequest(new { success = false, message });

                return Ok(new { success = true, message });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi đăng xuất tất cả: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra, vui lòng thử lại" });
            }
        }

        /// <summary>
        /// Tạo tài khoản Employee (Manager/Staff) - Chỉ dành cho Admin/Manager
        /// </summary>
        [HttpPost("create-employee")]
        [Authorize(Roles = "Admin,Manager")]
        public async Task<IActionResult> CreateEmployee([FromBody] CreateEmployeeDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ" });

                var currentUserRoles = User.Claims.Where(c => c.Type == ClaimTypes.Role).Select(c => c.Value).ToList();

                var (success, message) = await _authService.CreateEmployeeAsync(request, currentUserRoles);
                if (!success)
                    return BadRequest(new { success = false, message });

                return Ok(new { success = true, message });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi tạo nhân viên: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra, vui lòng thử lại" });
            }
        }

        /// <summary>
        /// Cập nhật trạng thái tài khoản (Khóa/Mở Khóa)
        /// </summary>
        [HttpPut("account/{id}/status")]
        [Authorize(Roles = "Admin,Manager")]
        public async Task<IActionResult> ChangeAccountStatus(int id, [FromQuery] MovieTicket.Domain.Entities.Status status)
        {
            try
            {
                var currentUserRoles = User.Claims.Where(c => c.Type == ClaimTypes.Role).Select(c => c.Value).ToList();
                var (success, message) = await _authService.ChangeAccountStatusAsync(id, status, currentUserRoles);

                if (!success)
                    return BadRequest(new { success = false, message });

                return Ok(new { success = true, message });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi khóa tài khoản: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra, vui lòng thử lại" });
            }
        }

        /// <summary>
        /// Xóa tài khoản
        /// </summary>
        [HttpDelete("account/{id}")]
        [Authorize(Roles = "Admin,Manager")]
        public async Task<IActionResult> DeleteAccount(int id)
        {
            try
            {
                var currentUserRoles = User.Claims.Where(c => c.Type == ClaimTypes.Role).Select(c => c.Value).ToList();
                var (success, message) = await _authService.DeleteAccountAsync(id, currentUserRoles);

                if (!success)
                    return BadRequest(new { success = false, message });

                return Ok(new { success = true, message });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi xóa tài khoản: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra, vui lòng thử lại" });
            }
        }
    }
}
