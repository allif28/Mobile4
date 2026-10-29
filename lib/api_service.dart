
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import 'article_model.dart';

class ApiService {
  static const String _feedUrl =
      'https://feeds.bbci.co.uk/news/rss.xml';

  static const String _proxyUrl =
      'https://proxy.cors.dev/';

  Future<List<Article>> fetchArticles() async {
    try {
      final uri = Uri.parse('$_proxyUrl$_feedUrl');

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil berita. HTTP ${response.statusCode}',
        );
      }

      final document = XmlDocument.parse(response.body);
      final items = document.findAllElements('item');

      final List<Article> articles = [];

      for (final item in items) {
        String getText(String tag) {
          final elements = item.findElements(tag);

          if (elements.isEmpty) {
            return '';
          }

          return elements.first.innerText.trim();
        }

        final title = getText('title');
        final description = getText('description');
        final link = getText('link');
        final publishedAt = getText('pubDate');

        String imageUrl = '';

        for (final element in item.descendants.whereType<XmlElement>()) {
          final tagName = element.name.local;

          if (tagName == 'thumbnail' || tagName == 'content') {
            final urlAttribute = element.getAttribute('url');

            if (urlAttribute != null &&
                urlAttribute.startsWith('http')) {
              imageUrl = urlAttribute;
              break;
            }
          }
        }

        if (title.isEmpty) {
          continue;
        }

        articles.add(
          Article(
            title: title,
            description: description.isEmpty
                ? 'Tidak ada deskripsi berita.'
                : description,
            url: link,
            source: 'BBC News',
            publishedAt: publishedAt,
            urlToImage: imageUrl.isEmpty ? null : imageUrl,
          ),
        );
      }

      if (articles.isEmpty) {
        throw Exception('Tidak ada berita yang ditemukan.');
      }

      return articles;
    } catch (e) {
      throw Exception('Gagal memuat berita: $e');
    }
  }
}
