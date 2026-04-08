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
    public class LikeMovieConfiguration : IEntityTypeConfiguration<LikeMovie>
    {
        public void Configure(EntityTypeBuilder<LikeMovie> entity)
        {
            entity.HasKey(e => new { e.UserId, e.MovieId }).HasName("PK__LikeMovi__A335E5EF7319EB51");

            entity.ToTable("LikeMovie");

            entity.Property(e => e.UserId).HasColumnName("UserID");
            entity.Property(e => e.MovieId).HasColumnName("MovieID");

            entity.HasOne(d => d.Movie).WithMany(p => p.LikeMovies)
                .HasForeignKey(d => d.MovieId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__LikeMovie__Movie__1F98B2C1");

            entity.HasOne(d => d.User).WithMany(p => p.LikeMovies)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__LikeMovie__UserI__208CD6FA");
        }

    }
}
