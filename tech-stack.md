# Tech stack

Shell scripts, twice: once for bash and zsh, once for PowerShell.

| Piece | Choice | Why |
|---|---|---|
| Shortcuts, bash side | one file that works in bash 3.2 and up, and zsh | Covers Linux, macOS, WSL2 and Git Bash. macOS still ships bash 3.2. |
| Shortcuts, PowerShell side | one file that works in Windows PowerShell 5.1 and PowerShell 7 | 5.1 is on every Windows computer. 7 runs on all three operating systems. |
| Saved names | plain `name=value` file in `~/.config/spl-alias-wrappers/config` | Both shells read the same file, and neither runs it as code |
| Install | one load line in the user's startup file or profile | `git pull` becomes the whole update path |
| Tests | `test.sh` and `test.ps1`, each with a small `check` helper | No test tool to install before the tests run |
| Automated testing | GitHub Actions: Ubuntu, macOS, Windows, plus Windows PowerShell 5.1 | Real Apple and Windows tools, not look-alikes |
| Line endings | LF everywhere, forced by `.gitattributes` | Git for Windows would otherwise break every bash script |
| Docs | markdown in the repo | Reads on GitHub without a build step |
| License | MIT | Students and viewers can use it with no questions |

No package manager, no build step, no dependency. A reader clones it and reads
every line in a few minutes. That is the design, not a shortcut.
