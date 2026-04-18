using MovieTicket.Application.DTOs.Booking;

namespace MovieTicket.Application.Services.IServices.IBooking
{
    public interface IBookingFlowService
    {
        Task<StartSeatHoldResponse> StartSeatHoldAsync(int accountId, StartSeatHoldRequest request);
        Task<ConfirmSeatBookingResponse> ConfirmSeatBookingAsync(int accountId, ConfirmSeatBookingRequest request);
        Task<bool> ReleaseExpiredHoldsAsync();
        Task<bool> ReleaseHoldAsync(int accountId, int holdId);
    }
}