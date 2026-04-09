using System.Collections.Generic;
using System.Threading.Tasks;
using MovieTicket.Domain.Entities;

namespace MovieTicket.Domain.IResponsitories.ICinema
{
    public interface ICinemaRepository
    {
        Task<IEnumerable<Cinema>> GetAllCinemasWithLocationsAsync();
        Task<Cinema?> GetCinemaByIdAsync(int cinemaId);
    }
}
