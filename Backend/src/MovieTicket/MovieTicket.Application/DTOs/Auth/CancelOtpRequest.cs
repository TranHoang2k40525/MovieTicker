using System.ComponentModel.DataAnnotations;

namespace MovieTicket.Application.DTOs.Auth
{
    public class CancelOtpRequest
    {
        [Required(ErrorMessage = "Email không được để trống")]
        public string Email { get; set; } = string.Empty;
    }
}
