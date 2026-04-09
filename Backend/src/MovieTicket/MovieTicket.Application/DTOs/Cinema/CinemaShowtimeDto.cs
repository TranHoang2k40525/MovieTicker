using System;
using System.Collections.Generic;

namespace MovieTicket.Application.DTOs.Cinema
{
    public class CinemaShowtimeDto
    {
        public int MovieId { get; set; }
        public string MovieTitle { get; set; } = string.Empty;
        public string ImageUrl { get; set; } = string.Empty;
        public string MovieAge { get; set; } = string.Empty;
        public string MovieGenre { get; set; } = string.Empty;
        public int? MovieRuntime { get; set; }

        public List<ShowtimeDetailDto> Showtimes { get; set; } = new List<ShowtimeDetailDto>();
    }

    public class ShowtimeDetailDto
    {
        public int ShowId { get; set; }
        public DateOnly ShowDate { get; set; }
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
        public int CinemaHallId { get; set; }
        public string HallName { get; set; } = string.Empty;
        public string ExperienceType { get; set; } = string.Empty; // e.g. 2D, 3D, IMAX
    }
}