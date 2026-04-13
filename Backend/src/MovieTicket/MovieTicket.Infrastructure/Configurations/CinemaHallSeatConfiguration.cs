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
    public class CinemaHallSeatConfiguration :IEntityTypeConfiguration<CinemaHallSeat>
    {
        public void Configure(EntityTypeBuilder<CinemaHallSeat> entity)
        {
            entity.HasKey(e => e.SeatId).HasName("PK__CinemaHa__311713D347655F51");

            entity.ToTable("CinemaHallSeat");

            entity.Property(e => e.SeatId).HasColumnName("SeatID").ValueGeneratedOnAdd();
            entity.Property(e => e.HallId).HasColumnName("HallID");
            entity.Property(e => e.PairId).HasColumnName("PairID");
            entity.Property(e => e.SeatNumber)
                .HasMaxLength(10)
                .IsUnicode(false);
            entity.Property(e => e.SeatPrice).HasColumnType("decimal(10, 2)");
            entity.Property(e => e.SeatType).HasMaxLength(20);
            entity.Property(e => e.Status).HasMaxLength(20);

            entity.Property(e => e.RowSeat)
                .HasColumnName("row_seat")
                .HasMaxLength(5);

            entity.Property(e => e.ColSeat)
                .HasColumnName("col_seat");

            entity.HasIndex(e => new { e.HallId, e.RowSeat, e.ColSeat }, "UQ_Hall_Row_Col").IsUnique();

            entity.HasOne(d => d.Hall).WithMany(p => p.CinemaHallSeats)
                .HasForeignKey(d => d.HallId)
                .HasConstraintName("FK__CinemaHal__HallI__1EA48E88");
        }
    }
}
