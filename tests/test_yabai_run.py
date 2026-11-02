"""Exercise timeout/recovery against a separate fake daemon client (no desktop changes)."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

WRAPPER = Path(__file__).resolve().parents[1] / 'src/.local/bin/yabai-run'
FAKE = r'''#!/usr/bin/perl
use strict;
use warnings;
use JSON::PP qw(encode_json);
use Time::HiRes qw(time sleep);
my $root = $ENV{FAKE_ROOT};
open my $calls, '>>', "$root/calls" or die $!;
print {$calls} encode_json(\@ARGV), "\n";
close $calls;
my $mode = $ENV{FAKE_MODE} // 'hang';
if ($ARGV[0] eq '--restart-service') {
    if ($mode eq 'restart-fail') {
        print STDERR "restart denied\n";
        exit 3;
    }
    sleep 20 if $mode eq 'restart-hang';
    open my $ready, '>', "$root/ready" or die $!;
    print {$ready} time + ($ENV{FAKE_DELAY} // 0);
    close $ready;
    exit 0;
}
if ($mode eq 'ok') {
    print encode_json(\@ARGV), "\n";
    exit 0;
}
if ($mode eq 'error') {
    print STDERR "could not locate a window\n";
    exit 1;
}
if (open my $ready, '<', "$root/ready") {
    my $at = <$ready>;
    close $ready;
    exit(time >= $at ? 0 : 1) if $ARGV[1] eq 'query';
    if ($mode ne 'retry-hang') {
        print "recovered\n";
        exit 0;
    }
}
if ($mode eq 'disconnect') {
    print STDERR "yabai-msg: failed to connect to socket..\n";
    exit 1;
}
sleep 20;
'''


class YabaiRunTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        fake = self.root / 'yabai'
        fake.write_text(FAKE)
        fake.chmod(0o755)
        self.env = dict(os.environ, TMPDIR=self.tmp.name, FAKE_ROOT=self.tmp.name,
                        YABAI_RUN_BIN=str(fake), YABAI_RUN_TIMEOUT='2',
                        YABAI_RUN_READY_TIMEOUT='10', YABAI_RUN_RESTART_TIMEOUT='10')

    def run_wrapper(self, **env):
        return subprocess.run([str(WRAPPER), 'window', '--focus', 'a b'],
                              env=dict(self.env, **env), text=True,
                              capture_output=True, timeout=25)

    def calls(self):
        return [json.loads(line) for line in (self.root / 'calls').read_text().splitlines()]

    def restarts(self):
        return self.calls().count(['--restart-service'])

    def test_normal_output_and_arguments(self):
        result = self.run_wrapper(FAKE_MODE='ok')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), ['-m', 'window', '--focus', 'a b'])
        self.assertEqual(self.restarts(), 0)

    def test_operation_error_does_not_restart(self):
        result = self.run_wrapper(FAKE_MODE='error')
        self.assertEqual(result.returncode, 1)
        self.assertIn('could not locate a window', result.stderr)
        self.assertEqual(self.restarts(), 0)

    def test_slow_startup_gets_separate_deadline(self):
        result = self.run_wrapper(FAKE_DELAY='3')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('recovered', result.stdout)
        self.assertEqual(self.restarts(), 1)

    def test_disconnected_service_recovers(self):
        result = self.run_wrapper(FAKE_MODE='disconnect')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.restarts(), 1)

    def test_restart_failure_stops_immediately(self):
        result = self.run_wrapper(FAKE_MODE='restart-fail')
        self.assertEqual(result.returncode, 3, result.stderr)
        self.assertIn('restart denied', result.stderr)
        self.assertFalse(any(call[1:2] == ['query'] for call in self.calls()))

    def test_restart_itself_has_a_deadline(self):
        result = self.run_wrapper(FAKE_MODE='restart-hang', YABAI_RUN_RESTART_TIMEOUT='2')
        self.assertEqual(result.returncode, 142, result.stderr)
        self.assertEqual(self.restarts(), 1)

    def test_startup_deadline_is_bounded(self):
        result = self.run_wrapper(FAKE_DELAY='20', YABAI_RUN_READY_TIMEOUT='0.6')
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertEqual(self.restarts(), 1)

    def test_retry_is_bounded_and_does_not_restart_twice(self):
        result = self.run_wrapper(FAKE_MODE='retry-hang')
        self.assertEqual(result.returncode, 142, result.stderr)
        self.assertEqual(self.restarts(), 1)

    def test_concurrent_timeouts_only_restart_once(self):
        env = dict(self.env, FAKE_DELAY='1')
        processes = [subprocess.Popen([str(WRAPPER), 'window', '--focus', 'east'],
                                     env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                     for _ in range(6)]
        for process in processes:
            process.communicate(timeout=25)
        self.assertEqual(self.restarts(), 1)
        self.assertEqual(sorted(p.returncode for p in processes), [0, 75, 75, 75, 75, 75])

    def test_killed_recovery_does_not_leave_stale_lock(self):
        process = subprocess.Popen([str(WRAPPER), 'window', '--focus', 'east'],
                                   env=dict(self.env, FAKE_DELAY='20'),
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            deadline = time.monotonic() + 8
            while not (self.root / 'ready').exists():
                self.assertLess(time.monotonic(), deadline)
                time.sleep(0.02)
            start = time.monotonic()
            busy = self.run_wrapper()
            self.assertEqual(busy.returncode, 75)
            self.assertLess(time.monotonic() - start, 1.5)
        finally:
            process.kill()
            process.communicate(timeout=2)
        result = self.run_wrapper(FAKE_MODE='ok')
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main()
