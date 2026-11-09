"""Exercise the SwiftBar AI usage plugin's parsing and rendering (no network)."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

PLUGIN = Path(__file__).resolve().parents[1] / 'src/.config/swiftbar/plugins/aiusage.5m.py'
spec = importlib.util.spec_from_file_location('aiusage', PLUGIN)
aiusage = importlib.util.module_from_spec(spec)
# プラグインフォルダに __pycache__ を作ると SwiftBar が別プラグインとして読み込み「?」アイコンが出る
sys.dont_write_bytecode = True
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

COPILOT_RESPONSE = {
    'quota_reset_date_utc': '2026-12-01T00:00:00.000Z',
    'quota_snapshots': {
        'premium_interactions': {
            'entitlement': 50000, 'remaining': 40000,
            'token_based_billing': True, 'unlimited': False,
            'overage_permitted': True,
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
        self.assertEqual(title.split(' | ')[0], 'CC77% CX18%')
        self.assertIn('--残り $275.23 / $1,200.00', out)
        # Claude の残りが 23% なので警告色になる
        self.assertIn('color=#f5a524', title)
        self.assertIn('--リセット', out)
        self.assertIn('(あと 4日1時間)', out)

    def test_failure_is_shown_with_message(self):
        out = aiusage.render(aiusage.Failure('boom'), aiusage.parse_codex(CODEX_RESPONSE, NOW), NOW)
        self.assertTrue(out.startswith('CC- CX18% |'))
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


class CopilotTest(unittest.TestCase):
    def test_monthly_quota_and_overage_permission(self):
        """残枠から使用率を算出し、超過許可と UTC リセット時刻を保持する。"""
        budget = aiusage.parse_copilot(COPILOT_RESPONSE, NOW)
        self.assertEqual(budget.used, 10000)
        self.assertEqual(aiusage.used_percent(budget), 20)
        self.assertEqual(budget.reset_at, 1796083200)
        self.assertTrue(budget.overage_allowed)
        self.assertEqual(budget.unit, 'credit')

    def test_missing_or_invalid_quota_is_failure(self):
        """不明な使用枠を誤って 0% と表示しない。"""
        for response in ({}, {'quota_snapshots': {}}, {'quota_snapshots': {
            'premium_interactions': {'entitlement': 0, 'remaining': 0},
        }}, {'quota_snapshots': {'premium_interactions': {
            'entitlement': 100, 'remaining': -1,
        }}}):
            with self.subTest(response=response):
                self.assertIsInstance(aiusage.parse_copilot(response, NOW), aiusage.Failure)

    def test_title_and_details_include_copilot(self):
        """Copilot の使用率と超過利用の説明を追加する。"""
        output = aiusage.render(aiusage.parse_claude(CLAUDE_CACHE),
                                aiusage.parse_codex(CODEX_RESPONSE, NOW), NOW,
                                aiusage.parse_copilot(COPILOT_RESPONSE, NOW))
        self.assertEqual(output.split(' | ')[0], 'CC77% CX18% CP20%')
        self.assertIn('GitHub Copilot', output)
        self.assertIn('--残り 40,000 / 50,000 credit', output)
        self.assertIn('--超過利用: 許可', output)

    def test_copilot_failure_does_not_hide_other_services(self):
        """Copilot が失敗しても他サービスの値を表示する。"""
        output = aiusage.render(aiusage.parse_claude(CLAUDE_CACHE),
                                aiusage.parse_codex(CODEX_RESPONSE, NOW), NOW,
                                aiusage.Failure('Copilot authentication failed'))
        self.assertTrue(output.startswith('CC77% CX18% CP- |'))
        self.assertIn('--Copilot authentication failed', output)

    def test_cached_value_survives_network_failure(self):
        """一時的な取得失敗時は元の取得日時と値を維持する。"""
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(aiusage, 'COPILOT_CACHE', Path(directory) / 'usage.json'):
                aiusage.load_copilot(NOW - 3600, fetch=lambda: COPILOT_RESPONSE)
                with patch.object(aiusage, 'fetch_copilot_usage', side_effect=RuntimeError('offline')) as fetch:
                    budget = aiusage.load_copilot(NOW, fetch=fetch)
                self.assertEqual(budget.fetched_at, NOW - 3600)
                self.assertEqual(budget.used, 10000)

    def test_missing_gh_returns_useful_error(self):
        """gh 未導入時にも例外でプラグイン全体を停止しない。"""
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(aiusage, 'COPILOT_CACHE', Path(directory) / 'usage.json'):
                with patch.object(aiusage, 'fetch_copilot_usage', side_effect=FileNotFoundError('gh')) as fetch:
                    result = aiusage.load_copilot(NOW, fetch=fetch)
                self.assertIsInstance(result, aiusage.Failure)
                self.assertIn('gh', result.message)


if __name__ == '__main__':
    unittest.main()
