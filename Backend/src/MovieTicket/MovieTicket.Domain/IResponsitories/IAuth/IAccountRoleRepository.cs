using MovieTicket.Domain.Entities;

namespace MovieTicket.Domain.IResponsitories.IAuth
{
    public interface IAccountRoleRepository
    {
        Task<AccountRole> CreateAsync(AccountRole accountRole);
        Task<bool> DeleteAsync(int id);
        Task<List<AccountRole>> GetByAccountIdAsync(int accountId);
        Task<List<AccountRole>> GetByRoleIdAsync(int roleId);
    }
}
