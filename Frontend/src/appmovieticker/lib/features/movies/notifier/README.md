# Notifier Bucket

Chức năng này xử lý thông báo người dùng.

## Vai Trò

- `domain`: notification entity, repository contract, use case lấy thông báo.
- `data`: model và datasource thông báo.
- `presentation`: màn hình danh sách thông báo.

## File Hiện Có

- [notifications_page.dart](presentation/pages/notification/notifications_page.dart)
- [notification_item.dart](data/models/notification/notification_item.dart)
- [notification_remote_datasource.dart](data/datasources/notification/notification_remote_datasource.dart)
