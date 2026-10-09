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
        # Explicit legacy SVG-parser tests; default PDF/JPG covered separately below.
        self.config = dict(export_formats=['svg'], width_mm=180, height_mm=120, dpi=300,
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
        self.config.pop('export_formats')
        self.assertEqual(self.svg()["checks"][".pdf_present"], "fail")
        self.assertEqual(self.svg()["checks"][".jpg_present"], "fail")

    def test_tag_exception(self):
        self.assertEqual(self.svg()["checks"]["svg_typography"], "pass")
        self.assertEqual(self.svg(text="Axis title")["checks"]["svg_typography"], "fail")

    def test_size_and_substitution(self):
        self.assertEqual(self.svg(size=20)["checks"]["svg_typography"], "fail")
        self.assertEqual(self.svg(family="Helvetica")["checks"]["svg_typography"], "fail")
        self.assertEqual(self.svg(family="Arial Narrow")["checks"]["svg_typography"], "fail")
        self.assertEqual(self.svg(width=183)["checks"]["svg_page_mm"], "fail")

    def test_lowercase_tag_profile(self):
        self.config.update(tag_case="lowercase", text_pt=dict(body=7, annotation=6.5, tick=6, panel_tag=8))
        self.assertEqual(self.svg(text="a", size=8)["checks"]["svg_typography"], "pass")
        self.assertEqual(self.svg(text="A", size=8)["checks"]["svg_typography"], "fail")  # wrong case for the profile
        self.assertEqual(self.svg(text="a", size=12)["checks"]["svg_typography"], "fail")  # old 12 pt tag size

    def test_uppercase_tag_profile_rejects_lowercase(self):
        self.config.update(tag_case="uppercase", text_pt=dict(body=7, annotation=6.5, tick=6, panel_tag=8))
        self.assertEqual(self.svg(text="A", size=8)["checks"]["svg_typography"], "pass")
        self.assertEqual(self.svg(text="a", size=8)["checks"]["svg_typography"], "fail")

    def test_collision(self):
        result = self.svg(marker=True)
        self.assertEqual(result["checks"]["svg_text_mark_clearance"], "warn")
        self.assertTrue(result["details"]["svg_text_mark_clearance"]["collisions"])

    def test_required_label_loss_is_a_hard_failure(self):
        self.config['expected_labels'] = ['Gene42']
        self.assertEqual(self.svg(text='not Gene42',size=6)['checks']['svg_required_labels'], 'fail')
        self.assertEqual(self.svg(text='Gene42',size=6)['checks']['svg_required_labels'], 'pass')

    def test_inherited_transform_and_missing_tags(self):
        self.config['n_panels'] = 4
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'transformed.svg'
            path.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="180mm" height="120mm" viewBox="0 0 510.236 340.157">'
                            '<g transform="translate(20,20) scale(4)" font-family="Arial" font-size="6px">'
                            '<text x="10" y="10" textLength="8">small</text></g></svg>')
            result = module.audit([path], self.config)
            self.assertEqual(result['checks']['svg_typography'], 'fail')
            self.assertEqual(result['checks']['svg_panel_tags'], 'fail')

    def test_inherited_font_and_supported_clearance(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'clean.svg'
            path.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="180mm" height="120mm" viewBox="0 0 510.236 340.157">'
                            '<g font-family="Arial" font-size="6px" transform="translate(20,20)">'
                            '<text x="10" y="10" textLength="8">clean</text></g></svg>')
            result = module.audit([path], self.config)
            self.assertEqual(result['checks']['svg_typography'], 'pass')
            self.assertEqual(result['checks']['svg_text_mark_clearance'], 'pass')
            self.assertEqual(result['checks']['svg_text_text_clearance'], 'pass')

    def test_inherited_anchor_and_relative_tspan(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'anchor.svg'
            path.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="180mm" height="120mm" viewBox="0 0 510.236 340.157">'
                            '<g font-family="Arial" font-size="6px" text-anchor="end"><text x="3" y="10" textLength="10">edge</text></g></svg>')
            self.assertEqual(module.audit([path], self.config)['checks']['svg_text_bounds'], 'warn')
            path.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="180mm" height="120mm" viewBox="0 0 510.236 340.157">'
                            '<text x="50" y="50" font-family="Arial" font-size="6px"><tspan textLength="8">relative</tspan></text></svg>')
            self.assertEqual(module.audit([path], self.config)['checks']['svg_text_bounds'], 'unverified')

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


