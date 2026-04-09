# AppMovieTicker Backend

## 1) Tổng quan
Backend của AppMovieTicker được xây dựng theo kiến trúc nhiều tầng trên ASP.NET Core Web API.
Mục tiêu chính của backend hiện tại:
- Xác thực và phân quyền người dùng bằng JWT.
- Quản lý vòng đời tài khoản: đăng ký, OTP, đăng nhập, refresh token, đổi/quên mật khẩu.
- Quản lý hồ sơ người dùng (profile, avatar).
- Hỗ trợ quản trị tài khoản nhân sự (Admin/Manager/Staff).

Nền tảng runtime:
- .NET 9.0
- ASP.NET Core Web API
- Entity Framework Core + SQL Server

## 2) Kiến trúc hệ thống
Dự án được tổ chức theo 4 layer:
- Presentation: API Controllers, middleware, DI, startup.
- Application: DTOs, interfaces, business use-cases.
- Infrastructure: DbContext, repository implementation, hạ tầng email/JWT/OTP.
- Domain: entities, value objects, enums, quy tắc domain.

Luồng phụ thuộc:
- Presentation -> Application -> Infrastructure -> Domain

Nguyên tắc:
- Domain không phụ thuộc layer khác.
- Controller không truy cập database trực tiếp.
- Giao tiếp qua interfaces để dễ mở rộng và test.

## 3) Cấu trúc thư mục chính
- src/MovieTicket/MovieTicket.Presentation: API host.
- src/MovieTicket/MovieTicket.Application: use-cases, DTOs, service contracts.
- src/MovieTicket/MovieTicket.Infrastructure: EF Core, repositories, external services.
- src/MovieTicket/MovieTicket.Domain: entities và value objects.
- src/MovieTicket/Assets/UserImagers: lưu ảnh avatar người dùng.
- src/MovieTicket/SeedAdmin.sql: seed admin/roles mẫu.
- database: scripts SQL hỗ trợ.

## 4) Công nghệ và thư viện chính
- Microsoft.AspNetCore.Authentication.JwtBearer
- Microsoft.EntityFrameworkCore + Microsoft.EntityFrameworkCore.SqlServer
- Swashbuckle.AspNetCore (Swagger UI)
- BCrypt.Net-Next (hash password, hash OTP)
- DotNetEnv (đọc biến môi trường từ file .env)

## 5) Tính năng đã có
### Xác thực và bảo mật
- Đăng ký tài khoản với trạng thái pending_verification.
- Gửi OTP qua email để xác thực đăng ký.
- Đăng nhập bằng email hoặc số điện thoại.
- Cấp Access Token và Refresh Token.
- Cấp lại Access Token bằng Refresh Token.
- Quên mật khẩu và đặt lại mật khẩu qua OTP.
- Đổi mật khẩu khi đã đăng nhập.
- Đăng xuất 1 thiết bị hoặc tất cả thiết bị.

### Quản lý user
- Lấy thông tin profile.
- Cập nhật profile.
- Upload avatar (jpg/jpeg/png/gif/webp, tối đa 5MB).
- Trả ảnh avatar trực tiếp qua endpoint GET.

### Quản trị tài khoản
- Tạo tài khoản employee (Manager/Staff) theo role hiện tại.
- Khóa/Mở khóa tài khoản.
- Xóa tài khoản.

### Background cleanup
- Dịch vụ nền dọn tài khoản pending_verification quá 5 phút.
- Chu kỳ chạy mỗi 1 phút.

## 6) Yêu cầu môi trường
- Windows/macOS/Linux
- .NET SDK 9.0+
- SQL Server (local hoặc remote)
- Tài khoản SMTP (Gmail App Password hoặc SMTP server tương đương)

Khuyến nghị:
- Cài dotnet-ef để thao tác migration thủ công khi cần.
  Lệnh: dotnet tool install --global dotnet-ef

## 7) Cấu hình môi trường
Backend đọc biến môi trường theo thứ tự ưu tiên:
1. Biến DB_*/JWT_*/EMAIL_* từ .env hoặc environment variables.
2. Fallback sang appsettings (ConnectionStrings/Jwt).

File mẫu:
- src/MovieTicket/.env.example

Tạo file môi trường local:
1. Sao chép .env.example thành .env trong thư mục src/MovieTicket.
2. Cập nhật giá trị DB, JWT, Email theo máy của bạn.

Biến quan trọng:
- DB_SERVER
- DB_NAME
- DB_USER
- DB_PASSWORD
- DB_ENCRYPT
- DB_TRUSTED_CONNECTION
- JWT_SECRET_KEY
- JWT_ISSUER
- JWT_AUDIENCE
- EMAIL_SMTP_HOST
- EMAIL_SMTP_PORT
- EMAIL_SMTP_USER
- EMAIL_SMTP_PASS
- EMAIL_FROM

Lưu ý bảo mật quan trọng:
- Không commit file .env.
- Không sử dụng secret thật trong tài liệu hoặc file mẫu khi chia sẻ ra ngoài.
- Nếu lộ mật khẩu/API key, cần đổi ngay.

## 8) Chạy dự án local
Từ thư mục Backend:
1. Di chuyển vào thư mục solution
   cd src/MovieTicket
2. Restore packages
   dotnet restore MovieTicket.slnx
3. Build
   dotnet build MovieTicket.slnx
