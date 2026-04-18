using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using MovieTicket.Application.DTOs.Booking;
using MovieTicket.Application.Services.IServices.IBooking;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IBooking;

namespace MovieTicket.Application.Services.Implementations.Booking
{
    public class SeatMapService : ISeatMapService
    {
        private static class CellTypes
        {
            public const string Seat = "SEAT";
            public const string Aisle = "AISLE";
            public const string Empty = "EMPTY";
            public const string Block = "BLOCK";
        }

        private static class SeatStates
        {
            public const string Available = "available";
            public const string Held = "held";
            public const string Booked = "booked";
            public const string Unavailable = "unavailable";
            public const string Layout = "layout";
        }

        private readonly ISeatMapRepository _seatMapRepository;
        private readonly ILogger<SeatMapService> _logger;

        public SeatMapService(ISeatMapRepository seatMapRepository, ILogger<SeatMapService> logger)
        {
            _seatMapRepository = seatMapRepository;
            _logger = logger;
        }
        public async Task<SeatMapDTO?> GetSeatMapByShowAsync(int showId)
        {
            _logger.LogInformation("Bắt đầu dựng sơ đồ ghế cho showId={ShowId}", showId);
            var shows = await _seatMapRepository.GetShowContextAsync(showId);
            if (shows == null || shows.HallId == null || shows.Hall == null || shows.Hall.Cinema == null || shows.Movie == null)
            {
                _logger.LogWarning("Thiếu ngữ cảnh suất chiếu cho showId={ShowId}", showId);

                return null;
            }
            var hallId = shows.HallId.Value;
            var layout = await _seatMapRepository.GetRoomLayoutByHallAsync(hallId);
            var seats = await _seatMapRepository.GetSeatsByHallAsync(hallId);
            var bookingSeats = await _seatMapRepository.GetBookingSeatsByShowAsync(showId);
            var validationWarnings = new List<string>();

            var seatByPos = new Dictionary<string, CinemaHallSeat>();
            var seatById = new Dictionary<int, CinemaHallSeat>();

            foreach (var seat in seats)
            {
                seatById[seat.SeatId] = seat;
                if (!string.IsNullOrWhiteSpace(seat.RowSeat) && seat.ColSeat.HasValue)
                {
                    var key = BuildPosKey(seat.RowSeat, seat.ColSeat.Value);
                    if (!seatByPos.ContainsKey(key))
                    {
                        seatByPos[key] = seat;
                    }
                    else
                    {
                        var msg = $"Trùng ánh xạ vị trí ghế tại key={key}, SeatId={seat.SeatId}";
                        validationWarnings.Add(msg);
                        _logger.LogWarning("{Message} ShowId={ShowId} HallId={HallId}", msg, showId, hallId);
                    }
                }
            }

            var now = DateTime.UtcNow;
            var bookingStateBySeatId = BuildBookingStateBySeatId(bookingSeats, now);

            var invalidCoupleSeatIds = GetInvalidCoupleSeats(seats, seatById, validationWarnings, showId, hallId);

            var rows = layout
                .GroupBy(x => x.RowSeat.Trim().ToUpperInvariant())
                .OrderBy(g => g.Key)
                .Select(g =>
                {
                    var rowDto = new SeatMapRowDto { RowSeat = g.Key };

                    foreach (var cell in g.OrderBy(x => x.ColSeat))
                    {
                        var cellType = (cell.CellType ?? string.Empty).Trim().ToUpperInvariant();
                        var cellDto = new SeatMapCellDto
                        {
                            ColSeat = cell.ColSeat,
                            CellType = cellType,
                            State = SeatStates.Unavailable,
                            Selectable = false
                        };

                        if (cellType == CellTypes.Seat)
                        {
                            var key = BuildPosKey(g.Key, cell.ColSeat);
                            if (seatByPos.TryGetValue(key, out var seat))
                            {
                                cellDto.SeatId = seat.SeatId;
                                cellDto.SeatNumber = seat.SeatNumber;
                                cellDto.SeatClass = MapSeatClass(seat.SeatType);
                                cellDto.SeatPrice = seat.SeatPrice;
                                cellDto.IsCoupleSeat = seat.SeatType == SeatType.Couple;
                                cellDto.PairId = seat.PairId;
                                if (seat.PairId.HasValue && seatById.TryGetValue(seat.PairId.Value, out var pairSeat))
                                {
                                    cellDto.PairSeatId = pairSeat.SeatId;
                                }

                                var state = MapSeatStateFromSeat(seat.Status);
                                if (bookingStateBySeatId.TryGetValue(seat.SeatId, out var bookedState))
                                {
                                    // override bằng trạng thái theo showId
                                    state = bookedState;
                                }

                                // Ghế đôi lỗi cặp coi như không thể chọn để tránh ghế lẻ ghế đôi.
                                if (seat.SeatType == SeatType.Couple && invalidCoupleSeatIds.Contains(seat.SeatId))
                                {
                                    state = SeatStates.Unavailable;
                                }

                                cellDto.State = state;
                                cellDto.Selectable = state == SeatStates.Available;
                            }
                        }
                        else if (cellType == CellTypes.Aisle || cellType == CellTypes.Empty || cellType == CellTypes.Block)
                        {
                            cellDto.State = SeatStates.Layout;
                            cellDto.Selectable = false;
                        }

                        rowDto.Cells.Add(cellDto);
                    }

                    return rowDto;
                })
                .ToList();

            MarkOddEdgeSeatRisks(rows, validationWarnings, showId, hallId);

            return new SeatMapDTO
            {
                ShowId = shows.ShowId,
                MovieId = shows.MovieId ?? 0,
                MovieTitle = shows.Movie.MovieTitle ?? string.Empty,
                ShowDate = shows.ShowDate ?? default,
                StartTime = shows.ShowTime?.ToTimeSpan() ?? TimeSpan.Zero,

                CinemaId = shows.Hall.CinemaId ?? 0,
                CinemaName = shows.Hall.Cinema.CinemaName ?? string.Empty,
                CinemaAddress = shows.Hall.Cinema.CityAddress ?? string.Empty,

                HallId = hallId,
                HallName = shows.Hall.HallName ?? string.Empty,

                Rows = rows,
                Legend = BuildLegend(),
                ValidationWarnings = validationWarnings
            };

        }

