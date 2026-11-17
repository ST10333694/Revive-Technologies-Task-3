import 'api_client.dart';

/// An active freelancer from the website's database.
class WebFreelancer {
  WebFreelancer({
    required this.id,
    required this.name,
    this.skill = '',
    this.bio = '',
    this.rating = 0,
    this.photoUrl,
    this.samples = const [],
  });

  final int id;
  final String name;
  final String skill;
  final String bio;
  final double rating;
  final String? photoUrl;
  final List<String> samples;

  static WebFreelancer fromJson(Map<String, dynamic> j) => WebFreelancer(
        id: (j['id'] as num).toInt(),
        name: j['name'] as String? ?? '',
        skill: j['skill'] as String? ?? '',
        bio: j['bio'] as String? ?? '',
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        photoUrl: j['photo_url'] as String?,
        samples: (j['samples'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      );
}

class WebFreelancerRepository {
  final _api = ApiClient();

  Future<List<WebFreelancer>> approved() async {
    final data = await _api.get('freelancers.php') as List<dynamic>;
    return data
        .map((e) => WebFreelancer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}