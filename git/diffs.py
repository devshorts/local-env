#!/usr/bin/env python3
"""Structured diff analysis for PRs.

Outputs JSON with per-file stats, bucket categorization, and import-noise
stripping -- everything the /git:pr skill needs in a single invocation.

To customize: edit BUCKET_RULES and IMPORT_NOISE_PATTERNS below.
"""

import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import PurePosixPath


# ---------------------------------------------------------------------------
# Configuration -- edit these to add buckets, rules, or noise patterns
# ---------------------------------------------------------------------------

@dataclass
class BucketRule:
    """A single rule that maps file paths to buckets.

    Match types:
      - "dir":      path contains this directory segment (e.g. "models/")
      - "prefix":   filename starts with this string
      - "suffix":   filename ends with this string (or tuple of strings)
      - "regex":    filename matches this regex
      - "header":   file content starts with this text (checked in a second pass)
    """
    bucket: str
    match_type: str  # dir | prefix | suffix | regex | header
    pattern: str | tuple[str, ...]


# Rules are evaluated top-to-bottom; first match wins.
BUCKET_RULES: list[BucketRule] = [
    # -- Auto-generated --
    BucketRule("auto_generated", "dir",    "models/"),
    BucketRule("auto_generated", "regex",  r"generated\..*\.tf$"),
    # Header-based detection runs as a second pass on files still marked "core"
    BucketRule("auto_generated", "header", "Auto-generated"),

    # -- Tests --
    BucketRule("tests", "dir",    "tests/"),
    BucketRule("tests", "prefix", "test_"),
    BucketRule("tests", "suffix", (".spec.ts", ".spec.tsx", ".test.ts", ".test.tsx")),

    # -- Docs --
    BucketRule("docs", "suffix", ".md"),
    BucketRule("docs", "dir",    "docs/"),
]

DEFAULT_BUCKET = "core"

# Patterns for lines considered "import noise" in diffs, keyed by extension.
# Each regex is matched against diff lines starting with + or -.
IMPORT_NOISE_PATTERNS: dict[str, re.Pattern] = {
    ".py":  re.compile(r"^[+-](import |from .+ import )"),
    ".ts":  re.compile(r"^[+-](import |export )"),
    ".tsx": re.compile(r"^[+-](import |export )"),
}

# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------


def run(cmd: list[str]) -> str:
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(json.dumps({"error": result.stderr.strip()}))
        sys.exit(1)
    return result.stdout


def merge_base(base_branch: str) -> str:
    return run(["git", "merge-base", base_branch, "HEAD"]).strip()


def categorize(path: str) -> str:
    """Categorize a file path using BUCKET_RULES (skips header rules)."""
    name = PurePosixPath(path).name

    for rule in BUCKET_RULES:
        if rule.match_type == "header":
            continue  # handled in second pass
        if rule.match_type == "dir" and rule.pattern in path:
            return rule.bucket
        if rule.match_type == "prefix" and name.startswith(rule.pattern):
            return rule.bucket
        if rule.match_type == "suffix" and name.endswith(rule.pattern):
            return rule.bucket
        if rule.match_type == "regex" and re.match(rule.pattern, name):
            return rule.bucket

    return DEFAULT_BUCKET


def check_header_rules(files: list[dict]) -> None:
    """Second pass: reclassify files that match header-based rules."""
    header_rules = [r for r in BUCKET_RULES if r.match_type == "header"]
    if not header_rules:
        return

    for f in files:
        if f["bucket"] != DEFAULT_BUCKET:
            continue
        try:
            content = run(["git", "show", f"HEAD:{f['path']}"])
        except SystemExit:
            continue  # deleted file
        first_chunk = content[:500].lower()
        for rule in header_rules:
            if rule.pattern.lower() in first_chunk and "do not edit" in first_chunk:
                f["bucket"] = rule.bucket
                break


def count_import_lines(diff_text: str, ext: str) -> dict[str, int]:
    pattern = IMPORT_NOISE_PATTERNS.get(ext)
    if not pattern:
        return {"added": 0, "removed": 0}

    added = removed = 0
    for line in diff_text.splitlines():
        if pattern.match(line):
            if line.startswith("+"):
                added += 1
            elif line.startswith("-"):
                removed += 1
    return {"added": added, "removed": removed}


def aggregate(files: list[dict]) -> dict:
    """Compute per-bucket totals and core-logic-only stats."""
    buckets: dict[str, dict] = {}
    for f in files:
        b = f["bucket"]
        if b not in buckets:
            buckets[b] = {"insertions": 0, "deletions": 0, "file_count": 0}
        buckets[b]["insertions"] += f["insertions"]
        buckets[b]["deletions"] += f["deletions"]
        buckets[b]["file_count"] += 1

    core_import_ins = sum(
        f.get("import_insertions", 0) for f in files if f["bucket"] == DEFAULT_BUCKET
    )
    core_import_dels = sum(
        f.get("import_deletions", 0) for f in files if f["bucket"] == DEFAULT_BUCKET
    )
    core = buckets.get(DEFAULT_BUCKET, {"insertions": 0, "deletions": 0, "file_count": 0})

    return {
        "buckets": buckets,
        "core_logic_only": {
            "insertions": core["insertions"] - core_import_ins,
            "deletions": core["deletions"] - core_import_dels,
            "file_count": core["file_count"],
        },
        "has_import_noise": core_import_ins > 0 or core_import_dels > 0,
    }


def analyze(base_branch: str) -> dict:
    mb = merge_base(base_branch)
    numstat_raw = run(["git", "diff", "--numstat", "-w", f"{mb}..HEAD"])

    files = []
    for line in numstat_raw.strip().splitlines():
        if not line:
            continue
        parts = line.split("\t", 2)
        if len(parts) != 3:
            continue
        ins, dels, path = parts

        if ins == "-" or dels == "-":
            ins_int, dels_int = 0, 0
        else:
            ins_int, dels_int = int(ins), int(dels)

        bucket = categorize(path)
        ext = PurePosixPath(path).suffix

        entry = {
            "path": path,
            "insertions": ins_int,
            "deletions": dels_int,
            "bucket": bucket,
        }

        if bucket == DEFAULT_BUCKET and ext in IMPORT_NOISE_PATTERNS:
            file_diff = run(["git", "diff", "-w", f"{mb}..HEAD", "--", path])
            imports = count_import_lines(file_diff, ext)
            entry["import_insertions"] = imports["added"]
            entry["import_deletions"] = imports["removed"]

        files.append(entry)

    check_header_rules(files)

    agg = aggregate(files)
    return {
        "merge_base": mb,
        "files": files,
        **agg,
    }


def main():
    base = sys.argv[1] if len(sys.argv) > 1 else "main"
    result = analyze(base)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
