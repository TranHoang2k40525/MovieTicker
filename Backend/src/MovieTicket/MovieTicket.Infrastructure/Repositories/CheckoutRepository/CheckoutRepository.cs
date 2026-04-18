using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.ICheckout;
using MovieTicket.Infrastructure.AppDbContext;

namespace MovieTicket.Infrastructure.Repositories.CheckoutRepository
{
    public class CheckoutRepository : ICheckoutRepository
    {
        private readonly AppMovieTickerDbContext _context;
        public CheckoutRepository(AppMovieTickerDbContext context)
        {
            _context = context;
        }

        public async Task<Booking?> GetBookingForCheckoutAsync(int bookingId)
        {
            return await _context.Bookings
                .Include(b => b.User)
                .Include(b => b.Show!)
                    .ThenInclude(s => s.Movie)
                .Include(b => b.Show!)
                    .ThenInclude(s => s.Hall!)
                        .ThenInclude(h => h.Cinema!)
                .Include(b => b.BookingSeats)
                    .ThenInclude(bs => bs.Seat)
                .Include(b => b.BookingProducts)
                    .ThenInclude(bp => bp.Product)
                .Include(b => b.Payments)
                .FirstOrDefaultAsync(b => b.BookingId == bookingId);

        }
        public Task<Voucher?> GetVoucherByCodeAsync(string code)
        {
            var normalized = code.Trim().ToUpperInvariant();
            return _context.Vouchers.FirstOrDefaultAsync(v => v.Code != null && v.Code.ToUpper() == normalized);
        }

        public Task<List<Voucher>> GetAvailableVouchersAsync(DateOnly today)
        {
            return _context.Vouchers
                .Where(v =>
                    v.IsActive == true &&
                    (!v.StartDate.HasValue || v.StartDate.Value <= today) &&
                    (!v.EndDate.HasValue || v.EndDate.Value >= today) &&
                    (!v.UsageLimit.HasValue || v.UsageCount.GetValueOrDefault() < v.UsageLimit.Value))
                .OrderByDescending(v => v.DiscountValue)
                .ToListAsync();
        }

        public Task<bool> HasUserUsedVoucherAsync(int userId, int voucherId, int bookingId)
        {
            return _context.VoucherUsages
                .AnyAsync(x => x.UserId == userId && x.VoucherId == voucherId && x.BookingId != bookingId);
        }
        public async Task AddVoucherUsageAsync(VoucherUsage usage) => await _context.VoucherUsages.AddAsync(usage);
        public async Task AddPaymentAsync(Payment payment) => await _context.Payments.AddAsync(payment);
        public async Task AddNotificationAsync(Notification notification) => await _context.Notifications.AddAsync(notification);
        public Task SaveChangesAsync() => _context.SaveChangesAsync();
    }
}
