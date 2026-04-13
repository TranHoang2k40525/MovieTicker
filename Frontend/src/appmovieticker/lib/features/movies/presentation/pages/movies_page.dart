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
      body: ListView.separated(
        itemCount: movies.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.movie),
            title: Text(movies[index]),
          );
        },
      ),
    );
  }
}
