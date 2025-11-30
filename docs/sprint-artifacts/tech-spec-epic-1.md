# Epic Technical Specification: Foundation (환경 설정)

Date: 2025-11-30
Author: BMad
Epic ID: 1
Status: Draft

---

## Overview

Epic 1은 Settlus of Catan 프로젝트의 기반을 구축하는 환경 설정 에픽입니다. Love2D 게임 엔진과 Lua 언어를 사용한 TDD 중심 개발 환경을 설정하며, 모든 후속 에픽의 개발을 가능하게 하는 프로젝트 구조, 라이브러리, 테스트 프레임워크를 준비합니다.

이 에픽은 GDD의 "Phase 0: 환경 설정" 요구사항과 Architecture 문서의 "Project Structure" 및 "Development Environment" 섹션을 구현합니다. TDD First 원칙에 따라 busted 테스트 프레임워크가 작동하는 것이 핵심 목표입니다.

## Objectives and Scope

### In-Scope

- 프로젝트 디렉토리 구조 생성 (Architecture 문서 기준)
- Love2D 엔트리포인트 파일 생성 (main.lua, conf.lua)
- 외부 라이브러리 설치 (classic, serpent, hump.gamestate)
- busted 테스트 프레임워크 설정 및 검증
- .busted 설정 파일 구성
- 샘플 테스트로 TDD 환경 검증

### Out-of-Scope

- 게임 로직 구현 (Epic 2-5에서 진행)
- UI/렌더링 구현 (Epic 6에서 진행)
- 씬 관리 구현 (Epic 7에서 진행)
- 에셋 파일 제작 (별도 작업)

## System Architecture Alignment

이 에픽은 Architecture 문서의 다음 섹션과 정렬됩니다:

- **Project Structure**: 전체 디렉토리 구조 정의
- **Core Architecture Principles**: 로직/렌더링 분리를 위한 디렉토리 분리
- **Development Environment**: 필수 도구 및 설정 명령어
- **ADR-001**: src/game/은 Love2D 의존성 없이 순수 Lua로 구현

**제약 사항:**
- Love2D 11.5+ 버전 필수
- Lua 5.1 (LuaJIT) 호환
- busted로 tests/ 디렉토리 테스트 가능해야 함

## Detailed Design

### Services and Modules

| 컴포넌트 | 파일 | 책임 | 입력 | 출력 |
|---------|------|------|------|------|
| 엔트리포인트 | main.lua | Love2D 콜백 정의 | Love2D 이벤트 | 게임 루프 |
| 설정 | conf.lua | 창 크기, 타이틀 설정 | - | Love2D config |
| 테스트 설정 | .busted | busted 탐색 경로 설정 | - | 테스트 구성 |

### Data Models and Contracts

이 에픽에서는 데이터 모델을 정의하지 않습니다. 프로젝트 구조와 설정 파일만 생성합니다.

**conf.lua 구조:**

```lua
function love.conf(t)
  t.window.title = "Settlus of Catan"
  t.window.width = 1280
  t.window.height = 720
  t.window.resizable = false
  t.version = "11.5"
  t.console = true  -- 디버그용
end
```

**.busted 구조:**

```lua
return {
  _all = {
    coverage = false,
    lpath = "src/?.lua;src/?/init.lua;lib/?.lua",
  },
  default = {
    verbose = true,
    ROOT = {"tests/"},
  },
}
```

### APIs and Interfaces

이 에픽에서는 API를 정의하지 않습니다. 라이브러리 인터페이스만 확인합니다.

**라이브러리 require 테스트:**

```lua
-- 각 라이브러리 로드 가능 확인
local classic = require("lib.classic")
local serpent = require("lib.serpent")
local gamestate = require("lib.hump.gamestate")
```

### Workflows and Sequencing

```
Story 1.1: 프로젝트 구조 생성
    ↓
Story 1.2: 외부 라이브러리 설치 (1.1 의존)
    ↓
Story 1.3: 테스트 환경 설정 (1.2 의존)
    ↓
Story 1.4: Love2D 기본 설정 (1.1 의존, 1.3과 병렬 가능)
```

**설정 순서:**

1. 디렉토리 구조 생성 (mkdir -p 명령어)
2. 라이브러리 파일 다운로드/복사
3. .busted 설정 파일 생성
4. 샘플 테스트 파일 생성 (tests/game/sample_spec.lua)
5. busted tests/ 실행하여 검증
6. main.lua, conf.lua 생성
7. love . 실행하여 검증

## Non-Functional Requirements

### Performance

- 테스트 실행 시간: 전체 테스트 스위트 < 1초 (샘플 테스트 기준)
- Love2D 창 열기: < 2초
- 라이브러리 로드: 즉시 (require 시점)

### Security

- 외부 라이브러리는 신뢰할 수 있는 소스에서만 다운로드:
  - classic: https://github.com/rxi/classic
  - serpent: https://github.com/pkulchenko/serpent
  - hump: https://github.com/vrld/hump
- 라이선스 확인: 모두 MIT 라이선스 (상용 사용 가능)

### Reliability/Availability

