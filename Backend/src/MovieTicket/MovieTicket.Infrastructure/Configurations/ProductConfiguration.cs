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
    public class ProductConfiguration : IEntityTypeConfiguration<Product>
    {
        public void Configure(EntityTypeBuilder<Product> entity)
        {
            entity.HasKey(e => e.ProductId).HasName("PK__Product__B40CC6ED714480AB");

            entity.ToTable("Product");

            entity.Property(e => e.ProductId).HasColumnName("ProductID").ValueGeneratedOnAdd();
            entity.Property(e => e.ProductDescription).HasMaxLength(255);
            entity.Property(e => e.ImageProduct).HasColumnType("nvarchar(max)");
            entity.Property(e => e.ProductName).HasMaxLength(100);
            entity.Property(e => e.ProductPrice).HasColumnType("decimal(10, 2)");
        }
    }
}
