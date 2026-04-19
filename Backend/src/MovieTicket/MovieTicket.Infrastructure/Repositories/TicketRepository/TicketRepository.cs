using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.ITicket;
using MovieTicket.Infrastructure.AppDbContext;

namespace MovieTicket.Infrastructure.Repositories.TicketRepository
{
    public class TicketRepository : ITicketRepository
    {
        private readonly AppMovieTickerDbContext _context;

        public TicketRepository(AppMovieTickerDbContext context)
        {
            _context = context;
        }

        public async Task<List<Booking>> GetConfirmedBookingsByUserAsync(int userId)
        {
            return await _context.Bookings
                .Include(b => b.Show!)
                    .ThenInclude(s => s.Movie)
                .Include(b => b.Show!)
                    .ThenInclude(s => s.Hall!)
                        .ThenInclude(h => h.Cinema!)
                .Include(b => b.Payments)
                .Where(b => b.UserId == userId && b.Status == BookingStatus.confirmed && b.Payments.Any())
                .OrderByDescending(b => b.BookingId)
                .ToListAsync();
        }

        public async Task<List<Booking>> GetTicketHistoryByUserAsync(int userId)
        {
            return await _context.Bookings
                .Include(b => b.Show!)
                    .ThenInclude(s => s.Movie)
                .Include(b => b.Show!)
                    .ThenInclude(s => s.Hall!)
                        .ThenInclude(h => h.Cinema!)
                .Include(b => b.Payments)
                .Where(b => b.UserId == userId && b.Status == BookingStatus.confirmed && b.Payments.Any())
                .OrderByDescending(b => b.Payments.Max(p => p.PaymentDate))
                .ToListAsync();
        }

        public async Task<Booking?> GetConfirmedBookingDetailAsync(int bookingId, int userId)
        {
            return await _context.Bookings
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
                .FirstOrDefaultAsync(b =>
                    b.BookingId == bookingId &&
                    b.UserId == userId &&
                    b.Status == BookingStatus.confirmed &&
                    b.Payments.Any());
        }

        public async Task<decimal> GetVoucherDiscountByBookingAsync(int bookingId)
        {
            var voucherUsage = await _context.VoucherUsages
                .Include(x => x.Voucher)
                .FirstOrDefaultAsync(x => x.BookingId == bookingId);

            return voucherUsage?.Voucher?.DiscountValue ?? 0m;
        }
    }
}
