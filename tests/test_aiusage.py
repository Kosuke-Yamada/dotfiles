"""Exercise the SwiftBar AI usage plugin's parsing and rendering (no network)."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

PLUGIN = Path(__file__).resolve().parents[1] / 'src/.config/swiftbar/plugins/aiusage.5m.py'
spec = importlib.util.spec_from_file_location('aiusage', PLUGIN)
aiusage = importlib.util.module_from_spec(spec)
spec.loader.exec_module(aiusage)

NOW = 1_793_000_000.0

CLAUDE_CACHE = {
    '_fetched_at': NOW - 30,
    'five_hour': None,
    'seven_day': None,
    'extra_usage': {'used_credits': 92477.0, 'monthly_limit': 120000, 'utilization': 77.06},
}

CODEX_RESPONSE = {
    'plan_type': 'business',
    'rate_limit': None,
    'spend_control': {
        'reached': False,
        'individual_limit': {
            'unit': 'credit',
            'limit': '20000',
            'used': '3582.43',
            'reset_at': NOW + 4 * 86400 + 3600,
        },
    },
}


class ParseTest(unittest.TestCase):
    def test_claude_credits_are_converted_from_cents(self):
        b = aiusage.parse_claude(CLAUDE_CACHE)
        self.assertAlmostEqual(aiusage.remaining(b), 275.23)
        self.assertEqual(b.unit, 'usd')

    def test_claude_without_monthly_limit_is_failure(self):
        self.assertIsInstance(aiusage.parse_claude({'extra_usage': None}), aiusage.Failure)

    def test_codex_spend_control(self):
        b = aiusage.parse_codex(CODEX_RESPONSE, NOW)
        self.assertAlmostEqual(aiusage.remaining(b), 16417.57)
        self.assertEqual(b.unit, 'credit')
        self.assertEqual(b.reset_at, NOW + 4 * 86400 + 3600)

    def test_codex_without_spend_control_is_failure(self):
        self.assertIsInstance(aiusage.parse_codex({'spend_control': None}, NOW), aiusage.Failure)

    def test_overspent_budget_never_goes_negative(self):
        b = aiusage.Budget(used=130, limit=100, unit='usd', fetched_at=NOW, reset_at=None)
        self.assertEqual(aiusage.remaining(b), 0)


class RenderTest(unittest.TestCase):
    def test_title_shows_used_percent(self):
        out = aiusage.render(aiusage.parse_claude(CLAUDE_CACHE), aiusage.parse_codex(CODEX_RESPONSE, NOW), NOW)
        title = out.splitlines()[0]
        # SwiftBar は最初の "|" 以降をパラメータとみなすため、表示部分に "|" を含めない
        self.assertEqual(title.split(' | ')[0], 'CC 77% · CX 18%')
        self.assertIn('--残り $275.23 / $1,200.00', out)
        # Claude の残りが 23% なので警告色になる
        self.assertIn('color=#f5a524', title)
        self.assertIn('--リセット', out)
        self.assertIn('(あと 4日1時間)', out)

    def test_failure_is_shown_with_message(self):
        out = aiusage.render(aiusage.Failure('boom'), aiusage.parse_codex(CODEX_RESPONSE, NOW), NOW)
        self.assertTrue(out.startswith('CC - · CX 18% |'))
        self.assertIn('--boom | color=#e5484d', out)

    def test_stale_value_is_marked(self):
        stale = aiusage.parse_codex(CODEX_RESPONSE, NOW - 3600)
        out = aiusage.render(aiusage.parse_claude(CLAUDE_CACHE), stale, NOW)
        self.assertIn('--1時間0分前の値', out)


class LoadCodexTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.orig_cache = aiusage.CODEX_CACHE
        aiusage.CODEX_CACHE = Path(self.tmp.name) / 'codex-usage.json'
        self.addCleanup(setattr, aiusage, 'CODEX_CACHE', self.orig_cache)

    def test_falls_back_to_cached_response_on_failure(self):
        aiusage.load_codex(NOW - 3600, fetch=lambda: CODEX_RESPONSE)

        def failing():
            raise RuntimeError('使用状況 API が HTTP 500 を返しました')

        b = aiusage.load_codex(NOW, fetch=failing)
        self.assertIsInstance(b, aiusage.Budget)
        self.assertEqual(b.fetched_at, NOW - 3600)

    def test_reports_error_without_cache(self):
        def failing():
            raise RuntimeError('トークンの期限切れ')

        r = aiusage.load_codex(NOW, fetch=failing)
        self.assertEqual(r, aiusage.Failure('トークンの期限切れ'))


if __name__ == '__main__':
    unittest.main()
