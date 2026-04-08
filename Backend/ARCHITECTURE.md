# 🏗️ ARCHITECTURE - HƯỚNG DẪN CẤU TRÚC CODE

## 📐 LAYERED ARCHITECTURE

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │  ← Controllers, API endpoints
│  MovieTicket.Presentation (Asp.Net Web) │
└──────────────┬──────────────────────────┘
               │
               ↓ (depends on)
┌──────────────────────────────────────┐
│      Application Layer                │  ← DTOs, Interfaces (contracts)
│  MovieTicket.Application (Class Lib)  │
└──────────────┬───────────────────────┘
               │
               ↓ (depends on)
┌──────────────────────────────────────┐
│      Infrastructure Layer             │  ← Repositories, Services, DbContext
│  MovieTicket.Infrastructure (Class)   │
└──────────────┬───────────────────────┘
               │
               ↓ (depends on)
┌──────────────────────────────────────┐
│         Domain Layer                  │  ← Entities, ValueObjects
│  MovieTicket.Domain (Class Library)   │
└──────────────────────────────────────┘
```

### ✅ Quy tắc Dependency:
- Presentation → Application → Infrastructure → Domain
- Domain **không** phụ thuộc cái gì
- Presentation **không** gọi trực tiếp Infrastructure

---

## 📂 CHI TIẾT TỪNG LAYER

### 1️⃣ DOMAIN LAYER - "Quy tắc kinh doanh"

**Folder**: `MovieTicket.Domain/`

#### Entities - Đại diện dữ liệu database
```
Entities/
├── Account.cs          ← Tài khoản (email, phone, password_hash)
├── User.cs             ← Thông tin cá nhân (tên, avatar, địa chỉ)
├── Role.cs             ← Vai trò (Admin, User, Staff, Manager)
├── Permission.cs       ← Quyền cụ thể (view_movies, book_tickets)
├── AccountRole.cs      ← Liên kết Account <-> Role (N-N)
├── RolePermission.cs   ← Liên kết Role <-> Permission (N-N)
├── Otp.cs              ← Mã OTP (hash, hạn, status)
├── RefreshToken.cs     ← Refresh token (hash, hạn)
├── LoginHistory.cs     ← Lịch sử đăng nhập (IP, device)
└── ... (các entity khác)
```

**Lưu ý**:
- Không call database trực tiếp
- Chỉ chứa properties + navigation properties
- Status là enum: `active`, `blocked`

#### ValueObjects - Các object không có identity
```
ValueObjects/
└── JwtClaim.cs         ← Data trong JWT token
                           (AccountId, Email, Roles, Permissions)
```

**Tại sao ValueObject**:
- Không có database identity
- Chỉ quan tâm giá trị
- Immutable (không đổi sau tạo)

---

### 2️⃣ APPLICATION LAYER - "Hợp đồng & DTO"

**Folder**: `MovieTicket.Application/`

#### DTOs - Transfer Objects (Request/Response)
```
DTOs/Auth/
├── RegisterRequest.cs       ← Input: email, phone, password, etc
├── VerifyOtpRequest.cs      ← Input: email, otp_code
├── LoginRequest.cs          ← Input: email_or_phone, password
├── LoginResponse.cs         ← Output: access_token, refresh_token, roles
├── ForgotPasswordRequest.cs ← Input: email
├── ResetPasswordRequest.cs  ← Input: email, otp_code, new_password
├── ChangePasswordRequest.cs ← Input: current_password, new_password
└── RefreshTokenRequest.cs   ← Input: refresh_token
```

**Tại sao dùng DTO**:
- ✅ Không expose Entity trực tiếp
- ✅ Validate input
- ✅ Ẩn các field nhạy cảm
- ✅ Có thể map khác nhau cho API khác nhau

**Example - LoginResponse vs Entity**:
```csharp
// ❌ KHÔNG BAO GIỜ trả Entity trực tiếp
{
  "account_id": 1,
  "password_hash": "$2a$10$...",      ← ⚠️ CÔNG KHAI HÀM
  "status": "active",
  "created_at": "2026-04-08",
  ...
}

// ✅ ĐÚNG - trả DTO
{
  "accountId": 1,
  "email": "user@example.com",
  "accessToken": "eyJhbGc...",
  "roles": ["User"]
}
```

#### Interfaces - "Hợp đồng"
```
IServices/
├── IRepositories.cs     ← Định nghĩa các repository
│   ├── IAccountRepository
│   ├── IOtpRepository
│   ├── IRefreshTokenRepository
│   ├── ILoginHistoryRepository
│   ├── IUserRepository
│   └── IAccountRoleRepository
│
└── IAuthService.cs      ← Định nghĩa auth service
    └── Methods: Register, VerifyOtp, Login, etc
