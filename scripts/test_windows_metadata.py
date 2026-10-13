"""Run with: python -m unittest discover -s scripts -p 'test_*.py'"""
import tempfile
from pathlib import Path
import unittest

from patch_windows_metadata import ARABIC_NAME, CPP_WIDE_LITERAL, check_runner, patch_runner


class WindowsMetadataTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.windows = Path(self.tmp.name)
        runner = self.windows / 'runner'
        runner.mkdir()
        (runner / 'main.cpp').write_text(
            'if (!window.Create(L"adwas_personnel", origin, size)) { return 1; }\n',
            encoding='utf-8',
        )
        (runner / 'Runner.rc').write_text(
            'VALUE "FileDescription", "adwas_personnel" "\\0"\n'
            'VALUE "InternalName", "adwas_personnel" "\\0"\n'
            'VALUE "ProductName", "adwas_personnel" "\\0"\n',
            encoding='utf-8',
        )

    def tearDown(self):
        self.tmp.cleanup()

    def test_changes_arabic_title_without_changing_internal_binary_name(self):
        patch_runner(self.windows)
        check_runner(self.windows)
        cpp = (self.windows / 'runner' / 'main.cpp').read_text(encoding='utf-8')
        rc = (self.windows / 'runner' / 'Runner.rc').read_text(encoding='utf-8')
        self.assertIn(CPP_WIDE_LITERAL, cpp)
        self.assertIn(ARABIC_NAME, rc)
        self.assertIn('VALUE "InternalName", "adwas_personnel"', rc)

    def test_remains_identical_when_run_twice(self):
        patch_runner(self.windows)
        before = tuple((self.windows / 'runner' / n).read_bytes() for n in ('main.cpp', 'Runner.rc'))
        patch_runner(self.windows)
        after = tuple((self.windows / 'runner' / n).read_bytes() for n in ('main.cpp', 'Runner.rc'))
        self.assertEqual(before, after)

    def test_rejects_unrecognized_flutter_runner(self):
        (self.windows / 'runner' / 'main.cpp').write_text('int main() {}', encoding='utf-8')
        with self.assertRaisesRegex(RuntimeError, 'one Windows window title'):
            patch_runner(self.windows)


if __name__ == '__main__':
    unittest.main()
