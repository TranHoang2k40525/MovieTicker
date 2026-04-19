using MovieTicket.Domain.Entities;

namespace MovieTicket.Domain.IResponsitories.ITicket
{
    public interface ITicketRepository
    {
        Task<List<Booking>> GetConfirmedBookingsByUserAsync(int userId);
        Task<List<Booking>> GetTicketHistoryByUserAsync(int userId);
        Task<Booking?> GetConfirmedBookingDetailAsync(int bookingId, int userId);
        Task<decimal> GetVoucherDiscountByBookingAsync(int bookingId);
    }
}
