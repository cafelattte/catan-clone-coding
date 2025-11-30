# Settlus of Catan - Game Architecture

**Author:** BMad
**Date:** 2025-11-30
**Engine:** Love2D
**Language:** Lua

---

## Executive Summary

Love2D 기반 카탄 클론 프로젝트의 기술 아키텍처. TDD 중심 개발을 위해 게임 로직과 렌더링을 완전히 분리하며, 확장 가능한 구조(AI, 네트워크)를 인터페이스 수준에서만 준비한다.

---

## Decision Summary

| Category | Decision | Version | Rationale |
|----------|----------|---------|-----------|
| Engine | Love2D | 11.5+ | 2D 게임, Lua 기반, 크로스플랫폼 |
| Language | Lua | 5.1 (LuaJIT) | Love2D 기본 |
| Testing | busted | latest | TDD 필수, BDD 스타일 |
| Serialization | serpent | latest | 디버깅 친화적 출력 |
| Class System | classic | latest | 단순, 단일 파일 |
| State Management | hump.gamestate | latest | 검증된 씬 관리 |
| Coordinate System | Axial + Cube | - | Red Blob Games 권장 |

---

## Project Structure

```
catan/
├── main.lua                 -- Love2D 엔트리포인트
├── conf.lua                 -- Love2D 설정
│
├── src/
│   ├── game/                -- 순수 게임 로직 (Love2D 의존 X)
│   │   ├── constants.lua    -- 자원 타입, 건물 비용
│   │   ├── hex.lua          -- 헥스 좌표계, 변환
│   │   ├── vertex.lua       -- 정점 정규화, 인접 계산
│   │   ├── edge.lua         -- 변 정규화, 인접 계산
│   │   ├── board.lua        -- 보드 상태, 타일 배치
│   │   ├── player.lua       -- 플레이어 데이터, 자원 관리
│   │   ├── rules.lua        -- 건설 규칙, 승리 조건
│   │   ├── actions.lua      -- 액션 정의 (Command 패턴)
│   │   ├── game_state.lua   -- GameState 통합, 직렬화
│   │   └── dice.lua         -- 주사위 로직
│   │
│   ├── players/             -- 플레이어 타입 (확장점)
│   │   ├── base.lua         -- Player 인터페이스
│   │   ├── human.lua        -- Human 입력 처리
│   │   └── dummy_ai.lua     -- 테스트용 더미 AI
│   │
│   ├── ui/                  -- 렌더링 (Love2D 의존)
│   │   ├── renderer.lua     -- 메인 렌더러
│   │   ├── board_view.lua   -- 헥스 보드 그리기
│   │   ├── hud.lua          -- 자원, 점수 표시
│   │   ├── input.lua        -- 마우스/터치 → 헥스 변환
│   │   └── colors.lua       -- 색상 팔레트
│   │
│   ├── scenes/              -- 씬/상태 (hump.gamestate)
│   │   ├── menu.lua         -- 메인 메뉴
│   │   ├── game.lua         -- 게임 플레이
│   │   └── game_over.lua    -- 게임 종료
│   │
│   └── utils/               -- 유틸리티
│       ├── debug.lua        -- hexToString 등
│       └── serialize.lua    -- serpent 래퍼
│
├── lib/                     -- 외부 라이브러리
│   ├── classic.lua          -- 클래스 시스템
│   ├── serpent.lua          -- 직렬화
│   └── hump/
│       └── gamestate.lua    -- 상태 관리
│
├── assets/                  -- 이미지, 폰트
│   ├── images/
│   └── fonts/
│
├── tests/                   -- busted 테스트
│   └── game/
│       ├── constants_spec.lua
│       ├── hex_spec.lua
│       ├── vertex_spec.lua
│       ├── edge_spec.lua
│       ├── board_spec.lua
│       ├── player_spec.lua
│       ├── rules_spec.lua
│       └── game_state_spec.lua
│
├── docs/                    -- 문서
│   ├── game-brief-*.md
│   ├── GDD.md
│   └── game-architecture.md
│
└── .busted                  -- busted 설정
```

---

## Core Architecture Principles

### 1. 로직/렌더링 완전 분리

```
┌─────────────────────────────────────────────────────────┐
│                    src/game/                            │
│         순수 Lua - Love2D 의존성 없음                    │
│         busted로 독립 테스트 가능                        │
└─────────────────────────────────────────────────────────┘
                          ▲
                          │ 단방향 의존
                          │
┌─────────────────────────────────────────────────────────┐
│                    src/ui/                              │
│         Love2D 의존 - 렌더링만 담당                      │
└─────────────────────────────────────────────────────────┘
```

