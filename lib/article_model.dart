
class Article {
  final String title;
  final String? description;
  final String? urlToImage;
  final String? url;
  final String? source;
  final String? publishedAt;

  const Article({
    required this.title,
    this.description,
    this.urlToImage,
    this.url,
    this.source,
    this.publishedAt,
  });
}
