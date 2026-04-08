using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MovieTicket.Domain.Entities;

namespace MovieTicket.Infrastructure.Configurations
{
    public class BookingProductConfiguration : IEntityTypeConfiguration<BookingProduct>
    {
        public void Configure(EntityTypeBuilder<BookingProduct> entity)
        {
            entity.HasKey(e => e.BookingProductId).HasName("PK__BookingP__8AFEF455DB05F0CA");

            entity.ToTable("BookingProduct");

            entity.Property(e => e.BookingProductId).HasColumnName("BookingProductID").ValueGeneratedOnAdd();
            entity.Property(e => e.BookingId).HasColumnName("BookingID");
            entity.Property(e => e.ProductId).HasColumnName("ProductID");
            entity.Property(e => e.TotalPriceBookingProduct).HasColumnType("decimal(10, 2)");

            entity.HasOne(d => d.Booking).WithMany(p => p.BookingProducts)
                .HasForeignKey(d => d.BookingId)
                .HasConstraintName("FK__BookingPr__Booki__18EBB532");

            entity.HasOne(d => d.Product).WithMany(p => p.BookingProducts)
                .HasForeignKey(d => d.ProductId)
                .HasConstraintName("FK__BookingPr__Produ__19DFD96B");
        }
    }
}
