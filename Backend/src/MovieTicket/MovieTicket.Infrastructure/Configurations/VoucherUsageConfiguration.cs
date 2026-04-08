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
    public  class VoucherUsageConfiguration: IEntityTypeConfiguration<VoucherUsage>
    {
        public void Configure(EntityTypeBuilder<VoucherUsage> entity)
        {
            entity.HasKey(e => e.VoucherUsageId).HasName("PK__VoucherU__4264F82BCCE06F4C");

            entity.ToTable("VoucherUsage");

            entity.Property(e => e.VoucherUsageId).HasColumnName("VoucherUsageID").ValueGeneratedOnAdd();
            entity.Property(e => e.BookingId).HasColumnName("BookingID");
            entity.Property(e => e.UsedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.UserId).HasColumnName("UserID");
            entity.Property(e => e.VoucherId).HasColumnName("VoucherID");

            entity.HasOne(d => d.User).WithMany(p => p.VoucherUsages)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__VoucherUs__UserI__2B0A656D");

            entity.HasOne(d => d.Voucher).WithMany(p => p.VoucherUsages)
                .HasForeignKey(d => d.VoucherId)
                .HasConstraintName("FK__VoucherUs__Vouch__2BFE89A6");
        }
    }
}
