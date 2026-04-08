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
    public class CinemaConfiguration :IEntityTypeConfiguration<Cinema>
    {
        public void Configure(EntityTypeBuilder<Cinema> entity)
        {
            entity.HasKey(e => e.CinemaId).HasName("PK__Cinema__59C9262697EE2F56");

            entity.ToTable("Cinema");

            entity.Property(e => e.CinemaId).HasColumnName("CinemaID").ValueGeneratedOnAdd();
            entity.Property(e => e.CinemaName).HasMaxLength(255);
            entity.Property(e => e.CityAddress).HasMaxLength(255);
            entity.Property(e => e.CityId).HasColumnName("CityID");

            entity.HasOne(d => d.City).WithMany(p => p.Cinemas)
                .HasForeignKey(d => d.CityId)
                .HasConstraintName("FK__Cinema__CityID__1CBC4616");
        }
    }
}
