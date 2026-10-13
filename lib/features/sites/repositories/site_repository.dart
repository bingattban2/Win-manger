import 'package:adwas_personnel/features/sites/domain/site_record.dart';

/// Inject an encrypted-SQLite implementation; test fixtures are separate.
abstract interface class SiteRepository {
  Future<SiteRecord?> byId(String siteId);
  Future<bool> nameInUse(String normalizedName, String excludedSiteId);
  Future<void> update(SiteRecord site);
  Future<void> appendRenameHistory({
    required String siteId,
    required String oldName,
    required String newName,
    required String actorId,
    required String auditEventId,
  });
}
