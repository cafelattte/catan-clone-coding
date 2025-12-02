# Epic Technical Specification: Complete Game Flow

Date: 2025-12-01
Author: BMad
Epic ID: 7
Status: Draft

---

## Overview

에픽 7은 Settlus of Catan 게임의 완전한 게임 플로우를 구현합니다. 현재까지 에픽 1-6에서 구축된 게임 로직(자원, 헥스 좌표계, 보드, 규칙)과 UI(렌더링, HUD, 입력)를 통합하여, 처음부터 끝까지 플레이 가능한 게임 경험을 제공합니다.

이 에픽은 hump.gamestate 라이브러리를 활용한 씬 관리 시스템을 도입하고, GameState 통합 모듈을 통해 턴 순서와 페이즈를 체계적으로 관리합니다.

## Objectives and Scope

### In-Scope

- 턴 순서 관리 (2-4 플레이어 순환)
- 페이즈 관리 (roll → main → end turn)
- **초기 배치(setup) 모드 상태 전이 로직** (snake draft: 1→2→3→4→4→3→2→1)
- 메인 메뉴 씬 구현 (New Game, Exit)
- 게임 플레이 씬 통합
- 게임 종료 씬 구현 (승리 발표, 최종 점수)
- hump.gamestate 기반 씬 전환

### Out-of-Scope

- 초기 배치 전용 UI (로직은 구현, UI는 기존 입력 시스템 활용)
- 저장/불러오기 기능
- AI 상대
- 거래 시스템 UI
- 온라인 멀티플레이어

## System Architecture Alignment

### Architecture 문서 참조

```
src/scenes/              -- 씬/상태 (hump.gamestate)
│   ├── menu.lua         -- 메인 메뉴
│   ├── game.lua         -- 게임 플레이
│   └── game_over.lua    -- 게임 종료
│
src/game/
│   └── game_state.lua   -- GameState 통합, 직렬화
```

### 기존 모듈 의존성

에픽 7은 다음 기존 모듈들을 활용합니다:

- `src/game/board.lua` - 보드 상태 관리
- `src/game/player.lua` - 플레이어 자원/점수 관리
- `src/game/rules.lua` - 게임 규칙, 승리 조건 체크
- `src/game/dice.lua` - 주사위 굴림
- `src/game/actions.lua` - 건설 실행
- `src/ui/board_view.lua` - 보드 렌더링
- `src/ui/hud.lua` - HUD 렌더링
- `src/ui/input.lua` - 입력 처리
- `lib/hump/gamestate.lua` - 씬 관리

---

## Detailed Design

### Services and Modules

| 모듈 | 책임 | 입력 | 출력 |
|------|------|------|------|
| `game_state.lua` | 게임 상태 통합, 턴/페이즈 관리 | 액션 요청 | 상태 변경 |
| `scenes/menu.lua` | 메인 메뉴 UI, 게임 시작 | 사용자 입력 | 씬 전환 |
| `scenes/game.lua` | 게임 플레이 통합 | 게임 상태 | 렌더링, 입력 처리 |
| `scenes/game_over.lua` | 게임 종료 UI | 승자 정보 | 씬 전환 |

### Data Models and Contracts

#### GameState 구조 (game_state.lua)

