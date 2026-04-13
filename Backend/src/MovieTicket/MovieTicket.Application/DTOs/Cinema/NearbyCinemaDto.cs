namespace MovieTicket.Application.DTOs.Cinema
{
    public class NearbyCinemaDto
    {
        public int CinemaId { get; set; }
        public string CinemaName { get; set; } = string.Empty;
        public string CityAddress { get; set; } = string.Empty;
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public double DistanceInKm { get; set; }
    }
}