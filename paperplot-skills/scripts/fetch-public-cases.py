#!/usr/bin/env python3
"""Fetch audited public inputs. Content drift is an error, never silently adopted."""
import argparse
import hashlib
from pathlib import Path
import tarfile
import tempfile
import urllib.request

SOURCES = {
    'airway.csv': ('https://raw.githubusercontent.com/stephenturner/deseq-to-fgsea/master/data/deseq-results-tidy-human-airway.csv', '30d728a302034b8cb807e5fc96384a5f4c23b0f75b4b333f093548f3309c68f6'),
    'exampleRanks.rda': ('https://raw.githubusercontent.com/alserglab/fgsea/master/data/exampleRanks.rda', '973ccb77ab36af2788b5f0d24ef520d008ca587102a82501ec2fd9b90a9f0bf5'),
    'examplePathways.rda': ('https://raw.githubusercontent.com/alserglab/fgsea/master/data/examplePathways.rda', '16d45fc4c3184ced29d9550e31176c73c3619cd4addc00989320b77ce4ba025e'),
    'CMplot_4.5.1.tar.gz': ('https://cran.r-project.org/src/contrib/Archive/CMplot/CMplot_4.5.1.tar.gz', '684661df212f9f7d2e4ec4263da39a759b5aa9bc304a41c008d8e62e79b08656'),
}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', default='visual-checks/public-inputs')
    args = parser.parse_args()
    root = Path(args.out); root.mkdir(parents=True, exist_ok=True)
    for name, (url, digest) in SOURCES.items():
        path = root / name
        if not path.exists():
            with tempfile.NamedTemporaryFile(dir=root, delete=False) as staging:
                temporary = Path(staging.name)
                try:
                    with urllib.request.urlopen(url, timeout=90) as response:
                        staging.write(response.read())
                except Exception:
                    temporary.unlink(missing_ok=True)
                    raise
            if hashlib.sha256(temporary.read_bytes()).hexdigest() != digest:
                temporary.unlink()
                raise SystemExit(f'Content hash changed: {url}')
            temporary.replace(path)
        if hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            raise SystemExit(f'Input hash mismatch: {path}')
        print(name, digest)
    with tarfile.open(root / 'CMplot_4.5.1.tar.gz') as archive:
        member = archive.getmember('CMplot/data/pig60K.rda')
        if not member.isfile():
            raise SystemExit('Unexpected archive member')
        destination = root / member.name
        destination.parent.mkdir(parents=True, exist_ok=True)
        payload = archive.extractfile(member).read()
        if destination.exists() and destination.read_bytes() != payload:
            raise SystemExit('Refusing to replace changed pig60K input')
        destination.write_bytes(payload)

if __name__ == '__main__':
    main()
