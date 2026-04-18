
using MovieTicket.Domain.Entities;

namespace MovieTicket.Domain.IResponsitories.IBooking
{
    public interface ISeatMapRepository
    {
        Task<Show?> GetShowContextAsync(int showId);
        Task<List<RoomLayout>> GetRoomLayoutByHallAsync(int hallId);
        Task<List<CinemaHallSeat>> GetSeatsByHallAsync(int hallId);
        Task<List<BookingSeat>> GetBookingSeatsByShowAsync(int showId);
    }
}
