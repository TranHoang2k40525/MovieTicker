
using System.ComponentModel.DataAnnotations;

namespace MovieTicket.Application.DTOs.Auth
{
    public class OTPDto
    {
        [Required(ErrorMessage = "Email không được để trống")]
        [EmailAddress(ErrorMessage = "Email không hợp lệ")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Mã OTP không được để trống")]
        [RegularExpression(@"^\d{6}$", ErrorMessage = "Mã OTP phải là 6 chữ số")]
        public string OtpCode { get; set; } = string.Empty;
    }
}
