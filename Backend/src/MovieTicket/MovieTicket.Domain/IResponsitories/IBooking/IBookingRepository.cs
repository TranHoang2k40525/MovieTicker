

using MovieTicket.Domain.Entities;

namespace MovieTicket.Domain.IResponsitories.IBooking
{
    public interface IBookingRepository
    {
        Task<Booking?> GetByIdWithDetailsAsync(int bookingId);
        Task<List<Booking>> GetExpiredPendingHoldsAsync(DateTime utcNow);
        Task AddAsync(Booking booking);
        Task SaveChangesAsync();
    }
}