        private static string BuildPosKey(string rowSeat, int colSeat)
        {
            return $"{rowSeat.Trim().ToUpperInvariant()}|{colSeat}";
        }

        private Dictionary<int, string> BuildBookingStateBySeatId(List<BookingSeat> bookingSeats, DateTime now)
        {
            var result = new Dictionary<int, string>();

            foreach (var bookingSeat in bookingSeats)
            {
                if (!bookingSeat.SeatId.HasValue)
                {
                    continue;
                }

                var seatId = bookingSeat.SeatId.Value;
                var candidateState = ResolveBookingState(bookingSeat, now);

                if (!result.TryGetValue(seatId, out var currentState))
                {
                    result[seatId] = candidateState;
                    continue;
                }

                if (GetStatePriority(candidateState) > GetStatePriority(currentState))
                {
                    result[seatId] = candidateState;
                }
            }

            return result;
        }

        private HashSet<int> GetInvalidCoupleSeats(
            List<CinemaHallSeat> seats,
            Dictionary<int, CinemaHallSeat> seatById,
            List<string> validationWarnings,
            int showId,
            int hallId)
        {
            var invalidIds = new HashSet<int>();

            foreach (var seat in seats.Where(s => s.SeatType == SeatType.Couple))
            {
                if (!seat.PairId.HasValue)
                {
                    invalidIds.Add(seat.SeatId);
                    var msg = $"Ghế đôi {seat.SeatId} ({seat.SeatNumber}) thiếu PairId.";
                    validationWarnings.Add(msg);
                    _logger.LogWarning("{Message} ShowId={ShowId} HallId={HallId}", msg, showId, hallId);
                    continue;
                }

                if (!seatById.TryGetValue(seat.PairId.Value, out var pairSeat))
                {
                    invalidIds.Add(seat.SeatId);
                    var msg = $"Ghế đôi {seat.SeatId} ({seat.SeatNumber}) trỏ tới PairId={seat.PairId} không tồn tại.";
                    validationWarnings.Add(msg);
                    _logger.LogWarning("{Message} ShowId={ShowId} HallId={HallId}", msg, showId, hallId);
                    continue;
                }

                var isValidPair = pairSeat.SeatType == SeatType.Couple && pairSeat.PairId == seat.SeatId;
                if (!isValidPair)
                {
                    invalidIds.Add(seat.SeatId);
                    invalidIds.Add(pairSeat.SeatId);
                    var msg = $"Ghép cặp ghế đôi không hợp lệ: ghế {seat.SeatId} <-> {pairSeat.SeatId}.";
                    validationWarnings.Add(msg);
                    _logger.LogWarning("{Message} ShowId={ShowId} HallId={HallId}", msg, showId, hallId);
                }
            }

            return invalidIds;
        }

