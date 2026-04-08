using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MovieTicket.Infrastructure.Services.IServices;

namespace MovieTicket.Infrastructure.Services.Implementations
{
    public class PasswordHashService : IPasswordHashService
    {
        /// <summary>
        /// Cost factor - số rounds để mã hóa
        /// 10 = khoảng 100ms trên CPU hiện đại
        /// 12 = khoảng 250ms (nếu muốn bảo mật cao hơn)
        /// Nếu attacker có GPU, có thể tăng lên 14-15
        /// </summary>
        private const int BcryptCostFactor = 10;

        /// <summary>
        /// Mã hóa mật khẩu
        /// 
        /// Ví dụ:
        /// Password: "MyPassword123!"
        /// Hash output: "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E36P4/saves"
        /// 
        /// Giải thích:
        /// - $2a$ = phiên bản BCrypt
        /// - $10$ = cost factor (10 rounds)
        /// - Tiếp theo = salt (22 ký tự)
        /// - Cuối cùng = hash (31 ký tự)
        /// </summary>

        public string HashPassword(string password)
        {
            // Implement a secure hashing algorithm, e.g., BCrypt
            return BCrypt.Net.BCrypt.HashPassword(password, BcryptCostFactor);
        }
        public bool VerifyPassword(string password, string hash)
        {
            // Verify the password against the hash
            try
            {
                // So sánh mật khẩu nhập với hash
                // BCrypt.Verify tự động:
                // 1. Trích salt từ hash
                // 2. Mã hóa password với salt đó
                // 3. So sánh byte-by-byte (timing-safe)
                return BCrypt.Net.BCrypt.Verify(password, hash);
            }
            catch
            {
                // Nếu hash không hợp lệ, trả về false
                return false;
            }
        }
    }
}
