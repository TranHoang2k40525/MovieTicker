# 🎬 MovieTicket - Hệ Thống Quản Lý Tài Khoản & Xác Thực

## ⚡ QUICK START

### 1. Clone & Setup
```bash
cd Backend
```

### 2. Cấu hình .env
```
ConnectionStrings__DefaultConnection=Server=HOANG;Database=MovieTicket;Trusted_Connection=true;Encrypt=false;
Jwt__SecretKey=MyVeryLongSecretKeyForJwtTokenThatIsAtLeast32Characters!@#
Jwt__Issuer=MovieTicketApp
Jwt__Audience=MovieTicketUsers
Email__SmtpUser=hoangzai2k403@gmail.com
Email__SmtpPass=ijivnpzaqmhzbvms
```

### 3. Database Migration
```bash
cd src/MovieTicket/MovieTicket.Infrastructure
dotnet ef database update
```

### 4. Chạy Server
```bash
cd src/MovieTicket/MovieTicket.Presentation
dotnet run
```

**Swagger**: http://localhost:5000/swagger

---

## 🔑 CÁC API CHÍNH

| Method | Endpoint | Mô Tả |
|--------|----------|-------|
| POST | `/api/auth/register` | Đăng ký |
| POST | `/api/auth/verify-otp` | Xác thực OTP |
| POST | `/api/auth/login` | Đăng nhập |
| POST | `/api/auth/forgot-password` | Quên mật khẩu |
| POST | `/api/auth/reset-password` | Reset mật khẩu |
| POST | `/api/auth/change-password` | Đổi mật khẩu |
| POST | `/api/auth/refresh-token` | Cấp lại token |
| POST | `/api/auth/logout` | Đăng xuất |
| POST | `/api/auth/logout-all` | Đăng xuất tất cả thiết bị |

---

## 📋 TEST FLOW

### 1. Đăng Ký
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@gmail.com",
    "phone": "0901234567",
    "password": "Test123@",
    "confirmPassword": "Test123@",
    "fullName": "Test User"
  }'
```

✅ Kiểm tra email để lấy OTP

### 2. Xác Thực OTP
```bash
curl -X POST http://localhost:5000/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@gmail.com",
    "otpCode": "123456"
  }'
```

✅ Ready to login

### 3. Đăng Nhập
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "emailOrPhone": "test@gmail.com",
    "password": "Test123@"
  }'
```

✅ Nhận `accessToken` & `refreshToken`

### 4. Gọi API với Token
```bash
curl -X POST http://localhost:5000/api/auth/change-password \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "currentPassword": "Test123@",
    "newPassword": "NewTest456@",
    "confirmPassword": "NewTest456@"
  }'
```

---

## 🔐 KEY FEATURES

✅ **Password Hashing**: BCrypt (cost=10)  
✅ **JWT Token**: HS256 (15 phút)  
✅ **Refresh Token**: Random 64 bytes (7 ngày)  
✅ **OTP**: 6 chữ số (10 phút)  
✅ **Email**: Gmail SMTP (thực tế)  
✅ **Login History**: IP + Device tracking  
✅ **Role & Permission**: User, Admin, Staff, Manager  
✅ **Logout All Devices**: Xóa tất cả refresh tokens

---

## 📚 CHI TIẾT

Xem **API_DOCUMENTATION.md** để biết:
- API endpoints đầy đủ
- Request/Response examples
- Database schema
- Security details
- JWT structure
- Email configuration
- Role & Permission system

---

## 🛠️ TECH STACK

- **Framework**: ASP.NET Core 9
- **Database**: SQL Server
- **Auth**: JWT + BCrypt
- **Email**: Gmail SMTP
- **ORM**: Entity Framework Core
- **API Doc**: Swagger/OpenAPI

---

## 📦 STRUCTURE

```
Domain Layer:
  - Entities (Account, User, Otp, etc)
  - ValueObjects (JwtClaim)

Application Layer:
  - DTOs (Request/Response)
  - Interfaces (IAuthService, IRepositories)

Infrastructure Layer:
  - Repositories (AccountRepository, OtpRepository, etc)
  - Services (AuthService, JwtTokenService, PasswordHashService, etc)
  - DbContext (AppMovieTickerDbContext)

Presentation Layer:
  - Controllers (AuthController)
  - Program.cs (DI + JWT Setup)
```

---

## 🔧 TROUBLESHOOTING

### Email không gửi?
- Check Gmail App Password (16 ký tự)
- Check SMTP Host: smtp.gmail.com
- Check Port: 587
- Enable 2FA on Gmail

### JWT error?
- Check SecretKey (>= 32 ký tự)
- Check token format: Bearer {token}
- Check token not expired

### Database error?
- Check connection string
- Run migrations: `dotnet ef database update`
- Check SQL Server running

---

**Last Updated**: April 2026  
**Status**: ✅ Production Ready