```lua
local GameState = {
  -- 보드 상태 (Board 객체)
  board = nil,

  -- 플레이어 목록 (Player 객체 배열)
  players = {},

  -- 게임 모드 (턴 시스템보다 상위 개념)
  -- "setup": 초기 배치 단계 (향후 Epic에서 UI 구현)
  -- "playing": 일반 게임 진행
  -- "finished": 게임 종료
  mode = "playing",

  -- 턴 관리 (mode = "playing"에서 사용)
  turn = {
    current = 1,           -- 현재 플레이어 인덱스 (1-based)
    phase = "roll",        -- "roll", "main"
    round = 1,             -- 현재 라운드 (턴 순환 횟수)
  },

  -- 초기 배치 상태 (mode = "setup"에서 사용)
  -- Snake Draft: Round 1 (1→2→3→4), Round 2 (4→3→2→1)
  setup = {
    round = 1,             -- 1 또는 2 (첫 번째/두 번째 배치)
    direction = "forward", -- "forward" (1→2→3→4) 또는 "reverse" (4→3→2→1)
    phase = "settlement",  -- "settlement" 또는 "road"
    currentPlayer = 1,     -- setup 모드의 현재 플레이어
    placementsThisRound = 0, -- 현재 라운드에서 완료된 배치 수
  },

  -- 주사위 결과
  diceResult = nil,        -- {die1, die2, sum} 또는 nil

  -- 게임 설정
  config = {
    playerCount = 4,
    victoryTarget = 10,
  },

  -- 승자 (mode = "finished"일 때 설정)
  winner = nil,            -- 승자 플레이어 ID 또는 nil
}
```

**설계 원칙 (First Principles):**
- `mode`는 게임의 전체 상태를 나타내는 상위 개념
- `turn`은 `mode = "playing"`에서만 의미 있음
- `setup`은 `mode = "setup"`에서만 의미 있음 (향후 구현 대비)
- 씬(UI)은 GameState를 *소유*하지 않고 *참조*만 함

#### 씬 인터페이스 (hump.gamestate 호환)

```lua
-- 모든 씬이 구현해야 하는 콜백
Scene = {
  enter = function(self, previous, ...) end,  -- 씬 진입 시
  leave = function(self) end,                  -- 씬 이탈 시
  update = function(self, dt) end,             -- 매 프레임
  draw = function(self) end,                   -- 렌더링
  keypressed = function(self, key) end,        -- 키 입력
  mousepressed = function(self, x, y, button) end,  -- 마우스 클릭
}
```

### APIs and Interfaces

#### GameState API

```lua
-- 생성자
GameState.new(playerCount: number) -> GameState

-- 모드 관리
GameState:getMode() -> string  -- "setup" | "playing" | "finished"
GameState:setMode(mode: string) -> void
GameState:isPlaying() -> boolean
GameState:isSetup() -> boolean
GameState:isFinished() -> boolean

-- Setup 모드 관리 (초기 배치)
GameState:getSetupPlayer() -> number        -- 현재 배치할 플레이어 ID
GameState:getSetupPhase() -> string         -- "settlement" | "road"
GameState:getSetupRound() -> number         -- 1 또는 2
GameState:advanceSetup() -> void            -- 다음 단계로 진행
GameState:placeInitialSettlement(vertex) -> boolean
GameState:placeInitialRoad(edge) -> boolean
GameState:isSetupComplete() -> boolean      -- 모든 초기 배치 완료 여부

-- 턴 관리 (mode = "playing")
GameState:getCurrentPlayer() -> Player
GameState:getCurrentPlayerId() -> number
GameState:getPhase() -> string  -- "roll" | "main"
GameState:endTurn() -> void
GameState:nextPlayer() -> void

-- 페이즈 관리 (mode = "playing")
GameState:rollDice() -> {die1, die2, sum}
GameState:setPhase(phase: string) -> void
GameState:canRoll() -> boolean   -- mode == "playing" and phase == "roll"
GameState:canBuild() -> boolean  -- mode == "playing" and phase == "main"

-- 승리 체크
GameState:checkVictory() -> number|nil  -- 승자 ID 또는 nil

-- 직렬화 (선택적, 향후 저장/불러오기용)
GameState:serialize() -> table
GameState.deserialize(data: table) -> GameState

-- 테스트용 팩토리 (상태 주입)
GameState.newForTesting(config: table) -> GameState
```

#### 씬 전환 API (hump.gamestate)

```lua
local Gamestate = require("lib.hump.gamestate")

-- 씬 전환
Gamestate.switch(scene, ...)  -- 즉시 전환
Gamestate.push(scene, ...)    -- 스택에 추가 (팝업용)
Gamestate.pop()               -- 스택에서 제거

-- 등록 (main.lua에서)
Gamestate.registerEvents()
```

