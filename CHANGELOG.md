# Changelog

Every change people will notice is written down here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and version numbers follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Removed

- `docs/ALIASES.md`, a personal inventory of one workstation that named private
  machines and projects. It never held anything the shortcuts need.

## [0.1.0] - 2026-09-13

First public release.

### Added

- Five shortcuts: `lsa`, `c`, `lsd`, `cc` and `cx`.
- `bash/` for bash and zsh on Linux, macOS, WSL2 and Git Bash.
- `powershell/` for Windows PowerShell 5.1 and PowerShell 7 on any OS.
- Installers that ask whether to rename or leave out any shortcut, and save the
  choices in `~/.config/spl-alias-wrappers/config`, which both shells read.
- `cc` and `cx` keep the agent safety check on unless the user opts out.
- A test suite for each shell, run on real Linux, macOS and Windows machines on
  every push, plus shellcheck and PSScriptAnalyzer lint checks.

[Unreleased]: https://github.com/darrenspl/spl-alias-wrappers/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/darrenspl/spl-alias-wrappers/releases/tag/v0.1.0