- 오프라인 개발 가능: 라이브러리는 lib/ 폴더에 로컬 복사
- 의존성 버전 고정: 특정 커밋 또는 릴리스 사용 권장
- 환경 재현성: README에 설정 명령어 문서화

### Observability

- busted 출력: 테스트 통과/실패 명확히 표시
- Love2D 콘솔: conf.lua에서 t.console = true로 디버그 출력 활성화
- 버전 확인: love --version으로 Love2D 버전 검증

## Dependencies and Integrations

### 외부 의존성

| 의존성 | 버전 | 용도 | 설치 방법 |
|--------|------|------|----------|
| Love2D | 11.5+ | 게임 엔진 | brew install love (macOS) |
| Lua | 5.1 (LuaJIT) | 스크립팅 | Love2D에 포함 |
| LuaRocks | latest | 패키지 관리 | brew install luarocks |
| busted | latest | TDD 프레임워크 | luarocks install busted |

### 번들 라이브러리

| 라이브러리 | 파일 위치 | 소스 URL |
|-----------|----------|----------|
| classic | lib/classic.lua | https://github.com/rxi/classic |
| serpent | lib/serpent.lua | https://github.com/pkulchenko/serpent |
| hump.gamestate | lib/hump/gamestate.lua | https://github.com/vrld/hump |

## Acceptance Criteria (Authoritative)

### AC1: 프로젝트 구조

프로젝트 루트에 다음 디렉토리가 존재해야 한다:
- src/game/, src/players/, src/ui/, src/scenes/, src/utils/
- lib/, tests/game/, assets/images/, assets/fonts/

### AC2: 엔트리포인트 파일

main.lua와 conf.lua가 프로젝트 루트에 존재해야 한다.

### AC3: 라이브러리 존재

- lib/classic.lua 존재
- lib/serpent.lua 존재
- lib/hump/gamestate.lua 존재

### AC4: 라이브러리 로드

각 라이브러리를 require로 로드할 수 있어야 한다 (에러 없음).

### AC5: 테스트 실행

`busted tests/` 명령어가 성공적으로 실행되고 "0 failures" 메시지를 출력해야 한다.

### AC6: Love2D 실행

`love .` 명령어가 1280x720 창을 열고 타이틀바에 "Settlus of Catan"이 표시되어야 한다.

### AC7: .busted 설정

.busted 파일이 존재하고 tests/ 디렉토리를 자동으로 탐색해야 한다.

## Traceability Mapping

| AC | Spec Section | Component | Test Idea |
|----|--------------|-----------|-----------|
| AC1 | Detailed Design | 디렉토리 | ls -la로 구조 확인 |
| AC2 | Detailed Design | main.lua, conf.lua | 파일 존재 확인 |
| AC3 | Dependencies | lib/ | 파일 존재 확인 |
| AC4 | Dependencies | 라이브러리 | require 테스트 |
| AC5 | Workflows | busted | busted tests/ 실행 |
| AC6 | Detailed Design | Love2D | love . 실행 |
| AC7 | Detailed Design | .busted | busted 설정 확인 |

## Risks, Assumptions, Open Questions

### Risks

| 리스크 | 영향 | 완화 |
|--------|------|------|
| **R1:** Love2D 버전 불일치 | 높음 | conf.lua에서 t.version = "11.5" 명시 |
| **R2:** busted 설치 실패 | 중간 | LuaRocks 대신 수동 설치 가이드 준비 |
| **R3:** 라이브러리 URL 변경 | 낮음 | lib/에 로컬 복사본 유지 |

### Assumptions

| 가정 | 검증 방법 |
|------|----------|
| **A1:** macOS 개발 환경 | brew 명령어 사용 가능 확인 |
| **A2:** Homebrew 설치됨 | brew --version 실행 |
| **A3:** 인터넷 연결 | 라이브러리 다운로드 가능 |

### Open Questions

*현재 미해결 질문 없음*

## Test Strategy Summary

### 테스트 레벨

| 레벨 | 대상 | 프레임워크 |
|------|------|-----------|
| 단위 테스트 | src/game/ 모듈 | busted |
| 통합 테스트 | 라이브러리 로드 | busted |
| 수동 테스트 | Love2D 창 | 육안 확인 |

### 테스트 파일

```
tests/
└── game/
    └── sample_spec.lua  -- Epic 1 검증용 샘플 테스트
```

### 샘플 테스트 내용

```lua
-- tests/game/sample_spec.lua
describe("Epic 1 Foundation", function()
  describe("Library Loading", function()
    it("should load classic", function()
      local classic = require("lib.classic")
      assert.is_not_nil(classic)
    end)

    it("should load serpent", function()
      local serpent = require("lib.serpent")
      assert.is_not_nil(serpent)
    end)
  end)
end)
```

### 커버리지 목표

- Epic 1은 환경 설정이므로 코드 커버리지 N/A
- 후속 에픽부터 src/game/ 90%+ 목표

---

_Generated by BMAD Epic Tech Context Workflow_
_Source: GDD.md, game-architecture.md, epics.md_
