using System.ComponentModel.DataAnnotations;

namespace MovieTicket.Application.DTOs.Auth
{
    public class LoginDto
    {
        [Required(ErrorMessage = "Email hoặc điện thoại không được để trống")]
        public string EmailOrPhone { get; set; } = string.Empty;

        [Required(ErrorMessage = "Mật khẩu không được để trống")]
        [MinLength(6, ErrorMessage = "Mật khẩu phải có ít nhất 6 ký tự")]
        public string Password { get; set; } = string.Empty;
    }
}
