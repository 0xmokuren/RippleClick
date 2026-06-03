# RippleClick

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | 한국어

<p>
  <a href="https://github.com/0xmokuren/RippleClick/releases"><img src="https://img.shields.io/github/v/release/0xmokuren/RippleClick?label=release" alt="최신 릴리스"></a>
  <a href="https://github.com/0xmokuren/RippleClick/releases"><img src="https://img.shields.io/github/downloads/0xmokuren/RippleClick/total" alt="다운로드 수"></a>
  <img src="https://img.shields.io/badge/macOS-13%2B-black?logo=apple" alt="macOS 13+">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/0xmokuren/RippleClick" alt="라이선스"></a>
</p>

**모든 클릭을 눈에 보이게.** RippleClick은 클릭하는 순간 마우스 포인터 위치에 파문(리플) 이펙트를 그려 주는 가벼운 macOS 메뉴 바 상주 앱입니다. 선택적으로 클릭 효과음도 재생할 수 있습니다. 화면 녹화, 라이브 데모, 발표, 튜토리얼 등 어디를 클릭했는지 정확히 보여 주고 싶은 상황에 안성맞춤입니다.

![RippleClick Demo](ripple-click-demo.gif)

## 주요 특징

- 🌊 **즉각적인 시각 피드백** — 클릭할 때마다 포인터 바로 아래에 부드러운 파문 애니메이션을 표시합니다.
- 🖱️ **왼쪽 · 오른쪽 · 더블 클릭 지원** — 클릭 종류마다 모양이 다르며 개별적으로 켜고 끌 수 있습니다.
- 🎨 **자유로운 커스터마이즈** — 12가지 색상 프리셋, 5단계 크기, 속도와 불투명도 조절 가능.
- 🌗 **라이트 / 다크 모드 대응** — 라이트와 다크 모드에 서로 다른 색을 지정할 수 있고 자동으로 전환됩니다.
- 🔊 **내장 클릭 효과음** — 합성 음 5종, 볼륨 슬라이더와 미리 듣기 제공.
- 🪶 **매우 가벼움** — 메뉴 바 전용, Dock 아이콘 없음, 대기 시 CPU 부하 거의 없음.
- 🌍 **4개 언어 지원** — 영어, 일본어, 简体中文, 한국어.

## 기능

### 클릭 종류

각 클릭 종류는 개별적으로 켜고 끌 수 있으며 모양도 독립적으로 설정합니다.

| 클릭       | 기본 모양                   | 설정 가능 항목                  |
| ---------- | --------------------------- | ------------------------------- |
| 왼쪽 클릭  | 단일 파문 링                | 색상 (일반 / 라이트 / 다크)     |
| 오른쪽 클릭| **이중 파문 링**            | 활성화, 외관별 색상             |
| 더블 클릭  | **크기 1.2배, 선 두께 2배** | 활성화, 외관별 색상             |

### 커스터마이즈

- **이펙트 색상** — 12가지 프리셋: 시안, 블루, 네이비, 퍼플, 핑크, 레드, 오렌지, 옐로, 라임, 그린, 틸, 화이트.
- **시스템 외관에 맞추기** — 라이트/다크 모드에 각각 색을 지정하면 macOS 전환에 맞춰 즉시 교체됩니다.
- **파문 최대 크기** — 5단계 (작게 → 크게).
- **애니메이션 속도** — 5단계 (빠르게 → 느리게).
- **불투명도** — 5단계 (옅게 → 진하게).
- **로그인 시 자동 실행** — 로그인할 때 자동으로 시작합니다.

### 클릭 효과음

효과음은 앱 내부에서 합성되므로(오디오 파일을 포함하지 않음) 어떤 볼륨에서도 선명하게 들립니다:

| 효과음     | 느낌                  |
| ---------- | --------------------- |
| Water Drop | 부드러운 물방울 소리  |
| Pop        | 짧게 터지는 팝 소리   |
| Sonar      | 깔끔한 소나 핑 소리   |
| Bubble     | 둥근 거품 소리        |
| Soft Click | 부드러운 기계식 클릭  |

볼륨은 5단계 슬라이더로 조절하며, **미리 듣기** 로 현재 효과음을 들어 볼 수 있습니다.

## 설치

### Homebrew (권장)

```bash
brew tap 0xmokuren/tap
brew install --cask rippleclick
```

### 수동 다운로드

[Releases](https://github.com/0xmokuren/RippleClick/releases)에서 최신 `.zip` 파일을 다운로드하고, 압축을 해제한 후 `RippleClick.app`을 Applications 폴더로 이동하세요.

> **첫 실행 시 참고:** "시스템 설정" → "개인정보 보호 및 보안" → "확인 없이 열기"에서 허용해야 합니다. 또한 시스템 전역의 클릭 감지를 위해 **손쉬운 사용** 권한을 요청합니다.

## 사용 방법

1. RippleClick을 실행하면 메뉴 바에 💧 아이콘이 나타납니다.
2. 아이콘을 클릭해 이펙트 **ON / OFF** 를 전환하거나 **설정** 을 엽니다.
3. **설정** 에서 색상, 크기, 속도, 불투명도, 클릭 종류, 효과음을 조정할 수 있습니다.

## 시스템 요구 사항

- macOS 13 (Ventura) 이상

## 개인정보

RippleClick이 손쉬운 사용 권한을 요청하는 이유는 오직 파문을 그리기 위해 클릭이 "언제" "어디서" 발생했는지 알기 위해서입니다. 클릭하거나 입력한 내용을 **기록·저장·전송하지 않습니다**. 네트워크 접속이나 분석도 전혀 하지 않습니다.

## 빌드 (개발자용)

```bash
swift build              # 디버그 빌드
swift run                # 개발 실행
swift test               # 테스트 실행

bash scripts/bundle.sh   # 릴리스 빌드 (.app 번들)
open RippleClick.app
```

> 손쉬운 사용 권한은 바이너리별로 부여되므로, 동작 확인은 `swift run` 보다 생성된 `.app` 으로 하는 것이 확실합니다. 아키텍처 설명과 서명/릴리스 절차는 [CLAUDE.md](CLAUDE.md)를 참고하세요.

## 기여

Issue와 Pull Request를 환영합니다. PR을 열기 전에 `swiftlint lint --strict` 와 `swift-format lint --strict --recursive Sources/ Tests/` 를 실행하고, 사용자 대상 문구를 변경했다면 4개 언어의 README를 동기화해 주세요.

## 라이선스

[MIT License](LICENSE)
