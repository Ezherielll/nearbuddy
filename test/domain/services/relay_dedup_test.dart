import 'package:flutter_test/flutter_test.dart';
import 'package:nearbuddy/core/constants.dart';

class RelayDeduplicator {
  final _seen = <String, DateTime>{};
  bool shouldRelay(String id) {
    final now = DateTime.now();
    _seen.removeWhere((_, t) =>
        now.difference(t).inSeconds > AppConstants.relayDeduplicationCacheSeconds);
    if (_seen.containsKey(id)) return false;
    _seen[id] = now;
    return true;
  }
}

void main() {
  test('first occurrence → relay', () => expect(RelayDeduplicator().shouldRelay('a'), isTrue));
  test('duplicate → skip', () {
    final d = RelayDeduplicator()..shouldRelay('a');
    expect(d.shouldRelay('a'), isFalse);
  });
  test('different IDs → both relay', () {
    final d = RelayDeduplicator()..shouldRelay('a');
    expect(d.shouldRelay('b'), isTrue);
  });
}
