# Intent

Written: 2026-09-12

The point is teaching, not tooling.

When these shortcuts show up in a class or a video, the question that follows is
always "what was that command?" This repo is the answer to that question. A link
is faster than a screenshot, and it stays right when the shortcut changes.

That sets the bar for every choice here:

- **Plain over clever.** A reader should understand the whole thing in one pass.
  No frameworks, no generated files, no build step.
- **Safe by default.** Handing a class a shortcut that turns off an agent's
  safety check would be teaching the wrong lesson. The flag is there, it is
  documented, and turning it on is the reader's own deliberate act.
- **Honest about the sharp edges.** `cc` hides the C compiler. `lsd` hides a
  real package. Both stay, because they are the names in muscle memory, and both
  are written down plainly in the README.
- **Small on purpose.** Five shortcuts. It grows only when a sixth one has
  earned its place in daily use, not because the repo looks thin.
