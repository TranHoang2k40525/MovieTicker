# Show Bucket

Chức năng này xử lý lịch chiếu và suất chiếu.

## Vai Trò

- `domain`: entity cho lịch chiếu, contract repository, use case lọc suất chiếu.
- `data`: model từ API lịch chiếu, datasource lấy suất theo phim hoặc theo rạp.
- `presentation`: page hiển thị lịch chiếu theo phim và theo rạp.

## File Hiện Có

- [movie_showtime_page.dart](presentation/pages/showtime/movie_showtime_page.dart)
- [cinema_showtime_page.dart](presentation/pages/showtime/cinema_showtime_page.dart)
- [movie_showtime_item.dart](data/models/showtime/movie_showtime_item.dart)
- [cinema_showtime_item.dart](data/models/showtime/cinema_showtime_item.dart)

## Quy Tắc

- Dữ liệu lịch chiếu chỉ nên nằm ở bucket này hoặc ở `movie` khi là thông tin mô tả phim.
