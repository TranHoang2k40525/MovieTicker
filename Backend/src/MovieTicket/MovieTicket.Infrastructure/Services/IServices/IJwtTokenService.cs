using MovieTicket.Domain.ValueObject;

namespace MovieTicket.Infrastructure.Services.IServices
{
    /// <summary>
    /// Interface cho JWT Token Service
    /// Tạo và xác thực JWT (JSON Web Token)
  
    /// JWT là một chuỗi chứa 3 phần:
    /// Header.Payload.Signature
    /// 
    /// Ví dụ thực tế:
    /// eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
    /// eyJhY2NvdW50SWQiOjEsImVtYWlsIjoiam9obkBlbWFpbC5jb20iLCJyb2xlcyI6WyJBZG1pbiJdfQ.
    /// jwtSTYHE4bR3X-3PmPnR1z_2nZM_r-V3K2Y9M9k5wE
    /// 
    /// Phần 1 (Header): Thuật toán mã hóa (HS256)
    /// Phần 2 (Payload): Dữ liệu (accountId, email, roles)
    /// Phần 3 (Signature): Chữ ký (dùng secret key để verify)
    /// </summary>
    public interface IJwtTokenService
    {
        /// <summary>
        /// Tạo Access Token
        /// 
        /// Access Token dùng để gọi API
        /// - Có hạn 15 phút
        /// - Nếu hết hạn, dùng Refresh Token để cấp lại
        /// 
        /// Chứa thông tin:
        /// - AccountId: ID tài khoản
        /// - Email: Email người dùng
        /// - Roles: Các vai trò (Admin, User, Staff...)
        /// - Permissions: Các quyền cụ thể
        /// - Exp (expiration): Thời gian hết hạn
        /// </summary>
        /// <param name="claim">JwtClaim chứa thông tin user</param>
        /// <returns>Access Token string</returns>
        string GenerateAccessToken(JwtClaim claim);

        /// <summary>
        /// Tạo Refresh Token
        /// 
        /// Refresh Token dùng để:
        /// - Cấp lại Access Token khi hết hạn
        /// - Không dùng để gọi API trực tiếp
        /// - Có hạn 7 ngày
        /// - Lưu trong database để có thể revoke
        /// </summary>
        /// <param name="accountId">ID tài khoản</param>
        /// <returns>Refresh Token string</returns>
        string GenerateRefreshToken(int accountId);

        /// <summary>
        /// Tạo Refresh Token đồng bộ và lưu vào database
        /// </summary>
        /// <param name="accountId">ID tài khoản</param>
        /// <returns>Refresh Token string</returns>
        Task<string> GenerateRefreshTokenAsync(int accountId);

        /// <summary>
        /// Xác thực Access Token
        /// Kiểm tra:
        /// 1. Signature hợp lệ (không bị sửa)
        /// 2. Chưa hết hạn
        /// 3. Dữ liệu hợp lệ
        /// </summary>
        /// <param name="token">JWT token</param>
        /// <returns>JwtClaim nếu token hợp lệ, null nếu không</returns>
        JwtClaim? ValidateToken(string token);

        /// <summary>
        /// Lấy AccountId từ token (dùng khi token hết hạn)
        /// Được gọi khi cấp lại token
        /// </summary>
        /// <param name="expiredToken">Token đã hết hạn</param>
        /// <returns>AccountId nếu token hợp lệ về signature</returns>
        int? GetAccountIdFromExpiredToken(string expiredToken);
    }
}