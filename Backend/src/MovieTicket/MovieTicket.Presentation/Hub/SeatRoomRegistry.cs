using System.Collections.Concurrent;

namespace MovieTicket.Presentation.Hub
{
    public class SeatRoomRegistry
    {
        private readonly ConcurrentDictionary<int, ConcurrentDictionary<string, int>> _roomConnections = new();
        private readonly ConcurrentDictionary<string, int> _connectionToShow = new();

        public void AddConnection(int showId, string connectionId, int accountId)
        {
            RemoveConnection(connectionId);

            var room = _roomConnections.GetOrAdd(showId, _ => new ConcurrentDictionary<string, int>());
            room[connectionId] = accountId;
            _connectionToShow[connectionId] = showId;
        }

        public int? RemoveConnection(string connectionId)
        {
            if (!_connectionToShow.TryRemove(connectionId, out var showId))
            {
                return null;
            }

            if (_roomConnections.TryGetValue(showId, out var room))
            {
                room.TryRemove(connectionId, out _);
                if (room.IsEmpty)
                {
                    _roomConnections.TryRemove(showId, out _);
                }
            }

            return showId;
        }

        public int CountInRoom(int showId)
        {
            if (_roomConnections.TryGetValue(showId, out var room))
            {
                return room.Count;
            }
            return 0;
        }
    }
}
