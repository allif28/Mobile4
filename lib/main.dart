
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';
import 'article_model.dart';

void main() {
  runApp(const NewsApp());
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Berita Terkini',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2457C5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2457C5),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
      ),
      home: const NewsHomePage(),
    );
  }
}

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({super.key});

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  final ApiService apiService = ApiService();
  final ScrollController scrollController = ScrollController();

  late Future<List<Article>> newsFuture;
  bool showBackToTop = false;

  @override
  void initState() {
    super.initState();

    newsFuture = apiService.fetchArticles();

    scrollController.addListener(() {
      final shouldShow = scrollController.offset > 300;

      if (shouldShow != showBackToTop && mounted) {
        setState(() {
          showBackToTop = shouldShow;
        });
      }
    });
  }

  Future<void> refreshNews() async {
    final future = apiService.fetchArticles();

    setState(() {
      newsFuture = future;
    });

    try {
      await future;
    } catch (_) {
    }
  }

  Future<void> openNews(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return;
    }

    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link berita tidak dapat dibuka.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat membuka berita.'),
          ),
        );
      }
    }
  }

  void backToTop() {
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'Tanggal tidak tersedia';
    }

    try {
      final parsedDate = DateTime.parse(
        date,
      );

      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (_) {
      return date;
    }
  }

  Widget buildNewsCard(Article article) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 18),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.urlToImage != null &&
              article.urlToImage!.isNotEmpty)
            Image.network(
              article.urlToImage!,
              width: double.infinity,
              height: 210,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 130,
                  width: double.infinity,
                  color: const Color(0xFFE7ECF5),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: Colors.blueGrey,
                  ),
                );
              },
            ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sumber berita.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    article.source ?? 'Sumber berita',
                    style: const TextStyle(
                      color: Color(0xFF2457C5),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                    color: Color(0xFF18243A),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  article.description ?? 'Deskripsi tidak tersedia.',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF5E687A),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        formatDate(article.publishedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => openNews(article.url),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Baca Selengkapnya'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2457C5),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.newspaper, size: 29),
            SizedBox(width: 10),
            Text(
              'Berita Terkini',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Muat ulang berita',
            onPressed: refreshNews,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: refreshNews,
        child: FutureBuilder<List<Article>>(
          future: newsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(
                    child: CircularProgressIndicator(),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text('Sedang memuat berita...'),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  const Icon(
                    Icons.cloud_off,
                    size: 70,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Berita gagal dimuat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: FilledButton.icon(
                      onPressed: refreshNews,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ),
                ],
              );
            }

            final articles = snapshot.data ?? [];

            if (articles.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  Icon(
                    Icons.article_outlined,
                    size: 60,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text('Belum ada berita tersedia.'),
                  ),
                ],
              );
            }

            return ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              children: [
                const Text(
                  'Berita Terbaru',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18243A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${articles.length} berita dari BBC News',
                  style: const TextStyle(
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 20),

                ...articles.map(buildNewsCard),

                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Sumber berita: BBC News RSS',
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),

      floatingActionButton: showBackToTop
          ? FloatingActionButton(
              onPressed: backToTop,
              tooltip: 'Kembali ke atas',
              backgroundColor: const Color(0xFF2457C5),
              foregroundColor: Colors.white,
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
