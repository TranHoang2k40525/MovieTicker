# Payment Bucket

Chức năng này xử lý thanh toán và mô phỏng thanh toán.

## Vai Trò

- `domain`: payment entity, repository contract, use case thanh toán.
- `data`: datasource thanh toán và model response.
- `presentation`: màn hình thanh toán thật hoặc mô phỏng.

## File Hiện Có

- [checkout_payment_page.dart](presentation/pages/payment/checkout_payment_page.dart)
- [payment_simulation_page.dart](presentation/pages/payment/payment_simulation_page.dart)
- [payment_remote_datasource.dart](data/datasources/payment/payment_remote_datasource.dart)

## Ghi Chú

- Nếu luồng checkout đang dùng payment trực tiếp, nên tách checkout và payment thành hai lớp nghiệp vụ riêng.
