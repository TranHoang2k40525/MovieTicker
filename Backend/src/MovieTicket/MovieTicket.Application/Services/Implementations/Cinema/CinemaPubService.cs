using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using MovieTicket.Application.DTOs.Cinema;
using MovieTicket.Application.Services.IServices.ICinema;
using MovieTicket.Domain.IResponsitories.ICinema;

namespace MovieTicket.Application.Services.Implementations.Cinema
{
    public class CinemaPubService : ICinemaPubService
    {
        private readonly ICinemaRepository _cinemaRepository;
        private readonly ICinemaShowtimeRepository _showtimeRepository;
        private readonly ILogger<CinemaPubService> _logger;

        public CinemaPubService(ICinemaRepository cinemaRepository, ICinemaShowtimeRepository showtimeRepository, ILogger<CinemaPubService> logger)
        {
            _cinemaRepository = cinemaRepository;
            _showtimeRepository = showtimeRepository;
            _logger = logger;
        }

        public async Task<IEnumerable<NearbyCinemaDto>> GetCinemasSortedByDistanceAsync(double userLat, double userLng)
        {
            try
            {
                var cinemas = await _cinemaRepository.GetAllCinemasWithLocationsAsync();

                var nearbyCinemas = cinemas.Select(c => new NearbyCinemaDto
                {
                    CinemaId = c.CinemaId,
                    CinemaName = c.CinemaName ?? string.Empty,
                    CityAddress = c.CityAddress ?? string.Empty,
                    Latitude = c.Latitude ?? 0,
                    Longitude = c.Longitude ?? 0,
                    DistanceInKm = CalculateDistance(userLat, userLng, c.Latitude ?? 0, c.Longitude ?? 0)
                })
                .OrderBy(c => c.DistanceInKm)
                .ToList();

                return nearbyCinemas;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Đã xảy ra lỗi khi lấy và sắp xếp các rạp chiếu phim gần đây.");
                return new List<NearbyCinemaDto>();
            }
        }

        public async Task<IEnumerable<CinemaShowtimeDto>> GetShowtimesByCinemaAsync(int cinemaId, DateOnly? filterDate)
        {
            try
            {
                var today = DateOnly.FromDateTime(DateTime.UtcNow);
                var fromDate = filterDate ?? today;

                // Quy tắc: tối đa xem trước 30 ngày
                var maxDate = today.AddDays(30);
                var toDate = fromDate;

                // Nếu người dùng yêu cầu xem trước vượt quá 30 ngày thì cắt về mốc tối đa
                if (fromDate > maxDate)
                {
                    fromDate = maxDate;
                    toDate = maxDate;
                }

                // Nếu người dùng chọn ngày trong quá khứ thì chuyển thành hôm nay
                if (fromDate < today)
                {
                    fromDate = today;
                    toDate = today;
                }

                var shows = await _showtimeRepository.GetShowsByCinemaAndDateAsync(cinemaId, fromDate, toDate);

                // Nhóm theo phim
                var movieGroup = shows
                    .Where(s => s.Movie != null)
                    .GroupBy(s => s.MovieId)
                    .Select(g => new CinemaShowtimeDto
                    {
                        MovieId = g.Key ?? 0,
                        MovieTitle = g.First().Movie?.MovieTitle ?? string.Empty,
                        ImageUrl = g.First().Movie?.ImageUrl ?? string.Empty,
                        MovieAge = g.First().Movie?.MovieAge ?? string.Empty,
                        MovieGenre = g.First().Movie?.MovieGenre ?? string.Empty,
                        MovieRuntime = g.First().Movie?.MovieRuntime,
                        Showtimes = g.Select(s => new ShowtimeDetailDto
                        {
                            ShowId = s.ShowId,
                            ShowDate = s.ShowDate ?? default,
                            StartTime = s.ShowTime.HasValue ? s.ShowTime.Value.ToTimeSpan() : TimeSpan.Zero,
                            EndTime = s.ShowTime.HasValue && s.Movie != null && s.Movie.MovieRuntime.HasValue
                                ? s.ShowTime.Value.ToTimeSpan().Add(TimeSpan.FromMinutes(s.Movie.MovieRuntime.Value))
                                : TimeSpan.Zero,
                            CinemaHallId = s.HallId ?? 0,
                            HallName = s.Hall?.HallName ?? string.Empty,
                            ExperienceType = "2D" // Mặc định là 2D
                        }).ToList()
                    }).ToList();

                return movieGroup;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Đã xảy ra lỗi khi lấy danh sách lịch chiếu cho Rạp có Id: {CinemaId}", cinemaId);
                return new List<CinemaShowtimeDto>();
            }
        }

