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
    public class RoleConfiguration : IEntityTypeConfiguration<Role>
    {
        public void Configure(EntityTypeBuilder<Role> entity)
        {
            entity.HasKey(e => e.RoleId).HasName("PK__Roles__760965CC90713F13");

            entity.Property(e => e.RoleId).HasColumnName("role_id").ValueGeneratedOnAdd();
            entity.Property(e => e.RoleName)
                .HasMaxLength(50)
                .HasColumnName("role_name");

            entity.Property(e => e.Type)
                .HasConversion<string>()
                .HasMaxLength(50)
                .HasColumnName("role_type");
        }
    }
}
