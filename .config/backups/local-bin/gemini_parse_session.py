#!/usr/bin/env python3
"""Extract user and gemini messages from a session history log."""

import argparse
import json
import sys
from typing import Any, Dict, List


TARGET_TYPES = {"user", "gemini"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract only user and gemini messages from a session history JSON file.",
    )
    parser.add_argument("input_path", help="Path to the session history JSON file")
    parser.add_argument(
        "-o",
        "--output",
        help="Optional path to write the filtered JSON. Defaults to stdout.",
    )
    return parser.parse_args()


def load_json(path: str) -> Dict[str, Any]:
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Error: file not found: {path}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError as exc:
        print(f"Error: failed to parse JSON ({exc})", file=sys.stderr)
        sys.exit(1)

    if not isinstance(data, dict):
        print("Error: top-level JSON structure must be an object", file=sys.stderr)
        sys.exit(1)
    return data


def extract_messages(data: Dict[str, Any]) -> List[Dict[str, str]]:
    messages = data.get("messages", [])
    if not isinstance(messages, list):
        print("Error: 'messages' must be a list", file=sys.stderr)
        sys.exit(1)

    filtered: List[Dict[str, str]] = []
    for message in messages:
        if not isinstance(message, dict):
            continue
        msg_type = message.get("type")
        if msg_type not in TARGET_TYPES:
            continue
        content = message.get("content", "")
        if not isinstance(content, str):
            content = str(content)
        filtered.append({"type": msg_type, "content": content})
    return filtered


def main() -> None:
    args = parse_args()
    data = load_json(args.input_path)
    user_gemini_messages = extract_messages(data)

    output_payload = {"userGeminiMessages": user_gemini_messages}
    output_str = json.dumps(output_payload, ensure_ascii=False, indent=2)

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
