using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MovieTicket.Application.Services.IServices.IBooking;
using MovieTicket.Domain.IResponsitories.IAuth;
using MovieTicket.Domain.IResponsitories.IBooking;

namespace MovieTicket.Application.Services.Implementations.Booking
{
    public class BookingFlowService : IBookingFlowService
    {
        private readonly IBookingRepository _bookingRepository;
        private readonly ISeatMapRepository _seatMapRepository;
        private readonly IAccountRepository _accountRepository;


        public BookingFlowService(ISeatMapService seatMapService)
        {
            _seatMapService = seatMapService;
        }
    }
}
