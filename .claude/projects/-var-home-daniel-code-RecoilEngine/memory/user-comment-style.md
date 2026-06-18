---
name: user-comment-style
description: User's preference for code comments — terse, why-only
metadata:
  type: feedback
---

Keep code comments concise. Only write a comment if it explains *why* something needs to exist; skip anything self-explanatory. No long comment blocks, no histrionics.

**Why:** User called this out directly after I left a 5-line explanatory comment in a gadget.
**How to apply:** Prefer one tight line stating the non-obvious reason. Don't narrate what the code does. Applies across C++ and Lua. See [[pr-2664-game-economy]].
