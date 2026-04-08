using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MovieTicket.Domain.IResponsitories.IAuth;
using MovieTicket.Domain.Entities;
using MovieTicket.Infrastructure.Services.IServices;

namespace MovieTicket.Infrastructure.Services.Implementations
{
    public class OtpService : IOtpService
    {
        private readonly IEmailService _emailService;
        private readonly IOtpRepository _otpRepository;
        
        public OtpService(IEmailService emailService, IOtpRepository otpRepository)
        {
            _emailService = emailService;
            _otpRepository = otpRepository;
        }
        
        // Generate 6-digit OTP code
        private string GenerateOtpCode()
        {
            var random = new Random();
            int otp = random.Next(0, 1000000);
            return otp.ToString("D6");
        }
        
        // Generate and send OTP via email, auto-delete expired OTPs
        public async Task<string> GenerateAndSendOtpAsync(int accountId, string purpose, string email)
        {
            await _otpRepository.DeleteExpiredAsync(accountId, purpose);
            
            var otpCode = GenerateOtpCode();
            var otpHash = BCrypt.Net.BCrypt.HashPassword(otpCode, 10);
            var otp = new Otp
            {
                AccountId = accountId,
                OtpHash = otpHash,
                Purpose = purpose,
                ExpiresAt = DateTime.UtcNow.AddMinutes(5)
            };
            await _otpRepository.CreateAsync(otp);

            string subject = purpose switch
            {
                "registration" => "Mã xác thực đăng ký - MovieTicket",
                "forgot_password" => "Mã đặt lại mật khẩu - MovieTicket",
                "change_email" => "Mã xác thực email mới - MovieTicket",
                _ => "Mã xác thực - MovieTicket"
            };
            string body = $@"
                <h2>Mã xác thực của bạn</h2>
                <p>Mã xác thực của bạn là: <strong>{otpCode}</strong></p>
                <p>Mã này có hiệu lực trong <strong>5 phút</strong>.</p>
                <p>Nếu không phải bạn yêu cầu, vui lòng bỏ qua tin nhắn này.</p>
            ";
            await _emailService.SendEmailAsync(email, subject, body);
            return otpCode;
        }
        
        // Verify OTP code, auto-delete expired OTPs
        public async Task<bool> VerifyOtpAsync(int accountId, string otpCode, string purpose)
        {
            await _otpRepository.DeleteExpiredAsync(accountId, purpose);
            
            var otp = await _otpRepository.GetLatestValidAsync(accountId, purpose);
            if (otp == null)
                return false;

            bool isValid = BCrypt.Net.BCrypt.Verify(otpCode, otp.OtpHash);
            if (!isValid)
                return false;

            otp.Used = true;
            await _otpRepository.UpdateAsync(otp);
            return true;
        }
        
        // Check if account can enter OTP
        public async Task<bool> IsOtpValidAsync(int accountId, string purpose)
        {
            await _otpRepository.DeleteExpiredAsync(accountId, purpose);
            return await _otpRepository.IsValidAsync(accountId, purpose);
        }
    }
}
