using Microsoft.Extensions.Logging;
using MovieTicket.Application.DTOs.Product;
using MovieTicket.Application.Services.IServices.IProduct;
using MovieTicket.Domain.IResponsitories.IProduct;


namespace MovieTicket.Application.Services.Implementations.Product
{
    public class ProductService : IProductService
    {
        private readonly IProductRepository _productRepository;
        private readonly ILogger<ProductService> _logger;
        public ProductService(IProductRepository productRepository, ILogger<ProductService> logger)
        {
            _productRepository = productRepository;
            _logger = logger;
        }

        private string GetImageUrl(string? imagePath)
        {
            if (string.IsNullOrWhiteSpace(imagePath))
            {
                return string.Empty;
            }

            if (imagePath.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                imagePath.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                return imagePath;
            }

            var fileName = Path.GetFileName(imagePath);
            return $"/assets/Images/PRODUCT/{fileName}";
        }

        public async Task<IEnumerable<ProductDto>> GetProductsAsync()
        {
            try
            {
                var products = await _productRepository.GetProductsAsync();
                return products.Select(p => new ProductDto
                {
                    ProductId = p.ProductId,
                    NameProduct = p.ProductName,
                    ImageProduct = p.ImageProduct,
                    ImageUrl = GetImageUrl(p.ImageProduct),
                    Description = p.ProductDescription,
                    Price = p.ProductPrice
                }).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while retrieving products.");
                throw new Exception($"An error occurred while retrieving products: {ex.Message}", ex);
            }

        }
        public async Task<ProductDto?> GetProductByIdAsync(int productId)
        {
            var productList = await _productRepository.GetProductByIdAsync(productId);
            var product = productList;

            if (product == null)
            {
                return null;
            }
            return new ProductDto
            {
                ProductId = product.ProductId,
                NameProduct = product.ProductName,
                ImageProduct = product.ImageProduct,
                ImageUrl = GetImageUrl(product.ImageProduct),
                Description = product.ProductDescription,
                Price = product.ProductPrice
            };
        }
    }
}