### 2. TDD First

모든 `src/game/` 모듈은 테스트 먼저 작성:

```lua
-- tests/game/player_spec.lua
describe("Player", function()
  describe("addResource", function()
    it("should add resources correctly", function()
      local player = Player.new(1)
      player:addResource("wood", 2)
      assert.equals(2, player:getResource("wood"))
    end)
  end)
end)
```

### 3. Command 패턴 (라이트)

모든 게임 액션은 테이블로 표현:

```lua
local action = {
  type = "BUILD_SETTLEMENT",
  player = 1,
  vertex = {q=0, r=1, dir="N"},
  -- 메타데이터 (선택)
  timestamp = os.time(),
  source = "human",  -- human/ai/network
  seq = game:nextSeq(),
}

game:execute(action)
```

### 4. Player 추상화

Human/AI/Network 모두 동일 인터페이스:

```lua
Player = {
  getAction = function(self, gameState)
    return action  -- Human: UI / AI: 알고리즘 / Network: 서버
  end
}
```

---

## Coordinate System Architecture

### 헥스 좌표계

```
Storage:     Axial (q, r)
                ↓ 변환
Calculation: Cube (x, y, z)  -- x + y + z = 0
                ↓ 변환
Rendering:   Pixel (px, py)
```

### 정점 표현

```lua
-- 헥스 기준 + 방향 (N, S만 사용)
local vertex = {q = 0, r = 0, dir = "N"}
```

### 변 표현

```lua
-- 헥스 기준 + 방향 (NE, E, SE만 사용)
local edge = {q = 0, r = 0, dir = "E"}
```

### 정규화 규칙

동일한 위치를 가리키는 다른 표현을 통일:

```lua
-- 예: (0,0,N)과 (0,-1,S)는 같은 정점
function normalizeVertex(q, r, dir)
  -- 정규화 로직
  return normalized_q, normalized_r, normalized_dir
end
```

---

## Data Architecture

### GameState 구조

```lua
local gameState = {
  board = {
    tiles = {
      {q=0, r=0, terrain="forest", number=8},
      -- ... 19개 타일
    },
    robber = {q = 0, r = 0},  -- 사막 시작
  },

  -- Map 구조: O(1) 조회, 중복 방지
  buildings = {
    settlements = {
      ["0,1,N"] = {player = 1},
      ["1,0,S"] = {player = 2},
    },
    cities = {},
    roads = {
      ["0,0,E"] = {player = 1},
    },
  },

  players = {
    {
      id = 1,
      resources = {wood=0, brick=0, sheep=0, wheat=0, ore=0},
      victoryPoints = 0,
    },
    -- ... 2-4 플레이어
  },

  turn = {
    current = 1,
    phase = "roll",  -- "roll", "build", "trade"
    rolled = nil,
  },

  config = {
    playerCount = 4,
    victoryTarget = 10,
  },
}
```

### 직렬화 규칙

- 순환 참조 X
- 함수 X
- ID로 참조
- serpent 호환

---

## Implementation Patterns

### Naming Conventions

| 대상 | 규칙 | 예시 |
|------|------|------|
| 파일명 | snake_case | `game_state.lua` |
| 모듈/클래스 | PascalCase | `GameState`, `Player` |
| 함수 | camelCase | `addResource()`, `getNeighbors()` |
| 상수 | UPPER_SNAKE | `RESOURCE_TYPES`, `BUILD_COSTS` |
| 지역변수 | camelCase | `currentPlayer`, `hexTile` |

### 좌표 문자열 형식

```lua
-- 헥스
hexToString(q, r)       --> "(0, 1)"

-- 정점
vertexToString(q, r, dir) --> "(0,1,N)"

-- 변
edgeToString(q, r, dir)   --> "(0,0,E)"
```

### 에러 핸들링

```lua
-- 실패 시 nil + error message 반환
function Player:build(buildingType, location)
  local canBuild, err = self:canBuild(buildingType, location)
  if not canBuild then
    return nil, err  -- "Not enough resources", "Invalid location", etc.
  end
  -- 건설 로직
  return true
end
```

### 테스트 파일 구조

```lua
-- tests/game/[module]_spec.lua
describe("[ModuleName]", function()

  before_each(function()
    -- 테스트 setup
  end)

  describe("[function_name]", function()
    it("should [expected behavior]", function()
      -- Arrange
      -- Act
      -- Assert
    end)

    it("should handle [edge case]", function()
      -- ...
    end)
  end)

end)
```

---

## Module Dependencies

