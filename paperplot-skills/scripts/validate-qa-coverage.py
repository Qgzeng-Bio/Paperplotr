#!/usr/bin/env python3
"""Self-audit for visual-QA review<->remediation coverage.

Guards two invariants so the "audit + how-to-fix" contract cannot silently rot:
  1. Every risk code emitted by visual-qa-rendered-image.py has either a
     remediation entry (REMEDIATION) or is explicitly informational
     (REMEDIATION_NONE).
  2. Every remediation doc path referenced actually exists on disk.

Exits non-zero with a readable report on any gap. No human input required.
"""

from __future__ import annotations

import importlib.util
import re
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[1]
QA_SCRIPT = SKILL_ROOT / "scripts" / "visual-qa-rendered-image.py"


def load_qa_module():
    spec = importlib.util.spec_from_file_location("visual_qa", QA_SCRIPT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def emitted_codes(source: str) -> set[str]:
    # Match risk(STATUS_*, "code", ...) calls.
    return set(re.findall(r'risk\(\s*STATUS_\w+\s*,\s*"([a-z0-9_]+)"', source))


def main() -> int:
    mod = load_qa_module()
    source = QA_SCRIPT.read_text()
    codes = emitted_codes(source)
    remediation = getattr(mod, "REMEDIATION", {})
    none_set = getattr(mod, "REMEDIATION_NONE", set())
    guardrails = getattr(mod, "NATURE_GUARDRAILS", [])

    problems: list[str] = []

    uncovered = sorted(c for c in codes if c not in remediation and c not in none_set)
    if uncovered:
        problems.append(
            "Risk codes without remediation or REMEDIATION_NONE entry:\n  - "
            + "\n  - ".join(uncovered)
        )

    missing_docs = sorted(
        {doc for doc, _ in remediation.values() if not (SKILL_ROOT / doc).exists()}
    )
    if missing_docs:
        problems.append(
            "Remediation docs that do not exist on disk:\n  - " + "\n  - ".join(missing_docs)
        )

    guardrail_codes = set()
    guardrail_docs = set()
    for gate in guardrails:
        guardrail_codes.update(gate.get("hard_codes", set()))
        guardrail_codes.update(gate.get("review_codes", set()))
        if gate.get("doc"):
            guardrail_docs.add(gate["doc"])
    guardrail_unemitted = sorted(c for c in guardrail_codes if c not in codes)
    if guardrail_unemitted:
        problems.append(
            "Nature guardrail codes that are not emitted by visual QA:\n  - "
            + "\n  - ".join(guardrail_unemitted)
        )
    guardrail_uncovered = sorted(c for c in guardrail_codes if c not in remediation and c not in none_set)
    if guardrail_uncovered:
        problems.append(
            "Nature guardrail codes without remediation coverage:\n  - "
            + "\n  - ".join(guardrail_uncovered)
        )
    missing_guardrail_docs = sorted(doc for doc in guardrail_docs if not (SKILL_ROOT / doc).exists())
    if missing_guardrail_docs:
        problems.append(
            "Nature guardrail docs that do not exist on disk:\n  - "
            + "\n  - ".join(missing_guardrail_docs)
        )

    # Stale entries: remediation for a code that is never emitted (warn only).
    stale = sorted(c for c in remediation if c not in codes)
    if stale:
        print("note: remediation entries for codes not currently emitted: " + ", ".join(stale))

    if problems:
        print("QA coverage self-audit FAILED:\n")
        print("\n\n".join(problems))
        return 1

    print(
        f"QA coverage self-audit passed: {len(codes)} emitted risk codes, "
        f"{len(remediation)} remediation entries, {len(guardrails)} Nature guardrails, all docs present."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