```

**Tại sao Interface**:
- ✅ Dependency Injection
- ✅ Dễ test (mock)
- ✅ Decouple layers
- ✅ Thay đổi implementation sau

---

### 3️⃣ INFRASTRUCTURE LAYER - "Implementation"

**Folder**: `MovieTicket.Infrastructure/`

#### Repositories - CRUD database
```
Repositories/AllRepositories.cs
├── AccountRepository           ← CRUD Account
│   - GetByIdAsync()
│   - GetByEmailAsync()
│   - GetByPhoneAsync()
│   - GetByEmailOrPhoneAsync()
│   - CreateAsync()
│   - UpdateAsync()
│   - EmailExistsAsync()
│   - PhoneExistsAsync()
│   - GetRolesAsync()
│   - GetPermissionsAsync()
│
├── OtpRepository               ← CRUD OTP
│   - CreateAsync()
│   - GetLatestValidAsync()
│   - UpdateAsync()
│   - IsValidAsync()
│
├── RefreshTokenRepository      ← CRUD RefreshToken
│   - CreateAsync()
│   - GetByTokenAsync()
│   - IsValidAsync()
│   - DeleteAsync()
│   - DeleteAllByAccountAsync()
│
├── LoginHistoryRepository      ← Ghi lịch sử
│   - CreateAsync()
│   - GetByAccountAsync()
│
├── UserRepository              ← CRUD User
│   - GetByAccountIdAsync()
│   - CreateAsync()
│   - UpdateAsync()
│
└── AccountRoleRepository       ← Liên kết Account-Role
    - CreateAsync()
    - GetByAccountIdAsync()
    - DeleteAsync()
    - HasRoleAsync()
```

**Query Example - GetByEmailAsync**:
```csharp
public async Task<Account?> GetByEmailAsync(string email)
{
    return await _context.Accounts
        // Eager load User để lấy thông tin cá nhân
        .Include(a => a.Users)
        // Eager load Roles để biết user là gì
        .Include(a => a.AccountRoles)
            .ThenInclude(ar => ar.Role)
        // Tìm theo email
        .FirstOrDefaultAsync(a => a.Email == email);
}
```

**Giải thích Include**:
- `Include()` = INNER JOIN (eager load)
- `ThenInclude()` = nested relationship
- Tránh N+1 queries (lặp lại query)

#### Services - Business Logic
```
Services/Interfaces/IServices.cs
├── IPasswordHashService        ← Hash password (BCrypt)
├── IJwtTokenService           ← Tạo/verify JWT token
├── IOtpService                ← Tạo/verify OTP + gửi email
└── IEmailService              ← Gửi email (Gmail SMTP)

Services/Implementations/
├── PasswordHashService.cs      ← BCrypt implementation
│   - HashPassword()           → $2a$10$...
│   - VerifyPassword()         → true/false
│
├── JwtTokenService.cs          ← JWT implementation
│   - GenerateAccessToken()    → JWT token (15m)
│   - GenerateRefreshToken()   → random base64 (7d)
│   - ValidateToken()          → JwtClaim or null
│
├── OtpService.cs               ← OTP implementation
│   - GenerateAndSendOtpAsync() → tạo + gửi email
│   - VerifyOtpAsync()          → verify + mark used
│   - IsOtpValidAsync()         → check còn hợp lệ
│
├── EmailService.cs             ← Gmail SMTP
│   - SendEmailAsync()
│   - SendEmailToMultipleAsync()
│
└── AuthService.cs              ← Tất cả logic auth
    - RegisterAsync()           ← register + phát OTP
    - VerifyRegistrationOtpAsync()
    - LoginAsync()              ← verify + phát tokens
    - ForgotPasswordAsync()
    - ResetPasswordAsync()
    - ChangePasswordAsync()
    - RefreshTokenAsync()
    - LogoutAsync()
    - LogoutAllDevicesAsync()
```

#### DbContext - Connection to Database
```
AppDbContext/AppMovieTickerDbContext.cs
├── DbSet<Account> Accounts
├── DbSet<User> Users
├── DbSet<Role> Roles
├── DbSet<Otp> Otps
├── DbSet<RefreshToken> RefreshTokens
├── DbSet<LoginHistory> LoginHistories
├── ... (DbSets khác)
└── OnModelCreating()           ← Configurations
    ├── modelBuilder.ApplyConfiguration<AccountConfiguration>
    ├── modelBuilder.ApplyConfiguration<UserConfiguration>
    └── ... configuration khác
