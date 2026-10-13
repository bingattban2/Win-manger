#!/usr/bin/env python3
"""Reproducible phase-00 requirement extraction, offline and stdlib-only.

The source is the authoritative redacted specification kept under docs/.
Detailed human review is required before the requirements become immutable.
"""
from __future__ import annotations

import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs' / 'SOURCE_SPECIFICATION_REDACTED.txt'
OUTPUT = ROOT / 'docs' / 'TRACEABILITY_MATRIX.csv'
PHASE = re.compile(r'^PHASE (\d{2}) — (.+)$')
NUMERIC = re.compile(r'^\s*\d+\.\s+(.+)$')
BULLET = re.compile(r'^\s*[-•]\s+(.+)$')


def category(phase: str, text: str) -> str:
    s = text.lower()
    if phase in ('04', '05', '06') or any(x in s for x in ('database', 'sqlite', 'drift', 'foreign-key', 'migration')):
        return 'DATABASE'
    if phase in ('09', '31', '39') or any(x in s for x in ('authorization', 'credential', 'password', 'role', 'encrypt', 'key protection')):
        return 'SECURITY'
    if phase in ('14', '15', '28', '29', '30') or any(x in s for x in ('excel', 'workbook', 'export', 'import')):
        return 'IMPORT_EXPORT'
    if phase in ('03', '33', '34', '35', '41', '42') or any(x in s for x in ('windows', 'backup', 'installer', 'portable')):
        return 'PLATFORM'
    if phase in ('10', '20', '21', '32') or any(x in s for x in ('screen', 'display', 'button', 'filter', 'scroll')):
        return 'UI'
    if phase in ('40',) or 'test' in s or 'verif' in s:
        return 'TEST'
    return 'BUSINESS'


def main() -> None:
    lines = SOURCE.read_text(encoding='utf-8').splitlines()
    phase = None
    phase_name = ''
    counters = {}
    rows = []
    for lineno, line in enumerate(lines, 1):
        m = PHASE.match(line)
        if m:
            phase, phase_name = m.groups()
            counters.setdefault(phase, 0)
            continue
        if phase is None or line.startswith('PART VIII'):
            if line.startswith('PART VIII'):
                break
            continue
        item = NUMERIC.match(line) or BULLET.match(line)
        if not item:
            continue
        requirement = item.group(1).strip()
        # Exclude single-word visual labels and numbered sequences from examples.
        if len(requirement) < 9:
            continue
        counters[phase] += 1
        requirement_id = f'P{phase}-R{counters[phase]:03d}'
        rows.append({
            'requirement_id': requirement_id,
            'phase': phase,
            'category': category(phase, requirement),
            'requirement': requirement,
            'source_line': str(lineno),
            'test_case_id': f'P{phase}-ACCEPT',
            'phase_title': phase_name,
            'implementation': 'PLANNED',
            'verification': 'NOT_RUN',
        })
    if len(counters) != 43 or sorted(counters) != [f'{i:02d}' for i in range(43)]:
        raise RuntimeError('Missing a required engineering phase')
    with OUTPUT.open('w', encoding='utf-8-sig', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    print(f'Generated {len(rows)} traceable atomic work items across {len(counters)} phases.')


if __name__ == '__main__':
    main()
