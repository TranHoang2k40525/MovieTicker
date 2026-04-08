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
    public class BookingSeatConfiguration : IEntityTypeConfiguration<BookingSeat>
    {
        public void Configure(EntityTypeBuilder<BookingSeat> entity)
        {
            entity.HasKey(e => e.BookingSeatId).HasName("PK__BookingS__FA4B942630564FAF");

            entity.ToTable("BookingSeat");

            entity.Property(e => e.BookingSeatId).HasColumnName("BookingSeatID").ValueGeneratedOnAdd();
            entity.Property(e => e.BookingId).HasColumnName("BookingID");
            entity.Property(e => e.HoldUntil).HasColumnType("datetime");
            entity.Property(e => e.SeatId).HasColumnName("SeatID");
            entity.Property(e => e.ShowId).HasColumnName("ShowID");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .IsUnicode(false);
            entity.Property(e => e.TicketPrice).HasColumnType("decimal(10, 2)");

            entity.HasOne(d => d.Booking).WithMany(p => p.BookingSeats)
                .HasForeignKey(d => d.BookingId)
                .HasConstraintName("FK__BookingSe__Booki__1AD3FDA4");

            entity.HasOne(d => d.Seat).WithMany(p => p.BookingSeats)
                .HasForeignKey(d => d.SeatId)
                .HasConstraintName("FK__BookingSe__SeatI__1BC821DD");
        }
    }
}
