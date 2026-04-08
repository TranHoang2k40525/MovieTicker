using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IAuth;
using MovieTicket.Domain.ValueObject;
using MovieTicket.Infrastructure.Services.IServices;

namespace MovieTicket.Infrastructure.Services.Implementations
{
    public class JwtTokenService : IJwtTokenService
    {
        private readonly IConfiguration _configuration;
        private readonly IRefreshTokenRepository _refreshTokenRepository;

        public JwtTokenService(IConfiguration configuration, IRefreshTokenRepository refreshTokenRepository)
        {
            _configuration = configuration;
            _refreshTokenRepository = refreshTokenRepository;
        }
        /// <summary>
        /// Lấy secret key từ appsettings.json
        /// Secret key dùng để ký và xác thực token
        /// QUAN TRỌNG: Phải giữ bí mật, không push vào git
        /// </summary>
        private string GetSecretKey()
        {
            var key = _configuration["Jwt:SecretKey"];
            if (string.IsNullOrEmpty(key))
                throw new InvalidOperationException("JWT SecretKey not configured");
            return key;
        }
        /// <summary>
        /// Lấy issuer (người phát hành token)
        /// </summary>
        private string GetIssuer()
        {
            return _configuration["Jwt:Issuer"] ?? "MovieTicketApp";
        }
        /// <summary>
        /// Lấy audience (đối tượng nhận token)
        /// </summary>
        private string GetAudience()
        {
            return _configuration["Jwt:Audience"] ?? "MovieTicketAppUsers";
        }
        /// <summary>
        /// Lấy thời gian sống của Access Token (tính bằng phút)
        /// </summary>
        private int GetAccessTokenExpirationMinutes()
        {
            return int.Parse(_configuration["Jwt:AccessTokenExpirationMinutes"] ?? "15");

        }
        /// <summary>
        /// Tạo Access Token
        /// 
        /// Quy trình:
        /// 1. Tạo SecurityKey từ secret
        /// 2. Tạo credentials để ký token
        /// 3. Tạo claims (dữ liệu chứa trong token)
        /// 4. Tạo JwtSecurityToken với claims
        /// 5. Ký token và trả về chuỗi
        /// 
        /// Ví dụ payload trong token:
        /// {
        ///   "accountId": 1,
        ///   "email": "user@example.com",
        ///   "roles": ["User"],
        ///   "permissions": ["viewMovies", "bookTickets"],
        ///   "iss": "MovieTicketApp",
        ///   "aud": "MovieTicketUsers",
        ///   "exp": 1681234567,
        ///   "iat": 1681233267
        /// }
        /// </summary>
        public string GenerateAccessToken(JwtClaim claim)
        {
            var securityKey = new SymmetricSecurityKey(
                            Encoding.UTF8.GetBytes(GetSecretKey())
                        ); 
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);
            // Tạo claims (dữ liệu chứa trong token)
            var tokenClaims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, claim.AccountId.ToString()),
                new Claim(ClaimTypes.Email, claim.Email ?? ""),

