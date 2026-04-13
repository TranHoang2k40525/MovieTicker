using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.ICinema;
using MovieTicket.Infrastructure.AppDbContext;

namespace MovieTicket.Infrastructure.Repositories.CinemaRepository
{
    public class CinemaShowtimeRepository : ICinemaShowtimeRepository
    {
        private readonly AppMovieTickerDbContext _context;

        public CinemaShowtimeRepository(AppMovieTickerDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Show>> GetShowsByCinemaAndDateAsync(int cinemaId, DateOnly fromDate, DateOnly toDate)
        {
            return await _context.Shows
                .Include(s => s.Movie)
                .Include(s => s.Hall)
                .AsNoTracking()
                .Where(s => s.Hall != null && s.Hall.CinemaId == cinemaId 
                            && s.ShowDate >= fromDate 
                            && s.ShowDate <= toDate)
                .OrderBy(s => s.ShowDate)
                .ThenBy(s => s.ShowTime)
                .ToListAsync();
        }

        public async Task<IEnumerable<Show>> GetShowsByMovieAndDateAsync(int movieId, DateOnly fromDate, DateOnly toDate)
        {
            return await _context.Shows
                .Include(s => s.Movie)
                .Include(s => s.Hall)
                    .ThenInclude(h => h.Cinema)
                .AsNoTracking()
                .Where(s => s.MovieId == movieId
                            && s.ShowDate >= fromDate 
                            && s.ShowDate <= toDate
                            && s.Hall != null && s.Hall.Cinema != null)
                .OrderBy(s => s.ShowDate)
                .ThenBy(s => s.ShowTime)
                .ToListAsync();
        }
    }
}