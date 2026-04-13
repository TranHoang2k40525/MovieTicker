using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.ICinema;
using MovieTicket.Infrastructure.AppDbContext;

namespace MovieTicket.Infrastructure.Repositories.CinemaRepository
{
    public class CinemaRepository : ICinemaRepository
    {
        private readonly AppMovieTickerDbContext _context;

        public CinemaRepository(AppMovieTickerDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Cinema>> GetAllCinemasWithLocationsAsync()
        {
            return await _context.Cinemas
                .AsNoTracking()
                .Where(c => c.Latitude.HasValue && c.Longitude.HasValue)
                .ToListAsync();
        }

        public async Task<Cinema?> GetCinemaByIdAsync(int cinemaId)
        {
            return await _context.Cinemas
                .AsNoTracking()
                .FirstOrDefaultAsync(c => c.CinemaId == cinemaId);
        }
    }
}
