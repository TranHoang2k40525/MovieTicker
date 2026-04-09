using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MovieTicket.Application.DTOs.Cinema;

namespace MovieTicket.Application.Services.IServices.ICinema
{
    public interface ICinemaPubService
    {
        Task<IEnumerable<NearbyCinemaDto>> GetCinemasSortedByDistanceAsync(double userLat, double userLng);
        Task<IEnumerable<CinemaShowtimeDto>> GetShowtimesByCinemaAsync(int cinemaId, DateOnly? filterDate);
    }
}