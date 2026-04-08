using System.ComponentModel.DataAnnotations;
using MovieTicket.Domain.Entities;

namespace MovieTicket.Application.DTOs.Auth
{
    public class CreateEmployeeDto
    {
        [Required(ErrorMessage = "Email không được để trống")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Số điện thoại không được để trống")]
        public string Phone { get; set; } = string.Empty;

        [Required(ErrorMessage = "Mật khẩu không được để trống")]
        [MinLength(6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự")]
        public string Password { get; set; } = string.Empty;

        [Required(ErrorMessage = "Tên đầy đủ không được để trống")]
        public string FullName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Quyền không được để trống (Manager hoặc Staff)")]
        public string RoleName { get; set; } = string.Empty;

        public int? CinemaId { get; set; }

        public string? Gender { get; set; }
        public DateOnly? DateOfBirth { get; set; }
        public string? Address { get; set; }
    }
}
