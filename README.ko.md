# RippleClick

[English](README.md) | [日本語](README.ja.md) | [简体中文](README.zh-Hans.md) | 한국어

macOS에서 마우스 왼쪽 클릭 시 포인터 위치에 파문(리플) 이펙트를 표시하는 메뉴 바 상주형 유틸리티 앱.

## 설치

### Homebrew (권장)

```bash
brew tap 0xmokuren/tap
brew install --cask rippleclick
```

### 수동 다운로드

[Releases](https://github.com/0xmokuren/RippleClick/releases)에서 최신 `.zip` 파일을 다운로드하고, 압축을 해제한 후 `RippleClick.app`을 Applications 폴더로 이동하세요.

> **첫 실행 시 참고:** "시스템 설정" → "개인정보 보호 및 보안" → "확인 없이 열기"에서 허용해야 합니다. 또한 클릭 감지를 위해 손쉬운 사용 권한을 요청합니다.

## 기능

- 왼쪽 클릭 시 파문 이펙트 표시
- 메뉴 바에서 이펙트 ON/OFF 전환
- 설정 화면에서 커스터마이즈 가능:
  - 이펙트 색상 (12가지 프리셋)
  - 파문 최대 크기 (5단계)
  - 로그인 시 자동 실행
- 다국어 지원 (영어, 일본어, 중국어, 한국어)

## 시스템 요구 사항

- macOS 13 (Ventura) 이상

## 빌드 (개발자용)

```bash
# 개발 환경
swift run

# 릴리스 빌드 (.app 번들)
bash scripts/bundle.sh
open RippleClick.app
```

## 라이선스

[MIT License](LICENSE)
