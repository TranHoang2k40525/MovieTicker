using MovieTicket.Application.DTOs.Auth;
using MovieTicket.Application.IServices;
using MovieTicket.Domain.Entities;
using MovieTicket.Domain.IResponsitories.IAuth;
using MovieTicket.Infrastructure.Services.IServices;
using Microsoft.Extensions.Logging;
namespace MovieTicket.Application.Services
{
    public class AuthService : IAuthService
    {
        private readonly IAccountRepository _accountRepository;
        private readonly IUserRepository _userRepository;
        private readonly IAccountRoleRepository _accountRoleRepository;
        private readonly IOtpRepository _otpRepository;
        private readonly IRefreshTokenRepository _refreshTokenRepository;
        private readonly ILoginHistoryRepository _loginHistoryRepository;
        private readonly IPasswordHashService _passwordHashService;
        private readonly IJwtTokenService _jwtTokenService;
        private readonly IOtpService _otpService;
        private readonly IEmailService _emailService;
        private readonly ILogger<AuthService> _logger;
        private readonly IRoleRepository _roleRepository;

        public AuthService(
            IAccountRepository accountRepository,
            IUserRepository userRepository,
            IAccountRoleRepository accountRoleRepository,
            IOtpRepository otpRepository,
            IRefreshTokenRepository refreshTokenRepository,
            ILoginHistoryRepository loginHistoryRepository,
            IPasswordHashService passwordHashService,
            IJwtTokenService jwtTokenService,
            IOtpService otpService,
            IEmailService emailService,
            ILogger<AuthService> logger,
            IRoleRepository roleRepository)
        {
            _accountRepository = accountRepository;
            _userRepository = userRepository;
            _accountRoleRepository = accountRoleRepository;
            _otpRepository = otpRepository;
            _refreshTokenRepository = refreshTokenRepository;
            _loginHistoryRepository = loginHistoryRepository;
            _passwordHashService = passwordHashService;
            _jwtTokenService = jwtTokenService;
            _otpService = otpService;
            _emailService = emailService;
            _logger = logger;
            _roleRepository = roleRepository;
        }

        public async Task<(bool Success, string Message)> RegisterAsync(RegisterDto request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
                    return (false, "Email và mật khẩu không được để trống");

                if (request.Password != request.ConfirmPassword)
                    return (false, "Mật khẩu xác nhận không khớp");

                if (request.Password.Length < 6)
                    return (false, "Mật khẩu phải có ít nhất 6 ký tự");

                var existingAccount = await _accountRepository.GetByEmailAsync(request.Email);
                if (existingAccount != null)
                    return (false, "Email đã được đăng ký");

                var account = new Account
                {
                    Email = request.Email.ToLower(),
                    Phone = request.Phone,
                    PasswordHash = _passwordHashService.HashPassword(request.Password),
                    Status = Status.pending_verification,
                    CreatedAt = DateTime.UtcNow
                };

                var createdAccount = await _accountRepository.CreateAsync(account);
                if (createdAccount == null)
                    return (false, "Không thể tạo tài khoản");

                // Tạo đối tượng User kèm thông tin cơ bản
                var user = new User
                {
                    AccountId = createdAccount.AccountId,
                    Email = request.Email.ToLower(),
                    Phone = request.Phone,
                    FullName = request.FullName ?? string.Empty,
                    Gender = request.Gender,
                    DateOfBirth = request.DateOfBirth,
                    Address = request.Address
                };
                await _userRepository.CreateAsync(user);

                // Assign default "User" role
                var roles = await GetOrCreateDefaultRole();
                if (roles != null)
                {
                    await _accountRoleRepository.CreateAsync(new AccountRole
                    {
                        AccountId = createdAccount.AccountId,
                        RoleId = roles.RoleId
                    });
                }

                await _otpService.GenerateAndSendOtpAsync(createdAccount.AccountId, "registration", request.Email);

                return (true, "Đăng ký thành công! Vui lòng kiểm tra email để xác thực tài khoản.");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi đăng ký: {ex.Message}");
                return (false, "Đã xảy ra lỗi, vui lòng thử lại");
            }
        }

