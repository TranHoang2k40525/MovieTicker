using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieTicket.Application.Services.IServices.ITicket;

namespace MovieTicket.Presentation.Controllers.Ticket
{
    [ApiController]
    [Route("api/tickets")]
    [Authorize]
    public class MyTicketController : ControllerBase
    {
        private readonly IMyTicketService _myTicketService;

        public MyTicketController(IMyTicketService myTicketService)
        {
            _myTicketService = myTicketService;
        }

        [HttpGet("my")]
        public async Task<IActionResult> GetMyTickets()
        {
            var accountId = GetAccountIdFromToken();
            if (accountId == null)
            {
                return Unauthorized(new { success = false, message = "Token không hợp lệ" });
            }

            var tickets = await _myTicketService.GetMyTicketsAsync(accountId.Value);
            return Ok(new { success = true, data = tickets });
        }

        [HttpGet("my/history")]
        public async Task<IActionResult> GetMyTicketHistory()
        {
            var accountId = GetAccountIdFromToken();
            if (accountId == null)
            {
                return Unauthorized(new { success = false, message = "Token không hợp lệ" });
            }

            var history = await _myTicketService.GetMyTicketHistoryAsync(accountId.Value);
            return Ok(new { success = true, data = history });
        }

        [HttpGet("my/{bookingId:int}")]
        public async Task<IActionResult> GetMyTicketDetail(int bookingId)
        {
            var accountId = GetAccountIdFromToken();
            if (accountId == null)
            {
                return Unauthorized(new { success = false, message = "Token không hợp lệ" });
            }

            var ticket = await _myTicketService.GetMyTicketDetailAsync(accountId.Value, bookingId);
            if (ticket == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy vé" });
            }

            return Ok(new { success = true, data = ticket });
        }

        private int? GetAccountIdFromToken()
        {
            var claim = User.FindFirst("accountId")?.Value;
            if (int.TryParse(claim, out var accountId) && accountId > 0)
            {
                return accountId;
            }

            return null;
        }
    }
}