```

---

### 4️⃣ PRESENTATION LAYER - "API & Endpoints"

**Folder**: `MovieTicket.Presentation/`

#### Controllers - HTTP Endpoints
```
Controllers/AuthController.cs
├── [HttpPost("register")]
│   Register(RegisterRequest)       ← POST /api/auth/register
│
├── [HttpPost("verify-otp")]
│   VerifyOtp(VerifyOtpRequest)     ← POST /api/auth/verify-otp
│
├── [HttpPost("login")]
│   Login(LoginRequest)             ← POST /api/auth/login
│
├── [HttpPost("forgot-password")]
│   ForgotPassword(...)             ← POST /api/auth/forgot-password
│
├── [HttpPost("reset-password")]
│   ResetPassword(...)              ← POST /api/auth/reset-password
│
├── [Authorize]
│   [HttpPost("change-password")]
│   ChangePassword(...)             ← POST /api/auth/change-password (cần token)
│
├── [HttpPost("refresh-token")]
│   RefreshToken(...)               ← POST /api/auth/refresh-token
│
├── [HttpPost("logout")]
│   Logout(...)                     ← POST /api/auth/logout
│
└── [Authorize]
    [HttpPost("logout-all")]
    LogoutAllDevices()              ← POST /api/auth/logout-all (cần token)
```

#### Program.cs - Dependency Injection & Middleware Setup
```csharp
// 1️⃣ Repositories DI
builder.Services.AddScoped<IAccountRepository, AccountRepository>();
builder.Services.AddScoped<IOtpRepository, OtpRepository>();
// ... các repository khác

// 2️⃣ Services DI
builder.Services.AddScoped<IPasswordHashService, PasswordHashService>();
builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
builder.Services.AddScoped<IOtpService, OtpService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<IAuthService, AuthService>();

// 3️⃣ DbContext
builder.Services.AddDbContext<AppMovieTickerDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"))
);

// 4️⃣ JWT Authentication
var key = Encoding.ASCII.GetBytes(jwtSecretKey);
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ValidateIssuer = true,
            ValidIssuer = issuer,
            ValidateAudience = true,
            ValidAudience = audience,
            ValidateLifetime = true
        };
    });

// 5️⃣ CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
    {
        builder.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
    });
});

// 6️⃣ Swagger
builder.Services.AddSwaggerGen(/* config */);

// 7️⃣ Middleware order (QUAN TRỌNG!)
app.UseAuthentication();    // ← Trước UseAuthorization
app.UseAuthorization();     // ← Sau UseAuthentication
app.UseCors("AllowAll");    // ← Trước MapControllers
app.MapControllers();       // ← Cuối cùng
```

---

## 🔄 DATA FLOW - EXAMPLE LOGIN

```
1. Browser: POST /api/auth/login
   {
     "emailOrPhone": "user@example.com",
     "password": "MyPass123@"
   }

                 ↓

2. Presentation Layer (AuthController)
   ├─ Validate ModelState
   ├─ Get IP Address from HttpContext
   ├─ Call _authService.LoginAsync()

                 ↓

3. Application Layer (IAuthService)
   ├─ Call repository để lấy Account
   ├─ Call _passwordHashService.VerifyPassword()
   ├─ Call _accountRepository.GetRolesAsync()
   ├─ Call _accountRepository.GetPermissionsAsync()
   ├─ Call _jwtTokenService.GenerateAccessToken()
   ├─ Call _jwtTokenService.GenerateRefreshToken()
   ├─ Call _refreshTokenRepository.CreateAsync()
      (save token to database)
   ├─ Call _loginHistoryRepository.CreateAsync()
      (record login history)
   └─ Return LoginResponse

                 ↓

4. Infrastructure Layer
   ├─ AccountRepository.GetByEmailOrPhoneAsync()
      └─ DbContext.Accounts
         .Include(...).FirstOrDefaultAsync()
   │
   ├─ PasswordHashService.VerifyPassword()
      └─ BCrypt.Verify()
   │
   ├─ JwtTokenService.GenerateAccessToken()
      └─ JwtSecurityToken + sign
   │
   ├─ RefreshTokenRepository.CreateAsync()
      └─ DbContext.RefreshTokens.Add()
   │
   └─ LoginHistoryRepository.CreateAsync()
      └─ DbContext.LoginHistories.Add()

                 ↓