class DefaultAuditTests(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.root = Path(self.folder.name)
        self.config = dict(width_mm=25.4, height_mm=25.4, dpi=300, tag_case='lowercase',
                           text_pt=dict(body=7, tick=6, panel_tag=8),
                           tolerance=dict(page_mm=.1, font_pt=.2, row_mm=.2))

    def jpeg(self, size=(300, 300), dpi=(300, 300), mode='RGB', encoding='JPEG'):
        from PIL import Image
        path = self.root / 'figure.jpg'
        Image.new(mode, size, 'white').save(path, format=encoding, dpi=dpi)
        return path

    def pdf(self, label='Gene42', tag='a', bold=True):
        # Structural extraction fixture only: genuine standard Helvetica names, NOT
        # fictional embedded Arial. Real font embedding/typography is tested in R.
        from pypdf import PdfWriter
        from pypdf.generic import DictionaryObject, NameObject, DecodedStreamObject
        writer = PdfWriter()
        page = writer.add_blank_page(width=72, height=72)
        fonts = DictionaryObject()
        for key, name in [('F1', 'Helvetica'), ('F2', 'Helvetica-Bold' if bold else 'Helvetica')]:
            fonts[NameObject('/' + key)] = writer._add_object(DictionaryObject({
                NameObject('/Type'): NameObject('/Font'), NameObject('/Subtype'): NameObject('/Type1'),
                NameObject('/BaseFont'): NameObject('/' + name)}))
        page[NameObject('/Resources')] = DictionaryObject({NameObject('/Font'): fonts})
        content = DecodedStreamObject()
        content.set_data((f'BT /F1 7 Tf 5 45 Td ({label}) Tj ET\n'
                          f'BT /F2 8 Tf 5 60 Td ({tag}) Tj ET\n').encode('ascii'))
        page[NameObject('/Contents')] = writer._add_object(content)
        path = self.root / 'figure.pdf'
        writer.write(path)
        return path

    def test_default_presence_and_no_svg_requirement(self):
        result = module.audit([self.jpeg(), self.pdf()], self.config)
        self.assertEqual(result['checks']['.pdf_present'], 'pass')
        self.assertEqual(result['checks']['.jpg_present'], 'pass')
        self.assertNotIn('.svg_present', result['checks'])
        self.assertNotIn('.png_present', result['checks'])
        self.assertEqual(result['checks']['pdf_typography'], 'fail')  # Helvetica is not Arial
        for key in ('jpg_pixels', 'jpg_dpi', 'jpg_rgb', 'jpg_encoding'):
            self.assertEqual(result['checks'][key], 'pass')
        for paths, key in (([self.jpeg()], '.pdf_present'), ([self.pdf()], '.jpg_present'),
                           ([self.root / 'missing.pdf', self.jpeg()], '.pdf_present')):
            self.assertEqual(module.audit(paths, self.config)['checks'][key], 'fail')

    def test_jpeg_negative_evidence(self):
        for kwargs, key in ((dict(size=(290, 300)), 'jpg_pixels'), (dict(dpi=(72, 72)), 'jpg_dpi'),
                            (dict(mode='CMYK'), 'jpg_rgb'), (dict(encoding='PNG'), 'jpg_encoding')):
            with self.subTest(kwargs=kwargs):
                self.assertEqual(module.audit([self.jpeg(**kwargs)], self.config)['checks'][key], 'fail')
        path = self.root / 'figure.jpg'
        path.write_bytes(b'not an image')
        self.assertEqual(module.audit([path], self.config)['checks']['.jpg_audit'], 'fail')

    def test_exact_pdf_labels_tags_and_not_reviewable(self):
        self.config.update(expected_labels=['Gene42'], expected_tags=['a'], panel_tags=True)
        good = module.audit([self.pdf(), self.jpeg()], self.config)
        for key in ('pdf_required_labels', 'pdf_panel_tags'):
            self.assertEqual(good['checks'][key], 'pass')
            self.assertNotIn(key, good['reviewable_checks'])
        for kwargs, key in ((dict(label='not Gene42'), 'pdf_required_labels'),
                            (dict(label=''), 'pdf_required_labels'), (dict(tag='A'), 'pdf_panel_tags'),
                            (dict(tag=''), 'pdf_panel_tags'), (dict(bold=False), 'pdf_panel_tags')):
            with self.subTest(kwargs=kwargs):
                result = module.audit([self.pdf(**kwargs), self.jpeg()], self.config)
                self.assertEqual(result['checks'][key], 'fail')
                self.assertNotIn(key, result['reviewable_checks'])
        self.config['expected_tags'] = ['a', 'b']
        self.assertEqual(module.audit([self.pdf(), self.jpeg()], self.config)['checks']['pdf_panel_tags'], 'fail')

    def test_no_requirements_and_unverified_geometry(self):
        result = module.audit([self.pdf(tag=''), self.jpeg()], self.config)
        self.assertEqual(result['checks']['pdf_required_labels'], 'not_applicable')
        self.assertEqual(result['checks']['pdf_panel_tags'], 'not_applicable')
        self.config.update(shared_row_labels=['Species a'], case='igs')
        result = module.audit([self.pdf(tag=''), self.jpeg()], self.config)
        for key in ('shared_row_alignment', 'scientific_name_italic', 'marker_dimensions', 'axis_tick_strokes'):
            self.assertEqual(result['checks'][key], 'unverified')
            self.assertIn(key, result['reviewable_checks'])
            self.assertTrue(result['details'][key]['reason'])

    def test_multiline_pdf_label_presence(self):
        self.config.update(expected_labels=['Gene\n42'], expected_tags=['a'], panel_tags=True)
        good = module.audit([self.pdf(label='Gene\n42'), self.jpeg()], self.config)
        self.assertEqual(good['checks']['pdf_required_labels'], 'pass')
        self.assertTrue(module.pdf_label_present('Gene\n42', [('Gene\n', 7, 'Arial'), ('42\n', 7, 'Arial')]))
        self.assertFalse(module.pdf_label_present('Gene\n42', [('not Gene\n42', 7, 'Arial')]))
        self.assertFalse(module.pdf_label_present('Gene\n42', [('Gene\nother\n42', 7, 'Arial')]))
        self.assertFalse(module.pdf_label_present('Gene42', [('not Gene42', 7, 'Arial')]))

    def test_text_presence_does_not_certify_visibility(self):
        self.config.update(expected_labels=['Gene42'], expected_tags=['a'], panel_tags=True)
        result = module.audit([self.pdf(), self.jpeg()], self.config)
        self.assertEqual(result['checks']['pdf_required_labels'], 'pass')
        self.assertEqual(result['checks']['pdf_panel_tags'], 'pass')
        self.assertEqual(result['checks']['pdf_text_visibility'], 'unverified')
        self.assertIn('pdf_text_visibility', result['reviewable_checks'])
        self.assertTrue(result['details']['pdf_text_visibility']['reason'])

    def test_invalid_format_contract(self):
        for formats in ([], ['jpg', 'jpg'], ['../jpg'], 'jpg', ['bad'], [None]):
            self.config['export_formats'] = formats
            self.assertEqual(module.audit([], self.config)['checks']['export_formats'], 'fail')


if __name__ == "__main__":
    unittest.main()