### Workflows and Sequencing

#### 게임 플로우 시퀀스

```
[시작]
   │
   ▼
┌──────────────┐
│  Menu Scene  │
│              │
│ - New Game   │───▶ 플레이어 수 선택 (2-4)
│ - Exit       │───▶ love.event.quit()
└──────────────┘
        │
        ▼ (New Game)
┌──────────────────────────────────────────────────────┐
│                    Game Scene                        │
│                                                      │
│  mode = "setup" (향후 Epic에서 UI 구현)              │
│      │ [Epic 7에서는 skip하고 바로 playing으로]      │
│      ▼                                               │
│  mode = "playing"  ◀──────────────────────┐          │
│      │                                    │          │
│      ▼                                    │          │
│  ┌─────────────┐    ┌─────────────┐       │          │
│  │ Roll Phase  │───▶│ Main Phase  │───▶ End Turn    │
│  │             │    │             │        │         │
│  │ - 주사위    │    │ - 건설      │        │         │
│  │   굴림      │    │ - (거래)    │        │         │
│  └─────────────┘    └─────────────┘        │         │
│                           │                │         │
│                           ▼                ▼         │
│                     승리 체크 ───▶ 10점? ───▶ Yes    │
│                                       │              │
│                                       ▼ No           │
│                                  다음 플레이어       │
│                                                      │
│      mode = "finished" ◀─────────────────────────────┘
└──────────────────────────────────────────────────────┘
        │ (mode = "finished")
        ▼
┌──────────────────┐
│  Game Over Scene │
│                  │
│ - Player X Wins! │
│ - 최종 점수      │
│ - New Game ──────│───▶ Menu Scene
│ - Exit           │───▶ love.event.quit()
└──────────────────┘
```

#### Setup 모드 상태 전이 (Snake Draft)

```
게임 시작 (mode = "setup", round = 1, direction = "forward")
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Round 1: Forward (1 → 2 → 3 → 4)                           │
│                                                             │
│  각 플레이어마다:                                            │
│    phase = "settlement" → 정착지 배치 (무료, 연결규칙 무시)   │
│         │                                                   │
│         ▼                                                   │
│    phase = "road" → 도로 배치 (정착지에 연결)                │
│         │                                                   │
│         ▼                                                   │
│    다음 플레이어 (또는 Round 2로)                            │
└─────────────────────────────────────────────────────────────┘
    │ (플레이어 4 완료)
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Round 2: Reverse (4 → 3 → 2 → 1)                           │
│                                                             │
│  각 플레이어마다:                                            │
│    phase = "settlement" → 정착지 배치                        │
│         │                                                   │
│         ▼                                                   │
│    ★ 두 번째 정착지 인접 타일 자원 지급 ★                    │
│         │                                                   │
│         ▼                                                   │
│    phase = "road" → 도로 배치                                │
│         │                                                   │
│         ▼                                                   │
│    다음 플레이어 (또는 Playing으로)                          │
└─────────────────────────────────────────────────────────────┘
    │ (플레이어 1 완료)
    ▼
mode = "playing", turn.current = 1, phase = "roll"
```

**advanceSetup() 상태 전이 로직:**

```lua
function GameState:advanceSetup()
  if self.setup.phase == "settlement" then
    -- 정착지 → 도로
    self.setup.phase = "road"
  else
    -- 도로 → 다음 플레이어 또는 다음 라운드
    self.setup.phase = "settlement"

    if self.setup.direction == "forward" then
      if self.setup.currentPlayer < self.config.playerCount then
        self.setup.currentPlayer = self.setup.currentPlayer + 1
      else
        -- Round 1 완료 → Round 2 시작 (역순)
        self.setup.round = 2
        self.setup.direction = "reverse"
        -- currentPlayer는 그대로 (마지막 플레이어부터 시작)
      end
    else -- reverse
      if self.setup.currentPlayer > 1 then
        self.setup.currentPlayer = self.setup.currentPlayer - 1
      else
        -- Round 2 완료 → Playing 모드로 전환
        self.mode = "playing"
        self.turn.current = 1
        self.turn.phase = "roll"
      end
    end
  end
end
```

