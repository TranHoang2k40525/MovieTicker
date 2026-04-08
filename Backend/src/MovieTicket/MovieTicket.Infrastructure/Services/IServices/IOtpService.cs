using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MovieTicket.Infrastructure.Services.IServices
{
    public interface IOtpService
    {
        Task<string> GenerateAndSendOtpAsync(int accountId, string purpose, string email);
        Task<bool> VerifyOtpAsync(int accountId, string otpCode, string purpose);
        Task<bool> IsOtpValidAsync(int accountId, string purpose);



    }
}
