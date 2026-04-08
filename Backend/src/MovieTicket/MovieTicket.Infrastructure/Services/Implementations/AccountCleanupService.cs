using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using MovieTicket.Domain.Entities;
using MovieTicket.Infrastructure.AppDbContext;
using Microsoft.EntityFrameworkCore;

namespace MovieTicket.Infrastructure.Services.Implementations
{
    public class AccountCleanupService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<AccountCleanupService> _logger;

        public AccountCleanupService(IServiceProvider serviceProvider, ILogger<AccountCleanupService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    // Chạy mỗi 1 phút
                    await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);

                    using var scope = _serviceProvider.CreateScope();
                    var dbContext = scope.ServiceProvider.GetRequiredService<AppMovieTickerDbContext>();

                    // Tìm các tài khoản pending_verification tạo từ 5 phút trước
                    var cutoffTime = DateTime.UtcNow.AddMinutes(-5);

                    var pendingAccounts = await dbContext.Accounts
                        .Where(a => a.Status == Status.pending_verification && a.CreatedAt < cutoffTime)
                        .Include(a => a.Otps)
                        .Include(a => a.Users)
                        .Include(a => a.AccountRoles)
                        .ToListAsync(stoppingToken);

                    if (pendingAccounts.Any())
                    {
                        foreach (var account in pendingAccounts)
                        {
                            // EF Core tracking allows deleting related entities safely before deleting account
                            dbContext.Otps.RemoveRange(account.Otps);
                            dbContext.Users.RemoveRange(account.Users);
                            dbContext.AccountRoles.RemoveRange(account.AccountRoles);
                            dbContext.Accounts.Remove(account);
                        }

                        await dbContext.SaveChangesAsync(stoppingToken);
                        _logger.LogInformation($"[AccountCleanupService] Đã dọn dẹp {pendingAccounts.Count} tài khoản pending quá 5 phút.");
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Lỗi xảy ra trong AccountCleanupService.");
                }
            }
        }
    }
}
