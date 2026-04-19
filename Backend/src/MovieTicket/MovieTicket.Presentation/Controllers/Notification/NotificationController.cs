using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MovieTicket.Application.Services.IServices.ITicket;

namespace MovieTicket.Presentation.Controllers.Notification
{
    [ApiController]
    [Route("api/notifications")]
    [Authorize]
    public class NotificationController : ControllerBase
    {
        private readonly IMyTicketService _myTicketService;

        public NotificationController(IMyTicketService myTicketService)
        {
            _myTicketService = myTicketService;
        }

        [HttpGet("my")]
        public async Task<IActionResult> GetMyNotifications()
        {
            var accountId = GetAccountIdFromToken();
            if (accountId == null)
            {
                return Unauthorized(new { success = false, message = "Token không hợp lệ" });
            }

            var notifications = await _myTicketService.GetMyNotificationsAsync(accountId.Value);
            return Ok(new { success = true, data = notifications });
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
