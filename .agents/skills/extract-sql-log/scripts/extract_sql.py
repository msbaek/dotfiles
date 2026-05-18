#!/usr/bin/env python3
"""Extract and format SQL statements from Spring Boot ActionRunner/p6spy logs.

Parses server logs containing:
  - actionSet JSON (ActionServiceImpl)
  - query(xxx) formatted SQL (QueryInfo)
  - p6spy inline SQL (duplicates, skipped)

Outputs formatted markdown with SQL grouped by actionSet.
"""

import re
import sys
import json
import argparse
from dataclasses import dataclass, field
from typing import Optional


# --- Masking patterns to detect in SQL string literals ---
MASKING_PATTERNS = [
    re.compile(r'\w+\*{2,}\w*'),       # te**@, code****name
    re.compile(r'\d+\*{2,}\d+'),       # 010****0000
    re.compile(r'^\*{3,}$'),           # *****
    re.compile(r'\w+\*{2,}@'),         # te**@
]

# Known masking fields per table (configurable via --masking-config)
DEFAULT_MASKING_FIELDS = {
    'SELL_DELIY_ADDR': ['ADDR1', 'ADDR2', 'RECIPIENT', 'RECIPIENT2', 'TEL', 'HP', 'SSN', 'SSN_ENC'],
    'SELL_DELIY_ADDR_ADD': ['PASS_NO', 'ACCT_NO', 'ACCT_NM', 'BIRTH'],
    'SELL_CER': ['TEL', 'HP', 'EMAIL'],
    'SELL': ['SSN', 'ACCT_NO'],
    'SELL_ADD': ['SSN', 'ACCT_NO'],
    'ONLINE_EVENT': ['USER_NM', 'CH_INFO', 'BIRTH', 'TEL'],
    'USER': ['USER_NM', 'EMAIL', 'TEL', 'HP'],
    'USER_DELIY_ADDR': ['ADDR1', 'ADDR2', 'RECIPIENT', 'TEL', 'HP'],
}


@dataclass
class ActionSetInfo:
    action_ids: list = field(default_factory=list)
    base_parms: dict = field(default_factory=dict)
    raw_json: str = ''


@dataclass
class SqlStatement:
    query_id: str
    sql: str
    sql_type: str           # INSERT, UPSERT, UPDATE, DELETE, SELECT, OTHER
    table_name: str
    actionset: Optional[ActionSetInfo] = None
    masked_values: list = field(default_factory=list)
    masking_field_access: list = field(default_factory=list)
    upsert_violations: list = field(default_factory=list)


# --- Parsing ---

def parse_log(text: str) -> list[SqlStatement]:
    """Parse log text, extract query() SQL blocks, skip p6spy duplicates."""
    lines = text.split('\n')
    results = []
    current_actionset = None
    current_query_id = None
    current_sql_lines = []

    # Patterns
    re_actionset = re.compile(r'actionSet:\s*(\{.+)')
    re_query = re.compile(r'query\((\w+)\):\s*(.*)')
    re_p6spy = re.compile(r'p6spy\s')
    re_timestamp = re.compile(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}')
    re_comment_prefix = re.compile(r'^--\s*')

    def flush():
        nonlocal current_query_id, current_sql_lines
        if current_query_id and current_sql_lines:
            sql = '\n'.join(current_sql_lines).strip()
            if sql:
                stmt = build_statement(current_query_id, sql, current_actionset)
                results.append(stmt)
        current_query_id = None
        current_sql_lines = []

    for raw_line in lines:
        line = raw_line.rstrip()

        # Strip comment prefix if present (user may paste with -- prefix)
        clean = re_comment_prefix.sub('', line).strip() if line.lstrip().startswith('--') else line

        # actionSet line
        as_match = re_actionset.search(clean)
        if as_match:
            flush()
            current_actionset = parse_actionset(as_match.group(1))
            continue

        # query(xxx) line
        q_match = re_query.search(clean)
        if q_match:
            flush()
            current_query_id = q_match.group(1)
            remainder = q_match.group(2).strip()
            if remainder:
                current_sql_lines.append(remainder)
            continue

        # p6spy line (skip - duplicate)
        if re_p6spy.search(line):
            flush()
            continue

        # Timestamp line without query/actionSet (new log entry = end of SQL block)
        if re_timestamp.match(line.strip()) and current_query_id:
            # Check if line contains SQL keywords (might be continuation)
            upper = line.upper()
            sql_kws = ['SELECT', 'INSERT', 'UPDATE', 'DELETE', 'FROM', 'WHERE',
                        'SET', 'VALUES', 'INTO', 'JOIN', 'LEFT', 'INNER', 'ORDER',
                        'GROUP', 'ON DUPLICATE', 'AND', 'OR', 'LIMIT']
            if not any(kw in upper for kw in sql_kws):
                flush()
                continue

        # Accumulate SQL lines
        if current_query_id:
            current_sql_lines.append(line)

    flush()
    return results


