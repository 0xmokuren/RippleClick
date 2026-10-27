"""Offline workflow boundaries and orchestration tests. Never use real signing or Git credentials."""
import base64
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import subprocess
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
FAKE_TOOLS = r'''#!/usr/bin/env python3
import json, os, pathlib, sys, zipfile
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['TOOL_LOG'], 'a') as log:
    log.write(json.dumps({'tool': name, 'verb': args[0] if args else ''}) + '\n')
if name == 'uuidgen':
    print('offline-keychain-password')
elif name == 'security':
    if args[0] == 'import' and os.environ.get('FAIL_IMPORT') == '1': sys.exit(1)
    if args[0] == 'create-keychain': pathlib.Path(args[-1]).touch()
elif name == 'codesign':
    pass
elif name == 'spctl':
    pass
elif name == 'xcrun':
    if args[:2] == ['notarytool', 'submit']:
        print(json.dumps({'status': 'Accepted', 'id': 'offline-submission'}))
    elif args[:2] == ['stapler', 'staple'] and os.environ.get('FAIL_STAPLE') == '1':
        sys.exit(68)
elif name == 'ditto':
    if args[:2] == ['-x', '-k']:
        with zipfile.ZipFile(args[2]) as archive: archive.extractall(args[3])
    else:
        app = pathlib.Path(args[-2])
        with zipfile.ZipFile(args[-1], 'w') as archive:
            for path in app.rglob('*'):
                if path.is_file(): archive.write(path, path.relative_to(app.parent))
elif name == 'git':
    clean = list(args)
    while clean and clean[0] == '-c': clean = clean[2:]
    if clean[0] == 'clone':
        assert clean[1] == 'https://github.com/0xmokuren/homebrew-tap.git'
        assert os.environ['GH_TOKEN'] not in ' '.join(args)
        if os.environ.get('FAIL_AUTH') == '1': sys.exit(128)
        repo = pathlib.Path(clean[-1]); (repo/'Casks').mkdir(parents=True)
        (repo/'Casks/rippleclick.rb').write_text('cask "rippleclick" do\n  version "0.0.1"\n  sha256 "' + '0'*64 + '"\n  desc "preserve this text"\nend\n')
    elif clean[0] == 'diff':
        sys.exit(0 if os.environ.get('NO_CHANGE') == '1' else 1)
    elif clean[0] == 'push':
        password = __import__('subprocess').check_output([os.environ['GIT_ASKPASS'], 'Password for GitHub:'], text=True).strip()
        assert password == os.environ['GH_TOKEN']
        cask = pathlib.Path('Casks/rippleclick.rb').read_text()
        assert 'version "1.2.3"' in cask and 'desc "preserve this text"' in cask
        assert os.environ['GH_TOKEN'] not in cask
'''


def workflow(name):
    ruby = "require 'yaml'; require 'json'; puts JSON.generate(YAML.safe_load(File.read(ARGV[0]), aliases: false))"
    return json.loads(subprocess.check_output(['ruby', '-e', ruby, str(ROOT / '.github/workflows' / name)], text=True))


