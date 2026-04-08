using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IAuth;
using MovieTicket.Infrastructure.AppDbContext;

namespace MovieTicket.Infrastructure.Repositories.AuthRespository
{
    public class AccountRepository : IAccountRepository
    {
        private readonly AppMovieTickerDbContext _context;
        public AccountRepository(AppMovieTickerDbContext context) 
        { 
            _context = context;

        }
        public async Task<Account?> GetByIdAsync(int accountId)
        {
            return await _context.Accounts.Include(a => a.Users).Include(a => a.AccountRoles)
                .ThenInclude(a => a.Role).FirstOrDefaultAsync(a => a.AccountId == accountId);
        }
        public async Task<Account?> GetByEmailAsync(string email)
        {
            return await _context.Accounts.Include(e=> e.Users).Include(e => e.AccountRoles)
                .ThenInclude(e => e.Role).FirstOrDefaultAsync(a => a.Email == email);
        }
        public async Task<Account?> GetByPhoneAsync(string phone)
        {
            return await _context.Accounts.Include(p => p.Users).Include(p => p.AccountRoles)
                .ThenInclude(p => p.Role).FirstOrDefaultAsync(a => a.Phone == phone);
        }
        public async Task<Account?> GetByEmailOrPhoneAsync(string emailOrPhone)
        {
            return await _context.Accounts.Include(e => e.Users).Include(e => e.AccountRoles)
                .ThenInclude(e => e.Role).FirstOrDefaultAsync(a => a.Email == emailOrPhone || a.Phone == emailOrPhone);
        }
        public async Task<Account?> CreateAsync(Account account)
        {
            account.Status = Status.active;
            account.CreatedAt = DateTime.UtcNow;
            _context.Accounts.Add(account);
            await _context.SaveChangesAsync();
            return account;
        }
        public async Task<bool> UpdateAsync(Account account)
        {
            var existingAccount = await _context.Accounts.FindAsync(account.AccountId);
            if (existingAccount == null)
            {
                return false;
            }
            existingAccount.Email = account.Email;
            existingAccount.Phone = account.Phone;
            existingAccount.PasswordHash = account.PasswordHash;
            existingAccount.Status = account.Status;
            existingAccount.UpdatedAt = DateTime.UtcNow;
            _context.Accounts.Update(existingAccount);
            await _context.SaveChangesAsync();
            return true;
        }
        public async Task<bool> EmailExistsAsync(string email)
        {
            return await _context.Accounts.AnyAsync(a => a.Email == email);
        }

        public async Task<bool> DeleteAsync(int accountId)
        {
            var account = await _context.Accounts.FindAsync(accountId);
            if (account == null) return false;

            _context.Accounts.Remove(account);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> PhoneExistsAsync(string phone)
        {
            return await _context.Accounts.AnyAsync(a => a.Phone == phone);
        }

        public async Task<List<Role>> GetRolesAsync(int accountId)
        {
            return await _context.AccountRoles.Where(ar => ar.AccountId == accountId)
                .Include(ar => ar.Role)
                .Select(ar => ar.Role!)
                .ToListAsync();
        }
        public async Task<List<Permission>> GetPermissionsAsync(int accountId)
        {
            return await _context.AccountRoles.Where(ar => ar.AccountId == accountId)
                .Include(ar => ar.Role)
                .ThenInclude(r => r!.RolePermissions)
                .ThenInclude(rp => rp.Permission)
                .SelectMany(ar => ar.Role!.RolePermissions.Select(rp => rp.Permission!))
                .Distinct()
                .ToListAsync();
        }






    }
}
