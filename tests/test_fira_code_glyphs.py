#!/usr/bin/env fontforge

import json
from pathlib import Path
import subprocess
import sys
import unittest

import fontforge
import psMat


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from apply_fira_code_variants import SYMBOL_CHARACTERS, VARIANT_REPLACEMENTS


WEIGHTS = ("Regular", "Medium", "Bold")
EXCLUDED_LIGATURES = (
    "&&", "~@", "\\/", ".?", "?:", "?=", "?.", "??", ";;", "/\\",
)


def open_font(path):
    return fontforge.open(str(ROOT / path))


def normalized_outline(glyph):
    outline = glyph.foreground
    x_min, _, _, _ = glyph.boundingBox()
    outline.transform(psMat.translate(-x_min, 0))
    return outline


def shape(weight, text, features):
    result = subprocess.run(
        [
            "hb-shape", str(ROOT / "fonts" / ("LigaFiraMono-%s.otf" % weight)),
            "--text=" + text, "--features=" + features, "--output-format=json",
        ],
        check=True, capture_output=True, text=True,
    )
    return json.loads(result.stdout)


class GeneratedFontsTest(unittest.TestCase):
    def test_donor_outlines_and_preserved_glyphs(self):
        for weight in WEIGHTS:
            donor = open_font("Fira_Code_v6.2/ttf/FiraCode-%s.ttf" % weight)
            original = open_font(
                "Ligaturizer/fonts/output/LigaFiraMono-%s.otf" % weight
            )
            output = open_font("fonts/LigaFiraMono-%s.otf" % weight)
            try:
                donor.em = output.em
                donor.selection.all()
                donor.unlinkReferences()
                donor.layers[1].is_quadratic = False
                replacements = {
                    output[ord(character)].glyphname: donor[ord(character)]
                    for character in SYMBOL_CHARACTERS
                }
                for source_name, target_names in VARIANT_REPLACEMENTS:
                    for name in target_names:
                        replacements[name] = donor[source_name]

                with self.subTest(weight=weight):
                    self.assertEqual(output.em, original.em)
                    self.assertEqual(output.familyname, "Liga Fira Mono")
                    self.assertEqual(output.fontname, "LigaFiraMono-" + weight)
                    self.assertEqual(output.gsub_lookups, original.gsub_lookups)
                    self.assertEqual(
                        {g.glyphname for g in output.glyphs()},
                        {g.glyphname for g in original.glyphs()},
                    )

                for old in original.glyphs():
                    glyph = output[old.glyphname]
                    with self.subTest(weight=weight, glyph=old.glyphname):
                        self.assertEqual(glyph.unicode, old.unicode)
                        self.assertEqual(glyph.altuni, old.altuni)
                        self.assertEqual(glyph.width, old.width)
                        self.assertEqual(glyph.getPosSub("*"), old.getPosSub("*"))
                        if glyph.glyphname in replacements:
                            expected = replacements[glyph.glyphname]
                            self.assertEqual(glyph.width, 600)
                            x_min, _, x_max, _ = glyph.boundingBox()
                            self.assertAlmostEqual(
                                (x_min + x_max) / 2, 300, delta=1
                            )
                            self.assertTrue(
                                normalized_outline(glyph).similar(
                                    normalized_outline(expected), 1
                                ),
                                "outline differs from Fira Code",
                            )
                        else:
                            self.assertTrue(
                                glyph.foreground.similar(old.foreground, 1)
                            )
            finally:
                donor.close()
                original.close()
                output.close()

    def test_ligatures_and_exclusions(self):
        included = ("++", "==", "!=", "<=", ">=", "->", "<-", "<=>")
        for weight in WEIGHTS:
            for text in EXCLUDED_LIGATURES + included:
                with self.subTest(weight=weight, text=text):
                    enabled = shape(weight, text, "calt=1,liga=1")
                    disabled = shape(weight, text, "calt=0,liga=0")
                    if text in EXCLUDED_LIGATURES:
                        self.assertEqual(enabled, disabled)
                    else:
                        self.assertNotEqual(enabled, disabled)
                    self.assertEqual(sum(g["ax"] for g in enabled), 600 * len(text))

    def test_dotted_zero_feature(self):
        for weight in WEIGHTS:
            with self.subTest(weight=weight):
                default = shape(weight, "0", "zero=0")
                alternate = shape(weight, "0", "zero=1")
                self.assertEqual(default[0]["g"], "zero")
                self.assertEqual(alternate[0]["g"], "zero.zero")
                self.assertEqual(default[0]["ax"], 600)
                self.assertEqual(alternate[0]["ax"], 600)


if __name__ == "__main__":
    unittest.main()
