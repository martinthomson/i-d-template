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

Before `make next`, it is a good idea to run `make idnits` and `make spellcheck`
and address any reported issues, but neither is required by the build.

## Before Committing

A pre-commit hook runs `make lint` and builds HTML to catch errors.
Always fix lint issues before committing:

1. Run `make` to build and lint
2. Fix any errors reported by lint (or run `make fix-lint` for whitespace issues)
3. Stage and commit

**Do not use `git commit --no-verify`** to bypass the pre-commit hook unless the user explicitly requests it.

## Source Files

Drafts are authored in one of three formats, kept in the repo root:

- `draft-*.md` — Markdown, the most common format. Two flavors are supported:
  [kramdown-rfc](https://github.com/cabo/kramdown-rfc) (most common) and
  [mmark](https://mmark.miek.nl/).
- `draft-*.xml` — [xml2rfc](https://authors.ietf.org/en/rfcxml-overview) v3, used directly when authored as XML.
- `draft-*.org` — Org mode (rare).

Note: when a draft is authored in Markdown, the build produces an intermediate
`draft-*.xml` file as a build artifact. Only edit `draft-*.xml` directly if it
is the authored source (i.e. there is no corresponding `draft-*.md` or
`draft-*.org`). When in doubt, edit the `.md` file.

## Documentation

Detailed documentation lives under `lib/doc/` (the `lib/` directory is the
i-d-template toolchain, vendored as a git submodule):

- `lib/doc/SETUP.md` — installing dependencies and platform notes
- `lib/doc/FEATURES.md` — full feature reference
- `lib/doc/SUBMITTING.md` — how to tag and submit drafts to the IETF datatracker
- `lib/doc/REPO.md` — repository setup guide
- `lib/doc/TEMPLATE.md` — template-based setup workflow

## Never Do

- Do not modify files under `lib/`. This is the i-d-template toolchain, updated separately via the git submodule.
- Do not edit `.github/workflows/` unless the task explicitly concerns CI configuration.
- Do not commit `draft-*.txt` or `draft-*.html` — these are build artifacts. The intermediate `draft-*.xml` produced from a `.md` source is also a build artifact.
