# Release permission boundaries

This design was reviewed against released commit `8bf3b53`. It does not change the
installed app or its privacy permissions. Existing v0.0.14 publication and OS-notification
findings remain separate. Normal CI validates this design offline; the new release
path still requires a future approved tag and real-credential integration verification.

## Job and credential boundaries

| Job | Repository token | Existing signing secrets | Existing tap token | Output |
| --- | --- | --- | --- | --- |
| build | contents:read | none | none | unsigned app, empty entitlement policy, release notes |
| sign | contents:read | six inputs in one step only | none | signed and notarized ZIP, notes |
| publish | contents:write | none | none | existing tag's GitHub Release |
| tap | contents:read | none | HOMEBREW_TAP_TOKEN in one step | existing homebrew-tap cask update |

Every checkout disables persisted credentials. The build and signing jobs run on
separate hosted macOS runners; publish and tap run on separate Ubuntu runners.
Repository application code is compiled before any signing material is available.
The signing job checks out the release helper scripts, but does not build or execute
the application. Only publish receives a write-capable GITHUB_TOKEN. This does not
reduce the scopes already held by HOMEBREW_TAP_TOKEN; those must be reviewed by its owner.

The signer keeps the same Developer ID identity, hardened runtime, timestamp and
current empty entitlement policy. It imports the existing P12 into a private temporary
keychain with codesign as the trusted application instead of allowing all applications.
It selects that keychain explicitly rather than modifying the keychain search list.
P12/P8 material and the temporary keychain are owned by a single shell step, with EXIT,
INT and TERM cleanup. No key paths or material enter GITHUB_ENV or job outputs. Hard
runner termination cannot guarantee shell traps; hosted-runner disposal remains a boundary.

The tap helper uses a clean HTTPS origin and a temporary GIT_ASKPASS script that reads
the existing token from the step environment. It never puts the value in a URL, file,
Git remote, credential helper, job output or artifact. Credential helpers are explicitly
empty for clone/push. Authentication failure stops the step; there is no alternate auth.
The temporary script and clone are removed on exit. Existing cask fields are preserved
apart from version and SHA256, and an already-current cask does not create a commit.

## Artifact and retry rules

All handoffs use immutable artifact IDs produced within this workflow run. Downloads
have no cross-repository token or run ID. SHA256 is checked before signing and before
publication. Intermediate artifacts contain only public app material and notes and
expire after seven days. File lists are explicit; signing-material directories cannot
be uploaded. Archive traversal/symlinks, unexpected app identity/version and nonempty
entitlement policy are rejected before credentials are imported.

Tags must be stable numeric versions such as v0.0.15. Arbitrary tag text is never
interpolated into shell source. Release-note commit text is written to a file, not a
multiline GITHUB_OUTPUT heredoc. Artifact names include run_attempt to avoid rerun
name collisions. Same-tag runs are serialized without canceling a signer in progress.

A failed tap job can be retried on its own after its existing credential is repaired;
it no longer reruns signing/publication. Publication refuses an already-existing
release and disables asset overwrites. Do not replay the old v0.0.14 workflow: its
single-job design is not retroactively changed by this proposal.

## Pinned actions

These SHAs were resolved through the upstream repositories' own refs on 2026-10-27.
This establishes ref provenance, not an independent code audit or signature guarantee.

| Action | Upstream ref | Commit |
| --- | --- | --- |
| actions/checkout | v6 | d23441a48e516b6c34aea4fa41551a30e30af803 |
| actions/upload-artifact | v7 | cf430e030ddbb5b0abf93d22962f4752f3646cd9 |
| actions/download-artifact | v8.0.2 | 9000827ccba6bdab643e8b6fd33ac0654aef8333 |
| softprops/action-gh-release | v3, annotated tag dereferenced | efb35369e0ad2afab669f228072c1b0d510eae64 |

Download-artifact v8 supports the current upload-artifact v7 format and same-run ID
retrieval. Existing CI actions are pinned too, and CI explicitly retains contents:read.
Pinned actions still execute code: a trusted-tag workflow and reviewed helpers remain
necessary. Branch/tag protection and environment approval rules are not changed here.

## Verification and operational review

Run `python3 Tests/ReleaseWorkflow/test_release_security.py` on macOS, plus `bash -n`
on the two helpers and actionlint on the workflows. The tests substitute security,
codesign, notarytool, stapler, Gatekeeper and git with offline fakes. They never use
real certificates, private keys, tap credentials, Apple submissions or repository pushes.
Their fixture bytes are explicitly non-credential markers, not generated certificates.
They check permission separation, pinned actions, fail-closed validation, cleanup after
import/staple failures, archive allowlists, token transport, auth failure and no-op updates.
These checks do not establish that the changed workflow has run successfully on GitHub.

Review changes to workflow permissions and temporary-keychain ACL/selection behavior
before applying them. No new secret name, credential destination, certificate or app
entitlement is introduced by this design. Offline tests do not perform live signing,
notarization, publication, tap updates, secret rotation or GitHub security-setting changes.
The existing HOMEBREW_TAP_TOKEN failed authentication during v0.0.14; its secure repair
is a separate approval and must not be bypassed. Do not create a new tag merely to
validate normal CI or alter the existing immutable v0.0.14 release.

References: [GitHub secure use](https://docs.github.com/en/actions/reference/security/secure-use),
[artifact downloads](https://github.com/actions/download-artifact/tree/v8.0.2),
[Developer ID](https://developer.apple.com/developer-id/).
