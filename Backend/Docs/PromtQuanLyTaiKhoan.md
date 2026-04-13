# Promt Quan Ly Tai Khoan

## Muc tieu
Hay sinh code .NET cho module quan ly tai khoan sao cho giong 100% phong cach hien co cua du an MovieTicket. Module nay bao gom dang ky, dang nhap, xac thuc OTP, quen mat khau, reset mat khau, doi mat khau, refresh token, dang xuat, dang xuat tat ca thiet bi va tao tai khoan employee.

## Rang buoc bat buoc
- Khong tu y doi kien truc dang co.
- Khong tu sinh lai hoac sua cac Entity, `AppMovieTickerDbContext` va cac `Configurations`; day la phan tu viet san cua du an.
- Giữ nguyen cach dat ten folder/namespace dang co, ke ca cac ten dang co tinh chat nhat quan voi code hien tai.
- Phai theo dung 3 lop chinh: Presentation -> Application -> Infrastructure -> Domain.
- Service tra ve tuple, khong tao response wrapper phuc tap.
- Controller tra ve anonymous object co dang `success`, `message`, `data` neu can.
- Tat ca API can co `try/catch`, ghi log bang `ILogger`, va tra ve thong diep tieng Viet ngan gon.

## Cach viet code 
### Presentation layer
- Controller dat trong `MovieTicket.Presentation.Controllers.Auth`.
- Dung `[ApiController]`, `[Route("api/[controller]")]`.
- API cong dung `[AllowAnonymous]` khi khong can dang nhap, `[Authorize]` khi can token.
- Moi action phai kiem tra `ModelState.IsValid` neu request co validation attributes.
- Neu sai input thi tra ve `BadRequest(new { success = false, message = "Input khong hop le" })` hoac thong diep tuong duong.
- Khi dang nhap can lay `ipAddress` tu `HttpContext.Connection.RemoteIpAddress` va `deviceInfo` tu `Request.Headers["User-Agent"]`.
- Khi can accountId tu token, lay claim `accountId` va `int.TryParse`.
- Cac action quan ly user/role phai lay `ClaimTypes.Role` tu token va truyen danh sach role xuong service.

### Application layer
- DTO nam trong `MovieTicket.Application.DTOs.Auth`.
- Interface dat trong `MovieTicket.Application.IServices`.
- Service dat trong `MovieTicket.Application.Services`.
- Moi ham service nen tra ve tuple dang:
  - `(bool Success, string Message)`
  - `(bool Success, LoginResponseDto? Response, string Message)`
- Validation duoc lam ngay dau ham: null/empty, mat khau xac nhan, do dai toi thieu, OTP hop le.
- Khi fail, return ngay voi thong diep ro rang bang tieng Viet.
- Khi thanh cong, cap nhat database thong qua repository va return message ngan gon.
- Neu can phan quyen, phai kien tra role truoc khi thao tac.

### Infrastructure layer
- Repository dat trong `MovieTicket.Infrastructure.Repositories.AuthRespository`.
- Service ho tro dat trong `MovieTicket.Infrastructure.Services.Implementations`.
- Dung EF Core truc tiep voi `AppMovieTickerDbContext`.
- Khi truy van, uu tien `Include`, `ThenInclude`, `AsNoTracking()` khi doc du lieu.
- Khi tao/sua/xoa, goi `SaveChangesAsync()` va tra ve ket qua phu hop.
- Password phai hash bang BCrypt, khong luu plain text.
- OTP phai hash, luu expiry, va danh dau `Used` khi da xac thuc.
- Refresh token phai duoc luu DB, co the xoa theo account hoac token.

## Luong nghiep vu phai giu dung
### Dang ky va xac thuc OTP
- Dang ky tao `Account` va `User`.
- Tu dong gan role mac dinh `User` neu chua co.
- Tao OTP registration va gui qua email.
- Trang thai tai khoan phai di theo mo hinh hien co cua du an: dang cho xac thuc, active, blocked.
- Co API huy dang ky / xoa OTP dang ky.

### Dang nhap va token
- Dang nhap bang email hoac so dien thoai.
- Kiem tra account status truoc khi cap token.
- Tao access token JWT tu `JwtClaim` gom `accountId`, `email`, `Role`, `Permissions`.
- Tao refresh token va luu DB.
- Login response phai co `AccountId`, `Email`, `FullName`, `AccessToken`, `RefreshToken`, `Roles`, `ExpiresIn`.
- Khi refresh token, phai verify refresh token trong DB va cap lai access token moi.
- Logout xoa refresh token hien tai.
- Logout all xoa refresh token theo account.

### Quen / reset / doi mat khau
- Quen mat khau gui OTP qua email voi purpose `forgot_password`.
- Reset mat khau can email + OTP + new password + confirm password.
- Doi mat khau can current password + new password + confirm password va accountId tu token.

### Tao employee va quan ly tai khoan
- Tao employee chi danh cho Admin/Manager theo rule hien co.
- Manager chi tao duoc Staff.
- Admin tao duoc Manager va Staff.
- Tao employee active ngay, khong can OTP.
- Co API doi trang thai tai khoan va xoa tai khoan.
- Khi xoa tai khoan phai xu ly refresh token, user profile va quan he lien quan theo cach an toan nhu code hien tai.

## Quy tac dat ten va phong cach
- Dung ten class, DTO, method, property theo kieu hien co cua du an.
- Dung `async`/`await` tat ca cac call I/O.
- Dung thong diep tieng Viet ngan, ro, khong lan man.
- Uu tien code don gian, thang, de doc, khong sua cau truc neu khong can.

## Luu y ve quyen va claim
- Token phai co claim `accountId`, `email`, `role`, `permission`.
- Role hien co: `Admin`, `Manager`, `Staff`, `User`.
- Permission mapping phai theo dung cach code hien tai cua du an.
- Cac API quan trong can `[Authorize(Roles = "Admin,Manager")]` khi xu ly manager/staff.