#### 턴 내 페이즈 전환 (mode = "playing")

```
턴 시작 (phase = "roll")
    │
    ▼
주사위 굴림 (rollDice())
    │
    ├── 7이 아닌 경우: 자원 분배
    │
    ▼
phase = "main"
    │
    ├── 건설 가능 (canBuild() = true)
    │   ├── 정착지 건설
    │   ├── 도시 건설
    │   └── 도로 건설
    │
    ▼
턴 종료 (endTurn())
    │
    ├── 승리 체크 (checkVictory())
    │   ├── 승자 있음 → status = "finished"
    │   └── 승자 없음 → 계속
    │
    ▼
다음 플레이어 (nextPlayer())
    │
    └── phase = "roll"
```

---

## Non-Functional Requirements

### Performance

| 지표 | 목표 | 측정 방법 |
|------|------|----------|
| 프레임레이트 | 60 FPS 유지 | love.timer.getFPS() |
| 씬 전환 지연 | < 100ms | 체감 측정 |
| 메모리 | 게임 중 < 100MB | collectgarbage("count") |

### Security

- 로컬 핫시트 게임이므로 보안 요구사항 최소
- 저장 파일 생성 시 사용자 디렉토리 내로 제한 (향후)

### Reliability/Availability

- 예외 발생 시 크래시 방지 (pcall 래핑)
- 잘못된 상태 전이 시 오류 메시지 출력

### Observability

- 콘솔에 턴/페이즈 변경 로깅
- 디버그 모드에서 게임 상태 덤프 가능

---

## Dependencies and Integrations

### 외부 라이브러리

| 라이브러리 | 버전 | 용도 |
|-----------|------|------|
| Love2D | 11.5+ | 게임 엔진 |
| hump.gamestate | latest | 씬 관리 |
| classic | latest | 클래스 시스템 |

### 내부 모듈 의존성

```
game_state.lua
    ├── board.lua
    ├── player.lua
    ├── rules.lua (checkVictory, distributeResources)
    ├── dice.lua
    └── actions.lua

scenes/game.lua
    ├── game_state.lua
    ├── board_view.lua
    ├── hud.lua
    └── input.lua

scenes/menu.lua
    └── hump/gamestate.lua

scenes/game_over.lua
    └── hump/gamestate.lua
```

---

## Acceptance Criteria (Authoritative)

### AC 7-1: 턴 순서 관리

```
AC 7-1.1: Given GameState with 4 players
          When game:getCurrentPlayer() 호출
          Then 현재 턴 플레이어 반환

AC 7-1.2: Given 플레이어1 턴
          When game:endTurn() 호출
          Then 현재 플레이어 = 플레이어2

AC 7-1.3: Given 플레이어4 턴
          When game:endTurn() 호출
          Then 현재 플레이어 = 플레이어1 (순환)
```

### AC 7-2: 페이즈 관리

```
AC 7-2.1: Given 턴 시작
          When game:getPhase() 호출
          Then "roll" 반환

AC 7-2.2: Given roll 페이즈
          When 주사위 굴림 완료
          Then 페이즈 = "main"

AC 7-2.3: Given main 페이즈
          When game:endTurn() 호출
          Then 다음 플레이어, 페이즈 = "roll"

AC 7-2.4: Given roll 페이즈
          When 건설 시도
          Then 실패 (canBuild() = false)
```

### AC 7-2.5: Setup 모드 (초기 배치)

