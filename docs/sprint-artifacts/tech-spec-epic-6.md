# Epic Technical Specification: Visual Experience

Date: 2025-11-30
Author: BMad
Epic ID: 6
Status: Draft

---

## Overview

Epic 6는 게임의 시각적 경험을 구현합니다. 지금까지 구축한 순수 게임 로직(src/game/)을 Love2D를 사용하여 화면에 렌더링하고, 플레이어의 마우스 입력을 게임 좌표로 변환하는 UI 레이어를 구축합니다. 이 에픽은 FR13(헥스 보드 렌더링), FR14(건물/도로 렌더링), FR15(HUD 표시), FR16(입력 처리)를 커버합니다.

## Objectives and Scope

### In-Scope

- 19개 헥스 타일 렌더링 (지형별 색상, 숫자 토큰)
- 정착지, 도시, 도로 렌더링 (플레이어별 색상)
- HUD 표시 (자원 5종, 승리 점수, 현재 턴, 주사위 결과)
- 마우스 클릭 → 헥스/정점/변 좌표 변환
- 건설 가능 위치 하이라이트

### Out-of-Scope

- 모바일 터치 입력 (추후 구현)
- 애니메이션 효과
- 사운드/음악
- 게임 씬 전환 (Epic 7)
- 줌/팬 기능

## System Architecture Alignment

Architecture 문서의 `src/ui/` 구조를 따름:

```
src/ui/
├── board_view.lua   -- 헥스 보드 및 건물 렌더링
├── hud.lua          -- 자원, 점수, 턴 표시
├── input.lua        -- 마우스 → 게임 좌표 변환
└── colors.lua       -- 색상 팔레트 정의
```

**의존성 방향:**
- `src/ui/` → `src/game/` (단방향)
- `src/game/`은 Love2D 의존성 없음 유지

## Detailed Design

### Services and Modules

| 모듈 | 책임 | 의존성 |
|------|------|--------|
| `colors.lua` | 지형, 플레이어, UI 색상 정의 | 없음 |
| `board_view.lua` | 헥스 타일, 건물, 도로 렌더링 | hex, board, colors |
| `hud.lua` | 자원, 점수, 턴 정보 표시 | player, constants, colors |
| `input.lua` | 픽셀 → 헥스/정점/변 좌표 변환 | hex, vertex, edge |

### Data Models and Contracts

#### colors.lua

```lua
local Colors = {
  -- 지형 색상 (RGB 0-1)
  TERRAIN = {
    forest = {0.2, 0.6, 0.2},    -- 녹색
    hills = {0.8, 0.5, 0.2},     -- 주황
    pasture = {0.6, 0.8, 0.4},   -- 연두
    fields = {0.9, 0.8, 0.3},    -- 노랑
    mountains = {0.5, 0.5, 0.5}, -- 회색
    desert = {0.9, 0.85, 0.7},   -- 베이지
  },

  -- 플레이어 색상
  PLAYER = {
    [1] = {0.9, 0.2, 0.2},  -- 빨강
    [2] = {0.2, 0.4, 0.9},  -- 파랑
    [3] = {0.2, 0.8, 0.2},  -- 초록
    [4] = {0.9, 0.8, 0.2},  -- 노랑
  },

  -- 숫자 토큰 색상
  NUMBER = {
    normal = {0, 0, 0},         -- 검정
    hot = {0.8, 0.1, 0.1},      -- 빨강 (6, 8)
  },

  -- UI 색상
  UI = {
    background = {0.1, 0.15, 0.2},
    text = {1, 1, 1},
    highlight = {1, 1, 0, 0.3},
  },
}
```

#### board_view.lua Interface

```lua
local BoardView = {}

-- 보드 전체 렌더링
function BoardView.draw(board, buildings, hexSize, offsetX, offsetY)
  -- 1. 모든 헥스 타일 그리기
  -- 2. 숫자 토큰 그리기
  -- 3. 도로 그리기
  -- 4. 건물 그리기
end

-- 단일 헥스 그리기
function BoardView.drawHex(q, r, terrain, number, hexSize, offsetX, offsetY)
end

-- 정착지 그리기 (삼각형)
function BoardView.drawSettlement(px, py, playerId, size)
end

-- 도시 그리기 (사각형)
function BoardView.drawCity(px, py, playerId, size)
end

-- 도로 그리기 (선)
function BoardView.drawRoad(px1, py1, px2, py2, playerId, width)
end

-- 하이라이트 (건설 가능 위치)
function BoardView.drawVertexHighlight(px, py, radius)
end

function BoardView.drawEdgeHighlight(px1, py1, px2, py2, width)
end
```

