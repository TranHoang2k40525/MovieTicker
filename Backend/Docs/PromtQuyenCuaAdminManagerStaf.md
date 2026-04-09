# Promt Quyen Cua Admin Manager Staf

## Muc tieu
Hay sinh code .NET cho phan quan ly quyen va phan quyen user sao cho giong phong cach cua du an MovieTicket hien co. Phan nay tap trung vao Admin, Manager, Staff, User, quyen truy cap, tao tai khoan nhan vien, khoa/mo khoa tai khoan va xoa tai khoan.

## Rang buoc bat buoc
- Khong tu y doi canh truc code.
- Khong sinh lai Entity, `AppMovieTickerDbContext`, `Configurations`.
- Giữ nguyen ten package/namespace, ke ca cac ten dang co nhu `IResponsitories`, `AuthRespository`, `MovieRespository` neu can dong bo voi project.
- Logic phan quyen phai nam trong service, controller chi la lop tiep nhan request va tra response.
- Moi endpoint quan ly quyen phai co `Authorize` phu hop.
- Moi ham service phai co `try/catch`, logger, va return tuple.

## Nhom quyen phai giu dung
- `Admin`
- `Manager`
- `Staff`
- `User`

## Cach code phai giong du an
### Presentation layer
- Dung controller trong `MovieTicket.Presentation.Controllers.Auth` cho cac API quan ly quyen tai khoan.
- API quan trong dang `[Authorize(Roles = "Admin,Manager")]`.
- Khi can check quyen trong code, lay `ClaimTypes.Role` tu token va bien thanh `List<string>`.
- Khong viet logic phan quyen phuc tap trong controller.

### Application layer
- Tao interface service trong `MovieTicket.Application.IServices`.
- Service tra ve tuple, khong return object phuc tap.
- Cac ham can co kieu:
  - `CreateEmployeeAsync(request, currentRoles)`
  - `ChangeAccountStatusAsync(targetAccountId, status, currentRoles)`
  - `DeleteAccountAsync(targetAccountId, currentRoles)`
- Neu khong du quyen thi tra ve thong diep ro rang bang tieng Viet.
- Neu account khong ton tai, tra ve message ngan gon.

### Infrastructure layer
- Dung repository cho `Account`, `User`, `Role`, `AccountRole`, `RefreshToken`.
- Khi can lay account, include `Users`, `AccountRoles`, `Role` de phuc vu kiem tra quyen.
- Khi xoa tai khoan, xu ly refresh token va relation lien quan truoc neu can.

## Rule phan quyen phai theo dung code hien co
### Tao employee
- Admin tao duoc `Manager` va `Staff`.
- Manager chi tao duoc `Staff`.
- `User` khong duoc tao employee.
- Employee duoc tao active ngay, khong can OTP.
- Employee phai co `Account`, `User` va `AccountRole`.
- Neu role chua co trong DB thi tao moi role tu dong.

### Khoa / mo khoa tai khoan
- Chi `Admin` va `Manager` duoc thao tac.
- Khong duoc thay doi trang thai cua `Admin`.
- `Manager` khong duoc thao tac tren tai khoan `Manager` neu khong phai `Admin`.
- `Status` phai dung cac gia tri hien co: `active`, `blocked`, `pending_verification`.

### Xoa tai khoan
- Chi `Admin` va `Manager` duoc thao tac.
- Khong duoc xoa `Admin`.
- `Manager` chi xoa duoc `Staff`/user theo rule hien co, khong duoc xoa `Manager` neu khong phai `Admin`.
- Truoc khi xoa account phai xoa refresh token va xu ly quan he neu can.

### Token, claim va permission
- JWT phai co `accountId`, `email`, `role`, `permission`.
- Permission mapping phai theo dung cach dang co trong code:
  - Admin: `view_users`, `manage_users`, `manage_movies`, `manage_bookings`, `view_reports`
  - Manager: `manage_bookings`, `view_cinema`, `manage_cinema`
  - Staff: `view_bookings`, `process_transactions`
  - User: `view_movies`, `book_tickets`, `view_bookings`
- Neu khong co role ro rang, co the fallback ve `User` nhu code hien tai.

## Cach viet thong diep va response
- Dung thong diep tieng Viet ngan gon, truc tiep.
- Controller tra ve `{ success = true, message = ... }` hoac `{ success = false, message = ... }`.
- Neu can tra data thi dung `data`.
- Khong tao response model phuc tap neu khong can.

## Luu y quan trong
- Chi tao prompt cho phan quyen; khong can viet lai phan entity hay DbContext.
- Phong cach code phai don gian, ro rang, va di thang vao rule phan quyen nhu project hien co.