class WorkflowBoundaries(unittest.TestCase):
    def test_only_publish_can_write_and_secrets_are_separated(self):
        release = workflow('release.yml')
        self.assertEqual(release['permissions'], {'contents': 'read'})
        self.assertEqual(set(release['jobs']), {'build', 'sign', 'publish', 'tap'})
        for name, job in release['jobs'].items():
            permissions = job.get('permissions', release['permissions'])
            self.assertEqual(permissions, {'contents': 'write' if name == 'publish' else 'read'})
            secrets = re.findall(r'secrets\.([A-Z_0-9]+)', json.dumps(job))
            if name in ['build', 'publish']:
                self.assertEqual(secrets, [])
            elif name == 'tap':
                self.assertEqual(secrets, ['HOMEBREW_TAP_TOKEN'])
            else:
                self.assertEqual(len(secrets), 6)
                self.assertNotIn('HOMEBREW_TAP_TOKEN', secrets)
        self.assertEqual(release['jobs']['publish']['needs'], ['build', 'sign'])
        self.assertEqual(release['jobs']['tap']['needs'], ['build', 'sign', 'publish'])
        publisher = release['jobs']['publish']['steps'][-1]
        self.assertIs(publisher['with']['overwrite_files'], False)
        triggers = release.get('on', release.get('true'))
        self.assertEqual(set(triggers), {'push'})
        self.assertEqual(triggers['push']['tags'], ['v*'])

    def test_actions_pinned_credentials_not_persisted_and_artifacts_scoped(self):
        for file in ['ci.yml', 'release.yml']:
            data = workflow(file)
            self.assertEqual(data['permissions'], {'contents': 'read'})
            for job in data['jobs'].values():
                for step in job['steps']:
                    action = step.get('uses', '')
                    if action:
                        self.assertRegex(action, r'^[\w./-]+@[0-9a-f]{40}$')
                    if action.startswith('actions/checkout@'):
                        self.assertIs(step['with']['persist-credentials'], False)
                    if action.startswith('actions/download-artifact@'):
                        self.assertIn('artifact-ids', step['with'])
                        self.assertNotIn('github-token', step['with'])
                    if file == 'release.yml' and action.startswith('actions/upload-artifact@'):
                        self.assertNotIn('**', step['with']['path'])
                        self.assertNotIn('ripple-sign', step['with']['path'])
                        self.assertIn('github.run_attempt', step['with']['name'])


