using System;
using System.Collections;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MovieTicket.Domain.Entities;

namespace MovieTicket.Domain.IReponsitories.IMovie
{
    public interface IMovieRepository
    {
        Task<Movie?> GetMovieByIdAsync(int movieId);
        Task<Movie?> GetMovieByNameAsync(string movieName);
        Task<IEnumerable<Movie>> GetAllMovieAsync(int page, int sizePage);
        // lay danh sach phim theo rap
        Task<IEnumerable<Movie>> GetMovieByCinemaAsync(int cinemaID, int page, int sizePage);
        //Lay phim dang chieu trong ngay
        Task<List<IEnumerable<Movie>>> GetMovieOnDayAsync();
        //lay phim dac biet
        Task<IEnumerable<Movie>> GetSpeciaMovieAsync();
        //Lay phim sap chieu
        Task<IEnumerable<Movie>> GetUpComingMovieAsync();
        //Lay danh sach phim dang chieu va sap chieu
        Task<IEnumerable<Movie>> GetMovieOnDayAndUpComingMovieAsync(int page, int sizePage);

        // Quản lý (Admin) - Thêm/Xóa/Sửa Phim
        Task<Movie> CreateMovieAsync(Movie movie);
        Task<bool> UpdateMovieAsync(Movie movie);
        Task<bool> DeleteMovieAsync(int movieId);

        // Cập nhật lượt thích
        Task<bool> ToggleLikeMovieAsync(int userId, int movieId, bool isLiked);
    }
}
