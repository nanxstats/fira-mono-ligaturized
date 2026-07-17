# Fira Mono Ligaturized

[Fira Mono](https://github.com/mozilla/Fira) patched with selected
[Fira Code](https://github.com/tonsky/FiraCode) ligatures and character designs
via [Ligaturizer](https://github.com/ToxicFrog/Ligaturizer).

The result keeps Fira Mono's letterforms and compact 600-unit tracking while
adding programming ligatures. The following Fira Code 6.2 stylistic variants
are promoted to the default glyphs, so editor support for their OpenType
feature tags is not required:

- `zero`: dotted `0`
- `cv02`: single-storey `g`
- `cv10`: serifed `l`
- `ss03`: conventional `&`
- `ss05`: enclosed `@`

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
- Add Ligaturizer's programming ligatures without replacing Fira Mono's
  ordinary punctuation glyphs.
- Post-process each weight with its matching Fira Code 6.2 TTF, promote the
  five selected variants to their base characters, and preserve Fira Mono's
  monospaced advance width.
- Write the final OTFs to `fonts/`.

`make cleanup` removes the Ligaturizer checkout and extracted source trees but
keeps the downloaded archives and generated fonts. `make clean` also removes
the generated fonts.

### Dropped ligatures

These ligatures are intentionally omitted:

`&&`, `~@`, `\/`, `.?`, `?:`, `?=`, `?.`, `??`, `;;`, `/\`
