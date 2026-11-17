import '../services/image_service.dart';
import 'decor_event.dart';
import 'decor_theme.dart';

/// The event being built while the decorator moves through the steps.
/// The same object is passed from screen to screen.
class EventDraft {
  EventDraft(this.id);

  final String id;
  String name = '';
  String type = eventTypes.first;
  String location = '';
  DateTime? date;
  final List<PickedPhoto> photos = [];
  DecorTheme? theme;
  final Map<String, EventLine> lines = {};

  /// The first photo is the cover. Kept so the existing save step still compiles.
  PickedPhoto? get cover => photos.isEmpty ? null : photos.first;

  int get itemsCents => lines.values.fold(0, (sum, l) => sum + l.lineCents);
}