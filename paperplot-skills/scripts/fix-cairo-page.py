#!/usr/bin/env python3
"""Restore fractional MediaBox points truncated by R's Linux Cairo device."""
import math
import os
from pathlib import Path
import sys
import tempfile
from pypdf import PdfReader, PdfWriter
from pypdf.generic import RectangleObject


def fix_page(path, width_pt, height_pt):
    if not all(math.isfinite(v) and v > 0 for v in (width_pt, height_pt)):
        raise ValueError('Expected positive finite page dimensions')
    reader = PdfReader(path)
    if len(reader.pages) != 1:
        raise ValueError('Only a newly rendered single-page Cairo PDF is supported')
    page = reader.pages[0]
    if tuple(page.mediabox.lower_left) != (0, 0) or page.get('/Rotate', 0):
        raise ValueError('Unexpected page origin or rotation')
    actual = (float(page.mediabox.width), float(page.mediabox.height))
    expected = (width_pt, height_pt)
    if any(abs(a - b) > 1e-6 and (abs(a - math.floor(b)) > 1e-6 or not 0 <= b-a < 1) for a,b in zip(actual,expected)):
        raise ValueError(f'Not the known Cairo integer-point truncation: {actual} vs {expected}')
    if all(abs(a-b) < 1e-6 for a,b in zip(actual,expected)):
        return
    content = page.get_contents().get_data()
    writer = PdfWriter(clone_from=reader)
    writer.pages[0].mediabox = RectangleObject([0, 0, width_pt, height_pt])
    if '/CropBox' in writer.pages[0]:
        writer.pages[0].cropbox = RectangleObject([0, 0, width_pt, height_pt])
    fd, temporary = tempfile.mkstemp(prefix='.cairo-page-',suffix='.pdf',dir=Path(path).parent)
    try:
        with os.fdopen(fd,'wb') as f:
            writer.write(f)
        verified = PdfReader(temporary)
        assert verified.pages[0].get_contents().get_data() == content
        os.replace(temporary,path)
    finally:
        if os.path.exists(temporary): os.unlink(temporary)


if __name__ == '__main__':
    fix_page(sys.argv[1],float(sys.argv[2]),float(sys.argv[3]))
