import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../data/datasources/movies_remote_datasource.dart';
import '../../data/models/product_item.dart';

enum _StoreTab { combo, product }

class StoreCatalogPage extends StatefulWidget {
  const StoreCatalogPage({super.key});

  @override
  State<StoreCatalogPage> createState() => _StoreCatalogPageState();
}

class _StoreCatalogPageState extends State<StoreCatalogPage> {
  final MoviesRemoteDataSource _remoteDataSource = di.sl<MoviesRemoteDataSource>();

  bool _loading = true;
  String? _error;
  List<ProductItem> _allItems = const [];
  _StoreTab _tab = _StoreTab.combo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final products = await _remoteDataSource.getProducts();
      if (!mounted) return;
      setState(() {
        _allItems = products;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được store';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  bool _isCombo(ProductItem item) {
    final name = (item.nameProduct ?? '').toLowerCase();
    return name.contains('combo');
  }

  List<ProductItem> get _filtered {
    if (_tab == _StoreTab.combo) {
      final combos = _allItems.where(_isCombo).toList();
      if (combos.isNotEmpty) return combos;
      return _allItems;
    }

    final products = _allItems.where((x) => !_isCombo(x)).toList();
    if (products.isNotEmpty) return products;
    return _allItems;
  }

  String _resolveImageUrl(ProductItem item) {
    final raw = item.imageUrl ?? item.imageProduct;
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final fileName = raw.split('\\').last.split('/').last;
    return '${ApiConstants.mediaBaseUrl}/assets/Images/PRODUCT/$fileName';
  }

  String _money(num? value) => '${(value ?? 0).toStringAsFixed(0)} đ';

  void _showDetail(ProductItem item) {
    final imageUrl = _resolveImageUrl(item);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.68,
          minChildSize: 0.48,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF7E7A6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB78E2D),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 120,
                          height: 120,
                          color: const Color(0xFFF1D670),
                          child: imageUrl.isEmpty
                              ? const Icon(Icons.local_movies_rounded, size: 54, color: Color(0xFFB78E2D))
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.local_movies_rounded, size: 54, color: Color(0xFFB78E2D)),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nameProduct ?? 'Sản phẩm',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4D3412),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _money(item.price),
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFFE44332),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mô tả',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4D3412),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description ?? 'Chưa có mô tả.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF3F2A0F),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(title: const Text('Store')),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _StoreTabButton(
                  title: 'Combo',
                  selected: _tab == _StoreTab.combo,
                  onTap: () => setState(() => _tab = _StoreTab.combo),
                ),
                _StoreTabButton(
                  title: 'Sản phẩm',
                  selected: _tab == _StoreTab.product,
                  onTap: () => setState(() => _tab = _StoreTab.product),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : items.isEmpty
                        ? const Center(child: Text('Không có dữ liệu'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final imageUrl = _resolveImageUrl(item);
                                return InkWell(
                                  onTap: () => _showDetail(item),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE9E9E9)),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: SizedBox(
                                            width: 70,
                                            height: 70,
                                            child: imageUrl.isEmpty
                                                ? Container(color: const Color(0xFFF2F2F2), child: const Icon(Icons.fastfood_rounded))
                                                : Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>
                                                        Container(color: const Color(0xFFF2F2F2), child: const Icon(Icons.fastfood_rounded)),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.nameProduct ?? 'Sản phẩm',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item.description ?? 'Xem chi tiết để biết thêm thông tin',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF616161)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _money(item.price),
                                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFE44332)),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemCount: items.length,
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _StoreTabButton extends StatelessWidget {
  const _StoreTabButton({required this.title, required this.selected, required this.onTap});

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: selected ? const Color(0xFFE44332) : Colors.transparent, width: 2)),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFFE44332) : const Color(0xFF333333),
            ),
          ),
        ),
      ),
    );
  }
}
