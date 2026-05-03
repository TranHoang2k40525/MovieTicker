# Movies Feature Structure

Feature `movies` hiện đang chứa nhiều luồng nghiệp vụ khác nhau. Để dễ maintain, nên tách theo 8 bucket chức năng trước, rồi trong mỗi bucket tiếp tục chia theo Clean Architecture.

## Bucket Chức Năng

```text
features/movies/
  movie/
    domain/
    data/
    presentation/
  show/
    domain/
    data/
    presentation/
  booking/
    domain/
    data/
    presentation/
  product/
    domain/
    data/
    presentation/
  ticker/
    domain/
    data/
    presentation/
  notifier/
    domain/
    data/
    presentation/
  payment/
    domain/
    data/
    presentation/
  cinema/
    domain/
    data/
    presentation/
```

## Ý Nghĩa Mỗi Bucket

- `movie`: danh sách phim, chi tiết phim, phim đang chiếu / sắp chiếu / phim đặc biệt.
- `show`: lịch chiếu, suất chiếu theo phim, theo rạp, theo ngày.
- `booking`: đặt vé, ghế đã chọn, lịch sử vé, chi tiết booking.
- `product`: combo, đồ ăn, sản phẩm đi kèm.
- `ticker`: sơ đồ ghế, realtime ghế, trạng thái ghế.
- `notifier`: thông báo của người dùng.
- `payment`: thanh toán, mô phỏng thanh toán, trạng thái giao dịch.
- `cinema`: rạp phim, rạp gần đây, thông tin rạp, danh sách booking theo rạp.

## Mapping Hiện Tại

### Movie

- [movies_page.dart](movie/presentation/pages/movie/movies_page.dart)
- [movie_detail_page.dart](movie/presentation/pages/movie/movie_detail_page.dart)
- [movie_menu_dialog.dart](movie/presentation/widgets/movie/movie_menu_dialog.dart)
- [movie_list_item.dart](movie/data/models/movie/movie_list_item.dart)
- [movies_remote_datasource.dart](movie/data/datasources/movie/movies_remote_datasource.dart)

### Show

- [movie_showtime_page.dart](show/presentation/pages/showtime/movie_showtime_page.dart)
- [cinema_showtime_page.dart](show/presentation/pages/showtime/cinema_showtime_page.dart)
- [movie_showtime_item.dart](show/data/models/showtime/movie_showtime_item.dart)
- [cinema_showtime_item.dart](show/data/models/showtime/cinema_showtime_item.dart)

### Booking

- [seat_map_page.dart](booking/presentation/pages/booking/seat_map_page.dart)
- [checkout_payment_page.dart](payment/presentation/pages/payment/checkout_payment_page.dart)
- [my_tickets_page.dart](booking/presentation/pages/booking/my_tickets_page.dart)
- [my_ticket_detail_page.dart](booking/presentation/pages/booking/my_ticket_detail_page.dart)
- [ticket_online_history_page.dart](booking/presentation/pages/booking/ticket_online_history_page.dart)
- [movie_booking_list_page.dart](booking/presentation/pages/booking/movie_booking_list_page.dart)
- [cinema_booking_list_page.dart](booking/presentation/pages/booking/cinema_booking_list_page.dart)
- [my_ticket_item.dart](booking/data/models/booking/my_ticket_item.dart)
- [my_ticket_detail.dart](booking/data/models/booking/my_ticket_detail.dart)
- [my_ticket_history_item.dart](booking/data/models/booking/my_ticket_history_item.dart)
- [seat_map_item.dart](booking/data/models/booking/seat_map_item.dart)
- [ticket_remote_datasource.dart](booking/data/datasources/booking/ticket_remote_datasource.dart)

### Product

- [store_catalog_page.dart](product/presentation/pages/product/store_catalog_page.dart)
- [combo_selection_page.dart](product/presentation/pages/product/combo_selection_page.dart)
- [product_item.dart](product/data/models/product/product_item.dart)

### Ticker

- [seat_realtime_event_item.dart](ticker/data/models/realtime/seat_realtime_event_item.dart)
- [seat_realtime_client.dart](../../core/realtime/seat_realtime_client.dart)

### Notifier

- [notifications_page.dart](notifier/presentation/pages/notification/notifications_page.dart)
- [notification_item.dart](notifier/data/models/notification/notification_item.dart)
- [notification_remote_datasource.dart](notifier/data/datasources/notification/notification_remote_datasource.dart)

### Payment

- [payment_simulation_page.dart](payment/presentation/pages/payment/payment_simulation_page.dart)
- [payment_remote_datasource.dart](payment/data/datasources/payment/payment_remote_datasource.dart)

### Cinema

- [nearby_cinemas_page.dart](cinema/presentation/pages/cinema/nearby_cinemas_page.dart)
- [cinema_detail_page.dart](cinema/presentation/pages/cinema/cinema_detail_page.dart)
- [nearby_cinema_item.dart](cinema/data/models/cinema/nearby_cinema_item.dart)

## Clean Architecture Rule Ở Từng Bucket

- `domain`: Entity, Repository Interface, Use Case.
- `data`: Model, Remote Data Source, Local Data Source, Repository Implementation.
- `presentation`: Page, Widget, Bloc/Riverpod.

## Hướng Dọn Code

1. Chuyển model về đúng bucket trước.
2. Tách datasource theo nghiệp vụ, không gom quá nhiều API vào một file lớn.
3. Tạo repository interface trong `domain` cho từng bucket.
4. Tách use case theo hành động rõ ràng thay vì gọi trực tiếp datasource từ UI.

