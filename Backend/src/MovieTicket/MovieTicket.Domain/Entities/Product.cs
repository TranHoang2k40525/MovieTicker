using System;
using System.Collections.Generic;

namespace MovieTicket.Domain.Entities
{

    public partial class Product
    {
        public int ProductId { get; set; }

        public string? ProductName { get; set; }

        public decimal? ProductPrice { get; set; }

        public string? ImageProduct { get; set; }

        public string? ProductDescription { get; set; }

        public virtual ICollection<BookingProduct> BookingProducts { get; set; } = new List<BookingProduct>();
    }
}