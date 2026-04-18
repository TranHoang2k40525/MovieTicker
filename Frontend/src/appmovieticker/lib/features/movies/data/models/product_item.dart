class ProductItem {
  const ProductItem({
    required this.productId,
    this.nameProduct,
    this.imageProduct,
    this.imageUrl,
    this.description,
    this.price,
  });

  final int productId;
  final String? nameProduct;
  final String? imageProduct;
  final String? imageUrl;
  final String? description;
  final num? price;

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      productId: _readInt(json['productId'] ?? json['ProductId']),
      nameProduct: _readString(json['nameProduct'] ?? json['NameProduct']),
      imageProduct: _readString(json['imageProduct'] ?? json['ImageProduct']),
      imageUrl: _readString(json['imageUrl'] ?? json['ImageUrl']),
      description: _readString(json['description'] ?? json['Description']),
      price: _readNum(json['price'] ?? json['Price']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String? _readString(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  static num? _readNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}
