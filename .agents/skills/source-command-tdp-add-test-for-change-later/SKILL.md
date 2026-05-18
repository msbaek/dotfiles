---
name: "source-command-tdp-add-test-for-change-later"
description: "This prompt forces AI to think like a maintainer. Not just a builder."
---

# source-command-tdp-add-test-for-change-later

Use this skill when the user asks to run the migrated source command `tdp-add-test-for-change-later`.

## Command Template

Add the following prompt

## Prompt

Based on this code, what would break or behave differently if I changed the underlying implementation later (e.g., switched from List to Set)?
Write tests that assert expected behavior to help catch such regressions.
