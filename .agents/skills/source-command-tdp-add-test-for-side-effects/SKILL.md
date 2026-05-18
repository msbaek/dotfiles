---
name: "source-command-tdp-add-test-for-side-effects"
description: "Sometimes AI writes utility methods that unexpectedly mutate input. Or it quietly modifies shared state."
---

# source-command-tdp-add-test-for-side-effects

Use this skill when the user asks to run the migrated source command `tdp-add-test-for-side-effects`.

## Command Template

Add the following prompt

## Prompt

Check if this method has side effects like modifying input arguments or static state.
Write a unit test that will fail if any such side effects occur.