4. Run API host
   dotnet run --project MovieTicket.Presentation/MovieTicket.Presentation.csproj

URL mặc định khi chạy Development:
- HTTP: http://localhost:5193
- HTTPS: https://localhost:7084
- Swagger: /swagger

Ví dụ:
- http://localhost:5193/swagger

## 9) Database và migration
Dự án có bật tự động apply migration khi startup:
- App sẽ gọi Database.Migrate() lúc khởi động.

Điều này có nghĩa:
- Nếu DB kết nối thành công và migration hợp lệ, schema sẽ tự cập nhật.

Khi cần thao tác migration thủ công:
1. Tạo migration mới
   dotnet ef migrations add TenMigrationMoi --project MovieTicket.Infrastructure/MovieTicket.Infrastructure.csproj --startup-project MovieTicket.Presentation/MovieTicket.Presentation.csproj
2. Cập nhật DB
   dotnet ef database update --project MovieTicket.Infrastructure/MovieTicket.Infrastructure.csproj --startup-project MovieTicket.Presentation/MovieTicket.Presentation.csproj

Script SQL hỗ trợ:
- database/06-04-2026.sql
- database/08-04-2026.sql
- database/AddAdmin.sql
- src/MovieTicket/SeedAdmin.sql

## 10) API chính
Base route auth:
- /api/Auth

Base route user:
- /api/User

### Nhóm Auth
- POST /api/Auth/register
- POST /api/Auth/verify-otp
- POST /api/Auth/cancel-registration
- POST /api/Auth/login
- POST /api/Auth/forgot-password
- POST /api/Auth/reset-password
- POST /api/Auth/change-password (Authorize)
- POST /api/Auth/refresh-token
- POST /api/Auth/logout
- POST /api/Auth/logout-all (Authorize)
- POST /api/Auth/create-employee (Authorize Roles: Admin,Manager)
- PUT /api/Auth/account/{id}/status (Authorize Roles: Admin,Manager)
- DELETE /api/Auth/account/{id} (Authorize Roles: Admin,Manager)

### Nhóm User
- GET /api/User/profile (Authorize)
- PUT /api/User/profile (Authorize)
- POST /api/User/avatar (Authorize, multipart/form-data)
- GET /api/User/avatar?accountId=1 (AllowAnonymous, có thể trả file ảnh)

## 11) Quy tắc phân quyền (theo code hiện tại)
- Admin có thể tạo Manager và Staff.
- Manager chỉ có thể tạo Staff.
- Tạo employee không yêu cầu OTP, tài khoản active ngay.

## 12) Dữ liệu mẫu và seed admin
File seed:
- src/MovieTicket/SeedAdmin.sql

Nội dung chính của script:
- Tạo roles cơ bản nếu chưa có (Admin, Manager, Staff, User).
- Tạo tài khoản admin mẫu nếu chưa tồn tại.
- Gán role Admin.

Khuyến nghị:
- Chỉ dùng thông tin seed cho môi trường dev/test.
- Đổi thông tin đăng nhập mặc định trước khi deploy.

## 13) Logging và theo dõi
- Logging cấu hình trong appsettings.
- Mức log mặc định: Information.
- Lỗi nghiệp vụ và lỗi hệ thống được ghi qua ILogger.

## 14) Lưu trữ avatar
Avatar được lưu tại:
- src/MovieTicket/Assets/UserImagers

Giới hạn upload:
- Định dạng: .jpg, .jpeg, .png, .gif, .webp
- Kích thước tối đa: 5MB

## 15) CORS
Hiện tại đang cấu hình policy AllowAll tại Program.cs:
- AllowAnyOrigin
- AllowAnyMethod
- AllowAnyHeader

Khuyến nghị cho production:
- Chỉ định danh sách domain frontend cụ thể.
- Không dùng AllowAnyOrigin trong môi trường internet public.

## 16) Troubleshooting
### Lỗi không kết nối DB
- Kiểm tra DB_SERVER, DB_NAME, DB_USER, DB_PASSWORD trong .env.
- Kiểm tra SQL Server đang chạy.
- Kiểm tra firewall và quyền login SQL.

### Lỗi JWT invalid hoặc 401
- Kiểm tra JWT_SECRET_KEY giữa môi trường tạo token và xác thực.
- Kiểm tra issuer/audience.
- Kiểm tra token hết hạn.

### Lỗi gửi email OTP
- Kiểm tra EMAIL_SMTP_USER và EMAIL_SMTP_PASS.
- Với Gmail, cần App Password thay vì mật khẩu thường.
- Kiểm tra cổng SMTP và cấu hình TLS/STARTTLS.

### Swagger không mở
- Kiểm tra app đang chạy đúng profile.
- Truy cập đúng URL theo launchSettings.

## 17) Quy trình làm việc gợi ý cho team
1. Cập nhật code mới nhất.
2. Copy/cập nhật file .env local.
3. Chạy restore, build, run.
4. Mở swagger test API.
5. Nếu thay đổi model: tạo migration mới và update DB.
6. Chạy test tích hợp/manual trước khi merge.

## 18) Ghi chú bảo trì
- Đảm bảo secrets không nằm trong source control.
- Định kỳ dọn dữ liệu dev/test và refresh tài khoản seed.
- Cân nhắc tách config theo môi trường (Development/Staging/Production).
- Cân nhắc thêm health check endpoint cho monitoring.
