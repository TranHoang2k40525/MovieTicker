using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using MovieTicket.Application.DTOs.User;
using System;
using System.Security.Claims;
using System.Threading.Tasks;

namespace MovieTicket.Presentation.Controllers.User
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class UserController : ControllerBase
    {
        private readonly MovieTicket.Application.IServices.IUserService _userService;
        private readonly ILogger<UserController> _logger;

        public UserController(
            MovieTicket.Application.IServices.IUserService userService,
            ILogger<UserController> logger)
        {
            _userService = userService;
            _logger = logger;
        }

        private int GetAccountIdFromClaims()
        {
            var accountIdClaim = User.FindFirst("accountId")?.Value;
            if (int.TryParse(accountIdClaim, out int accountId))
            {
                return accountId;
            }
            return 0;
        }

        /// <summary>
        /// Lấy thông tin Profile (dành cho mọi cấp độ)
        /// </summary>
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile()
        {
            try
            {
                var accountId = GetAccountIdFromClaims();
                if (accountId == 0)
                    return Unauthorized(new { success = false, message = "Token không hợp lệ" });

                var result = await _userService.GetProfileAsync(accountId);
                if (!result.Success)
                    return BadRequest(new { success = false, message = result.Message });

                return Ok(new { success = true, data = result.Profile });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi GetProfile API: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra" });
            }
        }

        /// <summary>
        /// Cập nhật thông tin Profile
        /// </summary>
        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateUserProfileDto request)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(new { success = false, message = "Dữ liệu cập nhật không hợp lệ" });

                var accountId = GetAccountIdFromClaims();
                if (accountId == 0)
                    return Unauthorized(new { success = false, message = "Token không hợp lệ" });

                var result = await _userService.UpdateProfileAsync(accountId, request);
                if (!result.Success)
                    return BadRequest(new { success = false, message = result.Message });

                return Ok(new { success = true, message = "Cập nhật thành công", data = result.Profile });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi UpdateProfile API: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra" });
            }
        }

        /// <summary>
        /// Tải Avatar (Xóa ảnh cũ và thay bằng ảnh mới với chuẩn định dạng thư mục)
        /// </summary>
        [HttpPost("avatar")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadAvatar(IFormFile file)
        {
            try
            {
                var accountId = GetAccountIdFromClaims();
                if (accountId == 0)
                    return Unauthorized(new { success = false, message = "Token không hợp lệ" });

                if (file == null || file.Length == 0)
                    return BadRequest(new { success = false, message = "File ảnh không được để trống" });

                var result = await _userService.UploadAvatarAsync(accountId, file);
                if (!result.Success)
                    return BadRequest(new { success = false, message = result.Message });

                return Ok(new { success = true, message = result.Message, avatarUrl = result.AvatarUrl });
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi Upload Avatar API: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra" });
            }
        }

        /// <summary>
        /// Xem (hoặc lấy file byte) Ảnh Đại Diện trực tiếp qua HTTP GET
        /// </summary>
        [HttpGet("avatar")]
        [AllowAnonymous]
        public async Task<IActionResult> GetAvatar([FromQuery] int accountId)
        {
            try
            {
                var targetId = accountId;

                // Nếu không truyền ID thì lấy của chính user đang đăng nhập (NẾU CÓ TOKEN)
                if (targetId <= 0)
                {
                    targetId = GetAccountIdFromClaims();
                }

                if (targetId <= 0)
                    return BadRequest(new { success = false, message = "Vui lòng cung cấp accountId hoặc đăng nhập" });

                var result = await _userService.GetAvatarBytesAsync(targetId);
                if (!result.Success || result.FileBytes == null)
                    return NotFound(new { success = false, message = result.Message });

                return File(result.FileBytes, result.ContentType ?? "application/octet-stream");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi GetAvatar Image API: {ex.Message}");
                return StatusCode(500, new { success = false, message = "Có lỗi xảy ra" });
            }
        }
    }
}