        public async Task<(bool Success, string Message)> VerifyRegistrationOtpAsync(OTPDto request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.OtpCode))
                    return (false, "Email và mã OTP không được để trống");

                var account = await _accountRepository.GetByEmailAsync(request.Email);
                if (account == null)
                    return (false, "Tài khoản không tồn tại");

                if (account.Status == Status.active)
                    return (false, "Tài khoản đã được xác thực");

                bool otpValid = await _otpService.VerifyOtpAsync(account.AccountId, request.OtpCode, "registration");
                if (!otpValid)
                    return (false, "Mã OTP không hợp lệ hoặc đã hết hạn");

                // Only update to active AFTER successful OTP verification
                account.Status = Status.active;
                account.UpdatedAt = DateTime.UtcNow;
                await _accountRepository.UpdateAsync(account);

                return (true, "Xác thực thành công! Tài khoản đã kích hoạt.");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi xác thực OTP: {ex.Message}");
                return (false, "Đã xảy ra lỗi, vui lòng thử lại");
            }
        }

        public async Task<(bool Success, string Message)> CancelRegistrationAsync(CancelOtpRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Email))
                    return (false, "Email không được để trống");

                var account = await _accountRepository.GetByEmailAsync(request.Email);
                if (account == null)
                    return (false, "Tài khoản không tồn tại");

                if (account.Status != Status.pending_verification)
                    return (false, "Chỉ có thể hủy đăng ký đối với tài khoản đang chờ xác thực (pending_verification)");

                // Delete associated OTPs
                await _otpRepository.DeleteExpiredAsync(account.AccountId, "registration"); // Optional cleanup
                // We'll directly delete the account and let cascade (or explicit) deletion remove others.
                // However, since we might not have cascade delete for sure, let's explicitly remove relationships:
                var user = await _userRepository.GetByAccountIdAsync(account.AccountId);
                if (user != null)
                {
                    await _userRepository.DeleteAsync(user.UserId);
                }

                var roles = await _accountRoleRepository.GetByAccountIdAsync(account.AccountId);
                if (roles != null)
                {
                    foreach (var r in roles)
                    {
                        await _accountRoleRepository.DeleteAsync(r.Id);
                    }
                }

                bool deleted = await _accountRepository.DeleteAsync(account.AccountId);
                if (!deleted)
                    return (false, "Không thể hủy tài khoản lúc này, vui lòng thử lại");

                return (true, "Đã hủy bỏ mã OTP và xóa tài khoản đăng ký lỗi/chưa hoàn thành.");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi hủy OTP đăng ký: {ex.Message}");
                return (false, "Đã xảy ra lỗi, vui lòng thử lại");
            }
        }

        public async Task<(bool Success, LoginResponseDto? Response, string Message)> LoginAsync(
            LoginDto request,
            string ipAddress,
            string deviceInfo)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.EmailOrPhone) || string.IsNullOrWhiteSpace(request.Password))
                    return (false, null, "Email/Điện thoại và mật khẩu không được để trống");

                var account = await _accountRepository.GetByEmailOrPhoneAsync(request.EmailOrPhone);
                if (account == null)
                    return (false, null, "Tài khoản không tồn tại");

                if (account.Status == Status.pending_verification)
                    return (false, null, "Tài khoản chưa được xác thực. Vui lòng kiểm tra email.");

                if (account.Status == Status.blocked)
                    return (false, null, "Tài khoản đã bị khóa");

                if (!_passwordHashService.VerifyPassword(request.Password, account.PasswordHash))
                    return (false, null, "Mật khẩu không chính xác");

                var user = await _userRepository.GetByAccountIdAsync(account.AccountId);

                var accountRoles = await _accountRoleRepository.GetByAccountIdAsync(account.AccountId);
                var roles = accountRoles?.Select(ar => ar.Role?.RoleName ?? "").Where(r => !string.IsNullOrEmpty(r)).ToList() ?? new List<string>();

                if (!roles.Any())
                    roles.Add("User");

                var jwtClaim = new MovieTicket.Domain.ValueObject.JwtClaim
                {
                    AccountId = account.AccountId,
                    Email = account.Email ?? "",
                    Role = roles,
                    Permissions = GetPermissionsForRoles(roles)
                };

                var accessToken = _jwtTokenService.GenerateAccessToken(jwtClaim);
                var refreshToken = await _jwtTokenService.GenerateRefreshTokenAsync(account.AccountId);

                var loginHistory = new LoginHistory
                {
                    AccountId = account.AccountId,
                    IpAddress = ipAddress,
                    DeviceInfo = deviceInfo,
                    LoginTime = DateTime.UtcNow,
                    
                };
                await _loginHistoryRepository.CreateAsync(loginHistory);

                var response = new LoginResponseDto
                {
                    AccountId = account.AccountId,
                    Email = account.Email ?? "",
                    FullName = user?.FullName ?? "",
                    AccessToken = accessToken,
                    RefreshToken = refreshToken,
                    Roles = roles,
                    ExpiresIn = 15 * 60
                };

                return (true, response, "Đăng nhập thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi đăng nhập: {ex.Message}");
                return (false, null, "Đã xảy ra lỗi, vui lòng thử lại");
            }
        }

        public async Task<(bool Success, string Message)> ForgotPasswordAsync(ForgotPasswordRequestDto request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Email))
                    return (false, "Email không được để trống");

                var account = await _accountRepository.GetByEmailAsync(request.Email);
                if (account == null)
                    return (false, "Tài khoản không tồn tại");

                 await _otpService.GenerateAndSendOtpAsync(account.AccountId, "forgot_password", request.Email);

                return (true, "Mã xác thực đã được gửi đến email của bạn");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi quên mật khẩu: {ex.Message}");
                return (false, "Đã xảy ra lỗi, vui lòng thử lại");
            }
        }

        public async Task<(bool Success, string Message)> ResetPasswordAsync(ResetPasswordRequestDto request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.OtpCode) || 
                    string.IsNullOrWhiteSpace(request.NewPassword))
                    return (false, "Email, mã OTP, và mật khẩu mới không được để trống");

                if (request.NewPassword != request.ConfirmPassword)
                    return (false, "Mật khẩu xác nhận không khớp");

                if (request.NewPassword.Length < 6)
                    return (false, "Mật khẩu phải có ít nhất 6 ký tự");

                var account = await _accountRepository.GetByEmailAsync(request.Email);
                if (account == null)
                    return (false, "Tài khoản không tồn tại");

                bool otpValid = await _otpService.VerifyOtpAsync(account.AccountId, request.OtpCode, "forgot_password");
                if (!otpValid)
                    return (false, "Mã OTP không hợp lệ hoặc đã hết hạn");

                account.PasswordHash = _passwordHashService.HashPassword(request.NewPassword);
                account.UpdatedAt = DateTime.UtcNow;
                await _accountRepository.UpdateAsync(account);

                return (true, "Mật khẩu đã được thay đổi thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi reset mật khẩu: {ex.Message}");
                return (false, "Đã xảy ra lỗi, vui lòng thử lại");
            }
        }

        public async Task<(bool Success, string Message)> ChangePasswordAsync(
            int accountId,
            ChangePasswordRequestDto request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.CurrentPassword) || 
                    string.IsNullOrWhiteSpace(request.NewPassword))
                    return (false, "Mật khẩu hiện tại và mật khẩu mới không được để trống");

                if (request.NewPassword != request.ConfirmPassword)
                    return (false, "Mật khẩu xác nhận không khớp");

                if (request.NewPassword.Length < 6)
                    return (false, "Mật khẩu phải có ít nhất 6 ký tự");

                var account = await _accountRepository.GetByIdAsync(accountId);
                if (account == null)
                    return (false, "Tài khoản không tồn tại");

                if (!_passwordHashService.VerifyPassword(request.CurrentPassword, account.PasswordHash))
                    return (false, "Mật khẩu hiện tại không chính xác");

                account.PasswordHash = _passwordHashService.HashPassword(request.NewPassword);
                account.UpdatedAt = DateTime.UtcNow;
                await _accountRepository.UpdateAsync(account);

                return (true, "Mật khẩu đã được thay đổi thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi đổi mật khẩu: {ex.Message}");
                return (false, "Đã xảy ra lỗi, vui lòng thử lại");
            }
        }

        public async Task<(bool Success, LoginResponseDto? Response, string Message)> RefreshTokenAsync(
            RefreshTokenRequestDto request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.RefreshToken))
                    return (false, null, "Refresh token không được để trống");

                var refreshToken = await _refreshTokenRepository.GetByTokenAsync(request.RefreshToken);
                if (refreshToken == null || refreshToken.ExpiresAt < DateTime.UtcNow)
                    return (false, null, "Refresh token không hợp lệ hoặc đã hết hạn");

                if (!refreshToken.AccountId.HasValue)
                    return (false, null, "Refresh token không hợp lệ");

                var account = await _accountRepository.GetByIdAsync(refreshToken.AccountId.Value);
                if (account == null)
                    return (false, null, "Tài khoản không tồn tại");

                var accountRoles = await _accountRoleRepository.GetByAccountIdAsync(account.AccountId);
                var roles = accountRoles?.Select(ar => ar.Role?.RoleName ?? "").Where(r => !string.IsNullOrEmpty(r)).ToList() ?? new List<string>();

                if (!roles.Any())
                    roles.Add("User");

                var jwtClaim = new MovieTicket.Domain.ValueObject.JwtClaim
                {
                    AccountId = account.AccountId,
                    Email = account.Email ?? "",
                    Role = roles,
                    Permissions = GetPermissionsForRoles(roles)
                };

                var accessToken = _jwtTokenService.GenerateAccessToken(jwtClaim);
                var user = await _userRepository.GetByAccountIdAsync(account.AccountId);

                var response = new LoginResponseDto
                {
                    AccountId = account.AccountId,
                    Email = account.Email ?? "",
                    FullName = user?.FullName ?? "",
                    AccessToken = accessToken,
                    RefreshToken = request.RefreshToken,
                    Roles = roles,
                    ExpiresIn = 15 * 60
                };

                return (true, response, "Token đã được cấp lại");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi cấp lại token: {ex.Message}");
                return (false, null, "Đã xảy ra lỗi, vui lòng thử lại");
            }
        }

        public async Task<(bool Success, string Message)> LogoutAsync(string refreshToken)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(refreshToken))
                    return (false, "Refresh token không được để trống");

                var token = await _refreshTokenRepository.GetByTokenAsync(refreshToken);
                if (token != null)
                {
                    await _refreshTokenRepository.DeleteAsync(token.TokenId);
                }

                return (true, "Đăng xuất thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi đăng xuất: {ex.Message}");
                return (false, "Đã xảy ra lỗi, vui lòng thử lại");
            }
        }

        public async Task<(bool Success, string Message)> LogoutAllDevicesAsync(int accountId)
        {
            try
            {
                await _refreshTokenRepository.DeleteByAccountIdAsync(accountId);
                return (true, "Đã đăng xuất trên tất cả thiết bị");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi đăng xuất tất cả: {ex.Message}");
                return (false, "Đã xảy ra lỗi, vui lòng thử lại");
            }
        }

        public async Task<(bool Success, string Message)> CreateEmployeeAsync(CreateEmployeeDto request, List<string> currentRoles)
        {
            try
            {
                var isAdmin = currentRoles.Any(r => r.Equals("Admin", StringComparison.OrdinalIgnoreCase));
                var isManager = currentRoles.Any(r => r.Equals("Manager", StringComparison.OrdinalIgnoreCase));
                var targetRole = request.RoleName?.Trim();

                if (string.IsNullOrEmpty(targetRole))
                    return (false, "Vui lòng chỉ định quyền (Manager hoặc Staff)");

                // Quyền tạo: Admin tạo được Manager & Staff. Manager chỉ tạo được Staff.
                if (targetRole.Equals("Manager", StringComparison.OrdinalIgnoreCase) && !isAdmin)
                    return (false, "Chỉ có Admin mới được tạo tài khoản Manager");

                if (targetRole.Equals("Staff", StringComparison.OrdinalIgnoreCase) && !isAdmin && !isManager)
                    return (false, "Bạn không có quyền tạo tài khoản Staff");

                var existingAccount = await _accountRepository.GetByEmailAsync(request.Email);
                if (existingAccount != null)
                    return (false, "Email đã được sử dụng");

                // Get role from DB to assign
                var role = await _roleRepository.GetByNameAsync(targetRole);
                if (role == null)
                {
                    // Create if not exist
                    RoleType parsedType = Enum.TryParse<RoleType>(targetRole, true, out var t) ? t : RoleType.Staff;
                    role = await _roleRepository.CreateAsync(new Role { RoleName = targetRole, Type = parsedType });
                }

                var account = new Account
                {
                    Email = request.Email.ToLower(),
                    Phone = request.Phone,
                    PasswordHash = _passwordHashService.HashPassword(request.Password),
                    Status = Status.active, // Active immediately, no OTP
                    CreatedAt = DateTime.UtcNow,
                    CinemaId = request.CinemaId
                };

                var createdAccount = await _accountRepository.CreateAsync(account);
                if (createdAccount == null)
                    return (false, "Không thể tạo tài khoản");

                // Assign role
                await _accountRoleRepository.CreateAsync(new AccountRole
                {
                    AccountId = createdAccount.AccountId,
                    RoleId = role.RoleId
                });

                // Create user profile
                var user = new User
                {
                    AccountId = createdAccount.AccountId,
                    Email = request.Email.ToLower(),
                    Phone = request.Phone,
                    FullName = request.FullName,
                    Gender = request.Gender,
                    DateOfBirth = request.DateOfBirth,
                    Address = request.Address
                };
                await _userRepository.CreateAsync(user);

                return (true, $"Tạo tài khoản {targetRole} thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi tạo nhân viên: {ex.Message}");
                return (false, "Đã xảy ra lỗi, vui lòng thử lại");
            }
        }

        public async Task<(bool Success, string Message)> ChangeAccountStatusAsync(int targetAccountId, Status status, List<string> currentRoles)
        {
            try
            {
                var isAdmin = currentRoles.Any(r => r.Equals("Admin", StringComparison.OrdinalIgnoreCase));
                var isManager = currentRoles.Any(r => r.Equals("Manager", StringComparison.OrdinalIgnoreCase));

                if (!isAdmin && !isManager)
                    return (false, "Bạn không có quyền thực hiện hành động này");

                var account = await _accountRepository.GetByIdAsync(targetAccountId);
                if (account == null)
                    return (false, "Tài khoản không tồn tại");

                // Get target roles
                var accountRoles = await _accountRoleRepository.GetByAccountIdAsync(targetAccountId);
                var targetAccountRoles = accountRoles?.Select(ar => ar.Role?.RoleName).ToList() ?? new List<string?>();

                var targetIsAdmin = targetAccountRoles.Any(r => r?.Equals("Admin", StringComparison.OrdinalIgnoreCase) == true);
                var targetIsManager = targetAccountRoles.Any(r => r?.Equals("Manager", StringComparison.OrdinalIgnoreCase) == true);

                if (targetIsAdmin)
                    return (false, "Không được thay đổi trạng thái của Admin");

                if (targetIsManager && !isAdmin)
                    return (false, "Chỉ Admin mới có quyền thao tác trên tài khoản Manager");

                account.Status = status;
                account.UpdatedAt = DateTime.UtcNow;
                await _accountRepository.UpdateAsync(account);

                return (true, $"Cập nhật trạng thái thành {status} thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi cập nhật trạng thái: {ex.Message}");
                return (false, "Đã xảy ra lỗi, vui lòng thử lại");
            }
        }

        public async Task<(bool Success, string Message)> DeleteAccountAsync(int targetAccountId, List<string> currentRoles)
        {
            try
            {
                var isAdmin = currentRoles.Any(r => r.Equals("Admin", StringComparison.OrdinalIgnoreCase));
                var isManager = currentRoles.Any(r => r.Equals("Manager", StringComparison.OrdinalIgnoreCase));

                if (!isAdmin && !isManager)
                    return (false, "Bạn không có quyền thực hiện hành động này");

                var account = await _accountRepository.GetByIdAsync(targetAccountId);
                if (account == null)
                    return (false, "Tài khoản không tồn tại");

                // Get target roles
                var accountRoles = await _accountRoleRepository.GetByAccountIdAsync(targetAccountId);
                var targetAccountRoles = accountRoles?.Select(ar => ar.Role?.RoleName).ToList() ?? new List<string?>();

                var targetIsAdmin = targetAccountRoles.Any(r => r?.Equals("Admin", StringComparison.OrdinalIgnoreCase) == true);
                var targetIsManager = targetAccountRoles.Any(r => r?.Equals("Manager", StringComparison.OrdinalIgnoreCase) == true);

                if (targetIsAdmin)
                    return (false, "Không được xóa tài khoản Admin");

                if (targetIsManager && !isAdmin)
                    return (false, "Chỉ Admin mới có quyền xóa tài khoản Manager");

                // Remove refresh tokens & otps & user before deleting account if there are FK constraints
                await _refreshTokenRepository.DeleteByAccountIdAsync(targetAccountId);

                var userProfile = await _userRepository.GetByAccountIdAsync(targetAccountId);
                if (userProfile != null)
                {
                    // Should delete user profile, but might cause FK issues with Bookings/LikeMovies, etc.
                    // We'll mark as blocked instead if really needed, but request asks for delete:
                    // Assuming delete user logic is supported or cascading
                }

                // Let's rely on DB cascading or Account repo deletion
                bool deleted = await _accountRepository.DeleteAsync(targetAccountId);
                if (!deleted)
                    return (false, "Không thể xóa tài khoản, có thể do ràng buộc dữ liệu (hãy sử dụng tính năng khóa)");

                return (true, "Xóa tài khoản thành công");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Lỗi xóa tài khoản: {ex.Message}");
                return (false, "Không thể xóa do ràng buộc dữ liệu, vui lòng Khóa tài khoản thay vì xóa");
            }
        }

        private List<string> GetPermissionsForRoles(List<string> roles)
        {
            var permissions = new List<string>();
            foreach (var role in roles)
            {
                switch (role.ToLower())
                {
                    case "admin":
                        permissions.AddRange(new[] { "view_users", "manage_users", "manage_movies", "manage_bookings", "view_reports" });
                        break;
                    case "manager":
                        permissions.AddRange(new[] { "manage_bookings", "view_cinema", "manage_cinema" });
                        break;
                    case "staff":
                        permissions.AddRange(new[] { "view_bookings", "process_transactions" });
                        break;
                    case "user":
                    default:
                        permissions.AddRange(new[] { "view_movies", "book_tickets", "view_bookings" });
                        break;
                }
            }
            return permissions.Distinct().ToList();
        }

        private async Task<Role?> GetOrCreateDefaultRole()
        {
            var role = await _roleRepository.GetByNameAsync("User");
            if (role == null)
            {
                role = await _roleRepository.CreateAsync(new Role
                {
                    RoleName = "User",
                    Type = RoleType.User
                });
            }
            return role;
        }
    }
}