                new Claim("accountId", claim.AccountId.ToString()),

            };            
            // Thêm role vào claims
            foreach(var role in claim.Role)
            {
                tokenClaims.Add(new Claim(ClaimTypes.Role, role));
            }
            // Thêm permissions vào claims
            foreach(var permission in claim.Permissions)
            {
                tokenClaims.Add(new Claim("permission", permission));
            }
            // Tính thời gian hết hạn
            var expires = DateTime.UtcNow.AddMinutes(GetAccessTokenExpirationMinutes());
            // Tạo token
            var token = new JwtSecurityToken(
                issuer: GetIssuer(),
                audience: GetAudience(),
                claims: tokenClaims,
                expires: expires,
                signingCredentials: credentials
            );
            // Chuyển token thành chuỗi
            return new JwtSecurityTokenHandler().WriteToken(token);


        }
        /// <summary>
        /// Tạo Refresh Token
        /// 
        /// Refresh Token:
        /// - Không phải JWT (chỉ là random chuỗi)
        /// - Lưu trong database để track
        /// - Dùng để cấp lại Access Token
        /// - Có thể revoke (logout tất cả thiết bị)
        /// 
        /// Quy trình:
        /// 1. Tạo 64 bytes ngẫu nhiên
        /// 2. Convert thành base64 string
        /// 3. Lưu vào database
        /// 4. Trả về token
        /// 
        /// Lợi ích:
        /// - Nếu Access Token bị lộ, attacker chỉ dùng được 15 phút
        /// - Refresh Token có hạn 7 ngày, có thể revoke nhanh
        /// - Có thể logout tất cả thiết bị bằng cách xóa tất cả RF tokens
        /// </summary>
        public string GenerateRefreshToken(int accountId)
        {
            var randomNumber = new byte[64];
            using(var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(randomNumber);
            }
            return Convert.ToBase64String(randomNumber);

        }
        /// <summary>
        /// Xác thực Access Token
        /// 
        /// Kiểm tra:
        /// 1. Signature hợp lệ (validate chữ ký)
        /// 2. Chưa hết hạn (exp claim)
        /// 3. Issuer/Audience đúng
        /// 
        /// Trả về JwtClaim nếu hợp lệ, null nếu không
        /// </summary>
        public JwtClaim? ValidateToken(string token)
        {
            try
            {
                var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(GetSecretKey()));
                var tokenHandler = new JwtSecurityTokenHandler();
                var principal = tokenHandler.ValidateToken(token, new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = securityKey,
                    ValidateIssuer = true,
                    ValidIssuer = GetIssuer(),
                    ValidateAudience = true,
                    ValidAudience = GetAudience(),
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero // Không cho thêm buffer thời gian
                }, out SecurityToken validatedToken);
                var jwtToken = (JwtSecurityToken)validatedToken;
                var accountIdClaim = principal.FindFirst("accountId")?.Value ?? "0";
                var emailClaim = principal.FindFirst(ClaimTypes.Email)?.Value;
                if (!int.TryParse(accountIdClaim, out int accountId) ||
                    string.IsNullOrEmpty(emailClaim))
                    return null;
                var roles = principal.FindAll(ClaimTypes.Role).Select(c => c.Value).ToList();
                var permissions = principal.FindAll("permission").Select(c => c.Value).ToList();
                return new JwtClaim
                {
                    AccountId = accountId,
                    Email = emailClaim,
                    Role = roles,
                    Permissions = permissions,
                    ExpiresAt = jwtToken.ValidTo
                };

            }
            catch
            {
                // Token không hợp lệ (hết hạn, signature sai, format sai...)

                return null;
            }
        }
        /// <summary>
        /// Lấy AccountId từ token đã hết hạn
        /// 
        /// Dùng trong flow refresh token:
        /// 1. Client gửi token hết hạn + refresh token
        /// 2. Server gọi GetAccountIdFromExpiredToken
        /// 3. Lấy được accountId từ token cũ
        /// 4. Xác minh refresh token trong database
        /// 5. Cấp lại access token mới
        /// 
        /// Tại sao không dùng ValidateToken?
        /// - ValidateToken reject token hết hạn
        /// - Method này bỏ qua kiểm tra lifetime
        /// - Vẫn kiểm tra signature (token không bị sửa)
        /// </summary>
        public int? GetAccountIdFromExpiredToken(string expiredToken)
        {
            try
            {
                var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(GetSecretKey()));
                var tokenHandler = new JwtSecurityTokenHandler();
                var principal = tokenHandler.ValidateToken(expiredToken, new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = securityKey,
                    ValidateIssuer = true,
                    ValidIssuer = GetIssuer(),
                    ValidateAudience = true,
                    ValidAudience = GetAudience(),
                    ValidateLifetime = false // Bỏ qua kiểm tra hết hạn
                }, out SecurityToken validatedToken);
                var accountIdClaim = principal.FindFirst("accountId")?.Value;
                if (int.TryParse(accountIdClaim, out int accountId))
                    return accountId;

                return null;

            }
            catch
            {
                return null;
            }
        }

        /// <summary>
        /// Tạo Refresh Token đồng bộ và lưu vào database
        /// </summary>
        public async Task<string> GenerateRefreshTokenAsync(int accountId)
        {
            var tokenString = GenerateRefreshToken(accountId);
            
            var refreshToken = new RefreshToken
            {
                AccountId = accountId,
                RefreshToken1 = tokenString,
                ExpiresAt = DateTime.UtcNow.AddDays(7),
                CreatedAt = DateTime.UtcNow
            };

            await _refreshTokenRepository.CreateAsync(refreshToken);
            return tokenString;
        }
    }
}
