#!/usr/bin/env python3
import importlib.util
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("export_audit", Path(__file__).with_name("export-audit.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class AuditTests(unittest.TestCase):
    def setUp(self):
        self.config = dict(width_mm=180, height_mm=120, dpi=600,
                           text_pt=dict(body=7, annotation=6.5, tick=6, panel_tag=12),
                           tolerance=dict(page_mm=.1, font_pt=.2, row_mm=.2))

    def svg(self, text="A", size=12, family="Arial", width=180, marker=False):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "figure.svg"
            path.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}mm" height="120mm" viewBox="0 0 510.236 340.157">'
                            f'<text x="10" y="30" textLength="10" style="font-family:{family};font-size:{size}px">{text}</text>'
                            + ('<circle cx="18" cy="27" r="3"/>' if marker else '') + '</svg>')
            return module.audit([path], self.config)

    def test_missing_formats_not_pass(self):
        self.assertNotEqual(self.svg()["status"], "pass")

    def test_tag_exception(self):
        self.assertEqual(self.svg()["checks"]["svg_typography"], "pass")
        self.assertEqual(self.svg(text="Axis title")["checks"]["svg_typography"], "fail")

    def test_size_and_substitution(self):
        self.assertEqual(self.svg(size=20)["checks"]["svg_typography"], "fail")
        self.assertEqual(self.svg(family="Helvetica")["checks"]["svg_typography"], "fail")
        self.assertEqual(self.svg(family="Arial Narrow")["checks"]["svg_typography"], "fail")
        self.assertEqual(self.svg(width=183)["checks"]["svg_page_mm"], "fail")

    def test_collision(self):
        result = self.svg(marker=True)
        self.assertEqual(result["checks"]["svg_text_mark_clearance"], "warn")
        self.assertTrue(result["details"]["svg_text_mark_clearance"]["collisions"])

    def test_shared_rows_and_repeated_n(self):
        self.config.update(n_panels=2, shared_row_labels=["Species a"], case="igs")
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "rows.svg"
            path.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="180mm" height="120mm" viewBox="0 0 510.236 340.157">'
                            '<text x="10" y="30" style="font-size:6.5px;font-family:Arial;font-style:italic">Species a</text>'
                            '<text x="200" y="34" style="font-size:6.5px;font-family:Arial;font-style:italic">Species a</text>'
                            '<text style="font-size:6px;font-family:Arial">n=113</text></svg>')
            result = module.audit([path], self.config)
            self.assertEqual(result["checks"]["shared_row_alignment"], "fail")
            self.assertEqual(result["checks"]["count_column_header"], "fail")


if __name__ == "__main__":
    unittest.main()
