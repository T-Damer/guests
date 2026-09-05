"""No downloads, engine or Apple tools needed for packaging helper regressions."""
import plistlib
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import package


class PackagingTests(unittest.TestCase):
    def test_rejects_path_traversal(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with zipfile.ZipFile(root / 'bad.zip', 'w') as archive:
                archive.writestr('Game.app/../../escape', 'bad')
            with self.assertRaises(RuntimeError):
                package.extract_app(root / 'bad.zip', root / 'out')
            self.assertFalse((root / 'escape').exists())

    def test_preserves_execute_permission_and_normalizes_only_outer_name(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with zipfile.ZipFile(root / 'app.zip', 'w') as archive:
                member = zipfile.ZipInfo('Old name.app/Contents/MacOS/Game')
                member.create_system = 3
                member.external_attr = 0o100755 << 16
                archive.writestr(member, b'example')
            bundle = package.extract_app(root / 'app.zip', root / 'out')
            binary = bundle / 'Contents/MacOS/Game'
            self.assertEqual(binary.read_bytes(), b'example')
            self.assertTrue(binary.stat().st_mode & 0o100)
            self.assertEqual(bundle.name, 'GUESTS.app')

    def test_rejects_symlink(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with zipfile.ZipFile(root / 'bad.zip', 'w') as archive:
                member = zipfile.ZipInfo('Game.app/Contents/link')
                member.create_system = 3
                member.external_attr = 0o120777 << 16
                archive.writestr(member, '/tmp/outside')
            with self.assertRaises(RuntimeError):
                package.extract_app(root / 'bad.zip', root / 'out')

    def test_rejects_single_architecture_binary(self):
        with tempfile.TemporaryDirectory() as temporary:
            bundle = Path(temporary) / 'GUESTS.app'
            (bundle / 'Contents/MacOS').mkdir(parents=True)
            (bundle / 'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleExecutable': 'Game'}))
            binary = bundle / 'Contents/MacOS/Game'
            binary.write_bytes(struct.pack('>II', 0xCAFEBABE, 1))
            binary.chmod(0o755)
            with self.assertRaises(RuntimeError):
                package.verify_macos(bundle)


if __name__ == '__main__':
    unittest.main()
