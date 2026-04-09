using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IAuth;
using MovieTicket.Infrastructure.AppDbContext;

namespace MovieTicket.Infrastructure.Repositories.AuthRespository
{
    public class OtpRepository : IOtpRepository
    {
        private readonly AppMovieTickerDbContext  _context;
        public OtpRepository(AppMovieTickerDbContext context)
        {
            _context = context;
        }
        public async Task<Otp> CreateAsync(Otp otp)
        {
            otp.CreatedAt = DateTime.UtcNow;
            otp.Used = false;
            otp.ExpiresAt = DateTime.UtcNow.AddMinutes(10);

            _context.Otps.Add(otp);
            await _context.SaveChangesAsync();
            return otp;
        }
        public async Task<Otp?> GetByIdAsync(int otpId)
        {
            return await _context.Otps.FirstOrDefaultAsync(o=> o.OtpId == otpId);
        }
        public async Task<Otp?> GetLatestValidAsync(int accountId, string purpose)
        {
            return await _context.Otps
                .Where(o => o.AccountId == accountId && o.Purpose == purpose && o.Used == false && o.ExpiresAt > DateTime.UtcNow)
                .OrderByDescending(o => o.CreatedAt)
                .FirstOrDefaultAsync();
        }
        public async Task<bool> UpdateAsync(Otp otp)

        {
            var existingOtp = await _context.Otps.FirstOrDefaultAsync(o => o.OtpId == otp.OtpId);
            if (existingOtp == null)
                return false;

            existingOtp.Used = otp.Used;
            _context.Otps.Update(existingOtp);
            await _context.SaveChangesAsync();
            return true;
        }
        public async Task<bool> IsValidAsync(int accountId, string purpose)
        {
            return await _context.Otps
                .AnyAsync(o => o.AccountId == accountId
                    && o.Purpose == purpose
                    && o.ExpiresAt > DateTime.UtcNow
                    && o.Used == false);
        }

        // Auto delete expired OTPs for account and purpose
        public async Task<int> DeleteExpiredAsync(int accountId, string purpose)
        {
            var expiredOtps = await _context.Otps
                .Where(o => o.AccountId == accountId && o.Purpose == purpose && o.ExpiresAt <= DateTime.UtcNow)
                .ToListAsync();
            
            if (expiredOtps.Count > 0)
            {
                _context.Otps.RemoveRange(expiredOtps);
                await _context.SaveChangesAsync();
            }
            return expiredOtps.Count;
        }
    }
}
