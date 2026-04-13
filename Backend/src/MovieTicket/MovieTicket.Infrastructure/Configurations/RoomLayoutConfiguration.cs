using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MovieTicket.Domain.Entities;

namespace MovieTicket.Infrastructure.Configurations
{
    public class RoomLayoutConfiguration : IEntityTypeConfiguration<RoomLayout>
    {
        public void Configure(EntityTypeBuilder<RoomLayout> builder)
        {
            builder.HasKey(e => e.LayoutId);

            builder.ToTable("RoomLayout");

            builder.Property(e => e.LayoutId).HasColumnName("layout_id");

            builder.Property(e => e.HallId).HasColumnName("HallID");

            builder.Property(e => e.RowSeat)
                .IsRequired()
                .HasMaxLength(5)
                .HasColumnName("row_seat");

            builder.Property(e => e.ColSeat).HasColumnName("col_seat");

            builder.Property(e => e.CellType)
                .IsRequired()
                .HasMaxLength(10)
                .HasColumnName("cell_type");

            builder.HasIndex(e => new { e.HallId, e.RowSeat, e.ColSeat }, "UQ_RoomLayout_Position").IsUnique();

            builder.HasOne(d => d.Hall)
                .WithMany(p => p.RoomLayouts)
                .HasForeignKey(d => d.HallId)
                .HasConstraintName("FK_RoomLayout_Hall");
        }
    }
}