#### hud.lua Interface

```lua
local HUD = {}

-- 전체 HUD 렌더링
function HUD.draw(gameState, screenWidth, screenHeight)
  -- 1. 현재 플레이어 자원 표시
  -- 2. 승리 점수 표시
  -- 3. 현재 턴 플레이어 표시
  -- 4. 주사위 결과 표시 (있으면)
end

-- 자원 패널 (하단)
function HUD.drawResourcePanel(player, x, y, width, height)
end

-- 점수 표시 (우측 상단)
function HUD.drawScorePanel(players, x, y)
end

-- 턴 정보 (상단)
function HUD.drawTurnInfo(currentPlayer, phase, x, y)
end

-- 주사위 결과
function HUD.drawDiceResult(die1, die2, x, y)
end
```

#### input.lua Interface

```lua
local Input = {}

-- 픽셀 → 헥스 좌표
function Input.pixelToHex(px, py, hexSize, offsetX, offsetY)
  -- hex.pixelToCube 활용
  -- 반환: {q, r} 또는 nil (보드 밖)
end

-- 픽셀 → 가장 가까운 정점
function Input.pixelToVertex(px, py, hexSize, offsetX, offsetY, threshold)
  -- 반환: {q, r, dir} 또는 nil (threshold 밖)
end

-- 픽셀 → 가장 가까운 변
function Input.pixelToEdge(px, py, hexSize, offsetX, offsetY, threshold)
  -- 반환: {q, r, dir} 또는 nil (threshold 밖)
end

-- 정점 픽셀 좌표 계산
function Input.getVertexPixel(q, r, dir, hexSize, offsetX, offsetY)
  -- 반환: {px, py}
end

-- 변 픽셀 좌표 계산 (양 끝점)
function Input.getEdgePixels(q, r, dir, hexSize, offsetX, offsetY)
  -- 반환: {px1, py1, px2, py2}
end
```

### APIs and Interfaces

이 에픽은 외부 API가 없음. Love2D 콜백과의 통합:

```lua
-- main.lua 또는 scenes/game.lua에서 호출
function love.draw()
  BoardView.draw(game.board, game.buildings, HEX_SIZE, OFFSET_X, OFFSET_Y)
  HUD.draw(game, love.graphics.getWidth(), love.graphics.getHeight())
end

function love.mousepressed(x, y, button)
  if button == 1 then
    local hex = Input.pixelToHex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y)
    local vertex = Input.pixelToVertex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, THRESHOLD)
    local edge = Input.pixelToEdge(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, THRESHOLD)
    -- 게임 로직에 전달
  end
end
```

### Workflows and Sequencing

#### 렌더링 순서

```
1. 배경 클리어
2. 모든 헥스 타일 (아래에서 위로)
3. 숫자 토큰
4. 도로 (변 위에)
5. 건물 (정점 위에)
6. 하이라이트 (선택/호버)
7. HUD (최상단)
```

#### 입력 처리 흐름

```
마우스 클릭
    ↓
현재 게임 모드 확인
    ↓
┌─ 건설 모드 ─┐
│ vertex/edge 선택 │
│ 건설 규칙 검증   │
│ 건설 실행       │
└───────────────┘
┌─ 일반 모드 ─┐
│ hex 선택    │
│ 정보 표시   │
└───────────┘
```

## Non-Functional Requirements

### Performance

| 항목 | 목표 | 측정 방법 |
|------|------|----------|
| 프레임레이트 | 60 FPS | love.timer.getFPS() |
| 렌더링 시간 | < 10ms/frame | 프로파일링 |
| 입력 지연 | < 16ms | 체감 |

**최적화 전략:**
- 정적 요소(헥스 타일)는 Canvas에 캐싱
- 매 프레임 재계산 최소화

