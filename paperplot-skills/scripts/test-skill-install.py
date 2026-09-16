#!/usr/bin/env python3
"""Install/rollback checks use temporary directories, never the user's skill path."""
import os
import json
import shutil
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[2]
INSTALLER = REPO / 'install-paperplot-skill.sh'


class InstallTests(unittest.TestCase):
    def run_install(self, root, **extra):
        env = dict(os.environ, PAPERPLOT_DEST=str(root),
                   PAPERPLOT_SOURCE_DIR=str(REPO / 'paperplot-skills'))
        env.update(extra)
        return subprocess.run(['/bin/sh', str(INSTALLER)], env=env,
                              cwd='/private/tmp' if Path('/private/tmp').exists() else '/tmp',
                              capture_output=True, text=True)

    def test_runtime_commands_and_upgrade_backup(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            destination = root / 'paperplot-skills'
            destination.mkdir()
            (destination / 'old-marker').write_text('recoverable')
            result = self.run_install(root, PAPERPLOT_OVERWRITE='1')
            self.assertEqual(result.returncode, 0, result.stderr)
            backups = list(root.glob('paperplot-skills.backup-*'))
            self.assertEqual(len(backups), 1)
            self.assertEqual((backups[0] / 'old-marker').read_text(), 'recoverable')
            for name in ('family-qa-score.py', 'vision-review-adapter.py', 'figure-project.R',
                         'export-audit.py', 'check-environment.R'):
                self.assertTrue((destination / 'scripts' / name).is_file(), name)
            self.assertFalse((destination / 'reports').exists())
            receipt = json.loads((destination / 'installation.json').read_text())
            self.assertEqual(receipt['skill_version'], 'standalone-0.7.0-rc.1')
            self.assertIn('actual demo PDF/SVG/PNG', receipt['acceptance'])

    def test_missing_environment_does_not_replace_install(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder); destination = root / 'paperplot-skills'; destination.mkdir()
            (destination / 'old-marker').write_text('unchanged')
            result = self.run_install(root, PAPERPLOT_OVERWRITE='1', PAPERPLOT_ENV=str(root / 'absent-runtime'))
            self.assertNotEqual(result.returncode, 0)
            self.assertTrue((destination / 'old-marker').exists())

    def test_post_switch_failure_restores_previous_install(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder); destination = root / 'skills' / 'paperplot-skills'; destination.mkdir(parents=True)
            (destination / 'old-marker').write_text('unchanged')
            source = root / 'source'; shutil.copytree(REPO / 'paperplot-skills', source)
            (source / 'scripts' / 'install-self-test.R').write_text('stop("deliberate post-switch failure")\n')
            result = self.run_install(destination.parent, PAPERPLOT_OVERWRITE='1', PAPERPLOT_SOURCE_DIR=str(source))
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual((destination / 'old-marker').read_text(), 'unchanged')

    def test_failed_download_preserves_previous_install(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            destination = root / 'skills' / 'paperplot-skills'
            destination.mkdir(parents=True)
            (destination / 'old-marker').write_text('unchanged')
            fake = root / 'bin'; fake.mkdir()
            for name in ('curl', 'wget'):
                command = fake / name
                command.write_text('#!/bin/sh\nexit 42\n')
                command.chmod(0o755)
            result = self.run_install(destination.parent, PAPERPLOT_OVERWRITE='1',
                                      PAPERPLOT_SOURCE_DIR='', PATH=str(fake)+os.pathsep+os.environ['PATH'])
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual((destination / 'old-marker').read_text(), 'unchanged')

    def test_bad_profile_does_not_touch_destination(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder); destination = root / 'paperplot-skills'; destination.mkdir()
            (destination / 'old-marker').write_text('unchanged')
            result = self.run_install(root, PAPERPLOT_OVERWRITE='1', PAPERPLOT_PROFILE='invalid')
            self.assertNotEqual(result.returncode, 0)
            self.assertTrue((destination / 'old-marker').exists())

    def test_broken_link_is_preserved_as_backup(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder); destination = root / 'paperplot-skills'
            destination.symlink_to(root / 'no-longer-present')
            result = self.run_install(root, PAPERPLOT_OVERWRITE='1')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue((destination / 'SKILL.md').exists())
            self.assertTrue(next(root.glob('paperplot-skills.backup-*')).is_symlink())


if __name__ == '__main__':
    unittest.main()
