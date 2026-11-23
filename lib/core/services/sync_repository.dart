/// Uzak senkronizasyon arayüzü.
///
/// v1'de BACKEND YOKTUR: tüm veri telefonda kalır. Bu arayüz,
/// gelecekte (örn. Firebase) eklenebilsin diye bırakılmıştır.
/// Uygulama her yerde bu arayüzü kullanır; gerçek uygulaması
/// [NoOpSyncRepository]'dir ve hiçbir yere veri göndermez.
library;

enum SyncStatus { disabled, idle, syncing, error }

class SyncState {
  const SyncState({
    required this.status,
    this.lastSyncedAt,
    this.messageTr,
  });

  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? messageTr;
}

abstract interface class SyncRepository {
  /// Senkronizasyon açık mı?
  bool get isEnabled;

  Stream<SyncState> watchState();

  /// Yerel değişiklikleri uzak sunucuya gönderir.
  Future<void> pushAll();

  /// Uzak değişiklikleri çeker.
  Future<void> pullAll();

  /// Paylaşılabilir özet üretir (yakın modu).
  /// v1'de bu metin cihazda oluşturulur ve kullanıcı paylaşır.
  Future<String> buildShareSummary({required Duration window});
}

/// v1 uygulaması: hiçbir yere veri göndermez.
class NoOpSyncRepository implements SyncRepository {
  const NoOpSyncRepository();

  @override
  bool get isEnabled => false;

  @override
  Stream<SyncState> watchState() => Stream.value(
        const SyncState(
          status: SyncStatus.disabled,
          messageTr: 'Uzak senkronizasyon kapalı. Tüm veri yalnızca '
              'bu telefonda tutuluyor.',
        ),
      );

  @override
  Future<void> pushAll() async {
    throw UnsupportedError(
      'v1\'de uzak senkronizasyon yoktur. Özeti paylaşmak için '
      'Yakın Modu ekranındaki paylaş düğmesini kullan.',
    );
  }

  @override
  Future<void> pullAll() async {
    throw UnsupportedError('v1\'de uzak senkronizasyon yoktur.');
  }

  @override
  Future<String> buildShareSummary({required Duration window}) async {
    throw UnsupportedError(
      'Özet üretimi CaregiverService tarafından yapılır.',
    );
  }
}
