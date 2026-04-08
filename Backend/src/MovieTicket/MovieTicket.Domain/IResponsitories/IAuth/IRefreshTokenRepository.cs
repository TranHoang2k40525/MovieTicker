using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MovieTicket.Domain.Entities;

namespace MovieTicket.Domain.IResponsitories.IAuth
{
    public interface IRefreshTokenRepository
    {
        Task<RefreshToken> CreateAsync(RefreshToken refreshToken);
        Task<RefreshToken?> GetByIdAsync(int tokenId);
        Task<RefreshToken?> GetByTokenAsync(string token);
        Task<bool> IsValidAsync(string token);
        Task<bool> DeleteAsync(int tokenId);
        Task<int> DeleteByAccountIdAsync(int accountId);
    }
}
