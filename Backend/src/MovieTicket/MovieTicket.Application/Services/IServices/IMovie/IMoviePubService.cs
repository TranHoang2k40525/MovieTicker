using System.Collections.Generic;
using System.Threading.Tasks;
using MovieTicket.Application.DTOs.Movie;

namespace MovieTicket.Application.Services.IServices.IMovie
{
    public interface IMoviePubService
    {
        Task<IEnumerable<MovieListDto>> GetNowShowingMoviesAsync();
        Task<IEnumerable<MovieListDto>> GetUpcomingMoviesAsync();
        Task<IEnumerable<MovieListDto>> GetSpecialMoviesAsync();
        Task<IEnumerable<MovieListDto>> GetAllShowingAndUpcomingMoviesAsync(int page, int sizePage);
        Task<MovieDetailDto?> GetMovieByIdAsync(int id);
        Task<MovieDetailDto?> GetMovieByNameAsync(string name);
    }
}
