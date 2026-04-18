using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IBooking;
using MovieTicket.Infrastructure.AppDbContext;

namespace MovieTicket.Infrastructure.Repositories.BookingRepository
{
    public class BookingRepository : IBookingRepository
    {
        private readonly AppMovieTickerDbContext _context;

        public BookingRepository(AppMovieTickerDbContext context)
        {
            _context = context;
        }

        public async Task<Booking?> GetByIdWithDetailsAsync(int bookingId)
        {
            return await _context.Bookings
                .Include(b => b.BookingSeats)
                .Include(b => b.BookingProducts)
                    .ThenInclude(bp => bp.Product)
                .FirstOrDefaultAsync(b => b.BookingId == bookingId);
        }

        public async Task<List<Booking>> GetExpiredPendingHoldsAsync(DateTime utcNow)
        {
            return await _context.Bookings
                .Include(b => b.BookingSeats)
                .Where(b =>
                    b.Status == BookingStatus.pending &&
                    b.BookingSeats.Any(s =>
                        s.Status == BookingSeatStatus.held &&
                        s.HoldUntil.HasValue &&
                        s.HoldUntil.Value <= utcNow))
                .ToListAsync();
        }

        public async Task AddAsync(Booking booking)
        {
            await _context.Bookings.AddAsync(booking);
        }

        public async Task SaveChangesAsync()
        {
            await _context.SaveChangesAsync();
        }
    }
}
