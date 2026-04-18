using MovieTicket.Domain.Entities;

namespace MovieTicket.Domain.IResponsitories.IProduct
{
    public interface IProductRepository
    {
        Task<IEnumerable<Product>> GetProductsAsync();
        Task<Product?> GetProductByIdAsync(int productId);

    }
}
