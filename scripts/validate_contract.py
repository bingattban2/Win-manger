#!/usr/bin/env python3
"""Offline contract consistency checks; no project dependencies beyond Python 3."""
from __future__ import annotations

import csv
import hashlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / 'docs'
REQUIRED = (
    'REQUIREMENTS.md',
    'BUSINESS_RULES.md',
    'DATA_MODEL.md',
    'SCREEN_SPECIFICATIONS.md',
    'PERMISSIONS.md',
    'TRACEABILITY_MATRIX.csv',
    'TEST_PLAN.md',
    'SOURCE_SPECIFICATION_REDACTED.txt',
    'PHASE_REPORT_00.md',
)


def check() -> None:
    for filename in REQUIRED:
        if not (DOCS / filename).is_file():
            raise AssertionError(f'Missing documentation: {filename}')
    source = (DOCS / 'SOURCE_SPECIFICATION_REDACTED.txt').read_text('utf-8')
    assert '<REDACTED_FOUNDATIONAL_PASSWORD>' in source
    phases = re.findall(r'^PHASE (\d\d) —', source, flags=re.MULTILINE)
    assert phases == [f'{p:02d}' for p in range(43)], 'Spec phase order incomplete'
    with (DOCS / 'TRACEABILITY_MATRIX.csv').open(encoding='utf-8-sig', newline='') as f:
        rows = list(csv.DictReader(f))
    assert len(rows) > 400, f'Insufficient atomic traceability: {len(rows)}'
    assert len({r['requirement_id'] for r in rows}) == len(rows)
    assert {r['phase'] for r in rows} == set(phases)
    line_count = len(source.splitlines())
    for row in rows:
        number = int(row['source_line'])
        assert 1 <= number <= line_count
        assert row['test_case_id'] == f"P{row['phase']}-ACCEPT"
        assert row['verification'] == 'NOT_RUN'
    # Secrets must never be embedded as literal credentials in the shipping source.
    # Only a one-way fingerprint of the prohibited literal is committed.
    prohibited_sha256 = '09e4b51b19c4a76f8462f0da43eed8b952d82eea82aed7750fab4134afc496e1'
    for path in [*ROOT.rglob('*.dart'), *ROOT.rglob('*.yaml'), *ROOT.rglob('*.yml'), *ROOT.rglob('*.md')]:
        content = path.read_text(encoding='utf-8')
        candidates = re.findall(r'[A-Za-z0-9]{12}', content)
        for candidate in candidates:
            assert hashlib.sha256(candidate.encode('utf-8')).hexdigest() != prohibited_sha256, (
                f'Plaintext credential in {path}')
    print('PASS: phase 00 documentation and all 43 phases are traceable.')
    print(f'PASS: {len(rows)} source-linked work items, 0 falsely verified.')
    print(f'Source SHA256 (redacted): {hashlib.sha256(source.encode()).hexdigest()}')


if __name__ == '__main__':
    check()
