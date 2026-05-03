# Ticker Bucket

Chức năng này xử lý sơ đồ ghế và realtime trạng thái ghế.

## Vai Trò

- `domain`: entity trạng thái ghế, repository contract realtime.
- `data`: model trạng thái ghế, datasource hoặc client realtime.
- `presentation`: seat map UI và trạng thái tương tác ghế.

## File Hiện Có

- [seat_realtime_event_item.dart](data/models/realtime/seat_realtime_event_item.dart)
- [seat_realtime_client.dart](../../../core/realtime/seat_realtime_client.dart)

## Ghi Chú

- Tầng realtime dùng lại từ `core` để tránh nối SignalR trực tiếp trong UI.
