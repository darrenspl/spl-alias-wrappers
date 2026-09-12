# Tech stack

POSIX shell, and nothing else.

| Piece | Choice | Why |
|---|---|---|
| Language | bash and zsh compatible shell | Already on every machine this targets |
| Install | one `.` line in the user's startup file | `git pull` becomes the whole update path |
| Tests | one bash script with a `check` helper | No test tool to install before the tests run |
| Docs | markdown in the repo | Reads on GitHub without a build step |
| License | MIT | Students and viewers can use it with no questions |

No package manager, no build step, no dependency. A reader clones it and reads
every line in a few minutes. That is the design, not a shortcut.