class OfflineScripts(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='ripple-offline-')
        self.addCleanup(self.tmp.cleanup)
        self.path = Path(self.tmp.name)
        tools = self.path / 'bin'; tools.mkdir()
        for name in ['security', 'codesign', 'xcrun', 'spctl', 'ditto', 'uuidgen', 'git']:
            p = tools / name; p.write_text(FAKE_TOOLS); p.chmod(0o700)
        runtime = self.path / 'runtime'; runtime.mkdir()
        tmpdir = self.path / 'system-temp'; tmpdir.mkdir()
        self.env = {k: v for k, v in os.environ.items() if k not in ['GH_TOKEN', 'GITHUB_TOKEN', 'SIGNING_IDENTITY']}
        self.env.update(PATH=str(tools) + os.pathsep + os.environ['PATH'], RUNNER_TEMP=str(runtime), TMPDIR=str(tmpdir),
                        TOOL_LOG=str(self.path/'tools.jsonl'), GITHUB_OUTPUT=str(self.path/'outputs'),
                        DEVELOPER_ID_CERT_P12_BASE64=base64.b64encode(b'offline-not-a-certificate').decode(),
                        DEVELOPER_ID_CERT_PASSWORD='offline-not-a-real-password',
                        SIGNING_IDENTITY='Developer ID Application: Offline Test (TEST)',
                        NOTARY_API_KEY_P8_BASE64=base64.b64encode(b'offline-not-a-private-key').decode(),
                        NOTARY_API_KEY_ID='OFFLINE', NOTARY_API_ISSUER_ID='offline-issuer',
                        GH_TOKEN='offline-token-marker-not-a-credential')
        self.input = self.path/'input'; self.input.mkdir()
        info = {'CFBundleIdentifier': 'com.0xmokuren.RippleClick', 'CFBundleVersion': '1.2.3', 'CFBundleShortVersionString': '1.2.3'}
        with zipfile.ZipFile(self.input/'unsigned-app.zip', 'w') as z:
            z.writestr('RippleClick.app/Contents/Info.plist', plistlib.dumps(info))
            z.writestr('RippleClick.app/Contents/MacOS/RippleClick', b'offline fixture - never executed')
        (self.input/'signing-entitlements.plist').write_bytes(plistlib.dumps({}))
        (self.input/'release-notes.md').write_text('Offline release notes\n')
        self.sha = hashlib.sha256((self.input/'unsigned-app.zip').read_bytes()).hexdigest()
        self.output = self.path/'output'

    def run_script(self, name, *args):
        return subprocess.run(['bash', str(ROOT/'scripts/release'/name), *map(str, args)], env=self.env,
                              text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    def tools(self):
        p = self.path/'tools.jsonl'
        return [json.loads(line) for line in p.read_text().splitlines()] if p.exists() else []

    def assert_private_material_cleaned(self):
        self.assertEqual(list((self.path/'runtime').glob('ripple-sign.*')), [])
        self.assertTrue(any(x == {'tool': 'security', 'verb': 'delete-keychain'} for x in self.tools()))

    def test_sign_success_only_public_payload_remains(self):
        result = self.run_script('sign-notarize.sh', self.input, self.output, '1.2.3', self.sha)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assert_private_material_cleaned()
        self.assertEqual(sorted(p.name for p in self.output.iterdir()), ['RippleClick-1.2.3.zip', 'release-notes.md'])
        with zipfile.ZipFile(self.output/'RippleClick-1.2.3.zip') as z:
            self.assertFalse(any(name.endswith(('.p8', '.p12')) for name in z.namelist()))
        self.assertNotIn(self.env['DEVELOPER_ID_CERT_PASSWORD'], result.stdout)

    def test_import_failure_cleans_material_and_does_not_notarize(self):
        self.env['FAIL_IMPORT'] = '1'
        result = self.run_script('sign-notarize.sh', self.input, self.output, '1.2.3', self.sha)
        self.assertNotEqual(result.returncode, 0)
        self.assert_private_material_cleaned()
        self.assertFalse(any(x['tool'] == 'xcrun' for x in self.tools()))

    def test_staple_failure_does_not_publish_payload_and_cleans(self):
        self.env['FAIL_STAPLE'] = '1'
        result = self.run_script('sign-notarize.sh', self.input, self.output, '1.2.3', self.sha)
        self.assertNotEqual(result.returncode, 0)
        self.assert_private_material_cleaned()
        self.assertFalse(self.output.exists())

    def test_wrong_digest_never_imports_credentials(self):
        result = self.run_script('sign-notarize.sh', self.input, self.output, '1.2.3', '0'*64)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.tools(), [])

    def test_unexpected_entitlements_never_import_credentials(self):
        (self.input/'signing-entitlements.plist').write_bytes(plistlib.dumps({'com.apple.security.get-task-allow': True}))
        result = self.run_script('sign-notarize.sh', self.input, self.output, '1.2.3', self.sha)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(x == {'tool': 'security', 'verb': 'import'} for x in self.tools()))
        self.assert_private_material_cleaned()

    def test_archive_traversal_is_rejected_before_import(self):
        with zipfile.ZipFile(self.input/'unsigned-app.zip', 'a') as archive:
            archive.writestr('../outside', b'offline malicious fixture')
        sha = hashlib.sha256((self.input/'unsigned-app.zip').read_bytes()).hexdigest()
        result = self.run_script('sign-notarize.sh', self.input, self.output, '1.2.3', sha)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(x == {'tool': 'security', 'verb': 'import'} for x in self.tools()))
        self.assertFalse((self.path/'outside').exists())
        self.assert_private_material_cleaned()

    def test_invalid_version_never_uses_credentials(self):
        result = self.run_script('sign-notarize.sh', self.input, self.output, '1.2.3;exit', self.sha)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.tools(), [])

    def test_tap_does_not_put_token_in_url_or_leave_askpass(self):
        result = self.run_script('update-tap.sh', '1.2.3', 'a'*64)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertNotIn(self.env['GH_TOKEN'], result.stdout)
        self.assertEqual(list((self.path/'runtime').glob('ripple-tap.*')), [])

    def test_tap_auth_failure_stops_without_fallback(self):
        self.env['FAIL_AUTH'] = '1'
        result = self.run_script('update-tap.sh', '1.2.3', 'a'*64)
        self.assertEqual(result.returncode, 128)
        self.assertEqual(len(self.tools()), 1)
        self.assertEqual(list((self.path/'runtime').glob('ripple-tap.*')), [])

    def test_tap_already_current_does_not_push(self):
        self.env['NO_CHANGE'] = '1'
        result = self.run_script('update-tap.sh', '1.2.3', 'a'*64)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(len(self.tools()), 2)


if __name__ == '__main__':
    unittest.main(verbosity=2)
