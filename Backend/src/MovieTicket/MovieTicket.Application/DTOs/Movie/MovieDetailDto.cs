using System;

namespace MovieTicket.Application.DTOs.Movie
{
    public class MovieDetailDto
    {
        public int MovieId { get; set; }
        public string MovieTitle { get; set; } = string.Empty;
        public string MovieDescription { get; set; } = string.Empty;
        public string MovieLanguage { get; set; } = string.Empty;
        public string MovieGenre { get; set; } = string.Empty;
        public DateOnly? MovieReleaseDate { get; set; }
        public int? MovieRuntime { get; set; }
        public string MovieAge { get; set; } = string.Empty;
        public string ImageUrl { get; set; } = string.Empty;
        public string MovieActor { get; set; } = string.Empty;
        public string MovieTrailler { get; set; } = string.Empty;
    }
}
