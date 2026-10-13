"""Static architecture checks supplement the real Dart pipeline unit tests."""
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "lib"


class PartVIArchitectureTests(unittest.TestCase):
    def test_00_gitignore_keeps_feature_layers_trackable(self):
        """Check the actual Git ignore engine, not a fragile text substring.

        Root-level backup/data directories must remain excluded, while
        feature source directories (including lib/features/backups) must
        always remain trackable in GitHub. The test works in a fresh checkout
        and independently of the GitHub uploader used by the developer.
        """
        features = (
            "authentication", "dashboard", "personnel", "sites", "statuses",
            "imports", "exports", "preparation", "monthly_accountability",
            "internal_transfers", "external_transfers", "dismissals",
            "archives", "reports", "users", "backups", "settings",
        )
        layers = ("presentation", "application", "domain", "repositories", "infrastructure")
        source_markers = [
            f"lib/features/{feature}/{layer}/.gitkeep"
            for feature in features for layer in layers
        ]
        private_paths = [
            "backups/backup.zip", "data/local-storage.bin",
            "user_data/private-export.zip", "private/access.txt",
            "secrets/credential.txt", "anywhere/personnel.db",
        ]
        with tempfile.TemporaryDirectory() as directory:
            temp = Path(directory)
            (temp / ".gitignore").write_text(
                (ROOT / ".gitignore").read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            subprocess.run(
                ["git", "init", "-q"], cwd=temp, check=True,
                capture_output=True, text=True,
            )
            process = subprocess.run(
                ["git", "check-ignore", "--no-index", "-v", "--stdin"],
                cwd=temp,
                input="\n".join(source_markers + private_paths) + "\n",
                capture_output=True, text=True,
            )
            self.assertIn(process.returncode, (0, 1), process.stderr)
            ignored = {
                line.split("\t", 1)[1].strip()
                for line in process.stdout.splitlines() if "\t" in line
            }
            excluded_source = sorted(set(source_markers) & ignored)
            self.assertEqual(excluded_source, [], f"Source tree ignored by Git: {excluded_source}")
            missing_protection = sorted(set(private_paths) - ignored)
            self.assertEqual(missing_protection, [], f"Private storage is not ignored: {missing_protection}")

    def test_01_feature_boundaries_exist(self):
        features = (
            "authentication", "dashboard", "personnel", "sites", "statuses",
            "imports", "exports", "preparation", "monthly_accountability",
            "internal_transfers", "external_transfers", "dismissals", "archives",
            "reports", "users", "backups", "settings",
        )
        for feature in features:
            for layer in ("presentation", "application", "domain", "repositories", "infrastructure"):
                self.assertTrue((LIB / "features" / feature / layer).is_dir(), (feature, layer))

    def test_02_shared_architecture_exists(self):
        required = (
            "bootstrap/service_container.dart", "app/navigation/role_navigation_policy.dart",
            "core/errors/operation_failures.dart", "core/errors/error_translator.dart",
            "core/audit/operation_audit.dart", "core/transactions/operation_pipeline.dart",
            "core/transactions/closed_transaction_executor.dart",
            "core/security/operation_authorizer.dart",
            "features/sites/repositories/site_repository.dart",
            "features/sites/application/rename_site_operation.dart",
        )
        for path in required:
            self.assertTrue((LIB / path).exists(), path)

    def test_03_required_atomic_steps_present(self):
        body = (LIB / "core/transactions/operation_pipeline.dart").read_text(encoding="utf-8")
        operations = ("operation.normalize(", "operation.validate(",
                      "authorizer.require(", "operation.readCurrent(",
                      "operation.checkPreconditions(", "operation.describe(",
                      "if (!confirmed)", "transactions.runInTransaction(",
                      "operation.apply(", "operation.recordHistory(",
                      "audit.append(", "operation.checkInvariants(",
                      "invalidator.invalidate(")
        for step in operations:
            self.assertIn(step, body, step)
        self.assertLess(body.index("operation.apply("), body.index("operation.recordHistory("))
        self.assertLess(body.index("operation.recordHistory("), body.index("audit.append("))
        self.assertLess(body.index("audit.append("), body.index("operation.checkInvariants("))
        self.assertLess(body.index("operation.checkInvariants("), body.index("invalidator.invalidate("))

    def test_04_no_repository_calls_or_sql_in_widgets(self):
        for path in (LIB / "features").rglob("*.dart"):
            if "presentation" not in path.parts:
                continue
            source = path.read_text(encoding="utf-8")
            for forbidden in ("INSERT INTO ", "UPDATE app_users ",
                              "DELETE FROM ", "sqlite3_open(", ".runInTransaction("):
                self.assertNotIn(forbidden, source, str(path))

    def test_05_sqlite_fail_closed(self):
        source = (LIB / "core/transactions/closed_transaction_executor.dart").read_text(encoding="utf-8")
        self.assertIn("throw const OperationFailure(", source)
        self.assertIn("persistenceUnavailable", source)
        self.assertNotIn("await transactionBody()", source)

    def test_06_no_direct_network_dependencies(self):
        pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
        for dependency in ("supabase_flutter:", "firebase_core:", "http:", "dio:"):
            self.assertNotIn("  " + dependency, pubspec)

    def test_07_names_and_artifacts(self):
        self.assertIn("0.0.6+6", (ROOT / "pubspec.yaml").read_text(encoding="utf-8"))
        metadata = (LIB / "core/config/project_info.dart").read_text(encoding="utf-8")
        self.assertIn("التمام اليومي", metadata)
        script = (ROOT / "scripts/package_windows.ps1").read_text(encoding="utf-8")
        self.assertIn("Altamam_AlYawmi_Part_VI_Windows_x64.zip", script)

    def test_08_cache_retained(self):
        workflow = (ROOT / ".github/workflows/windows-foundation.yml").read_text(encoding="utf-8")
        self.assertRegex(workflow, r"cache:\s*true")
        self.assertRegex(workflow, r"pub-cache:\s*true")
        self.assertIn("flutter build windows --release", workflow)

    def test_09_pipeline_tests_cover_rollback_and_replay(self):
        tests = (ROOT / "test/unit/operation_pipeline_test.dart").read_text(encoding="utf-8")
        for phrase in ("rolls back", "single-use", "stale preview", "confirmation", "fail-closed"):
            self.assertIn(phrase, tests)


if __name__ == "__main__":
    unittest.main()
