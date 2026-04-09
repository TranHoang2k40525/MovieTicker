# Promt Movie

## Muc tieu
Hay sinh code .NET cho phan movie sao cho giong phong cach hien co cua MovieTicket. Phan nay phuc vu API cong khai cho phim dang chieu, sap chieu, phim dac biet, tim phim, lay phim theo ID va phan trang danh sach phim.

## Rang buoc bat buoc
- Khong doi kien truc chung cua du an.
- Khong tu y sinh lai Entity, `AppMovieTickerDbContext` va `Configurations`.
- Giữ nguyen namespace va cach dat ten dang co trong project.
- Controller phai la lop mo, nghia la lien quan movie public thi `[AllowAnonymous]`.
- Service phai co logger va xu ly loi bang `try/catch`.

## Cach code phai giong du an
### Presentation layer
- Controller dat trong `MovieTicket.Presentation.Controllers.Movie`.
- Route dung dang `api/[controller]`.
- Cac API public khong can auth.
- Neu input khong hop le thi tra `BadRequest` voi message ngan gon.
- Neu khong tim thay movie thi tra `NotFound`.

### Application layer
- Interface service dat trong `MovieTicket.Application.Services.IServices.IMovie`.
- Service dat trong `MovieTicket.Application.Services.Implementations.Movie`.
- DTO dat trong `MovieTicket.Application.DTOs.Movie`.
- Cac ham service tra ve `IEnumerable<MovieListDto>` hoac `MovieDetailDto?`.
- Neu co loi thi log va tra ve danh sach rong hoac `null`.

### Infrastructure layer
- Repository movie dat trong `MovieTicket.Infrastructure.Repositories.MovieRespository`.
- Dung EF Core, `AsNoTracking()` cho cac query doc.
- Can `Include` khi can load relation phuc vu filter/ordering.
- Phan ghi du lieu phai goi `SaveChangesAsync()`.

## Luong nghiep vu movie phai giu dung
### Danh sach phim
- `now-showing`: phim co show trong ngay hien tai.
- `upcoming`: phim co `MovieReleaseDate > today`.
- `special`: phim co so like cao, sap xep giam dan theo so `LikeMovies` co `IsLiked == true`.
- `showing-and-upcoming`: lay phim dang chieu va sap chieu, co phan trang.

### Tim kiem va chi tiet
- Tim phim theo ID.
- Tim phim theo ten, so sanh truc tiep theo ten phim.
- Tra ve DTO khong tra Entity truc tiep.

## Mapping DTO phai giong code hien co
### MovieListDto
- `MovieId`
- `MovieTitle`
- `ImageUrl`
- `MovieReleaseDate`
- `MovieRuntime`
- `MovieAge`
- `MovieGenre`
- `MovieActor`
- `MovieLanguage`

### MovieDetailDto
- `MovieId`
- `MovieTitle`
- `MovieDescription`
- `MovieLanguage`
- `MovieGenre`
- `MovieReleaseDate`
- `MovieRuntime`
- `MovieAge`
- `ImageUrl`
- `MovieActor`
- `MovieTrailler`

## Cach xu ly loi va return
- Neu page hoac sizePage <= 0, reset ve gia tri mac dinh hop ly.
- Neu tham so khong hop le, log warning hoac tra null.
- Neu co exception, log error va tra empty result.
- Khong push logic phuc tap ra controller.

## Dinh huong viet code
- Uu tien code ngan, ro, de doc.
- Dung `Select` de map tu Entity sang DTO.
- Giữ phong cach public API don gian va trang nhan nhu code hien co.
- Khong can cac tinh nang quan ly movie phuc tap neu khong co trong project hien tai; chi viet theo pattern du an dang co.