5. Database Layer (AppMovieTickerDbContext)
   ├─ Execute SQL queries to get Account
   ├─ Execute SQL INSERT RefreshToken
   ├─ Execute SQL INSERT LoginHistory
   └─ Return data

                 ↓

6. Presentation Layer (AuthController) - Response
   {
     "success": true,
     "data": {
       "accountId": 1,
       "email": "user@example.com",
       "accessToken": "eyJhbGc...",
       "refreshToken": "base64...",
       "roles": ["User"],
       "expiresIn": 900
     }
   }

                 ↓

7. Browser: Nhận response
   ├─ Save accessToken to localStorage/memory
   ├─ Save refreshToken to httpOnly cookie
   └─ Redirect to home
```

---

## 🎯 DESIGN PATTERNS ĐƯỢC SỬ DỤNG

### 1. Dependency Injection
```csharp
// Constructor Injection
public class AuthController
{
    private readonly IAuthService _authService;
    
    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }
}

// Benefit:
// ✅ Loosely coupled
// ✅ Easy to test (mock)
// ✅ Flexible
```

### 2. Repository Pattern
```csharp
// Interface định nghĩa
public interface IAccountRepository
{
    Task<Account?> GetByEmailAsync(string email);
}

// Implementation
public class AccountRepository : IAccountRepository
{
    public async Task<Account?> GetByEmailAsync(string email)
    {
        return await _context.Accounts
            .FirstOrDefaultAsync(a => a.Email == email);
    }
}

// Benefit:
// ✅ Decouple data access
// ✅ Easy to swap implementations
// ✅ Testable
```

### 3. Service Pattern
```csharp
// High-level business logic
public class AuthService : IAuthService
{
    private readonly IAccountRepository _accountRepository;
    private readonly IPasswordHashService _passwordHashService;
    private readonly IJwtTokenService _jwtTokenService;
    
    public async Task<(bool, LoginResponse?, string)> LoginAsync(...)
    {
        // Orchestrate repositories + services
        var account = await _accountRepository.GetByEmailOrPhoneAsync(...);
        bool isValid = _passwordHashService.VerifyPassword(...);
        var token = _jwtTokenService.GenerateAccessToken(...);
    }
}

// Benefit:
// ✅ Encapsulate complex logic
// ✅ Reusable
// ✅ Testable
```

### 4. DTO Pattern
```csharp
// Request DTO
public class LoginRequest
{
    public string EmailOrPhone { get; set; }
    public string Password { get; set; }
}

// Response DTO
public class LoginResponse
{
    public int AccountId { get; set; }
    public string AccessToken { get; set; }
    public string RefreshToken { get; set; }
}

// Benefit:
// ✅ Data validation
// ✅ Hide sensitive fields
// ✅ Versioning API
```

---

## ✅ BEST PRACTICES

### ✓ DO
- Use interfaces/contracts
- Inject dependencies
- Use async/await
- Validate input
- Log errors
- Handle exceptions
- Use DTO for API
- Separate concerns
- Follow naming conventions

### ✗ DON'T
- Hardcode values
- Mix concerns
- Sync database calls
- Trust user input
- Return Entity directly
- Use static methods for services
- Catch exception without handling
- Create circular dependencies

---

## 🧪 TESTING

### Unit Test Example:
```csharp
[Test]
public async Task LoginAsync_WithValidCredentials_ReturnsAccessToken()
{
    // Arrange
    var mockAccountRepository = new Mock<IAccountRepository>();
    var mockPasswordHashService = new Mock<IPasswordHashService>();
    var mockJwtTokenService = new Mock<IJwtTokenService>();
    
    var authService = new AuthService(
        mockAccountRepository.Object,
        mockPasswordHashService.Object,
        mockJwtTokenService.Object
    );
    
    // Act
    var (success, response, message) = await authService.LoginAsync(
        new LoginRequest { EmailOrPhone = "test@example.com", Password = "Test123@" },
        "127.0.0.1",
        "Chrome"
    );
    
    // Assert
    Assert.IsTrue(success);
    Assert.IsNotNull(response.AccessToken);
}
```

---

## 📊 CONCLUSION

Architecture này tuân theo:
- ✅ SOLID principles
- ✅ Clean Architecture
- ✅ Separation of Concerns
- ✅ Dependency Inversion Principle
- ✅ Interface Segregation

**Result**: Code dễ test, maintain, extend ✨
