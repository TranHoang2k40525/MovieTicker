

using MovieTicket.Application.DTOs.Booking;

namespace MovieTicket.Application.Services.IServices.IBooking
{
    public interface ISeatMapService
    {
        Task<SeatMapDTO?> GetSeatMapByShowAsync(int showId);
    }
}
