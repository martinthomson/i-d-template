# IETF Internet-Draft Development

## Build Commands

| Command | Description |
|---------|-------------|
| `make` | Build all outputs (txt, html) and run lint |
| `make latest` | Build txt and html without linting |
| `make lint` | Run all lint checks |
| `make fix-lint` | Auto-fix lint issues (whitespace) |
| `make txt` | Build text output only |
| `make html` | Build HTML output only |
| `make diff` | Show changes since last published draft |
| `make clean` | Remove build artifacts |
| `make idnits` | Run IETF nits checker |
| `make spellcheck` | Run spell checker |
| `make next` | Build versioned copies for submission |
| `make deps` | Install dependencies |

## Before Committing

A pre-commit hook runs `make lint` and builds HTML to catch errors.
Always fix lint issues before committing:

1. Run `make` to build and lint
2. Fix any errors reported by lint (or run `make fix-lint` for whitespace issues)
3. Stage and commit

**Do not use `git commit --no-verify`** to bypass the pre-commit hook unless the user explicitly requests it.

## Source Files

Draft sources are `draft-*.md`, `draft-*.xml`, or `draft-*.org` files in the repo root. The build system auto-detects the format and processes them through the appropriate toolchain (kramdown-rfc, mmark, or xml2rfc).
