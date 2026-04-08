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
    public class ShowConfiguration:         IEntityTypeConfiguration<Show>
    {
        public void Configure(EntityTypeBuilder<Show> entity)
        {
            entity.HasKey(e => e.ShowId).HasName("PK__Show__6DE3E0D22611764A");

            entity.ToTable("Show");

            entity.Property(e => e.ShowId).HasColumnName("ShowID").ValueGeneratedOnAdd();
            entity.Property(e => e.HallId).HasColumnName("HallID");
            entity.Property(e => e.MovieId).HasColumnName("MovieID");

            entity.HasOne(d => d.Hall).WithMany(p => p.Shows)
                .HasForeignKey(d => d.HallId)
                .HasConstraintName("FK__Show__HallID__282DF8C2");

            entity.HasOne(d => d.Movie).WithMany(p => p.Shows)
                .HasForeignKey(d => d.MovieId)
                .HasConstraintName("FK__Show__MovieID__29221CFB");
        }
    }
}
