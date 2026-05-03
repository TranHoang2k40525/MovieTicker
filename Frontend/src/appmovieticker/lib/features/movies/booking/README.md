# Booking Bucket

Chức năng này xử lý đặt vé, vé của tôi và chi tiết booking.

## Vai Trò

- `domain`: booking entity, repository contract, use case tạo và xem booking.
- `data`: model booking, datasource gọi API booking.
- `presentation`: seat map, checkout, lịch sử vé, chi tiết vé.

## File Hiện Có

- [seat_map_page.dart](presentation/pages/booking/seat_map_page.dart)
- [my_tickets_page.dart](presentation/pages/booking/my_tickets_page.dart)
- [my_ticket_detail_page.dart](presentation/pages/booking/my_ticket_detail_page.dart)
- [ticket_online_history_page.dart](presentation/pages/booking/ticket_online_history_page.dart)
- [movie_booking_list_page.dart](presentation/pages/booking/movie_booking_list_page.dart)
- [cinema_booking_list_page.dart](presentation/pages/booking/cinema_booking_list_page.dart)
- [my_ticket_item.dart](data/models/booking/my_ticket_item.dart)
- [my_ticket_detail.dart](data/models/booking/my_ticket_detail.dart)
- [my_ticket_history_item.dart](data/models/booking/my_ticket_history_item.dart)
- [seat_map_item.dart](data/models/booking/seat_map_item.dart)
- [ticket_remote_datasource.dart](data/datasources/booking/ticket_remote_datasource.dart)

## Quy Tắc

- Booking không nên trộn logic thanh toán chi tiết; payment nên tách riêng khi đủ nghiệp vụ.
