using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IBooking;
using MovieTicket.Infrastructure.AppDbContext;

namespace MovieTicket.Infrastructure.Repositories.BookingRepository
{
    public class SeatMapRepository : ISeatMapRepository
    {
        private readonly AppMovieTickerDbContext _context;
        public SeatMapRepository(AppMovieTickerDbContext context)
        {
            _context = context;
        }
        public async Task<Show?> GetShowContextAsync(int showId)
        {
           return await _context.Shows.AsNoTracking()
                .Include(s=> s.Movie)
                .Include(s=> s.Hall)
            .ThenInclude(h => h!.Cinema)
                .FirstOrDefaultAsync(s=> s.ShowId == showId);
        }
        public async Task<List<RoomLayout>> GetRoomLayoutByHallAsync(int hallId)
        {
            return await _context.RoomLayouts
                .AsNoTracking()
                .Where(x => x.HallId == hallId)
                .OrderBy(x => x.RowSeat)
                .ThenBy(x => x.ColSeat)
                .ToListAsync();
        }
        public async Task<List<CinemaHallSeat>> GetSeatsByHallAsync(int hallId)
        {
            return await _context.CinemaHallSeats
                .AsNoTracking()
                .Where(x => x.HallId == hallId)
                .ToListAsync();
        }
        //
        public async Task<List<BookingSeat>> GetBookingSeatsByShowAsync(int showId)
        {
            return await _context.BookingSeats
                .AsNoTracking()
                .Where(x => x.ShowId == showId)
                .OrderByDescending(x => x.HoldUntil)
                .ToListAsync();
        }

    }
}
