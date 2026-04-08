using MovieTicket.Domain.Entities;

namespace MovieTicket.Domain.IResponsitories.IAuth
{
    public interface IUserRepository
    {
        Task<User?> GetByIdAsync(int userId);
        Task<User?> GetByAccountIdAsync(int accountId);
        Task<User> CreateAsync(User user);
        Task<bool> UpdateAsync(User user);
        Task<bool> DeleteAsync(int userId);
    }
}
