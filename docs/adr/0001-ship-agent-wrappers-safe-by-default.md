# ADR 0001: Ship cc and cx with agent safety checks on

Date: 2026-09-12
**Status:** Accepted

## Context

On his own machines, Darren runs `cc` as
`claude --dangerously-skip-permissions` and `cx` as
`codex --dangerously-bypass-approvals-and-sandbox`. Both flags turn off the
question the tool asks before it runs a command.

This repo is public and is meant to be handed to students during a class or
linked under a video. A one line install that quietly turns off an agent's
safety check is a different thing from one person choosing it for their own box.

## Options considered

a. Safe by default, the flags turn on when the user sets `SPL_YOLO=1`.
b. Ship the flags on, warn loudly in the README.
c. Ship the flags on, print a warning the first time the shell loads.

## Decision

Option a.

`aliases.sh` defines `cc` and `cx` without the flags. When `SPL_YOLO=1` is set
in the environment, it defines them with the flags instead. Darren sets that
one variable in his own startup file and his daily use is unchanged.

## Why

- The reader who does nothing gets the safe version. That is the right default
  for a stranger following a video.
- Turning it off stays possible and takes one line, so nobody has to fork the
  repo or edit a file that `git pull` will overwrite.
- Setting a variable named `SPL_YOLO` is a deliberate act. Nobody does it by
  accident, and it is easy to find again later.

## Cost

Darren has one extra line in his own startup file, and it must sit above the
line that sources `aliases.sh`. `install.sh` does not add it, on purpose.

## Checked by

`test.sh` asserts the flag is absent by default and present under `SPL_YOLO=1`,
for both `cc` and `cx`. Four of its thirteen checks cover this decision.
