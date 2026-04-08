using MovieTicket.Domain.Entities;

namespace MovieTicket.Domain.IResponsitories.IAuth
{
    public interface IOtpRepository
    {
        Task<Otp> CreateAsync(Otp otp);
        Task<Otp?> GetByIdAsync(int otpId);
        /// <summary>
        /// Lấy OTP gần nhất chưa hết hạn và chưa dùng của một account
        /// </summary>s
        /// <param name="accountId">ID của tài khoản</param>
        /// <param name="purpose">Mục đích OTP (registration, forgot_password, etc.)</param>
        /// <returns>OTP nếu tìm thấy</returns>
        Task<Otp?> GetLatestValidAsync(int accountId, string purpose);
        Task<bool> UpdateAsync(Otp otp);
        Task<bool> IsValidAsync(int accountId, string purpose);
        Task<int> DeleteExpiredAsync(int accountId, string purpose);

    }
}