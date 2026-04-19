using Microsoft.AspNetCore.SignalR;

namespace MovieTicket.Presentation.Hub
{
    public class SeatBookingHub : Microsoft.AspNetCore.SignalR.Hub
    {
        private readonly SeatRoomRegistry _seatRoomRegistry;

        public SeatBookingHub(SeatRoomRegistry seatRoomRegistry)
        {
            _seatRoomRegistry = seatRoomRegistry;
        }

        public async Task JoinShowRoom(int showId)
        {
            if (showId <= 0)
            {
                throw new HubException("showId không hợp lệ");
            }

            var accountId = ResolveAccountId();
            _seatRoomRegistry.AddConnection(showId, Context.ConnectionId, accountId);

            await Groups.AddToGroupAsync(Context.ConnectionId, BuildRoomName(showId));
            await Clients.Caller.SendAsync("JoinedShowRoom", new
            {
                showId,
                memberCount = _seatRoomRegistry.CountInRoom(showId)
            });
        }

        public async Task LeaveShowRoom(int showId)
        {
            _seatRoomRegistry.RemoveConnection(Context.ConnectionId);
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, BuildRoomName(showId));
            await Clients.Caller.SendAsync("LeftShowRoom", new { showId });
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var showId = _seatRoomRegistry.RemoveConnection(Context.ConnectionId);
            if (showId.HasValue)
            {
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, BuildRoomName(showId.Value));
            }

            await base.OnDisconnectedAsync(exception);
        }

        public static string BuildRoomName(int showId) => $"show-{showId}";

        private int ResolveAccountId()
        {
            var claimValue = Context.User?.FindFirst("accountId")?.Value;
            return int.TryParse(claimValue, out var accountId) ? accountId : 0;
        }
    }
}
