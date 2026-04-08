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
    public class LoginHistoryConfiguration : IEntityTypeConfiguration<LoginHistory>
    {public void Configure(EntityTypeBuilder<LoginHistory> entity)
        {
            entity.HasKey(e => e.HistoryId).HasName("PK__LoginHis__096AA2E9C6FFBA14");

            entity.ToTable("LoginHistory");

            entity.Property(e => e.HistoryId).HasColumnName("history_id").ValueGeneratedOnAdd(); 
            entity.Property(e => e.AccountId).HasColumnName("account_id");
            entity.Property(e => e.DeviceInfo)
                .HasMaxLength(255)
                .HasColumnName("device_info");
            entity.Property(e => e.IpAddress)
                .HasMaxLength(50)
                .HasColumnName("ip_address");
            entity.Property(e => e.LoginTime)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("login_time");

            entity.HasOne(d => d.Account).WithMany(p => p.LoginHistories)
                .HasForeignKey(d => d.AccountId)
                .HasConstraintName("FK__LoginHist__accou__2180FB33");
        }
    }
}
