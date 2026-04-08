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
    public class AccountConfiguration : IEntityTypeConfiguration<Account>
    {
        public void Configure(EntityTypeBuilder<Account> entity)
        {
            entity.ToTable("Account");
            entity.HasKey(e => e.AccountId).HasName("PK__Accounts__46A222CD72F2C3F9");

            entity.HasIndex(e => e.Email, "UQ__Accounts__AB6E6164EE02E64B").IsUnique();

            entity.HasIndex(e => e.Phone, "UQ__Accounts__B43B145F1057CB3A").IsUnique();

            entity.Property(e => e.AccountId).HasColumnName("account_id").ValueGeneratedOnAdd();
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.Email)
                .HasMaxLength(100)
                .HasColumnName("email");
            entity.Property(e => e.PasswordHash)
                .HasMaxLength(255)
                .HasColumnName("password_hash");
            entity.Property(e => e.Phone)
                .HasMaxLength(20)
                .HasColumnName("phone");
            entity.Property(e => e.Status)
                .HasConversion<string>()
                .HasMaxLength(20)
                .HasColumnName("status");
            entity.Property(e => e.UpdatedAt)
                .HasColumnType("datetime")
                .HasColumnName("updated_at");

            entity.Property(e => e.CinemaId)
                .HasColumnName("cinema_id");

            entity.HasOne(d => d.Cinema)
                .WithMany(p => p.Accounts)
                .HasForeignKey(d => d.CinemaId)
                .HasConstraintName("FK_Account_Cinema");
        }
    }
}