### Security

N/A - 로컬 싱글플레이어 게임

### Reliability/Availability

- 렌더링 실패 시 기본 색상 폴백
- 잘못된 좌표 입력 시 nil 반환 (크래시 방지)

### Observability

- `love.graphics.print`로 디버그 정보 표시 (개발 모드)
- FPS 카운터 표시 옵션

## Dependencies and Integrations

### 내부 의존성 (src/game/)

| 모듈 | 용도 | 상태 |
|------|------|------|
| `hex.lua` | 좌표 변환 (cubeToPixel, pixelToCube) | ✅ 구현됨 |
| `vertex.lua` | 정점 정규화, 좌표 계산 | ✅ 구현됨 |
| `edge.lua` | 변 정규화, 좌표 계산 | ✅ 구현됨 |
| `board.lua` | 타일 정보 조회 | ✅ 구현됨 |
| `player.lua` | 자원, 점수 조회 | ✅ 구현됨 |
| `constants.lua` | 자원 타입, 지형 타입 | ✅ 구현됨 |

### 외부 의존성

| 라이브러리 | 버전 | 용도 |
|-----------|------|------|
| Love2D | 11.5+ | 그래픽 렌더링, 입력 처리 |

### 설정 상수

```lua
-- conf.lua 또는 별도 config
local Config = {
  HEX_SIZE = 50,           -- 헥스 크기 (픽셀)
  BOARD_OFFSET_X = 640,    -- 보드 중심 X
  BOARD_OFFSET_Y = 360,    -- 보드 중심 Y
  VERTEX_THRESHOLD = 15,   -- 정점 선택 임계값 (픽셀)
  EDGE_THRESHOLD = 10,     -- 변 선택 임계값 (픽셀)
  BUILDING_SIZE = 12,      -- 건물 크기
  ROAD_WIDTH = 4,          -- 도로 두께
}
```

## Acceptance Criteria (Authoritative)

### AC-6.1: 헥스 보드 렌더링

1. 19개 헥스 타일이 올바른 위치에 렌더링됨
2. 각 타일은 지형에 맞는 색상으로 표시됨 (forest=녹색, hills=주황, ...)
3. 각 타일 중앙에 숫자 토큰이 표시됨 (사막 제외)
4. 6, 8은 빨간색으로 강조 표시됨

### AC-6.2: 건물/도로 렌더링

1. 정착지는 삼각형으로, 도시는 사각형으로 표시됨
2. 도로는 변을 따라 선으로 표시됨
3. 각 건물/도로는 소유 플레이어의 색상으로 표시됨
4. 플레이어 색상: 1=빨강, 2=파랑, 3=초록, 4=노랑

### AC-6.3: HUD 표시

1. 현재 플레이어의 5종 자원이 숫자로 표시됨
2. 현재 플레이어의 승리 점수가 표시됨
3. 현재 턴 플레이어가 누구인지 표시됨
4. 주사위 굴림 후 결과가 표시됨

### AC-6.4: 마우스 → 헥스 변환

1. 헥스 타일 클릭 시 해당 헥스의 (q, r) 좌표가 반환됨
2. 보드 바깥 클릭 시 nil이 반환됨
3. 헥스 위 호버 시 하이라이트 가능

### AC-6.5: 정점/변 선택

1. 정점 근처 클릭 시 해당 정점의 (q, r, dir) 좌표가 반환됨
2. 변 근처 클릭 시 해당 변의 (q, r, dir) 좌표가 반환됨
3. 임계값(threshold) 밖 클릭 시 nil 반환
4. 건설 가능 위치가 하이라이트 표시됨

## Traceability Mapping

