import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'crypto_service.dart';
import 'key_manager.dart';

final cryptoServiceProvider = Provider<CryptoService>((_) => CryptoService());

final keyManagerProvider = Provider<KeyManager>((_) => KeyManager(
      _SecureStorageAdapter(const FlutterSecureStorage()),
    ));

final myDeviceIdProvider = FutureProvider<String>(
    (ref) => ref.watch(keyManagerProvider).deviceId());

class _SecureStorageAdapter implements KeyValueStore {
  final FlutterSecureStorage _s;
  _SecureStorageAdapter(this._s);
  @override
  Future<String?> read({required String key}) => _s.read(key: key);
  @override
  Future<void> write({required String key, required String value}) =>
      _s.write(key: key, value: value);
}
