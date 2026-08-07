import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/uuid_generator.dart';
import '../../data/database/app_database.dart';

final dmSessionsProvider = StreamProvider<List<SessionRow>>(
    (ref) => ref.watch(sessionsDaoProvider).watchAllSessions());

final dmControllerProvider = Provider<DmController>((ref) => DmController(ref));

class DmController {
  final Ref _ref;
  DmController(this._ref);

  /// Returns the existing session for the peer, or creates a new one.
  Future<String> startDm(String peerDeviceId, String peerNickname) async {
    final dao = _ref.read(sessionsDaoProvider);
    final existing = await dao.sessionForPeer(peerDeviceId);
    if (existing != null) return existing.id;
    final id = UuidGenerator.generate();
    await dao.upsertSession(SessionsCompanion.insert(
      id: id, peerDeviceId: peerDeviceId, peerNickname: peerNickname,
      createdAt: DateTime.now(),
    ));
    return id;
  }
}
