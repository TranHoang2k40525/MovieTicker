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
    public class CityConfiguration: IEntityTypeConfiguration<City>
    {
        public void Configure(EntityTypeBuilder<City> entity)
    {
            entity.HasKey(e => e.CityId).HasName("PK__City__F2D21A964D499A0D");

            entity.ToTable("City");

            entity.Property(e => e.CityId).HasColumnName("CityID").ValueGeneratedOnAdd();
            entity.Property(e => e.CityName).HasMaxLength(255);
        }
    }
}
