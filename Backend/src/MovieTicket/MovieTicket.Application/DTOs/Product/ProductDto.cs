using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MovieTicket.Application.DTOs.Product
{
    public class ProductDto
    {
        public int ProductId { get; set; }
        public string? NameProduct { get; set; }
        public string? ImageProduct { get; set; }
        public string? ImageUrl { get; set; }
        public decimal? Price { get; set; }
        public string? Description { get; set; }

    }
}
