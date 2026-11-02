# Fira Mono Ligaturized

[Fira Mono](https://github.com/mozilla/Fira) patched with selected
[Fira Code](https://github.com/tonsky/FiraCode) ligatures and character designs
via [Ligaturizer](https://github.com/ToxicFrog/Ligaturizer).

The result keeps Fira Mono's letterforms and compact 600-unit tracking while
adding programming ligatures. Selected standalone symbols also use Fira Code
6.2 outlines so their size and shape are consistent with the coding ligatures.
The following Fira Code 6.2 stylistic variants are promoted to the default
glyphs, so editor support for their OpenType feature tags is not required:

- `zero`: dotted `0`
- `cv02`: single-storey `g`
- `cv10`: serifed `l`
- `ss03`: conventional `&`
- `ss05`: enclosed `@`

### Standalone symbols

Each weight uses its matching Fira Code 6.2 designs for:

- Coding punctuation: `! # % * + - . / : ; < = > ? \ ^ _ | ~`.
- Arithmetic symbols: U+00AC, U+00B1, U+00D7, U+00F7, U+2202, U+220F,
  U+2211, U+2212, U+2215, U+2219, U+221A, U+221E, U+2229, and U+222B.
- Comparisons: U+2248, U+2260, U+2261, U+2264, and U+2265.
- Arrows: U+2190 through U+2199.

These glyphs are scaled to Fira Mono's em size and centered in its 600-unit
cell without horizontal stretching. They also apply when ligatures are
disabled. Other glyphs retain their Fira Mono designs, apart from the five
stylistic variants above.

## Setup

Install with Homebrew:

```bash
brew install --cask nanxstats/tap/font-fira-mono-ligaturized
```

Or install the generated fonts from `fonts/` using your OS font manager.

Fira Mono 3.206 has three upright weights and no italic styles. This repo
generates:

- `LigaFiraMono-Regular.otf`
- `LigaFiraMono-Medium.otf`
- `LigaFiraMono-Bold.otf`

### VS Code

In VS Code, press `Cmd` + `Shift` + `P`, search for
`Preferences: Open User Settings (JSON)`, and configure the font family and
ligatures:

```json
"editor.fontFamily": "'Liga Fira Mono', monospace",
"editor.fontLigatures": "'calt', 'liga'",
"terminal.integrated.fontFamily": "'Liga Fira Mono', monospace",
"terminal.integrated.fontLigatures.enabled": true,
```

### Ghostty

Open Ghostty settings (`Cmd` + `,`) and set:

```ini
font-family = Liga Fira Mono
```

Press `Cmd` + `Shift` + `,` to reload the configuration.

## Build

Run `make` or `make build` in the repository root. The build requires `git`,
`curl`, `unzip`, and FontForge. On macOS, the Makefile installs FontForge with
Homebrew if it is missing.

The Makefile will:

- Reuse `Fira-4.106.zip` and `Fira_Code_v6.2.zip` when present, or download
  them from their GitHub release URLs when missing.
- Extract the Regular, Medium, and Bold Fira Mono OTFs and their matching Fira
  Code 6.2 TTFs.
- Reuse a local `Ligaturizer/` checkout when present, or shallow-clone it when
  missing, then initialize only its `fonts/fira` submodule.
- Stage the three Fira Mono OTFs in `Ligaturizer/fonts/fira-mono/` and patch
  Ligaturizer's `renamed_fonts` mapping to emit the `Liga Fira Mono` family.
- Remove the intentionally excluded ligatures listed below.
- Add Ligaturizer's programming ligatures.
- Post-process each weight with its matching Fira Code 6.2 TTF, replace the
  standalone symbols listed above, promote the five selected variants to
  their base characters, and preserve Fira Mono's monospaced advance width.
- Write the final OTFs to `fonts/`.

`make cleanup` removes the Ligaturizer checkout and extracted source trees but
keeps the downloaded archives and generated fonts. `make clean` also removes
the generated fonts.

Run `make test` to build and validate all three weights. In addition to the
build dependencies, the tests require HarfBuzz's `hb-shape` command
(`brew install harfbuzz` on macOS). Tests compare the generated outlines with
Fira Code, check that other glyphs and advances are preserved, and verify
ligature shaping, exclusions, and the dotted-zero feature.

### Dropped ligatures

These ligatures are intentionally omitted:

`&&`, `~@`, `\/`, `.?`, `?:`, `?=`, `?.`, `??`, `;;`, `/\`