def parse_actionset(json_str: str) -> ActionSetInfo:
    """Parse actionSet JSON, extract action IDs and baseParms."""
    info = ActionSetInfo(raw_json=json_str[:300])
    try:
        data = json.loads(json_str)
        info.action_ids = [a.get('actionID', '') for a in data.get('actionList', [])]
        info.base_parms = data.get('baseParms', {})
    except (json.JSONDecodeError, AttributeError):
        pass
    return info


def build_statement(query_id: str, sql: str, actionset: Optional[ActionSetInfo]) -> SqlStatement:
    """Build a SqlStatement with classification and masking analysis."""
    sql_type = classify_sql(sql)
    table_name = extract_table(sql)

    stmt = SqlStatement(
        query_id=query_id,
        sql=sql,
        sql_type=sql_type,
        table_name=table_name,
        actionset=actionset,
    )

    # Detect masked values in string literals
    stmt.masked_values = detect_masked_values(sql)

    # Check UPSERT for masking field violations
    if sql_type == 'UPSERT':
        stmt.upsert_violations = check_upsert_violations(sql, table_name)

    # For SELECT, find masking field access
    if sql_type == 'SELECT':
        stmt.masking_field_access = find_masking_field_access(sql)

    return stmt


def classify_sql(sql: str) -> str:
    upper = sql.strip().upper()
    if upper.startswith('INSERT'):
        return 'UPSERT' if 'ON DUPLICATE KEY UPDATE' in upper else 'INSERT'
    if upper.startswith('UPDATE'):
        return 'UPDATE'
    if upper.startswith('DELETE'):
        return 'DELETE'
    if upper.startswith('SELECT'):
        return 'SELECT'
    return 'OTHER'


def extract_table(sql: str) -> str:
    upper = sql.strip().upper()
    for pattern in [
        r'INSERT\s+INTO\s+(\w+)',
        r'UPDATE\s+(\w+)',
        r'DELETE\s+FROM\s+(\w+)',
        r'FROM\s+(\w+)',
    ]:
        m = re.search(pattern, upper)
        if m:
            return m.group(1)
    return 'UNKNOWN'


def detect_masked_values(sql: str) -> list[str]:
    """Find string literals that look masked."""
    literals = re.findall(r"'([^']*)'", sql)
    masked = []
    for lit in literals:
        if not lit:
            continue
        for pat in MASKING_PATTERNS:
            if pat.search(lit):
                masked.append(lit)
                break
    return masked


def check_upsert_violations(sql: str, table_name: str) -> list[str]:
    """Check if ON DUPLICATE KEY UPDATE includes masking fields."""
    fields = DEFAULT_MASKING_FIELDS.get(table_name, [])
    if not fields:
        return []

    match = re.search(r'ON\s+DUPLICATE\s+KEY\s+UPDATE\s+(.+)', sql, re.IGNORECASE | re.DOTALL)
    if not match:
        return []

    update_part = match.group(1).upper()
    return [f for f in fields if re.search(rf'\b{f}\s*=', update_part)]