| AC | Spec Section | Component | Test Idea |
|----|--------------|-----------|-----------|
| AC-6.1.1 | Detailed Design - board_view | BoardView.draw | 19개 타일 위치 검증 |
| AC-6.1.2 | Data Models - colors | Colors.TERRAIN | 지형별 색상 매핑 확인 |
| AC-6.1.3 | Workflows - 렌더링 순서 | BoardView.drawHex | 숫자 토큰 표시 확인 |
| AC-6.1.4 | Data Models - colors | Colors.NUMBER.hot | 6,8 빨간색 확인 |
| AC-6.2.1 | APIs - board_view | drawSettlement, drawCity | 도형 확인 |
| AC-6.2.2 | APIs - board_view | drawRoad | 선 렌더링 확인 |
| AC-6.2.3 | Data Models - colors | Colors.PLAYER | 플레이어별 색상 확인 |
| AC-6.3.1 | APIs - hud | drawResourcePanel | 자원 표시 확인 |
| AC-6.3.2 | APIs - hud | drawScorePanel | 점수 표시 확인 |
| AC-6.3.3 | APIs - hud | drawTurnInfo | 턴 정보 확인 |
| AC-6.3.4 | APIs - hud | drawDiceResult | 주사위 결과 확인 |
| AC-6.4.1 | APIs - input | pixelToHex | 좌표 변환 테스트 |
| AC-6.4.2 | APIs - input | pixelToHex | nil 반환 테스트 |
| AC-6.5.1 | APIs - input | pixelToVertex | 정점 선택 테스트 |
| AC-6.5.2 | APIs - input | pixelToEdge | 변 선택 테스트 |
| AC-6.5.3 | APIs - input | threshold 로직 | 임계값 테스트 |

## Risks, Assumptions, Open Questions

### Risks

| 리스크 | 확률 | 영향 | 완화 방안 |
|--------|------|------|----------|
| 정점/변 픽셀 좌표 계산 오류 | 중 | 높음 | hex.lua의 cubeToPixel 재활용, 시각적 디버그 |
| 렌더링 성능 저하 | 낮 | 중 | Canvas 캐싱, 필요시 최적화 |
| 클릭 판정 부정확 | 중 | 중 | threshold 조정 가능하게 설계 |

### Assumptions

1. Love2D 11.5+ 사용 (love.graphics API 호환)
2. 해상도 1280x720 기준 설계 (conf.lua)
3. Pointy-top 헥스 레이아웃 (Architecture 결정)
4. 마우스 입력만 지원 (터치는 추후)

### Open Questions

1. **Q:** 헥스 크기(HEX_SIZE)는 고정인가, 줌 기능이 필요한가?
   **A:** MVP는 고정 크기, 줌은 추후 고려

2. **Q:** 건설 가능 위치 하이라이트는 항상 표시인가, 건설 모드에서만인가?
   **A:** 건설 모드에서만 표시 (Epic 7에서 모드 관리)

## Test Strategy Summary

### 단위 테스트 (busted)

UI 모듈은 Love2D 의존성이 있어 기존 busted 테스트와 분리:

- `input.lua`의 좌표 변환 로직은 순수 계산이므로 테스트 가능
- `colors.lua`는 상수 정의이므로 테스트 불필요

### 통합 테스트

```lua
-- tests/ui/input_spec.lua (hex.lua 의존)
describe("Input", function()
  describe("pixelToHex", function()
    it("should return center hex for center pixel", function()
      local hex = Input.pixelToHex(640, 360, 50, 640, 360)
      assert.same({q=0, r=0}, hex)
    end)
  end)
end)
```

### 수동 테스트 (Visual)

1. 게임 실행 후 19개 타일 렌더링 확인
2. 각 지형 색상이 올바른지 확인
3. 숫자 토큰 위치 및 색상 확인
4. 건물/도로 배치 후 렌더링 확인
5. HUD 정보가 게임 상태와 일치하는지 확인
6. 클릭 위치가 올바른 좌표로 변환되는지 콘솔 출력으로 확인

### 테스트 환경

```lua
-- 디버그 모드에서 클릭 좌표 출력
function love.mousepressed(x, y, button)
  local hex = Input.pixelToHex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y)
  local vertex = Input.pixelToVertex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, 15)
  print(string.format("Click: (%d, %d) -> Hex: %s, Vertex: %s",
    x, y,
    hex and string.format("(%d,%d)", hex.q, hex.r) or "nil",
    vertex and string.format("(%d,%d,%s)", vertex.q, vertex.r, vertex.dir) or "nil"
  ))
end
```

---

_Generated by BMAD Epic Tech Context Workflow_
_Based on: GDD.md, game-architecture.md, epics.md_
