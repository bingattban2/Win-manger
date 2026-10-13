import 'package:adwas_personnel/core/audit/operation_audit.dart';
import 'package:adwas_personnel/core/errors/operation_failures.dart';
import 'package:adwas_personnel/core/security/account_policy.dart';
import 'package:adwas_personnel/core/security/authentication_service.dart';
import 'package:adwas_personnel/core/security/operation_authorizer.dart';
import 'package:adwas_personnel/core/transactions/closed_transaction_executor.dart';
import 'package:adwas_personnel/core/transactions/operation_pipeline.dart';
import 'package:adwas_personnel/features/sites/application/rename_site_operation.dart';
import 'package:adwas_personnel/features/sites/domain/site_record.dart';
import 'package:adwas_personnel/features/sites/repositories/site_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const originalSite = SiteRecord(
  id: 'site-1',
  name: 'الموقع الأول',
  normalizedName: 'الموقع الأول',
  isSystemSite: false,
  isActive: true,
  updatedAtUtc: '2026-10-13T12:00:00Z',
);

final testSession = LocalSession(
  accountId: 'user-1',
  token: 'fixture-session',
  lastActiveUtc: DateTime.utc(2026, 10, 13),
);

class Fixture {
  final Map<String, SiteRecord> sites = {'site-1': originalSite};
  final List<String> history = [];
  final List<OperationAuditEvent> events = [];

  Fixture duplicate() {
    final copy = Fixture();
    copy.sites
      ..clear()
      ..addAll(sites);
    copy.history.addAll(history);
    copy.events.addAll(events);
    return copy;
  }

  void restore(Fixture other) {
    sites
      ..clear()
      ..addAll(other.sites);
    history
      ..clear()
      ..addAll(other.history);
    events
      ..clear()
      ..addAll(other.events);
  }
}

class FixtureSiteRepository implements SiteRepository {
  FixtureSiteRepository(this.fixture);

  final Fixture fixture;
  bool failHistory = false;
  bool failPersistInvariant = false;
  bool failWrite = false;

  @override
  Future<SiteRecord?> byId(String siteId) async {
    final site = fixture.sites[siteId];
    if (failPersistInvariant && site != null && site.name != originalSite.name) {
      return originalSite;
    }
    return site;
  }

  @override
  Future<bool> nameInUse(String normalizedName, String excludedSiteId) async =>
      fixture.sites.values.any((site) =>
          site.id != excludedSiteId &&
          site.normalizedName == normalizedName &&
          site.isActive);

  @override
  Future<void> update(SiteRecord site) async {
    if (failWrite) throw StateError('Simulated write failure');
    fixture.sites[site.id] = site;
  }

  @override
  Future<void> appendRenameHistory({
    required String siteId,
    required String oldName,
    required String newName,
    required String actorId,
    required String auditEventId,
  }) async {
    if (failHistory) throw StateError('Simulated history failure');
    fixture.history.add('$siteId/$oldName/$newName/$actorId/$auditEventId');
  }
}

class FixtureTransactionExecutor implements TransactionExecutor {
  FixtureTransactionExecutor(this.fixture);

  final Fixture fixture;
  int commits = 0;
  int rollbacks = 0;

  @override
  Future<T> runInTransaction<T>(Future<T> Function() transactionBody) async {
    final before = fixture.duplicate();
    try {
      final result = await transactionBody();
      commits++;
      return result;
    } catch (_) {
      fixture.restore(before);
      rollbacks++;
      rethrow;
    }
  }
}

class FixtureAuditWriter implements OperationAuditWriter {
  FixtureAuditWriter(this.fixture);

  final Fixture fixture;
  bool fail = false;

  @override
  Future<void> append(OperationAuditEvent event) async {
    if (fail) throw StateError('Audit storage failed');
    fixture.events.add(event);
  }
}

class FixtureInvalidator implements OperationStateInvalidator {
  bool fail = false;
  int count = 0;

  @override
  Future<void> invalidate(String operationType, String targetId) async {
    count++;
    if (fail) throw StateError('UI projections unavailable');
  }
}