```
AC 7-2.5.1: Given 새 게임 시작
            When GameState.new(4) 호출
            Then mode = "setup", round = 1, direction = "forward"
            And setup.currentPlayer = 1, setup.phase = "settlement"

AC 7-2.5.2: Given setup 모드, 플레이어1 정착지 배치 완료
            When advanceSetup() 호출
            Then setup.phase = "road" (같은 플레이어)

AC 7-2.5.3: Given setup 모드, 플레이어1 도로 배치 완료
            When advanceSetup() 호출
            Then setup.currentPlayer = 2, setup.phase = "settlement"

AC 7-2.5.4: Given setup 모드 Round 1, 플레이어4 도로 배치 완료
            When advanceSetup() 호출
            Then round = 2, direction = "reverse"
            And setup.currentPlayer = 4 (역순 시작)

AC 7-2.5.5: Given setup 모드 Round 2, 플레이어1 정착지 배치 완료
            When 두 번째 정착지 배치
            Then 인접 타일 자원 각 1개씩 해당 플레이어에게 지급

AC 7-2.5.6: Given setup 모드 Round 2, 플레이어1 도로 배치 완료
            When advanceSetup() 호출
            Then mode = "playing", turn.current = 1, phase = "roll"
```

### AC 7-2.6: UI 피드백

```
AC 7-2.6.1: Given roll 페이즈
            When 건설 버튼 표시
            Then 버튼이 비활성화(회색) 상태
            (UI가 canBuild() 결과와 동기화)

AC 7-2.6.2: Given 턴 전환 시
            When 다음 플레이어로 변경
            Then 화면에 "Player X's Turn" 알림 표시
```

### AC 7-3: 메인 메뉴 씬

```
AC 7-3.1: Given 게임 실행
          When 초기 로드 완료
          Then 메인 메뉴 씬 표시

AC 7-3.2: Given 메인 메뉴
          When "New Game" 클릭
          Then 플레이어 수 선택 UI 표시

AC 7-3.3: Given 플레이어 수 선택 후
          When 게임 시작
          Then 게임 씬으로 전환

AC 7-3.4: Given 메인 메뉴
          When "Exit" 클릭
          Then 게임 종료
```

### AC 7-4: 게임 종료 처리

```
AC 7-4.1: Given 게임 진행 중
          When 플레이어가 10점 달성 (건설 완료 직후 체크)
          Then mode = "finished", 게임 종료 씬으로 전환

AC 7-4.2: Given 게임 종료 씬
          When 화면 표시
          Then "Player X Wins!" 메시지 표시
          And 최종 점수 표시

AC 7-4.3: Given 게임 종료 씬
          When "New Game" 클릭
          Then 메인 메뉴로 이동

AC 7-4.4: Given 게임 종료 씬
          When "Exit" 클릭
          Then 게임 종료
```

### AC 7-5: 게임 플레이 통합

```
AC 7-5.1: Given game.lua 게임 씬
          When "Roll Dice" 버튼 클릭
          Then gameState:rollDice() 호출
          And 주사위 결과 HUD에 표시
          And roll 페이즈가 아니면 버튼 비활성화

AC 7-5.2: Given game.lua 게임 씬
          When "Settlement" 버튼 클릭
          Then settlement 선택 모드 진입
          And 유효한 정점 하이라이트

AC 7-5.3: Given settlement 선택 모드
          When 유효한 정점 클릭
          Then Actions.buildSettlement() 실행
          And 건물 렌더링 업데이트
          And 승리 체크

AC 7-5.4: Given game.lua 게임 씬
          When "City" 버튼 클릭
          Then city 선택 모드 진입
          And 업그레이드 가능한 정착지 하이라이트

AC 7-5.5: Given city 선택 모드
          When 유효한 정점 클릭 (기존 정착지)
          Then Actions.buildCity() 실행
          And 건물 렌더링 업데이트
          And 승리 체크

AC 7-5.6: Given game.lua 게임 씬
          When "Road" 버튼 클릭
          Then road 선택 모드 진입
          And 유효한 변 하이라이트

AC 7-5.7: Given road 선택 모드
          When 유효한 변 클릭
          Then Actions.buildRoad() 실행
          And 건물 렌더링 업데이트

AC 7-5.8: Given main 페이즈
          When "End Turn" 버튼 클릭
          Then gameState:endTurn() 호출
          And 다음 플레이어로 전환
          And roll 페이즈가 아니면 버튼 비활성화
```

