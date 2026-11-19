"""Copilot CLI の permissionRequest フックが単独の git コマンドだけを許可することを確認する。"""
import json
from pathlib import Path
import subprocess
import unittest

HOOK = Path(__file__).resolve().parents[1] / 'src/.copilot/scripts/allow-git.sh'


def decide(command: str) -> str:
    payload = json.dumps({'toolName': 'bash', 'toolInput': {'command': command}})
    result = subprocess.run(['bash', str(HOOK)], input=payload, capture_output=True, text=True, check=True)
    return result.stdout.strip()


class AllowGitTest(unittest.TestCase):
    def test_allows_git_commands(self):
        for command in ['git status', 'git push origin main', '  git reset --hard HEAD', 'git']:
            with self.subTest(command=command):
                self.assertEqual(json.loads(decide(command)), {'behavior': 'allow'})

    def test_falls_through_for_other_or_chained_commands(self):
        for command in [
            'gitea status',
            'echo git',
            'git status && rm -rf x',
            'git status; rm -rf x',
            'git log | sh',
            'git log > out',
            'git commit -m "$(whoami)"',
            'git commit -m `whoami`',
            'git status\nrm -rf x',
        ]:
            with self.subTest(command=command):
                self.assertEqual(decide(command), '')


if __name__ == '__main__':
    unittest.main()
