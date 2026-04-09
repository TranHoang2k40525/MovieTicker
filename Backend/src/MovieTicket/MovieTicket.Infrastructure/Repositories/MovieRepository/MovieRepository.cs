using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IReponsitories.IMovie;
using MovieTicket.Infrastructure.AppDbContext;

namespace MovieTicket.Infrastructure.Repositories.MovieRespository
{
    public class MovieRepository : IMovieRepository
    {
        private readonly AppMovieTickerDbContext _context;
        public MovieRepository(AppMovieTickerDbContext context)
        {
            _context = context;
        }
        public async Task<Movie?> GetMovieByIdAsync(int movieId)      
        {
            return await _context.Movies.AsNoTracking().FirstOrDefaultAsync(m => m.MovieId == movieId);
        }
        public async Task<Movie?> GetMovieByNameAsync(string movieName)
        {
            return await _context.Movies.AsNoTracking().FirstOrDefaultAsync(m => m.MovieTitle == movieName);
        }
        public async Task<IEnumerable<Movie>> GetAllMovieAsync(int page, int sizePage)
        {
            return await _context.Movies.AsNoTracking().Skip((page - 1) * sizePage).Take(sizePage).ToListAsync();
        }
        // lay danh sach phim theo rap
        public async Task<IEnumerable<Movie>> GetMovieByCinemaAsync(int cinemaID, int page, int sizePage)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);

            return await _context.Movies
                .AsNoTracking()
                .Where(m => m.Shows.Any(s => s.Hall != null && s.Hall.CinemaId == cinemaID && s.ShowDate >= today))
                .Skip((page - 1) * sizePage)
                .Take(sizePage)
                .ToListAsync();
        }

        //Lay phim dang chieu trong ngay
        public async Task<List<IEnumerable<Movie>>> GetMovieOnDayAsync()
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);

            var movies = await _context.Movies
                .AsNoTracking()
                .Where(m => m.Shows.Any(s => s.ShowDate == today))
                .ToListAsync();

            return new List<IEnumerable<Movie>> { movies };
        }

        //lay phim dac biet
        public async Task<IEnumerable<Movie>> GetSpeciaMovieAsync()
        {
            // Define rules for special movies, assuming "đặc biệt" based on certain genres or likes
            // Example: Order by top Liked
            return await _context.Movies
                .AsNoTracking()
                .Include(m => m.LikeMovies)
                .OrderByDescending(m => m.LikeMovies.Count(lm => lm.IsLiked == true))
                .Take(10)
                .ToListAsync();
        }

        //Lay phim sap chieu
        public async Task<IEnumerable<Movie>> GetUpComingMovieAsync()
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);

            return await _context.Movies
                .AsNoTracking()
                .Where(m => m.MovieReleaseDate > today)
                .OrderBy(m => m.MovieReleaseDate)
                .Take(10)
                .ToListAsync();
        }

        //Lay danh sach phim dang chieu va sap chieu
        public async Task<IEnumerable<Movie>> GetMovieOnDayAndUpComingMovieAsync(int page, int sizePage)
        {
            var today = DateOnly.FromDateTime(DateTime.UtcNow);

            return await _context.Movies
                .AsNoTracking()
                .Where(m => m.MovieReleaseDate >= today || m.Shows.Any(s => s.ShowDate >= today))
                .OrderBy(m => m.MovieReleaseDate)
                .Skip((page - 1) * sizePage)
                .Take(sizePage)
                .ToListAsync();
        }

        //  CÁC CHỨC NĂNG DÀNH CHO NGHIỆP VỤ QUẢN LÝ

        public async Task<Movie> CreateMovieAsync(Movie movie)
        {
            _context.Movies.Add(movie);
            await _context.SaveChangesAsync();
            return movie;
        }

        public async Task<bool> UpdateMovieAsync(Movie movie)
        {
            var existingMovie = await _context.Movies.FindAsync(movie.MovieId);
            if (existingMovie == null)
            {
                return false;
            }

            _context.Entry(existingMovie).CurrentValues.SetValues(movie);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DeleteMovieAsync(int movieId)
        {
            var movie = await _context.Movies
                .Include(m => m.Shows)
                .Include(m => m.LikeMovies)
                .FirstOrDefaultAsync(m => m.MovieId == movieId);

            if (movie == null)
                return false;

            // Xóa rác liên đới trước (Nên cẩn thận với bảng Shows nếu có Bookings)
            if (movie.LikeMovies.Any())
            {
                _context.LikeMovies.RemoveRange(movie.LikeMovies);
            }

            _context.Movies.Remove(movie);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> ToggleLikeMovieAsync(int userId, int movieId, bool isLiked)
        {
            var likeMovie = await _context.LikeMovies
                .FirstOrDefaultAsync(lm => lm.UserId == userId && lm.MovieId == movieId);

            if (likeMovie != null)
            {
                likeMovie.IsLiked = isLiked;
                _context.LikeMovies.Update(likeMovie);
            }
            else
            {
                likeMovie = new LikeMovie 
                { 
                    UserId = userId, 
                    MovieId = movieId, 
                    IsLiked = isLiked 
                };
                _context.LikeMovies.Add(likeMovie);
            }

            return await _context.SaveChangesAsync() > 0;
        }
    }
}
