/// Immutable site identity; label changes never change the stable ID.
class SiteRecord {
  const SiteRecord({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.isSystemSite,
    required this.isActive,
    required this.updatedAtUtc,
  });

  final String id;
  final String name;
  final String normalizedName;
  final bool isSystemSite;
  final bool isActive;
  final String updatedAtUtc;

  SiteRecord renamed(String displayName, String normalized, String timestampUtc) => SiteRecord(
    id: id,
    name: displayName,
    normalizedName: normalized,
    isSystemSite: isSystemSite,
    isActive: isActive,
    updatedAtUtc: timestampUtc,
  );
}