```
constants.lua  (의존성 없음)
     ↓
hex.lua  (의존성 없음)
     ↓
vertex.lua  ← hex.lua
edge.lua    ← hex.lua
     ↓
board.lua  ← hex, vertex, edge, constants
     ↓
player.lua  ← constants
     ↓
rules.lua  ← board, player, constants
     ↓
actions.lua  ← rules
     ↓
game_state.lua  ← 모든 모듈
```

---

## Development Phases Mapping

| Phase | 모듈 | 테스트 파일 |
|:-----:|------|------------|
| 0 | 환경설정 | - |
| 1 | constants, player | constants_spec, player_spec |
| 2a | hex | hex_spec |
| 2b | vertex, edge | vertex_spec, edge_spec |
| 3 | board | board_spec |
| 4a | dice, rules (기본) | dice_spec, rules_spec |
| 4b | rules (건설), actions | rules_spec, actions_spec |
| 4c | rules (초기배치) | rules_spec |
| 5 | game_state | game_state_spec |
| 6 | UI (board_view, hud, input) | - |
| 7 | scenes (menu, game, game_over) | - |

---

## Development Environment

### Prerequisites

| 도구 | 버전 | 용도 |
|------|------|------|
| Love2D | 11.5+ | 게임 엔진 |
| Lua | 5.1 (LuaJIT) | 스크립팅 |
| LuaRocks | latest | 패키지 관리 |
| busted | latest | 테스트 |

### Setup Commands

```bash
# Love2D 설치 (macOS)
brew install love

# LuaRocks 설치 (macOS)
brew install luarocks

# busted 설치
luarocks install busted

# 프로젝트 구조 생성
mkdir -p src/{game,players,ui,scenes,utils}
mkdir -p lib tests/game assets/{images,fonts} docs

# 라이브러리 다운로드
# classic.lua, serpent.lua, hump/gamestate.lua → lib/
```

### 테스트 실행

```bash
# 전체 테스트
busted tests/

# 특정 모듈 테스트
busted tests/game/hex_spec.lua

# 감시 모드 (변경 시 자동 실행)
busted --watch tests/
```

### 게임 실행

```bash
# 개발 모드
love .

# 또는 폴더 지정
love /path/to/catan
```

---

## Extension Points (YAGNI - 인터페이스만)

### AI Player

```lua
-- src/players/ai.lua (나중에 구현)
local AI = Player:extend()

function AI:getAction(gameState)
  -- AI 로직
  return action
end
```

### Network Player

```lua
-- src/players/network.lua (나중에 구현)
local NetworkPlayer = Player:extend()

function NetworkPlayer:getAction(gameState)
  -- 서버에서 액션 수신
  return receivedAction
end
```

### Save/Load

```lua
-- game_state.lua에 이미 직렬화 가능한 구조
local saved = serpent.dump(gameState)
local loaded = serpent.load(saved)
```

---

## Risk Mitigation

| 리스크 | 대응 | 검증 시점 |
|--------|------|----------|
| 헥스 좌표계 버그 | Red Blob Games 참조, 시각화 디버그 | Phase 2a |
| 정점 정규화 오류 | 모든 케이스 TDD 커버 | Phase 2b |
| 순환참조 직렬화 | serpent 테스트 | Phase 5 |

---

## Architecture Decision Records (ADRs)

### ADR-001: 로직/렌더링 분리

**결정:** `src/game/`은 Love2D 의존성 없이 순수 Lua로 구현

**이유:** TDD 가능, 테스트 속도 향상, 로직 재사용성

**결과:** busted로 게임 로직 독립 테스트 가능

---

### ADR-002: Axial + Cube 좌표계

**결정:** 저장은 Axial, 계산은 Cube 변환 사용

**이유:** 저장 효율 + 계산 정확성 (Red Blob Games 권장)

**참조:** https://www.redblobgames.com/grids/hexagons/

---

### ADR-003: Map 기반 건물 저장

**결정:** 정규화된 좌표 문자열을 키로 사용하는 Map 구조

**이유:** O(1) 조회, 중복 자동 방지

**예시:** `settlements["0,1,N"] = {player = 1}`

---

### ADR-004: Command 패턴 라이트

**결정:** 모든 액션을 테이블로 표현, 메타데이터 포함

**이유:** 리플레이/디버깅 가능, AI/Network 확장 용이

**YAGNI:** Undo/Redo는 구현하지 않음 (인터페이스만 열어둠)

---

_Generated by BMAD Game Architecture Workflow_
_Based on: GDD.md, game-brief-settlus-of-catan-2025-11-30.md, brainstorming-session-results-2025-11-29.md_

_Next Steps: `/bmad:bmgd:workflows:sprint-planning` 워크플로우로 스프린트 계획_
