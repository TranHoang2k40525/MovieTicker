namespace MovieTicket.Domain.Entities
{


    public partial class Voucher
    {
        public int VoucherId { get; set; }

        public string? Code { get; set; }

        public decimal? DiscountValue { get; set; }

        public DateOnly? StartDate { get; set; }

        public DateOnly? EndDate { get; set; }

        public string? Description { get; set; }

        public int? PaymentId { get; set; }

        public bool? IsActive { get; set; }

        public string? Title { get; set; }

        public string? ImageVoucher { get; set; }

        public int? UsageLimit { get; set; }

        public int? UsageCount { get; set; }

        public bool? IsRestricted { get; set; }

        public virtual ICollection<VoucherUsage> VoucherUsages { get; set; } = new List<VoucherUsage>();
    }
}