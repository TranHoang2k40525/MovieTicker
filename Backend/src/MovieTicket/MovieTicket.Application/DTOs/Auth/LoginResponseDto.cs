using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MovieTicket.Application.DTOs.Auth
{
    public class LoginResponseDto
    {
        public int AccountId { get; set; }
        public string? Email { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string? AccessToken { get; set; }
        public string? RefreshToken { get; set; }
        public List<string> Roles { get; set; } = new List<string>();
        public DateTime AccessTokenExpiresAt { get; set; }
        public int ExpiresIn { get; set; }


    }
}
