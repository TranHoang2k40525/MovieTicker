# Library Architecture

Thư mục `lib` của app này nên được hiểu theo Clean Architecture theo từng feature.

## Mục tiêu

- Tầng `domain` chỉ chứa logic nghiệp vụ thuần Dart.
- Tầng `data` chứa chi tiết kỹ thuật: API, local storage, model, repository implementation.
- Tầng `presentation` chứa UI và state management như BLoC hoặc Riverpod.
- Tầng `core` chứa các phần dùng chung cho toàn app: network, errors, theme, DI, widgets tái sử dụng.

## Dependency Rule

- `presentation` phụ thuộc vào `domain`.
- `data` phụ thuộc vào `domain`.
- `domain` không phụ thuộc vào Flutter, Dio, SharedPreferences, database hay bất kỳ framework nào.

## Cấu trúc đề xuất

```text
lib/
  main.dart
  core/
    constants/
    di/
    errors/
    network/
    realtime/
    theme/
    widgets/
  features/
    auth/
      domain/
        entities/
        repositories/
        usecases/
      data/
        datasources/
        models/
        repositories/
      presentation/
        bloc/
        pages/
        widgets/
    movies/
      domain/
        entities/
        repositories/
        usecases/
      data/
        datasources/
        models/
        repositories/
      presentation/
        bloc/
        pages/
        widgets/
```

## Mapping hiện tại

- `features/auth` đã đi đúng hướng Clean Architecture: có đủ `domain`, `data`, `presentation`.
- `features/movies` hiện đang mạnh ở `data` và `presentation`, nhưng chưa có lớp `domain` rõ ràng.
- `core/network/dio_client.dart` là hạ tầng dùng chung, nên giữ ở `core`.
- `core/realtime/seat_realtime_client.dart` cũng thuộc `core` vì là dịch vụ kỹ thuật dùng xuyên feature.

## Cách phát triển tiếp theo

Khi thêm một nghiệp vụ mới, ưu tiên tạo theo thứ tự:

1. `domain/entities` để định nghĩa dữ liệu nghiệp vụ.
2. `domain/repositories` để khai báo contract.
3. `domain/usecases` để đóng gói business logic.
4. `data/models`, `data/datasources`, `data/repositories` để hiện thực chi tiết.
5. `presentation` để gọi use case và render UI.
