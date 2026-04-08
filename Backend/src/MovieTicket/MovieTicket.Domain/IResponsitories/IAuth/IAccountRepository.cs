using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MovieTicket.Domain.Entities;  
namespace MovieTicket.Domain.IResponsitories.IAuth
{
    public interface IAccountRepository
    {
        Task<Account?> GetByIdAsync(int accountId);
        Task<Account?> GetByEmailAsync(string email);
        Task<Account?> GetByPhoneAsync(string phone);
        Task<Account?> GetByEmailOrPhoneAsync(string emailOrPhone);
        Task<Account?> CreateAsync(Account account);
        Task<bool> UpdateAsync(Account account);
        Task<bool> DeleteAsync(int accountId);
        Task<bool> EmailExistsAsync(string email);
        Task<bool> PhoneExistsAsync(string phone);
        Task<List<Role>> GetRolesAsync(int accountId);
        Task<List<Permission>> GetPermissionsAsync(int accountId);
    }
}
