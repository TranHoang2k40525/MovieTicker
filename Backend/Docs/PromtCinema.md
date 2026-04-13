# Promt Cinema

## Muc tieu
Hay sinh code .NET cho phan cinema sao cho giong phong cach hien co cua MovieTicket. Phan nay bao gom tim rap gan nhat, lay showtime theo rap, lay rap theo phim va sap xep theo khoang cach dia ly.

## Rang buoc bat buoc
- Khong doi kien truc chung.
- Khong tu y sinh lai Entity, `AppMovieTickerDbContext` va `Configurations`.
- Giữ nguyen namespace/cach dat ten cua project.
- Controller public nen `[AllowAnonymous]`.
- Service phai co logger va xu ly loi bang `try/catch`.

## Cach code phai giong du an
### Presentation layer
- Controller dat trong `MovieTicket.Presentation.Controllers.Cinema`.
- Route dung `api/[controller]`.
- API nhan `LocationRequestDto`, `MovieLocationRequestDto` hoac `cinemaId` + `filterDate`.
- Neu ModelState khong hop le thi tra `BadRequest(ModelState)` hoac `BadRequest` voi message ro rang.
- Neu cinemaId hoac movieId <= 0 thi tra loi ngay.

### Application layer
- Interface service dat trong `MovieTicket.Application.Services.IServices.ICinema`.
- Service dat trong `MovieTicket.Application.Services.Implementations.Cinema`.
- DTO dat trong `MovieTicket.Application.DTOs.Cinema`.
- Cac ham service tra ve `IEnumerable<NearbyCinemaDto>`, `IEnumerable<CinemaShowtimeDto>`, hoac `IEnumerable<CinemaListForMovieDto>`.
- Neu co loi thi tra danh sach rong.

### Infrastructure layer
- Repository cinema va cinema-showtime dat trong `MovieTicket.Infrastructure.Repositories.CinemaRepository`.
- Dung `Include`, `ThenInclude`, `AsNoTracking()` khi query du lieu show/rap/phim.
- Sap xep va group du lieu o service, khong day qua controller.

## Luong nghiep vu cinema phai giu dung
### Rap gan nhat
- Nhan latitude/longitude.
- Tinh khoang cach bang cong thuc Haversine.
- Tra ve danh sach rap sort tang dan theo `DistanceInKm`.
- Chi lay cac rap co latitude/longitude hop le.

### Showtime theo rap
- Nhan `cinemaId` va `filterDate`.
- Neu `filterDate` rong thi dung ngay hien tai.
- Chi cho xem truoc toi da 30 ngay.
- Neu ngay yeu cau o qua khu thi cap ve hom nay.
- Nhom show theo phim.
- Moi showtime phai co start/end time duoc tinh tu `ShowTime` + `MovieRuntime`.
- `ExperienceType` mac dinh la `2D` nhu code hien co.

### Rap theo phim
- Nhan `movieId`, `latitude`, `longitude`, `filterDate`.
- Loc show theo phim va theo khoang ngay hop le.
- Nhom theo rap.
- Sap xep theo khoang cach tang dan.

## Mapping DTO phai giong code hien co
### LocationRequestDto
- `Latitude`
- `Longitude`

### MovieLocationRequestDto
- Ke thua `LocationRequestDto`
- `MovieId`

### NearbyCinemaDto
- `CinemaId`
- `CinemaName`
- `CityAddress`
- `Latitude`
- `Longitude`
- `DistanceInKm`

### CinemaShowtimeDto
- `MovieId`
- `MovieTitle`
- `ImageUrl`
- `MovieAge`
- `MovieGenre`
- `MovieRuntime`
- `Showtimes`

### ShowtimeDetailDto
- `ShowId`
- `ShowDate`
- `StartTime`
- `EndTime`
- `CinemaHallId`
- `HallName`
- `ExperienceType`

### CinemaListForMovieDto
- `CinemaId`
- `CinemaName`
- `CityAddress`
- `DistanceInKm`
- `Showtimes`

## Cach xu ly loi va return
- Neu co exception, log error va tra danh sach rong.
- Khong tao response phuc tap neu khong can.
- Khong de logic tinh khoang cach hoac group show roi controller moi xu ly.

## Dinh huong viet code
- Uu tien code don gian, ro rang, dung pattern dang co.
- Dung `DateOnly` cho ngay.
- Dung `TimeSpan` cho gio bat dau/ket thuc.
- Khong can them business rule ngoai nhung gi code hien tai da co.