def find_masking_field_access(sql: str) -> list[str]:
    """Find masking fields read by SELECT."""
    upper = sql.upper()
    accessed = []
    for table, fields in DEFAULT_MASKING_FIELDS.items():
        for f in fields:
            if re.search(rf'\b{f}\b', upper):
                accessed.append(f'{table}.{f}')
    # Detect SELECT alias.* patterns
    star_aliases = re.findall(r'(\w+)\.\*', upper)
    for alias in star_aliases:
        if alias in DEFAULT_MASKING_FIELDS:
            for f in DEFAULT_MASKING_FIELDS[alias]:
                entry = f'{alias}.{f} (via *)'
                if entry not in accessed:
                    accessed.append(entry)
    return accessed


# --- Output ---

def format_markdown(stmts: list[SqlStatement], include_select: bool = False) -> str:
    out = ['# SQL Log Analysis\n']

    counter = 0
    issues = []

    for s in stmts:
        if not include_select and s.sql_type == 'SELECT':
            continue

        counter += 1

        # Badges
        badge = ''
        if s.upsert_violations:
            badge += ' ⚠️ MASKING VIOLATION'
            issues.append(('VIOLATION', s.query_id, s.table_name,
                          f'UPDATE includes: {", ".join(s.upsert_violations)}'))
        if s.masked_values:
            badge += ' ⚠️ MASKED DATA'
            issues.append(('MASKED', s.query_id, s.table_name,
                          f'Values: {", ".join(s.masked_values)}'))
        if s.sql_type == 'SELECT' and s.masking_field_access:
            badge += ' 🔒'

        out.append(f'### {counter}. query({s.query_id}) — {s.sql_type} → {s.table_name}{badge}\n')
        out.append('```sql')
        out.append(f'-- query_id: {s.query_id}')
        out.append(f'-- table: {s.table_name}')
        if s.masking_field_access:
            out.append(f'-- masking fields accessed: {", ".join(s.masking_field_access[:5])}')
        out.append(clean_sql(s.sql))
        out.append('```\n')

    # Summary
    out.append('\n---\n')
    if issues:
        out.append('## ⚠️ Masking Issues\n')
        out.append('| Type | query_id | Table | Detail |')
        out.append('|------|----------|-------|--------|')
        for typ, qid, tbl, detail in issues:
            out.append(f'| {typ} | {qid} | {tbl} | {detail} |')
    else:
        out.append('## ✅ No Masking Issues Found\n')

    # Stats
    type_counts = {}
    for s in stmts:
        type_counts[s.sql_type] = type_counts.get(s.sql_type, 0) + 1
    out.append(f'\n**Total: {len(stmts)} queries** — ' +
               ', '.join(f'{t}: {c}' for t, c in sorted(type_counts.items())))

    return '\n'.join(out)


def clean_sql(sql: str) -> str:
    """Remove empty lines, normalize whitespace."""
    lines = [l.rstrip() for l in sql.split('\n') if l.strip()]
    return '\n'.join(lines)


# --- Main ---

def main():
    parser = argparse.ArgumentParser(
        description='Extract SQL from ActionRunner/p6spy logs')
    parser.add_argument('input', nargs='?',
                       help='Log file path (default: stdin)')
    parser.add_argument('--all', '-a', action='store_true',
                       help='Include SELECT statements')
    parser.add_argument('--output', '-o',
                       help='Output markdown file')
    parser.add_argument('--json', action='store_true',
                       help='Output as JSON instead of markdown')
    args = parser.parse_args()

    text = open(args.input).read() if args.input else sys.stdin.read()
    stmts = parse_log(text)

    if args.json:
        data = [{
            'query_id': s.query_id,
            'sql_type': s.sql_type,
            'table': s.table_name,
            'masked_values': s.masked_values,
            'upsert_violations': s.upsert_violations,
            'masking_field_access': s.masking_field_access,
            'sql': s.sql,
        } for s in stmts if args.all or s.sql_type != 'SELECT']
        result = json.dumps(data, indent=2, ensure_ascii=False)
    else:
        result = format_markdown(stmts, include_select=args.all)

    if args.output:
        with open(args.output, 'w') as f:
            f.write(result)
        print(f'Written to {args.output}', file=sys.stderr)
    else:
        print(result)


if __name__ == '__main__':
    main()
