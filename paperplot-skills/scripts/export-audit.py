#!/usr/bin/env python3
"""Audit actual physical exports. Missing evidence is never a pass."""
import argparse
import hashlib
import json
import math
import re
import shutil
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path


IDENTITY = (1., 0., 0., 1., 0., 0.)


def multiply(a, b):
    return (a[0]*b[0]+a[2]*b[1], a[1]*b[0]+a[3]*b[1],
            a[0]*b[2]+a[2]*b[3], a[1]*b[2]+a[3]*b[3],
            a[0]*b[4]+a[2]*b[5]+a[4], a[1]*b[4]+a[3]*b[5]+a[5])


def point(matrix, x, y):
    return matrix[0]*x+matrix[2]*y+matrix[4], matrix[1]*x+matrix[3]*y+matrix[5]


def svg_transform(value):
    result = IDENTITY
    tokens = list(re.finditer(r'([A-Za-z]+)\s*\(([^)]*)\)', value or ''))
    if re.sub(r'([A-Za-z]+)\s*\(([^)]*)\)', '', value or '').strip(' ,\t\n'):
        raise ValueError('Unsupported SVG transform')
    for token in tokens:
        name = token[1]
        nums = [float(x) for x in re.split(r'[\s,]+', token[2].strip()) if x]
        if name == 'matrix' and len(nums) == 6:
            matrix = tuple(nums)
        elif name == 'translate' and len(nums) in (1,2):
            matrix = (1,0,0,1,nums[0],nums[1] if len(nums)==2 else 0)
        elif name == 'scale' and len(nums) in (1,2):
            matrix = (nums[0],0,0,nums[-1],0,0)
        elif name == 'rotate' and len(nums) in (1,3):
            angle = math.radians(nums[0]); c,s = math.cos(angle),math.sin(angle)
            matrix = (c,s,-s,c,0,0)
            if len(nums)==3:
                matrix = multiply(multiply((1,0,0,1,nums[1],nums[2]),matrix),(1,0,0,1,-nums[1],-nums[2]))
        elif name in ('skewX','skewY') and len(nums)==1:
            tangent = math.tan(math.radians(nums[0]))
            matrix = (1,0,tangent,1,0,0) if name=='skewX' else (1,tangent,0,1,0,0)
        else:
            raise ValueError('Unsupported SVG transform: '+name)
        result = multiply(result,matrix)
    return result


def svg_nodes(root):
    inherited = ('font-family','font-size','font-weight','font-style','text-anchor','stroke','stroke-width','stroke-linecap','fill')
    def walk(node, matrix, parent_style):
        if node.tag.split('}')[-1] in ('defs','clipPath','metadata','style','title','desc'):
            return
        style = dict(parent_style)
        style.update({key:node.get(key) for key in inherited if node.get(key) is not None})
        style.update({k:v.strip() for k,v in re.findall(r'([\w-]+)\s*:\s*([^;]+)',node.get('style',''))})
        matrix = multiply(matrix,svg_transform(node.get('transform')))
        yield node,matrix,style
        for child in node:
            yield from walk(child,matrix,style)
    yield from walk(root,IDENTITY,{})