class FixtureAuthorizer implements OperationAuthorizer {
  AppRole role = AppRole.supervisor;
  bool active = true;
  int calls = 0;

  @override
  Future<AuthorizedOperator> require(
    LocalSession session,
    AppPermission permission,
  ) async {
    calls++;
    if (!active || session.accountId != 'user-1' ||
        !AccountPolicy.allows(role, permission)) {
      throw const PermissionDenied();
    }
    return AuthorizedOperator('user-1', role);
  }
}

class Harness {
  Harness()
      : fixture = Fixture(),
        authorizer = FixtureAuthorizer(),
        invalidator = FixtureInvalidator() {
    repository = FixtureSiteRepository(fixture);
    audit = FixtureAuditWriter(fixture);
    transactions = FixtureTransactionExecutor(fixture);
    coordinator = OperationCoordinator<RenameSiteCommand, SiteRecord, SiteRecord>(
      operation: RenameSiteOperation(repository),
      authorizer: authorizer,
      transactions: transactions,
      audit: audit,
      invalidator: invalidator,
      clock: () => DateTime.utc(2026, 10, 13, 19),
    );
  }

  final Fixture fixture;
  final FixtureAuthorizer authorizer;
  final FixtureInvalidator invalidator;
  late final FixtureSiteRepository repository;
  late final FixtureAuditWriter audit;
  late final FixtureTransactionExecutor transactions;
  late final OperationCoordinator<RenameSiteCommand, SiteRecord, SiteRecord>
      coordinator;

  Future<PreparedOperation<RenameSiteCommand>> prepare([String name = 'موقع جديد']) =>
      coordinator.prepare(
        session: testSession,
        command: RenameSiteCommand('site-1', name),
      );

  Future<OperationReceipt<SiteRecord>> execute(
    PreparedOperation<RenameSiteCommand> prepared, {
    bool confirmed = true,
  }) => coordinator.execute(
        session: testSession,
        prepared: prepared,
        confirmed: confirmed,
      );
}

