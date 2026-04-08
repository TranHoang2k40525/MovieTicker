using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using MovieTicket.Application.DTOs.User;
using MovieTicket.Application.IServices;
using MovieTicket.Domain.IResponsitories.IAuth;
using System;
using System.IO;
using System.Threading.Tasks;

namespace MovieTicket.Application.Services
{
    public class UserService : IUserService
    {
        private readonly IUserRepository _userRepository;
        private readonly IAccountRepository _accountRepository;
        private readonly ILogger<UserService> _logger;

        public UserService(
            IUserRepository userRepository,
            IAccountRepository accountRepository,
            ILogger<UserService> logger)
        {
            _userRepository = userRepository;
            _accountRepository = accountRepository;
            _logger = logger;
        }

        public async Task<(bool Success, UserProfileDto? Profile, string Message)> GetProfileAsync(int accountId)
        {
            try
            {
                var user = await _userRepository.GetByAccountIdAsync(accountId);
                if (user == null)
                    return (false, null, "Không tìm thấy thông tin người dùng");

                var profile = new UserProfileDto
                {
                    UserId = user.UserId,
                    AccountId = user.AccountId,
                    FullName = user.FullName,
                    Email = user.Email,
                    Phone = user.Phone,
                    Gender = user.Gender,
                    DateOfBirth = user.DateOfBirth,
                    Address = user.Address,
                    AvatarUrl = user.AvatarUrl
                };

                return (true, profile, "Thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi lấy profile: {ex.Message}");
                return (false, null, "Lỗi xảy ra khi lấy thông tin");
            }
        }

        public async Task<(bool Success, UserProfileDto? Profile, string Message)> UpdateProfileAsync(int accountId, UpdateUserProfileDto request)
        {
            try
            {
                var user = await _userRepository.GetByAccountIdAsync(accountId);
                if (user == null)
                    return (false, null, "Không tìm thấy thông tin người dùng");

                var account = await _accountRepository.GetByIdAsync(accountId);
                if (account == null)
                    return (false, null, "Tài khoản không tồn tại");

                // Cập nhật thông tin User profile
                user.FullName = request.FullName;
                user.Phone = request.Phone;
                user.Gender = request.Gender;
                user.DateOfBirth = request.DateOfBirth;
                user.Address = request.Address;

                // Đồng bộ số điện thoại sang bảng Account nếu cần
                if (account.Phone != request.Phone)
                {
                    account.Phone = request.Phone;
                    account.UpdatedAt = DateTime.UtcNow;
                    await _accountRepository.UpdateAsync(account);
                }

                await _userRepository.UpdateAsync(user);

                var profileDto = new UserProfileDto
                {
                    UserId = user.UserId,
                    AccountId = user.AccountId,
                    FullName = user.FullName,
                    Email = user.Email,
                    Phone = user.Phone,
                    Gender = user.Gender,
                    DateOfBirth = user.DateOfBirth,
                    Address = user.Address,
                    AvatarUrl = string.IsNullOrWhiteSpace(user.AvatarUrl) ? null : user.AvatarUrl
                };

                return (true, profileDto, "Cập nhật thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi cập nhật profile: {ex.Message}");
                return (false, null, "Lỗi xảy ra khi cập nhật thông tin");
            }
        }

        public async Task<(bool Success, string? AvatarUrl, string Message)> UploadAvatarAsync(int accountId, IFormFile file)
        {
            try
            {
                if (file == null || file.Length == 0)
                    return (false, null, "Vui lòng chọn một ảnh hợp lệ");

                var user = await _userRepository.GetByAccountIdAsync(accountId);
                if (user == null)
                    return (false, null, "Không tìm thấy người dùng");

                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
                var extension = Path.GetExtension(file.FileName).ToLower();
                if (Array.IndexOf(allowedExtensions, extension) == -1)
                    return (false, null, "Chỉ hỗ trợ định dạng ảnh (.jpg, .jpeg, .png, .gif, .webp)");

                if (file.Length > 5 * 1024 * 1024)
                    return (false, null, "Kích thước ảnh tối đa 5MB");

                // Determine target directory (Assets/UserImagers relative to MovieTicket root)
                // Cung cấp thư mục cùng cấp với MovieTicket, tức là trong src/Assets/UserImagers
                var projectDirectory = Directory.GetCurrentDirectory(); 
                var solutionRoot = Directory.GetParent(projectDirectory)?.FullName ?? projectDirectory;
                var assetsFolder = Path.Combine(solutionRoot, "Assets", "UserImagers");

                if (!Directory.Exists(assetsFolder))
                {
                    Directory.CreateDirectory(assetsFolder);
                }

                // Delete old avatar if exists
                if (!string.IsNullOrWhiteSpace(user.AvatarUrl))
                {
                    var oldFileName = Path.GetFileName(user.AvatarUrl); // Assume AvatarUrl contains the filename or is the filename
                    var oldFilePath = Path.Combine(assetsFolder, oldFileName);
                    if (File.Exists(oldFilePath))
                    {
                        File.Delete(oldFilePath);
                    }
                }

                // Generate new file name like "FullName_UserId_Date.ext"
                // Handle Vietnamese or special chars in FullName safely for OS file
                var safeName = string.IsNullOrWhiteSpace(user.FullName) ? "User" : string.Join("_", user.FullName.Split(Path.GetInvalidFileNameChars()));
                safeName = safeName.Replace(" ", "");
                var dateStr = DateTime.UtcNow.ToString("yyyyMMddHHmmss");

                var newFileName = $"{safeName}_{user.UserId}_{dateStr}{extension}";
                var newFilePath = Path.Combine(assetsFolder, newFileName);

                using (var stream = new FileStream(newFilePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                // We save just the filename as URL or relative path to fetch it dynamically
                user.AvatarUrl = newFileName;
                await _userRepository.UpdateAsync(user);

                return (true, newFileName, "Tải ảnh đại diện thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi tải ảnh đại diện: {ex.Message}");
                return (false, null, "Lỗi xảy ra khi tải ảnh đại diện");
            }
        }

        public async Task<(bool Success, byte[]? FileBytes, string? ContentType, string Message)> GetAvatarBytesAsync(int accountId)
        {
            try
            {
                var user = await _userRepository.GetByAccountIdAsync(accountId);
                if (user == null || string.IsNullOrWhiteSpace(user.AvatarUrl))
                    return (false, null, null, "Người dùng chưa có ảnh đại diện");

                var projectDirectory = Directory.GetCurrentDirectory();
                var solutionRoot = Directory.GetParent(projectDirectory)?.FullName ?? projectDirectory;
                var assetsFolder = Path.Combine(solutionRoot, "Assets", "UserImagers");

                var oldFileName = Path.GetFileName(user.AvatarUrl);
                var filePath = Path.Combine(assetsFolder, oldFileName);

                if (!File.Exists(filePath))
                    return (false, null, null, "Video hoặc ảnh không tồn tại");

                var bytes = await File.ReadAllBytesAsync(filePath);

                var extension = Path.GetExtension(filePath).ToLower();
                string contentType = extension switch
                {
                    ".jpg" or ".jpeg" => "image/jpeg",
                    ".png" => "image/png",
                    ".gif" => "image/gif",
                    ".webp" => "image/webp",
                    _ => "application/octet-stream"
                };

                return (true, bytes, contentType, "Thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi lấy file ảnh byte: {ex.Message}");
                return (false, null, null, "Lỗi xảy ra");
            }
        }
    }
}
