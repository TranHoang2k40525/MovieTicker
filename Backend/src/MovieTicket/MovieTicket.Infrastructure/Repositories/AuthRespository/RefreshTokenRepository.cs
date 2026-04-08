

using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IAuth;
using MovieTicket.Infrastructure.AppDbContext;

namespace MovieTicket.Infrastructure.Repositories.AuthRespository
{
    public class RefreshTokenRepository : IRefreshTokenRepository
    {
        private readonly AppMovieTickerDbContext _context;
        public RefreshTokenRepository(AppMovieTickerDbContext context)
        {
            _context = context;
        }
        public async Task<RefreshToken> CreateAsync(RefreshToken refreshToken)
        {
            refreshToken.CreatedAt = DateTime.UtcNow;
            _context.RefreshTokens.Add(refreshToken);
            await _context.SaveChangesAsync();
            return refreshToken;
        }
        public async Task<RefreshToken?> GetByIdAsync(int tokenId)
        {
            return await _context.RefreshTokens
                .FirstOrDefaultAsync(rt => rt.TokenId == tokenId);
        }
        public async Task<RefreshToken?> GetByTokenAsync(string token)
        {
            return await _context.RefreshTokens
                .FirstOrDefaultAsync(rt => rt.RefreshToken1 == token);
        }
        public async Task<bool> IsValidAsync(string token)
        {
            return await _context.RefreshTokens
                .AnyAsync(rt => rt.RefreshToken1 == token
                    && rt.ExpiresAt > DateTime.UtcNow);
        }
        public async Task<bool> DeleteAsync(int tokenId)
        {
            var refreshToken = await _context.RefreshTokens
                .FirstOrDefaultAsync(rt => rt.TokenId == tokenId);
            if (refreshToken == null)
                return false;
            _context.RefreshTokens.Remove(refreshToken);
            await _context.SaveChangesAsync();
            return true;
        }
        public async Task<int> DeleteByAccountIdAsync(int accountId)
        {
            var refreshTokens = await _context.RefreshTokens
                .Where(rt => rt.AccountId == accountId)
                .ToListAsync();
            
            _context.RefreshTokens.RemoveRange(refreshTokens);
            await _context.SaveChangesAsync();
            return refreshTokens.Count;
        }
    }
}