        private void MarkOddEdgeSeatRisks(List<SeatMapRowDto> rows, List<string> validationWarnings, int showId, int hallId)
        {
            foreach (var row in rows)
            {
                // Nhóm liên tiếp các ghế có thể chọn trong cùng 1 row.
                var runStart = -1;

                for (var i = 0; i <= row.Cells.Count; i++)
                {
                    var isSelectableSeat = i < row.Cells.Count &&
                                           row.Cells[i].CellType == CellTypes.Seat &&
                                           row.Cells[i].State == SeatStates.Available;

                    if (isSelectableSeat)
                    {
                        if (runStart == -1)
                        {
                            runStart = i;
                        }
                        continue;
                    }

                    if (runStart != -1)
                    {
                        var runLength = i - runStart;
                        if (runLength == 1)
                        {
                            var riskyCell = row.Cells[runStart];
                            riskyCell.IsOddEdgeRisk = true;

                            var msg = $"Nguy cơ ghế lẻ ở biên tại hàng {row.RowSeat}, cột {riskyCell.ColSeat}, ghế {riskyCell.SeatNumber ?? "N/A"}.";
                            validationWarnings.Add(msg);
                            _logger.LogWarning("{Message} ShowId={ShowId} HallId={HallId}", msg, showId, hallId);
                        }

                        runStart = -1;
                    }
                }
            }
        }

        private static string ResolveBookingState(BookingSeat bookingSeat, DateTime now)
        {
            if (bookingSeat.Status == BookingSeatStatus.booked)
            {
                return SeatStates.Booked;
            }

            if (bookingSeat.Status == BookingSeatStatus.held && bookingSeat.HoldUntil.HasValue && bookingSeat.HoldUntil.Value > now)
            {
                return SeatStates.Held;
            }

            return SeatStates.Available;
        }

        private static int GetStatePriority(string state)
        {
            if (state == SeatStates.Booked) return 3;
            if (state == SeatStates.Held) return 2;
            if (state == SeatStates.Available) return 1;
            return 0;
        }

        private static string ResolveBookingState(List<BookingSeat> rows, DateTime now)
        {
            //neu co ban ghi booked -> booked
            if (rows.Any(x => x.Status == BookingSeatStatus.booked))
            {
                return SeatStates.Booked;

            }
            // neu held het han -> held
            var hasHeld = rows.Any(x =>
                x.Status == BookingSeatStatus.held &&
                x.HoldUntil.HasValue &&
                x.HoldUntil.Value > now);
            if (hasHeld)
            {
                return SeatStates.Held;
            }
            return SeatStates.Available;
        }
        private static string MapSeatStateFromSeat(SeatStatus? status)
        {
            if (status == SeatStatus.booked) return SeatStates.Booked;
            if (status == SeatStatus.held) return SeatStates.Held;
            return SeatStates.Available;
        }
        private static string MapSeatClass(SeatType? seatType)
        {
            if (seatType == SeatType.VIP) return "VIP";
            if (seatType == SeatType.Couple) return "SWEET_BOX";
            return "THUONG";
        }
        private static List<SeatLegendItemDto> BuildLegend()
        {
            return new List<SeatLegendItemDto>
            {
                new SeatLegendItemDto { Key = "booked", Label = "Đã đặt" },
                new SeatLegendItemDto { Key = "selected", Label = "Đang chọn" },
                new SeatLegendItemDto { Key = "VIP", Label = "VIP" },
                new SeatLegendItemDto { Key = "THUONG", Label = "Thường" },
                new SeatLegendItemDto { Key = "SWEET_BOX", Label = "Sweet box" }
            };
        }


    }
}