def audit(paths, spec):
    checks, details = {}, {}
    expected = (spec["width_mm"], spec["height_mm"])
    allowed = list(spec["text_pt"].values())
    tol = spec["tolerance"]

    def dimension(key, actual):
        checks[key] = "pass" if all(abs(a - b) <= tol["page_mm"] for a, b in zip(actual, expected)) else "fail"
        details[key] = actual

    def typography(key, texts):
        bad = []
        for text, size, family in texts:
            if not text.strip():
                continue
            valid_size = any(abs(size - value) <= tol["font_pt"] for value in allowed)
            if abs(size - spec["text_pt"]["panel_tag"]) <= tol["font_pt"]:
                valid_size = bool(re.fullmatch(r"[A-Z]", text.strip()))
            font_name = family.split(",")[0].split("+")[-1]
            font_name = re.sub(r"[^a-z]", "", font_name.lower())
            arial = font_name in {"arial", "arialmt", "arialbold", "arialboldmt", "arialitalic", "arialitalicmt", "arialbolditalic", "arialbolditalicmt"}
            if not valid_size or not arial:
                bad.append(dict(text=text, size_pt=size, family=family))
        checks[key] = "fail" if bad else "pass" if texts else "unverified"
        details[key] = {"text_count": len(texts), "violations": bad}

    found = {p.suffix.lower() for p in paths}
    for ext in (".pdf", ".svg", ".png"):
        checks[ext + "_present"] = "pass" if ext in found else "unverified"
    for path in paths:
        if not path.exists():
            checks[str(path)] = "fail"
            continue
        ext = path.suffix.lower()
        details[path.name] = {"sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
        try:
            if ext == ".png":
                from PIL import Image
                with Image.open(path) as im:
                    checks["png_pixels"] = "pass" if all(abs(a - b / 25.4 * spec["dpi"]) <= 1 for a, b in zip(im.size, expected)) else "fail"
                    checks["png_rgb"] = "pass" if im.mode in ("RGB", "RGBA") else "fail"
            elif ext == ".pdf":
                from pypdf import PdfReader
                reader = PdfReader(path)
                checks["pdf_single_page"] = "pass" if len(reader.pages) == 1 else "fail"
                page = reader.pages[0]
                from pypdf.generic import ContentStream
                ops = ContentStream(page.get_contents(), reader).operations
                checks["pdf_rgb_or_gray"] = "fail" if any(op in (b"k", b"K") for _, op in ops) else "pass"
                dimension("pdf_page_mm", (float(page.mediabox.width) * 25.4 / 72, float(page.mediabox.height) * 25.4 / 72))
                texts = []

                def visitor(text, cm, tm, font, size):
                    scale = (cm[0] ** 2 + cm[1] ** 2) ** 0.5 * (tm[0] ** 2 + tm[1] ** 2) ** 0.5
                    texts.append((text, float(size) * scale, str((font or {}).get("/BaseFont", ""))))

                page.extract_text(visitor_text=visitor)
                typography("pdf_typography", texts)
                if shutil.which("pdffonts"):
                    rows = subprocess.check_output(["pdffonts", str(path)], text=True).splitlines()[2:]
                    checks["pdf_font_embedding"] = "pass" if rows and all(len(r.split()) >= 6 and r.split()[-5] == "yes" for r in rows) else "fail"
                    details["pdf_fonts"] = rows
                else:
                    checks["pdf_font_embedding"] = "unverified"
            elif ext == ".svg":
                root = ET.parse(path).getroot()

                def mm(value):
                    match = re.fullmatch(r"([\d.]+)(mm|cm|pt|px)?", value)
                    if not match:
                        raise ValueError("Unsupported SVG dimensions")
                    return float(match[1]) * {"mm": 1, "cm": 10, "pt": 25.4 / 72, "px": 25.4 / 96, None: 25.4 / 96}[match[2]]

                dimension("svg_page_mm", (mm(root.get("width", "")), mm(root.get("height", ""))))
                view = [float(x) for x in root.get("viewBox", "0 0 0 0").split()]
                scale_pt = mm(root.get("width")) / view[2] * 72 / 25.4
                texts, boxes, circles, row_positions = [], [], [], {}
                tags, axis_strokes, tick_strokes, medians, maxima = [], [], [], [], []
                shared_rows = spec.get("shared_row_labels") or []
                italic_rows = []
                unsupported_geometry = []
                for node, matrix, style in svg_nodes(root):
                    tag = node.tag.split("}")[-1]
                    sx = math.hypot(matrix[0],matrix[1]); sy = math.hypot(matrix[2],matrix[3])
                    if abs(sx-sy)>1e-6:
                        unsupported_geometry.append('non-uniform transform')
                    if tag in ('path','polygon','rect','image','use'):
                        unsupported_geometry.append(tag)
                    if tag in ("line", "polyline", "path") and style.get("stroke", "").strip().upper() == "#333333":
                        raw_stroke = style.get("stroke-width", "0")
                        stroke = float(re.match(r"[\d.]+", raw_stroke)[0]) * scale_pt * max(sx,sy)
                        if style.get("stroke-linecap", "").strip() == "square":
                            axis_strokes.append(stroke)
                        points = [float(v) for v in re.findall(r"-?[\d.]+", node.get("points", ""))]
                        if len(points) == 4:
                            length_pt = ((points[2]-points[0])**2 + (points[3]-points[1])**2)**.5 * scale_pt
                            if abs(length_pt - spec.get("tick_length_pt", 2.2)) < .03:
                                tick_strokes.append(stroke)
                    if tag in ('text','tspan'):
                        # Tspans are checked separately, with inherited font/transform.
                        text = node.text or ''
                        if not text.strip():
                            continue
                        raw_size = style.get("font-size", node.get("font-size", "0"))
                        match = re.fullmatch(r'([\d.]+)(px)?',raw_size.strip())
                        if not match:
                            raise ValueError('Unsupported SVG font unit: '+raw_size)
                        raw_numeric = float(match[1])
                        size = raw_numeric * scale_pt * sy
                        family = style.get("font-family", node.get("font-family", ""))
                        texts.append((text, size, family))
                        if text in shared_rows:
                            row_positions.setdefault(text, []).append(point(matrix,float(node.get('x',0)),float(node.get('y',0)))[1] * scale_pt * 25.4 / 72)
                            italic_rows.append(style.get("font-style") == "italic")
                        if abs(size - spec["text_pt"]["panel_tag"]) <= tol["font_pt"]:
                            tags.append((text, style.get("font-weight") in ("bold", "700")))
                        if tag == 'tspan' and (node.get('x') is None or node.get('y') is None):
                            unsupported_geometry.append('relative tspan positioning')
                            continue
                        if node.get('dx') is not None or node.get('dy') is not None:
                            unsupported_geometry.append('relative text offsets')
                            continue
                        x, y = float(node.get("x", 0)), float(node.get("y", 0))
                        width = float(re.match(r"[\d.]+", node.get("textLength", "0"))[0])
                        if width:
                            anchor = style.get("text-anchor", "start")
                            x -= width if anchor == "end" else width / 2 if anchor == "middle" else 0
                            corners = [point(matrix,px,py) for px,py in ((x,y-raw_numeric),(x+width,y-raw_numeric),(x+width,y),(x,y))]
                            boxes.append((text,min(c[0] for c in corners),min(c[1] for c in corners),max(c[0] for c in corners),max(c[1] for c in corners)))
                        else:
                            unsupported_geometry.append('text without textLength')
                    elif tag == "circle":
                        cx,cy = point(matrix,float(node.get('cx',0)),float(node.get('cy',0)))
                        circles.append((cx,cy,float(node.get('r',0))*max(sx,sy)))
                        if style.get("fill", "").strip().upper() == "#173B73":
                            medians.append(float(node.get("r")) * 2 * scale_pt)
                    elif tag == "polygon" and style.get("fill", "").strip().upper() == "#D55E00":
                        coords = [float(v) for v in re.findall(r"-?[\d.]+", node.get("points", ""))]
                        maxima.append((max(coords[1::2]) - min(coords[1::2])) * scale_pt)
                typography("svg_typography", texts)
                expected_labels = spec.get('expected_labels') or []
                normalize_text = lambda x: re.sub(r'\s+', ' ', x).strip()
                actual_labels = {normalize_text(t) for t, _, _ in texts}
                missing_labels = [t for t in expected_labels if normalize_text(t) not in actual_labels]
                checks['svg_required_labels'] = ('fail' if missing_labels else 'pass') if expected_labels else 'not_applicable'
                details['svg_required_labels'] = {'missing': missing_labels, 'expected': expected_labels,
                    'reason': 'Explicit single-line required labels' if expected_labels else 'No direct-label requirement was declared for this figure'}
                if axis_strokes and tick_strokes and "stroke_pt" in spec:
                    checks["axis_tick_strokes"] = "pass" if all(abs(x-spec["stroke_pt"]["axis"]) <= .06 for x in axis_strokes) and all(abs(x-spec["stroke_pt"]["tick"]) <= .06 for x in tick_strokes) else "fail"
                    details["axis_tick_strokes_pt"] = sorted(set(axis_strokes + tick_strokes))
                expected_tags = spec.get('expected_tags')
                if expected_tags is None:
                    expected_tags = list('ABCDEFGHIJKLMNOPQRSTUVWXYZ'[:spec.get('n_panels',1)]) if spec.get('panel_tags',spec.get('n_panels',1)>1) else []
                checks['svg_panel_tags'] = ('pass' if all(bold for _,bold in tags) and sorted(t.strip() for t,_ in tags)==sorted(expected_tags)
                                            else 'fail') if expected_tags or tags else 'not_applicable'
                details['expected_panel_tags'] = expected_tags
                if shared_rows:
                    checks["shared_row_alignment"] = "unverified"
                    if all(len(row_positions.get(label, [])) == spec["n_panels"] for label in shared_rows):
                        checks["shared_row_alignment"] = "pass" if all(max(v) - min(v) <= tol["row_mm"] for v in row_positions.values()) else "fail"
                    details["shared_row_positions_mm"] = row_positions
                    checks["scientific_name_italic"] = "pass" if italic_rows and all(italic_rows) else "fail"
                if spec.get("case") == "igs":
                    strings = [t.strip() for t, _, _ in texts]
                    checks["count_column_header"] = "pass" if strings.count("n") == 1 and not any(re.match(r"n\s*=", t) for t in strings) else "fail"
                    checks["marker_dimensions"] = "pass" if medians and maxima and all(abs(x - 4.5) < .1 for x in medians) and all(abs(x - 5) < .1 for x in maxima) else "fail"
                    details["marker_dimensions_pt"] = {"circle_diameters": medians, "triangle_heights": maxima}
                checks["svg_editable_text"] = "pass" if texts else "fail"
                details["svg_font_dependency"] = "Arial must be installed in the editing environment; text elements do not imply font embedding."
                collisions = []
                for text, x0, y0, x1, y1 in boxes:
                    for cx, cy, radius in circles:
                        dx, dy = max(x0 - cx, 0, cx - x1), max(y0 - cy, 0, cy - y1)
                        if dx * dx + dy * dy < (radius + .2 * 72 / 25.4 / scale_pt) ** 2:
                            collisions.append({"text": text, "bbox": [x0, y0, x1, y1], "circle": [cx, cy, radius]})
                checks["svg_text_mark_clearance"] = "warn" if collisions else "unverified" if unsupported_geometry else "pass"
                details["svg_text_mark_clearance"] = {"method": "textLength rectangles vs circles; other marks require visual review", "collisions": collisions}
                text_pairs = []
                outside = []
                for i, a in enumerate(boxes):
                    if a[1]<view[0] or a[2]<view[1] or a[3]>view[0]+view[2] or a[4]>view[1]+view[3]:
                        outside.append({'text':a[0],'bbox':a[1:]})
                    for b in boxes[i+1:]:
                        if min(a[3],b[3])>max(a[1],b[1]) and min(a[4],b[4])>max(a[2],b[2]):
                            text_pairs.append({'text':[a[0],b[0]],'boxes':[a[1:],b[1:]]})
                checks['svg_text_text_clearance'] = 'warn' if text_pairs else 'unverified' if unsupported_geometry else 'pass'
                checks['svg_text_bounds'] = 'warn' if outside else 'unverified' if unsupported_geometry else 'pass'
                details['svg_text_text_clearance'] = text_pairs
                details['svg_text_bounds'] = outside
                details['unsupported_geometry'] = sorted(set(unsupported_geometry))
        except (ImportError, ValueError, OSError, subprocess.SubprocessError, ET.ParseError,TypeError,IndexError,ZeroDivisionError) as exc:
            checks[ext + "_audit"] = "unverified"
            details[ext + "_error"] = str(exc)
    status = "fail" if "fail" in checks.values() else "warn" if "warn" in checks.values() else "unverified" if "unverified" in checks.values() else "pass"
    reviewable = ['svg_text_mark_clearance','svg_text_text_clearance','svg_text_bounds']
    return {"version": "2.0", "status": status, "checks": checks, "details": details,
            'reviewable_checks':[k for k in reviewable if checks.get(k) in ('warn','unverified')]}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--spec", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("paths", nargs="+")
    args = parser.parse_args()
    result = audit([Path(x) for x in args.paths], json.loads(Path(args.spec).read_text()))
    Path(args.out).write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n")
    raise SystemExit(2 if result["status"] == "fail" else 0)
