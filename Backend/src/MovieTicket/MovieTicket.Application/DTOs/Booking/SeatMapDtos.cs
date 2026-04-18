using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MovieTicket.Application.DTOs.Booking
{
    public class SeatMapDTO
    {
        public int ShowId { get; set; }
        public int MovieId { get; set; }
        public string MovieTitle { get; set; } = string.Empty;
        public DateOnly ShowDate { get; set; }
        public TimeSpan StartTime { get; set; }

        public int CinemaId { get; set; }
        public string CinemaName { get; set; } = string.Empty;
        public string CinemaAddress { get; set; } = string.Empty;

        public int HallId { get; set; }
        public string HallName { get; set; } = string.Empty;

        public List<SeatMapRowDto> Rows { get; set; } = new();
        public List<SeatLegendItemDto> Legend { get; set; } = new();
        public List<string> ValidationWarnings { get; set; } = new();
    }
    public class SeatMapRowDto
    {
        public string RowSeat { get; set; } = string.Empty;
        public List<SeatMapCellDto> Cells { get; set; } = new();
    }
    public class SeatMapCellDto
    {
        public int ColSeat { get; set; }
        public string CellType { get; set; } = string.Empty; // SEAT/AISLE/EMPTY/BLOCK

        public int? SeatId { get; set; }
        public string? SeatNumber { get; set; }
        public string? SeatClass { get; set; } // THUONG/VIP/SWEET_BOX
        public decimal? SeatPrice { get; set; }
        public int? PairId { get; set; }
        public int? PairSeatId { get; set; }
        public bool IsCoupleSeat { get; set; }
        public bool IsOddEdgeRisk { get; set; }

        public string State { get; set; } = "unavailable"; // available/held/booked/unavailable
        public bool Selectable { get; set; }
    }
    public class SeatLegendItemDto
    {
        public string Key { get; set; } = string.Empty;
        public string Label { get; set; } = string.Empty;
    }
}
