#!/usr/bin/env python3
"""Filter conversation logs to keep only user and gemini messages."""

import argparse
import json
import sys
from typing import Any, Dict, List


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Filter a conversation history JSON file to keep only user and gemini messages.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  python filter_dialog.py conversation.json\n"
            "  python filter_dialog.py conversation.json --output filtered.json\n"
        ),
    )
    parser.add_argument(
        "input_path",
        help="Path to the JSON file containing the conversation history",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Optional path to write the filtered JSON. Defaults to stdout.",
    )
    return parser.parse_args()


def load_history(path: str) -> Dict[str, Any]:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: file not found: {path}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as exc:
        print(f"Error: failed to parse JSON ({exc})", file=sys.stderr)
        sys.exit(1)


def filter_messages(history: Dict[str, Any]) -> Dict[str, Any]:
    allowed_types = {"user", "gemini"}
    raw_messages: List[Dict[str, Any]] = history.get("history", [])

    if not isinstance(raw_messages, list):
        print("Error: 'history' must be a list", file=sys.stderr)
        sys.exit(1)

    filtered: List[Dict[str, str]] = []
    for message in raw_messages:
        if not isinstance(message, dict):
            continue
        msg_type = message.get("type")
        if msg_type not in allowed_types:
            continue
        text = message.get("text", "")
        if not isinstance(text, str):
            text = str(text)
        filtered.append({"type": msg_type, "text": text})

    return {"history": filtered}


def main() -> None:
    args = parse_args()
    history = load_history(args.input_path)
    filtered_history = filter_messages(history)

    output_str = json.dumps(filtered_history, ensure_ascii=False, indent=2)
    if args.output:
        try:
            with open(args.output, "w", encoding="utf-8") as f:
                f.write(output_str)
                f.write("\n")
        except OSError as exc:
            print(f"Error: failed to write output ({exc})", file=sys.stderr)
            sys.exit(1)
    else:
        print(output_str)


if __name__ == "__main__":
    main()