void main() {
  test('prepare is read-only and produces old/new preview', () async {
    final h = Harness();
    final preview = await h.prepare(' موقع   جديد ');
    expect(preview.description.oldValues['name'], 'الموقع الأول');
    expect(preview.description.newValues['name'], 'موقع جديد');
    expect(h.fixture.sites['site-1']!.name, 'الموقع الأول');
    expect(h.fixture.history, isEmpty);
    expect(h.fixture.events, isEmpty);
    expect(h.transactions.commits, 0);
  });

  test('confirmation is mandatory, then commit is atomic and audited', () async {
    final h = Harness();
    final preview = await h.prepare();
    await expectLater(h.execute(preview, confirmed: false),
        throwsA(isA<OperationFailure>()));
    expect(h.transactions.commits, 0);
    final receipt = await h.execute(preview);
    expect(receipt.result.name, 'موقع جديد');
    expect(receipt.projectionUpdated, isTrue);
    expect(h.transactions.commits, 1);
    expect(h.fixture.history, hasLength(1));
    expect(h.fixture.events, hasLength(1));
    expect(h.fixture.events.single.id, receipt.auditEventId);
    expect(h.fixture.events.single.actorId, 'user-1');
    expect(h.fixture.events.single.executedAtUtc.isUtc, isTrue);
    expect(h.fixture.history.single, contains(receipt.auditEventId));
    expect(h.invalidator.count, 1);
  });

  test('preview is single-use and replay cannot cause second write', () async {
    final h = Harness();
    final preview = await h.prepare();
    await h.execute(preview);
    await expectLater(h.execute(preview), throwsA(isA<OperationFailure>()));
    expect(h.transactions.commits, 1);
    expect(h.fixture.history, hasLength(1));
  });

  test('stale preview is rejected inside transaction', () async {
    final h = Harness();
    final preview = await h.prepare();
    h.fixture.sites['site-1'] = originalSite.renamed('تعديل خارجي', 'تعديل خارجي', '2026-10-13T13:00:00Z');
    await expectLater(h.execute(preview), throwsA(isA<OperationFailure>()));
    expect(h.transactions.rollbacks, 1);
    expect(h.fixture.sites['site-1']!.name, 'تعديل خارجي');
    expect(h.fixture.history, isEmpty);
  });

  test('history failure rolls back the site mutation', () async {
    final h = Harness();
    final preview = await h.prepare();
    h.repository.failHistory = true;
    await expectLater(h.execute(preview), throwsStateError);
    expect(h.fixture.sites['site-1']!.name, 'الموقع الأول');
    expect(h.fixture.events, isEmpty);
    expect(h.transactions.rollbacks, 1);
  });

  test('audit failure rolls back mutation and history', () async {
    final h = Harness();
    final preview = await h.prepare();
    h.audit.fail = true;
    await expectLater(h.execute(preview), throwsStateError);
    expect(h.fixture.sites['site-1']!.name, 'الموقع الأول');
    expect(h.fixture.history, isEmpty);
    expect(h.transactions.rollbacks, 1);
  });

  test('invariant failure rolls back all preceding steps', () async {
    final h = Harness();
    final preview = await h.prepare();
    h.repository.failPersistInvariant = true;
    await expectLater(h.execute(preview), throwsStateError);
    expect(h.fixture.sites['site-1']!.name, 'الموقع الأول');
    expect(h.fixture.history, isEmpty);
    expect(h.fixture.events, isEmpty);
  });

  test('inactive account at confirm blocks all writes', () async {
    final h = Harness();
    final preview = await h.prepare();
    h.authorizer.active = false;
    await expectLater(h.execute(preview), throwsA(isA<PermissionDenied>()));
    expect(h.transactions.commits, 0);
    expect(h.fixture.history, isEmpty);
  });

  test('duplicate site name is rejected in transaction', () async {
    final h = Harness();
    h.fixture.sites['site-2'] = const SiteRecord(
      id: 'site-2',
      name: 'موقع جديد',
      normalizedName: 'موقع جديد',
      isSystemSite: false,
      isActive: true,
      updatedAtUtc: '2026-10-13T12:00:00Z',
    );
    final preview = await h.prepare();
    await expectLater(h.execute(preview), throwsA(isA<OperationFailure>()));
    expect(h.fixture.sites['site-1']!.name, 'الموقع الأول');
  });

  test('system sites cannot be renamed even before confirmation', () async {
    final h = Harness();
    h.fixture.sites['site-1'] = const SiteRecord(
      id: 'site-1',
      name: 'غير محدد',
      normalizedName: 'غير محدد',
      isSystemSite: true,
      isActive: true,
      updatedAtUtc: '2026-10-13T12:00:00Z',
    );
    await expectLater(h.prepare(), throwsA(isA<OperationFailure>()));
    expect(h.transactions.commits, 0);
  });

  test('post-commit refresh failure does not claim rollback', () async {
    final h = Harness();
    h.invalidator.fail = true;
    final receipt = await h.execute(await h.prepare());
    expect(receipt.projectionUpdated, isFalse);
    expect(h.transactions.commits, 1);
    expect(h.fixture.events, hasLength(1));
  });

  test('secure storage not installed means fail-closed execution', () async {
    final h = Harness();
    final coordinator = OperationCoordinator<RenameSiteCommand, SiteRecord,
        SiteRecord>(
      operation: RenameSiteOperation(h.repository),
      authorizer: h.authorizer,
      transactions: const ClosedTransactionExecutor(),
      audit: h.audit,
      invalidator: h.invalidator,
    );
    final preview = await coordinator.prepare(
      session: testSession,
      command: const RenameSiteCommand('site-1', 'تعديل'),
    );
    await expectLater(
      coordinator.execute(session: testSession, prepared: preview, confirmed: true),
      throwsA(isA<OperationFailure>()),
    );
    expect(h.fixture.history, isEmpty);
    expect(h.fixture.sites['site-1']!.name, 'الموقع الأول');
  });
}
