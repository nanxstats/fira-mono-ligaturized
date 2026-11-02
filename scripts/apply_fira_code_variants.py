#!/usr/bin/env fontforge

import os
import sys

import fontforge
import psMat


SYMBOL_CHARACTERS = (
    "!#%*+-./:;<=>?\\^_|~"
    "\u00ac\u00b1\u00d7\u00f7"
    "\u2190\u2191\u2192\u2193\u2194\u2195\u2196\u2197\u2198\u2199"
    "\u2202\u220f\u2211\u2212\u2215\u2219\u221a\u221e\u2229\u222b"
    "\u2248\u2260\u2261\u2264\u2265"
)

VARIANT_REPLACEMENTS = (
    # Keep Fira Mono's existing `zero` feature from restoring its slashed zero.
    ("zero.zero", ("zero", "zero.zero")),
    ("g.cv02", ("g",)),
    ("l.cv10", ("l",)),
    ("ampersand.ss03", ("ampersand",)),
    ("at.ss05", ("at",)),
)


def weight_name(font):
    return font.fontname.rsplit("-", 1)[-1]


def glyph_replacements(source, target):
    replacements = []
    for character in SYMBOL_CHARACTERS:
        codepoint = ord(character)
        if codepoint not in source:
            raise ValueError("missing source symbol: U+%04X" % codepoint)
        if codepoint not in target:
            raise ValueError("missing target symbol: U+%04X" % codepoint)
        # Unicode names can differ, for example arrowupdown vs. arrowupdn.
        replacements.append(
            (source[codepoint].glyphname, (target[codepoint].glyphname,))
        )
    return tuple(replacements) + VARIANT_REPLACEMENTS


def center_in_cell(glyph, cell_width):
    x_min, _, x_max, _ = glyph.boundingBox()
    x_offset = (cell_width - x_min - x_max) / 2.0
    glyph.transform(psMat.translate(x_offset, 0))
    glyph.width = cell_width


def copy_glyph(source, target, source_name, target_name, cell_width):
    # Resolve components in the donor font, not against Fira Mono's glyphs.
    source[source_name].unlinkRef()
    source.selection.none()
    source.selection.select(source_name)
    source.copy()

    target.selection.none()
    target.selection.select(target_name)
    target.paste()
    center_in_cell(target[target_name], cell_width)

    if target[target_name].width != cell_width:
        raise ValueError("failed to preserve the cell width for %s" % target_name)


def main():
    if len(sys.argv) != 4:
        raise SystemExit(
            "usage: apply_fira_code_variants.py INPUT_FONT FIRA_CODE_FONT OUTPUT_FONT"
        )

    input_font, donor_font, output_font = sys.argv[1:]
    target = fontforge.open(input_font)
    source = fontforge.open(donor_font)

    try:
        if weight_name(target) != weight_name(source):
            raise ValueError(
                "font weight mismatch: %s and %s"
                % (target.fontname, source.fontname)
            )

        replacements = glyph_replacements(source, target)
        cell_width = target["m"].width
        target_names = tuple(
            target_name
            for _, names in replacements
            for target_name in names
        )

        for source_name, _ in replacements:
            if source_name not in source:
                raise ValueError("missing source glyph: %s" % source_name)
        for target_name in target_names:
            if target_name not in target:
                raise ValueError("missing target glyph: %s" % target_name)
            if target[target_name].width != cell_width:
                raise ValueError("non-monospace target glyph: %s" % target_name)

        source.em = target.em
        for source_name, names in replacements:
            for target_name in names:
                copy_glyph(source, target, source_name, target_name, cell_width)

        output_dir = os.path.dirname(output_font)
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)

        target.generate(output_font)
    finally:
        source.close()
        target.close()


if __name__ == "__main__":
    main()