---

## Traceability Mapping

| AC | Spec Section | Component/API | Test Idea |
|----|--------------|---------------|-----------|
| AC 7-1.1 | Data Models | GameState:getCurrentPlayer() | game_state_spec.lua |
| AC 7-1.2 | APIs | GameState:endTurn() | game_state_spec.lua |
| AC 7-1.3 | APIs | GameState:nextPlayer() | 경계값 테스트 |
| AC 7-2.1 | Data Models | GameState.turn.phase | game_state_spec.lua |
| AC 7-2.2 | APIs | GameState:rollDice() | game_state_spec.lua |
| AC 7-2.3 | Workflows | endTurn 시퀀스 | game_state_spec.lua |
| AC 7-2.4 | APIs | GameState:canBuild() | 페이즈 체크 테스트 |
| AC 7-2.5.1 | Data Models | GameState.new() | game_state_spec.lua |
| AC 7-2.5.2 | APIs | advanceSetup() | setup 상태 전이 테스트 |
| AC 7-2.5.3 | APIs | advanceSetup() | 플레이어 순서 테스트 |
| AC 7-2.5.4 | APIs | advanceSetup() | Round 전환 테스트 |
| AC 7-2.5.5 | Workflows | placeInitialSettlement() | 자원 지급 테스트 |
| AC 7-2.5.6 | APIs | advanceSetup() | setup→playing 전환 테스트 |
| AC 7-2.6.1 | Scenes | UI 동기화 | 수동 테스트 (버튼 상태) |
| AC 7-2.6.2 | Scenes | 턴 전환 알림 | 수동 테스트 |
| AC 7-3.1 | Workflows | Gamestate.switch(menu) | 수동 테스트 |
| AC 7-3.2 | Scenes | menu:mousepressed() | 수동 테스트 |
| AC 7-3.3 | Scenes | Gamestate.switch(game) | 수동 테스트 |
| AC 7-3.4 | Scenes | love.event.quit() | 수동 테스트 |
| AC 7-4.1 | Workflows | checkVictory 연동 | 통합 테스트 |
| AC 7-4.2 | Scenes | game_over:draw() | 수동 테스트 |
| AC 7-4.3 | Scenes | Gamestate.switch(menu) | 수동 테스트 |
| AC 7-4.4 | Scenes | love.event.quit() | 수동 테스트 |
| AC 7-5.1 | Scenes | Roll Dice 버튼 + rollDice | 수동 테스트 |
| AC 7-5.2 | Scenes | Settlement 버튼 + 선택 모드 | 수동 테스트 |
| AC 7-5.3 | Scenes | mousepressed + Actions.buildSettlement | 수동 테스트 |
| AC 7-5.4 | Scenes | City 버튼 + 선택 모드 | 수동 테스트 |
| AC 7-5.5 | Scenes | mousepressed + Actions.buildCity | 수동 테스트 |
| AC 7-5.6 | Scenes | Road 버튼 + 선택 모드 | 수동 테스트 |
| AC 7-5.7 | Scenes | mousepressed + Actions.buildRoad | 수동 테스트 |
| AC 7-5.8 | Scenes | End Turn 버튼 + endTurn | 수동 테스트 |

---

## Risks, Assumptions, Open Questions

### Risks

| ID | 설명 | 완화 전략 |
|----|------|----------|
| R1 | hump.gamestate와 기존 main.lua 충돌 | main.lua 리팩토링, 씬으로 로직 이전 |
| R2 | 씬 간 상태 전달 복잡성 | GameState를 전역 또는 씬 파라미터로 전달 |
| R3 | 초기 배치 UI 복잡도 | setup 모드 로직 완전 구현, UI는 기존 입력 시스템 재활용 |

### Assumptions

