using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IAuth;
using MovieTicket.Infrastructure.AppDbContext;

namespace MovieTicket.Infrastructure.Repositories.AuthRespository
{
    public class AccountRoleRepository : IAccountRoleRepository
    {
        private readonly AppMovieTickerDbContext _context;

        public AccountRoleRepository(AppMovieTickerDbContext context)
        {
            _context = context;
        }

        public async Task<AccountRole> CreateAsync(AccountRole accountRole)
        {
            _context.AccountRoles.Add(accountRole);
            await _context.SaveChangesAsync();
            return accountRole;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            var accountRole = await _context.AccountRoles.FindAsync(id);
            if (accountRole == null)
                return false;

            _context.AccountRoles.Remove(accountRole);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<List<AccountRole>> GetByAccountIdAsync(int accountId)
        {
            return await _context.AccountRoles
                .Include(ar => ar.Role)
                .Where(ar => ar.AccountId == accountId)
                .ToListAsync();
        }

        public async Task<List<AccountRole>> GetByRoleIdAsync(int roleId)
        {
            return await _context.AccountRoles
                .Where(ar => ar.RoleId == roleId)
                .ToListAsync();
        }
    }
}
