namespace MovieTicket.Application.DTOs.Cinema
{
    using System.Collections.Generic;

    public class CinemaListForMovieDto
    {
        public int CinemaId { get; set; }
        public string CinemaName { get; set; } = string.Empty;
        public string CityAddress { get; set; } = string.Empty;
        public double DistanceInKm { get; set; }

        public List<ShowtimeDetailDto> Showtimes { get; set; } = new List<ShowtimeDetailDto>();
    }
}