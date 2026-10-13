#!/usr/bin/env python3
"""Set Arabic Windows window/resource metadata on the generated Flutter runner.

The Dart package and CMake binary name stay ASCII for maximum toolchain
compatibility. The release-packaging step separately renames the deliverable.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import re

ARABIC_NAME = 'التمام اليومي'
CPP_WIDE_LITERAL = 'L"' + ''.join(f'\\u{ord(character):04x}' for character in ARABIC_NAME) + '"'


def patch_runner(windows: Path) -> None:
    source = windows / 'runner' / 'main.cpp'
    resource = windows / 'runner' / 'Runner.rc'
    if not source.is_file() or not resource.is_file():
        raise FileNotFoundError('Missing Flutter-generated Windows runner files')

    cpp = source.read_text(encoding='utf-8-sig')
    patched_cpp, changes = re.subn(
        r'(\bwindow\.Create(?:AndShow)?\s*\(\s*)L"[^"]*"',
        lambda match: match.group(1) + CPP_WIDE_LITERAL,
        cpp,
    )
    if changes != 1:
        raise RuntimeError(f'Expected one Windows window title, found {changes}')

    rc = resource.read_text(encoding='utf-8-sig')
    if '#pragma code_page(65001)' not in rc:
        rc = '#pragma code_page(65001)\n' + rc

    # Update only the friendly title strings; keep the internal DLL/EXE names.
    for attribute in ('FileDescription', 'ProductName'):
        expression = r'(\bVALUE\s+"' + attribute + r'",\s*)"[^"]*"'
        rc, changes = re.subn(
            expression,
            lambda match: match.group(1) + '"' + ARABIC_NAME + '"',
            rc,
        )
        if changes != 1:
            raise RuntimeError(f'Expected one {attribute} resource, found {changes}')

    source.write_text(patched_cpp, encoding='utf-8', newline='\n')
    resource.write_text(rc, encoding='utf-8', newline='\n')


def check_runner(windows: Path) -> None:
    main = (windows / 'runner' / 'main.cpp').read_text(encoding='utf-8-sig')
    rc = (windows / 'runner' / 'Runner.rc').read_text(encoding='utf-8-sig')
    if CPP_WIDE_LITERAL not in main:
        raise AssertionError('Windows C++ window title has not been localized')
    if '#pragma code_page(65001)' not in rc:
        raise AssertionError('Windows resource is missing UTF-8 declaration')
    for attribute in ('FileDescription', 'ProductName'):
        if not re.search(r'\bVALUE\s+"' + attribute + r'",\s*"' + ARABIC_NAME + r'"', rc):
            raise AssertionError(f'Wrong Windows resource: {attribute}')


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--windows', type=Path, default=Path(__file__).resolve().parents[1] / 'windows')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    if not args.check:
        patch_runner(args.windows)
    check_runner(args.windows)
    print('PASS: Arabic Windows window title and resource metadata verified.')


if __name__ == '__main__':
    main()
