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
    public class CinemaHallConfiguration : IEntityTypeConfiguration<CinemaHall>
    {
        public void Configure(EntityTypeBuilder<CinemaHall> entity)
        {
            entity.HasKey(e => e.HallId).HasName("PK__CinemaHa__7E60E2748CC49DFC");

            entity.ToTable("CinemaHall");

            entity.Property(e => e.HallId).HasColumnName("HallID").ValueGeneratedOnAdd();
            entity.Property(e => e.CinemaId).HasColumnName("CinemaID");
            entity.Property(e => e.HallName).HasMaxLength(255);

            entity.HasOne(d => d.Cinema).WithMany(p => p.CinemaHalls)
                .HasForeignKey(d => d.CinemaId)
                .HasConstraintName("FK__CinemaHal__Cinem__1DB06A4F");
        }

        
    }
}
