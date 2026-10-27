# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.0.14] - 2026-10-27

### Fixed
- Remove unnecessary Accessibility permission prompts at startup for mouse-only monitoring, including local development launches.
- Isolate login-item operations behind an injected manager so tests never register or unregister real login items.
- Correct permission guidance in all four README translations.

## [1.0.0] - 2026-03-26

### Added
- Ripple effect on left click with cyan default color
- Menu bar icon with colored center dot reflecting current color
- Settings window with 12 color presets, 5 size levels, launch at login
- Reset to defaults button in settings
- Localization support (English, Japanese, Simplified Chinese, Korean)
- Accessibility permission prompt on first launch
- App bundle with icon
- CI pipeline (build, test, lint, format)
- Automated release workflow via GitHub Actions
