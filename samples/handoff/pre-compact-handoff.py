#!/usr/bin/env python3
"""
PreCompact Hook: Extract key context before auto-compact or /compact.
Writes a handoff document so post-compact session can recover critical info.
"""

import json
import sys

from handoff_core import extract_context, write_handoff


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        sys.exit(0)

    session_id = data.get("session_id", "unknown")
    transcript_path = data.get("transcript_path", "")
    trigger = data.get("trigger", "PreCompact (auto-compact or /compact)")
    source_cwd = data.get("cwd", "")

    if not transcript_path:
        sys.exit(0)

    context = extract_context(transcript_path)
    if not context or (not context["user_messages"] and not context["files_touched"]):
        sys.exit(0)

    handoff_result = write_handoff(
        context=context,
        session_id=session_id,
        trigger=trigger,
        transcript_path=transcript_path,
        source_cwd=source_cwd,
    )

    # Output JSON for Claude Code to inject as system message
    output = {
        "systemMessage": (
            f"[PreCompact Handoff] Context snapshot saved to {handoff_result['handoff_file']}. "
            f"Captured {len(context['user_messages'])} user messages and "
            f"{len(context['files_touched'])} file references. "
            f"Updated latest handoff at {handoff_result['latest_handoff_file']}."
        )
    }
    print(json.dumps(output))


if __name__ == "__main__":
    main()
