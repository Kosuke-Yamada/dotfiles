"""Check the three-way merge of the dotfiles-managed Claude Code settings."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / 'src/.claude/merge-settings.py'

ITERM_HOOK = {'hooks': [{'type': 'command', 'command': 'it2 handle-agent-hook'}]}
SHARED_HOOK = {'matcher': 'Bash', 'hooks': [{'type': 'command', 'command': 'shared.sh'}]}


class MergeSettingsTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.source, self.target, self.base = root / 'source.json', root / 'target.json', root / 'base.json'

    def tearDown(self):
        self.tmp.cleanup()

    def run_merge(self, source, target=None):
        self.source.write_text(json.dumps(source))
        if target is not None:
            self.target.write_text(json.dumps(target))
        subprocess.run([sys.executable, str(SCRIPT), str(self.source), str(self.target), str(self.base)],
                       check=True, capture_output=True)
        return json.loads(self.target.read_text())

    def test_creates_target_from_source(self):
        source = {'model': 'opus', 'hooks': {'Stop': [SHARED_HOOK]}}
        self.assertEqual(self.run_merge(source), source)
        self.assertEqual(json.loads(self.base.read_text()), source)

    def test_keeps_local_hooks_and_keys(self):
        source = {'model': 'opus', 'hooks': {'Stop': [SHARED_HOOK]}}
        target = {'model': 'sonnet', 'localOnly': True, 'hooks': {'Stop': [SHARED_HOOK, ITERM_HOOK], 'Notification': [ITERM_HOOK]}}
        merged = self.run_merge(source, target)
        self.assertEqual(merged['model'], 'opus')
        self.assertTrue(merged['localOnly'])
        self.assertEqual(merged['hooks']['Stop'], [SHARED_HOOK, ITERM_HOOK])
        self.assertEqual(merged['hooks']['Notification'], [ITERM_HOOK])

    def test_removes_what_source_dropped(self):
        first = {'theme': 'auto', 'permissions': {'allow': ['Bash(make *)', 'Bash(pnpm *)']}, 'hooks': {'Stop': [SHARED_HOOK]}}
        self.run_merge(first)
        target = json.loads(self.target.read_text())
        target['permissions']['allow'].append('Bash(ls *)')
        target['hooks']['Stop'].append(ITERM_HOOK)
        self.target.write_text(json.dumps(target))

        merged = self.run_merge({'permissions': {'allow': ['Bash(make *)']}})
        self.assertNotIn('theme', merged)
        self.assertEqual(merged['permissions']['allow'], ['Bash(make *)', 'Bash(ls *)'])
        self.assertEqual(merged['hooks'], {'Stop': [ITERM_HOOK]})

    def test_rejects_invalid_json(self):
        self.source.write_text('{')
        result = subprocess.run([sys.executable, str(SCRIPT), str(self.source), str(self.target), str(self.base)],
                                capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('JSON を読み込めません', result.stderr)


if __name__ == '__main__':
    unittest.main()
