
namespace MovieTicket.Domain.Entities
{

    public partial class City
    {
        public int CityId { get; set; }

        public string CityName { get; set; } = null!;

        public virtual ICollection<Cinema> Cinemas { get; set; } = new List<Cinema>();
    }
}