#!/usr/bin/env python3
"""
generate_xcstrings.py

Reads Localization.swift and extracts the en / zh inline dictionaries,
then writes a valid Xcode String Catalog (.xcstrings) JSON file.

Usage:
    python3 scripts/generate_xcstrings.py
"""

import json
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
LOCALIZATION_SWIFT = PROJECT_DIR / "Floreboard" / "Localization.swift"
OUTPUT_XCSTRINGS = PROJECT_DIR / "Floreboard" / "Localizable.xcstrings"


def extract_dict_block(source: str, marker: str) -> str:
    """Return the text between `marker = [` and the matching `]`."""
    pattern = re.escape(marker) + r"\s*=\s*\["
    m = re.search(pattern, source)
    if not m:
        print(f"ERROR: Could not find '{marker}' in source.", file=sys.stderr)
        sys.exit(1)

    start = m.end()  # right after the opening `[`
    depth = 1
    i = start
    while i < len(source) and depth > 0:
        if source[i] == "[":
            depth += 1
        elif source[i] == "]":
            depth -= 1
        i += 1
    return source[start : i - 1]


def parse_entries(block: str) -> dict[str, str]:
    """
    Parse Swift dictionary literal entries of the form:
        "key": "value",
    Handles:
      - escaped quotes  \"
      - {{template}} variables
      - & HTML entities
      - trailing commas and inline comments
    """
    entries: dict[str, str] = {}
    # Match "key": "value" pairs.  Values may contain escaped quotes.
    # We use a non-greedy match but then handle \" inside the value.
    pattern = re.compile(
        r'"((?:[^"\\]|\\.)*)"\s*:\s*"((?:[^"\\]|\\.)*)"',
    )
    for m in pattern.finditer(block):
        key = m.group(1)
        value = m.group(2)
        # Unescape Swift string escapes that matter for .xcstrings
        value = value.replace('\\"', '"')
        # Keep \n as literal newline in the JSON value
        value = value.replace("\\n", "\n")
        entries[key] = value
    return entries


def build_xcstrings(en: dict[str, str], zh: dict[str, str]) -> dict:
    all_keys = sorted(set(en.keys()) | set(zh.keys()))
    strings: dict = {}
    for key in all_keys:
        localizations: dict = {}
        if key in en:
            localizations["en"] = {
                "stringUnit": {"state": "translated", "value": en[key]}
            }
        if key in zh:
            localizations["zh-Hans"] = {
                "stringUnit": {"state": "translated", "value": zh[key]}
            }
        strings[key] = {"localizations": localizations}

    return {
        "sourceLanguage": "en",
        "strings": strings,
        "version": "1.0",
    }


def main():
    source = LOCALIZATION_SWIFT.read_text(encoding="utf-8")

    en_block = extract_dict_block(source, "static let en: [String: String]")
    zh_block = extract_dict_block(source, "static let zh: [String: String]")

    en_entries = parse_entries(en_block)
    zh_entries = parse_entries(zh_block)

    print(f"Parsed {len(en_entries)} EN entries, {len(zh_entries)} ZH entries.")

    # Sanity: warn about keys present in one but not the other
    only_en = set(en_entries) - set(zh_entries)
    only_zh = set(zh_entries) - set(en_entries)
    if only_en:
        print(f"WARNING: Keys only in EN: {only_en}", file=sys.stderr)
    if only_zh:
        print(f"WARNING: Keys only in ZH: {only_zh}", file=sys.stderr)

    catalog = build_xcstrings(en_entries, zh_entries)

    OUTPUT_XCSTRINGS.write_text(
        json.dumps(catalog, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Written {len(catalog['strings'])} keys to {OUTPUT_XCSTRINGS}")


if __name__ == "__main__":
    main()
