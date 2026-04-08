using Microsoft.AspNetCore.Http;
using MovieTicket.Application.DTOs.User;
using System.Threading.Tasks;

namespace MovieTicket.Application.IServices
{
    public interface IUserService
    {
        Task<(bool Success, UserProfileDto? Profile, string Message)> GetProfileAsync(int accountId);
        Task<(bool Success, UserProfileDto? Profile, string Message)> UpdateProfileAsync(int accountId, UpdateUserProfileDto request);
        Task<(bool Success, string? AvatarUrl, string Message)> UploadAvatarAsync(int accountId, IFormFile file);
        Task<(bool Success, byte[]? FileBytes, string? ContentType, string Message)> GetAvatarBytesAsync(int accountId);
    }
}
