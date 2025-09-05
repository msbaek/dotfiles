#!/usr/bin/env python3
"""
Simple hook to append "use ultrathink" to user prompts
"""

import json
import sys

try:
    # Read input from stdin
    input_data = json.load(sys.stdin)
    prompt = input_data.get("prompt", "")

    # Only append if prompt ends with -u flag
    if prompt.rstrip().endswith("-u"):
        print(
            "\nUse the maximum amount of ultrathink. Take all the time you need. It's much better if you do too much research and thinking than not enough."
        )

except Exception as e:
    print(f"append_ultrathink hook error: {str(e)}", file=sys.stderr)
    sys.exit(1)
