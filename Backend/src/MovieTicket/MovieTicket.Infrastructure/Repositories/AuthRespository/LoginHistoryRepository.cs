using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IAuth;
using MovieTicket.Infrastructure.AppDbContext;

namespace MovieTicket.Infrastructure.Repositories.AuthRespository
{
    public class LoginHistoryRepository : ILoginHistoryRepository
    {
        private readonly AppMovieTickerDbContext _context;
        public LoginHistoryRepository(AppMovieTickerDbContext context)
        {
            _context = context;
        }
        public async Task<LoginHistory> CreateAsync(LoginHistory loginHistory)
        {
            loginHistory.LoginTime = DateTime.UtcNow;
            _context.LoginHistories.Add(loginHistory);
            await _context.SaveChangesAsync();
            return loginHistory;

        }
        public async Task<List<LoginHistory>> GetByAccountAsync(int accountId, int limit = 10)
        {
            return await Task.FromResult(_context.LoginHistories
                .Where(lh => lh.AccountId == accountId)
                .OrderByDescending(lh => lh.LoginTime)
                .Take(limit)
                .ToList());
        }


    }
}