| ID | 가정 |
|----|------|
| A1 | hump.gamestate가 정상 작동함 (lib/hump/gamestate.lua 존재) |
| A2 | 기존 규칙 모듈(rules.lua)의 checkVictory가 정상 동작 |
| A3 | 테스트는 주로 game_state.lua에 집중 (씬은 수동 테스트) |

### Open Questions

| ID | 질문 | 결정 |
|----|------|------|
| Q1 | 초기 배치 페이즈를 Epic 7에 포함할지? | **In-scope** - 로직 완전 구현, 전용 UI는 기존 입력 시스템 활용 |
| Q2 | 플레이어 수 선택 UI 디자인? | 간단한 버튼 (2, 3, 4) |
| Q3 | 게임 상태 저장/불러오기 포함? | **Out-of-scope** - serialize 인터페이스만 준비 |

---

## Test Strategy Summary

### Unit Tests (busted)

- `tests/game/game_state_spec.lua`
  - **Setup 모드 테스트**
    - Snake Draft 순서 (forward: 1→2→3→4, reverse: 4→3→2→1)
    - 2인, 3인, 4인 게임 각각 setup 순서 검증
    - settlement → road 페이즈 전환
    - Round 1 → Round 2 전환
    - Round 2 완료 → playing 모드 전환
    - 두 번째 정착지 자원 지급
  - **Playing 모드 테스트**
    - 턴 순환 로직 (2인, 3인, 4인 각각)
    - 페이즈 전환 로직 (roll → main)
    - 모드 전환 로직 (playing → finished)
    - 승리 체크 연동
    - canRoll/canBuild 상태 체크

### 상태 주입 테스트

```lua
-- 테스트용 팩토리 메서드 (특정 상태로 시작)
GameState.newForTesting({
  playerCount = 2,
  currentPlayer = 1,
  phase = "main",
  players = {
    {victoryPoints = 9},  -- 승리 직전 상태
    {victoryPoints = 5},
  },
})
```

### Integration Tests

- GameState + Rules.checkVictory 연동
- GameState + Rules.distributeResources 연동
- 씬 전환 시 GameState 생명주기 (생성/정리)

### Manual Tests

- 메뉴 씬 네비게이션
- 게임 씬 플로우 (roll → build → end turn)
- 게임 종료 씬 표시 및 네비게이션
- 전체 게임 플레이스루 (2-4인)

### Edge Cases

- 플레이어 4 → 플레이어 1 순환
- 2인, 3인, 4인 게임 각각 플레이어 순환 검증
- roll 페이즈에서 건설 시도 방지
- 정확히 10점 도달 시 즉시 승리
- 건설로 10점 초과 시 승리
- 빠른 연속 클릭 시 중복 액션 방지
- 게임 도중 창 닫기/최소화 처리
- Game Over에서 New Game 시 이전 상태 완전 정리

---

## Implementation Notes (Root Cause Analysis 기반)

### 씬 전환 시 상태 정리

```lua
-- menu.lua에서 새 게임 시작 시
function menu:startGame(playerCount)
  -- 기존 GameState 명시적 정리
  currentGame = nil
  collectgarbage("collect")

  -- 새 GameState 생성
  currentGame = GameState.new(playerCount)
  Gamestate.switch(game, currentGame)
end
```

### 플레이어 순환 경계 처리

```lua
function GameState:nextPlayer()
  -- playerCount에 맞게 순환 (2인, 3인, 4인 게임 모두 지원)
  self.turn.current = (self.turn.current % self.config.playerCount) + 1
end
```

### 승리 체크 트리거 시점

- 건설 완료 직후 즉시 `checkVictory()` 호출
- `mode = "finished"` 설정 후 씬 전환
- endTurn()이 아닌 건설 액션에서 트리거

---

_Generated by BMAD Epic Tech Context Workflow_
_Enhanced with: First Principles, Stakeholder Mapping, Root Cause Analysis, Six Thinking Hats_
_Based on: GDD.md, game-architecture.md, epics.md_
