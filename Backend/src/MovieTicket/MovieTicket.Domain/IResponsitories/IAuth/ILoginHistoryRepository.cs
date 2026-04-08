using MovieTicket.Domain.Entities;

namespace MovieTicket.Domain.IResponsitories.IAuth
{
    public interface ILoginHistoryRepository
    {
        // Tao mot record login history moi
        Task<LoginHistory> CreateAsync(LoginHistory loginHistory);
        //Lay lich su dang nhap gan nhat cua mot account
        Task<List<LoginHistory>> GetByAccountAsync(int accountId, int limit = 10);

    }
}
