import 'package:flutter/material.dart';

class MoviesPage extends StatelessWidget {
  const MoviesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final movies = [
      'Avengers: Endgame',
      'Spider-Man: No Way Home',
      'The Dark Knight',
      'Inception',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách phim'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.green.shade50,
            child: const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 8),
                Text(
                  '🎉 ĐĂNG NHẬP THÀNH CÔNG!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: movies.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.movie),
                  title: Text(movies[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
