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
    public class MovieConfiguration : IEntityTypeConfiguration<Movie>
    {public void Configure(EntityTypeBuilder<Movie> entity)
        {
            entity.HasKey(e => e.MovieId).HasName("PK__Movie__4BD2943A61565677");

            entity.ToTable("Movie");

            entity.Property(e => e.MovieId).HasColumnName("MovieID").ValueGeneratedOnAdd();
            entity.Property(e => e.MovieActor).HasMaxLength(255);
            entity.Property(e => e.MovieDescription).HasColumnType("nvarchar(max)");
            entity.Property(e=> e.ImageUrl).HasColumnType("nvarchar(max)");
            entity.Property(e => e.MovieAge).HasMaxLength(50);
            entity.Property(e => e.MovieGenre).HasMaxLength(100);
            entity.Property(e => e.MovieLanguage).HasMaxLength(50);
            entity.Property(e => e.MovieTitle).HasMaxLength(255);
            entity.Property(e => e.MovieTrailler).HasMaxLength(500);
        }
    }
}
