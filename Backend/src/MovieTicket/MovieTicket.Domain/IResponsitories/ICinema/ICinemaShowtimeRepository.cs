using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MovieTicket.Domain.Entities;

namespace MovieTicket.Domain.IResponsitories.ICinema
{
    public interface ICinemaShowtimeRepository
    {
        Task<IEnumerable<Show>> GetShowsByCinemaAndDateAsync(int cinemaId, DateOnly fromDate, DateOnly toDate);
    }
}