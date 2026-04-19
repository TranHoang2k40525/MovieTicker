using MovieTicket.Application.DTOs.Ticket;

namespace MovieTicket.Application.Services.IServices.ITicket
{
    public interface IMyTicketService
    {
        Task<List<MyTicketItemDto>> GetMyTicketsAsync(int accountId);
        Task<MyTicketDetailDto?> GetMyTicketDetailAsync(int accountId, int bookingId);
        Task<List<MyTicketHistoryItemDto>> GetMyTicketHistoryAsync(int accountId);
    }
}
