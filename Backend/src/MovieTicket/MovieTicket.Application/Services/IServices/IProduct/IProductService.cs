using MovieTicket.Application.DTOs.Product;

namespace MovieTicket.Application.Services.IServices.IProduct
{
    public interface IProductService
    {
        Task<IEnumerable<ProductDto>> GetProductsAsync();
        Task<ProductDto?> GetProductByIdAsync(int productId);
    }
}
