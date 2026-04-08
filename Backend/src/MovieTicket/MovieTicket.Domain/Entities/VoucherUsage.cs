namespace MovieTicket.Domain.Entities {

    public partial class VoucherUsage
    {
        public int VoucherUsageId { get; set; }

        public int? VoucherId { get; set; }

        public int? UserId { get; set; }

        public DateTime? UsedAt { get; set; }

        public int? BookingId { get; set; }

        public virtual User? User { get; set; }

        public virtual Voucher? Voucher { get; set; }
    }
}


