

namespace MovieTicket.Domain.Entities
{

    public partial class Cinema
    {
        public int CinemaId { get; set; }

        public string? CinemaName { get; set; }

        public int? CityId { get; set; }

        public string? CityAddress { get; set; }

        public double? Latitude { get; set; }

        public double? Longitude { get; set; }

        public virtual ICollection<CinemaHall> CinemaHalls { get; set; } = new List<CinemaHall>();

        public virtual ICollection<Account> Accounts { get; set; } = new List<Account>();

        public virtual City? City { get; set; }
    }
}