        public async Task<IEnumerable<CinemaListForMovieDto>> GetCinemasByMovieSortedByDistanceAsync(int movieId, double userLat, double userLng, DateOnly? filterDate)
        {
            try
            {
                var today = DateOnly.FromDateTime(DateTime.UtcNow);
                var fromDate = filterDate ?? today;

                // Quy tắc: tối đa xem trước 30 ngày
                var maxDate = today.AddDays(30);
                var toDate = fromDate;

                if (fromDate > maxDate)
                {
                    fromDate = maxDate;
                    toDate = maxDate;
                }

                if (fromDate < today)
                {
                    fromDate = today;
                    toDate = today;
                }

                var shows = await _showtimeRepository.GetShowsByMovieAndDateAsync(movieId, fromDate, toDate);

                // Nhóm theo Rạp
                var cinemaGroup = shows
                    .Where(s => s.Hall != null && s.Hall.Cinema != null)
                    .GroupBy(s => s.Hall!.CinemaId)
                    .Select(g => new CinemaListForMovieDto
                    {
                        CinemaId = g.Key ?? 0,
                        CinemaName = g.First().Hall?.Cinema?.CinemaName ?? string.Empty,
                        CityAddress = g.First().Hall?.Cinema?.CityAddress ?? string.Empty,
                        DistanceInKm = CalculateDistance(userLat, userLng, g.First().Hall?.Cinema?.Latitude ?? 0, g.First().Hall?.Cinema?.Longitude ?? 0),
                        Showtimes = g.Select(s => new ShowtimeDetailDto
                        {
                            ShowId = s.ShowId,
                            ShowDate = s.ShowDate ?? default,
                            StartTime = s.ShowTime.HasValue ? s.ShowTime.Value.ToTimeSpan() : TimeSpan.Zero,
                            EndTime = s.ShowTime.HasValue && s.Movie != null && s.Movie.MovieRuntime.HasValue
                                ? s.ShowTime.Value.ToTimeSpan().Add(TimeSpan.FromMinutes(s.Movie.MovieRuntime.Value))
                                : TimeSpan.Zero,
                            CinemaHallId = s.HallId ?? 0,
                            HallName = s.Hall?.HallName ?? string.Empty,
                            ExperienceType = "2D" // Mặc định là 2D
                        }).ToList()
                    })
                    .OrderBy(c => c.DistanceInKm)
                    .ToList();

                return cinemaGroup;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Đã xảy ra lỗi khi lấy danh sách rạp và lịch chiếu theo Phim có Id: {MovieId}", movieId);
                return new List<CinemaListForMovieDto>();
            }
        }

        // Công thức Haversine để tính khoảng cách thực tế trên bản đồ (km)
        private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
        {
            var R = 6371; // Bán kính Trái Đất (km)
            var dLat = Deg2Rad(lat2 - lat1);
            var dLon = Deg2Rad(lon2 - lon1);

            var a = 
                Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(Deg2Rad(lat1)) * Math.Cos(Deg2Rad(lat2)) * 
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a)); 
            var d = R * c; // Distance in km
            return d;
        }

        private double Deg2Rad(double deg)
        {
            return deg * (Math.PI / 180);
        }

    }
}