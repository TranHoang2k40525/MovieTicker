# Movie Bucket

Chức năng này chứa dữ liệu và UI liên quan đến phim.

## Vai Trò

- `domain`: entity phim, repository contract, use case lấy danh sách và chi tiết phim.
- `data`: model ánh xạ API, datasource gọi phim, repository implementation.
- `presentation`: page và widget liên quan danh sách phim, chi tiết phim, danh sách phim đã đặt.

## File Hiện Có

- [movies_page.dart](presentation/pages/movie/movies_page.dart)
- [movie_detail_page.dart](presentation/pages/movie/movie_detail_page.dart)
- [movie_menu_dialog.dart](presentation/widgets/movie/movie_menu_dialog.dart)
- [movie_list_item.dart](data/models/movie/movie_list_item.dart)
- [movies_remote_datasource.dart](data/datasources/movie/movies_remote_datasource.dart)

## Quy Tắc

- UI không gọi thẳng API.
- Model phải có hướng chuyển sang entity khi domain được bổ sung.
