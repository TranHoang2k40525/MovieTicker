namespace MovieTicket.Domain.Entities
{

    public partial class Movie
    {
        public int MovieId { get; set; }

        public string? MovieTitle { get; set; }

        public string? MovieDescription { get; set; }

        public string? MovieLanguage { get; set; }

        public string? MovieGenre { get; set; }

        public DateOnly? MovieReleaseDate { get; set; }

        public int? MovieRuntime { get; set; }

        public string? MovieAge { get; set; }

        public string? ImageUrl { get; set; }

        public string? MovieActor { get; set; }

        public string? MovieTrailler { get; set; }

        public virtual ICollection<LikeMovie> LikeMovies { get; set; } = new List<LikeMovie>();

        public virtual ICollection<Show> Shows { get; set; } = new List<Show>();
    }
}