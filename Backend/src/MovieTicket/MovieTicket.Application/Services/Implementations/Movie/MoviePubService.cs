using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using MovieTicket.Application.DTOs.Movie;
using MovieTicket.Application.Services.IServices.IMovie;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IReponsitories.IMovie;

namespace MovieTicket.Application.Services.Implementations.Movie
{
    public class MoviePubService : IMoviePubService
    {
        private readonly IMovieRepository _movieRepository;
        private readonly ILogger<MoviePubService> _logger;

        public MoviePubService(IMovieRepository movieRepository, ILogger<MoviePubService> logger)
        {
            _movieRepository = movieRepository;
            _logger = logger;
        }

        public async Task<IEnumerable<MovieListDto>> GetNowShowingMoviesAsync()
        {
            try
            {
                var moviesList = await _movieRepository.GetMovieOnDayAsync();
                var movies = moviesList.FirstOrDefault() ?? new List<Domain.Entities.Movie>();
                return movies.Select(m => MapToMovieListDto(m));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Đã xảy ra lỗi khi lấy danh sách phim đang chiếu.");
                return new List<MovieListDto>();
            }
        }

        public async Task<IEnumerable<MovieListDto>> GetUpcomingMoviesAsync()
        {
            try
            {
                var movies = await _movieRepository.GetUpComingMovieAsync();
                return movies.Select(m => MapToMovieListDto(m));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Đã xảy ra lỗi khi lấy danh sách phim sắp chiếu.");
                return new List<MovieListDto>();
            }
        }

        public async Task<IEnumerable<MovieListDto>> GetSpecialMoviesAsync()
        {
            try
            {
                var movies = await _movieRepository.GetSpeciaMovieAsync();
                return movies.Select(m => MapToMovieListDto(m));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Đã xảy ra lỗi khi lấy danh sách phim đặc biệt.");
                return new List<MovieListDto>();
            }
        }

        public async Task<IEnumerable<MovieListDto>> GetAllShowingAndUpcomingMoviesAsync(int page, int sizePage)
        {
            try
            {
                if (page <= 0) page = 1;
                if (sizePage <= 0) sizePage = 10;

                var movies = await _movieRepository.GetMovieOnDayAndUpComingMovieAsync(page, sizePage);
                return movies.Select(m => MapToMovieListDto(m));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Đã xảy ra lỗi khi lấy danh sách tất cả các phim đang chiếu và sắp chiếu. Page: {Page}, SizePage: {SizePage}", page, sizePage);
                return new List<MovieListDto>();
            }
        }

        public async Task<MovieDetailDto?> GetMovieByIdAsync(int id)
        {
            try
            {
                if (id <= 0)
                {
                    _logger.LogWarning("ID phim không hợp lệ: {Id}", id);
                    return null;
                }

                var movie = await _movieRepository.GetMovieByIdAsync(id);
                if (movie == null) return null;
                return MapToMovieDetailDto(movie);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Đã xảy ra lỗi khi lấy phim theo ID: {Id}", id);
                return null;
            }
        }

        public async Task<MovieDetailDto?> GetMovieByNameAsync(string name)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(name))
                {
                    _logger.LogWarning("Tên phim truyền vào bị rỗng khi gọi GetMovieByNameAsync.");
                    return null;
                }

                var movie = await _movieRepository.GetMovieByNameAsync(name);
                if (movie == null) return null;
                return MapToMovieDetailDto(movie);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Đã xảy ra lỗi khi tìm phim theo tên: {Name}", name);
                return null;
            }
        }

        private MovieListDto MapToMovieListDto(Domain.Entities.Movie m)
        {
            return new MovieListDto
            {
                MovieId = m.MovieId,
                MovieTitle = m.MovieTitle ?? string.Empty,
                ImageUrl = m.ImageUrl ?? string.Empty,
                MovieReleaseDate = m.MovieReleaseDate,
                MovieRuntime = m.MovieRuntime,
                MovieAge = m.MovieAge ?? string.Empty,
                MovieGenre = m.MovieGenre ?? string.Empty,
                MovieActor = m.MovieActor ?? string.Empty,
                MovieLanguage = m.MovieLanguage ?? string.Empty
            };
        }

        private MovieDetailDto MapToMovieDetailDto(Domain.Entities.Movie m)
        {
            return new MovieDetailDto
            {
                MovieId = m.MovieId,
                MovieTitle = m.MovieTitle ?? string.Empty,
                MovieDescription = m.MovieDescription ?? string.Empty,
                MovieLanguage = m.MovieLanguage ?? string.Empty,
                MovieGenre = m.MovieGenre ?? string.Empty,
                MovieReleaseDate = m.MovieReleaseDate,
                MovieRuntime = m.MovieRuntime,
                MovieAge = m.MovieAge ?? string.Empty,
                ImageUrl = m.ImageUrl ?? string.Empty,
                MovieActor = m.MovieActor ?? string.Empty,
                MovieTrailler = m.MovieTrailler ?? string.Empty
            };
        }
    }
}
