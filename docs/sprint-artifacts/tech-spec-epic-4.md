# Epic Technical Specification: Board State (보드 상태)

Date: 2025-11-30
Author: BMad
Epic ID: 4
Status: Draft

---

## Overview

Epic 4는 카탄 게임 보드의 상태 관리를 구현합니다. 19개 헥스 타일 생성, 숫자 토큰 배치, 정착지/도시/도로 배치 및 조회 기능을 포함합니다.

이 에픽은 GDD의 "Phase 3: 보드 상태" 요구사항과 Architecture 문서의 `src/game/board.lua` 모듈을 구현합니다. Epic 3(헥스 좌표계)의 정점/변 정규화 기능을 활용하여 건물 위치를 관리합니다.

## Objectives and Scope

### In-Scope

- 19개 헥스 타일로 구성된 카탄 표준 보드 생성
- 지형별 타일 분포 (숲4, 언덕3, 목초지4, 농장4, 산3, 사막1)
- 숫자 토큰 배치 (2-12, 7 제외)
- 정점에 정착지/도시 배치 및 조회
- 변에 도로 배치 및 조회
- 특정 숫자의 타일 조회 (자원 분배용)
- 플레이어별 건물/도로 조회

### Out-of-Scope

- 건설 규칙 검증 (Epic 5: Game Rules)
- 자원 분배 로직 (Epic 5)
- 보드 렌더링 (Epic 6: Visual Experience)
- 도둑 이동 (2차 구현)

## System Architecture Alignment

이 에픽은 Architecture 문서의 다음 섹션과 정렬됩니다:

- **Project Structure**: `src/game/board.lua`
- **Module Dependencies**: board.lua ← hex.lua, vertex.lua, edge.lua, constants.lua
- **ADR-003**: Map 기반 건물 저장 - 정규화된 좌표 문자열을 키로 사용

**제약 사항:**
- `src/game/` 내 모든 모듈은 Love2D 의존성 없이 순수 Lua로 구현
- busted로 독립 테스트 가능
- 직렬화 가능한 데이터 구조 (serpent 호환)

## Detailed Design

### Services and Modules

| 모듈 | 파일 | 책임 | 의존성 |
|------|------|------|--------|
| Board | src/game/board.lua | 보드 상태 관리, 타일/건물/도로 | hex.lua, vertex.lua, edge.lua, constants.lua |

### Data Models and Contracts

**Board 구조 (Architecture GameState 참조):**

```lua
local Board = {}
Board.__index = Board

function Board.new()
  local self = setmetatable({}, Board)

  -- 타일 저장: Map 구조 (key = "q,r")
  self.tiles = {}  -- tiles["0,0"] = {q=0, r=0, terrain="forest", number=8}

  -- 건물 저장: Map 구조 (key = 정규화된 정점 문자열)
  self.settlements = {}  -- settlements["0,1,N"] = {player=1}
  self.cities = {}       -- cities["0,0,N"] = {player=1}

  -- 도로 저장: Map 구조 (key = 정규화된 변 문자열)
  self.roads = {}  -- roads["0,0,E"] = {player=1}

  -- 도둑 위치 (사막에서 시작)
  self.robber = nil  -- {q=0, r=0}

  return self
end
```

**타일 분포 상수:**

```lua
-- constants.lua에 추가
TILE_DISTRIBUTION = {
  forest = 4,    -- 목재
  hills = 3,     -- 벽돌
  pasture = 4,   -- 양모
  fields = 4,    -- 밀
  mountains = 3, -- 광석
  desert = 1,    -- 없음
}

NUMBER_TOKEN_DISTRIBUTION = {
  [2] = 1,
  [3] = 2,
  [4] = 2,
  [5] = 2,
  [6] = 2,
  [8] = 2,
  [9] = 2,
  [10] = 2,
  [11] = 2,
  [12] = 1,
}
```

**표준 보드 레이아웃 (19 헥스):**

```
링 구조:
- 중심 (1개): (0, 0)
- 내부 링 (6개): 거리 1
- 외부 링 (12개): 거리 2

Axial 좌표:
중심: (0, 0)
내부: (1,0), (1,-1), (0,-1), (-1,0), (-1,1), (0,1)
외부: (2,0), (2,-1), (2,-2), (1,-2), (0,-2), (-1,-1),
      (-2,0), (-2,1), (-2,2), (-1,2), (0,2), (1,1)
```

### APIs and Interfaces

**Board 생성 API:**

| 함수 | 파라미터 | 반환값 | 설명 |
|------|----------|--------|------|
| `Board.new()` | 없음 | Board | 빈 보드 생성 |
| `Board.newStandard()` | 없음 | Board | 19타일 표준 보드 생성 |
| `Board.newWithSeed(seed)` | seed: number | Board | 시드 기반 랜덤 보드 |

**타일 API:**

| 함수 | 파라미터 | 반환값 | 설명 |
|------|----------|--------|------|
| `board:getTile(q, r)` | q, r: number | tile or nil | 타일 정보 조회 |
| `board:getAllTiles()` | 없음 | table | 모든 타일 목록 |
| `board:getTilesWithNumber(num)` | num: number | table | 해당 숫자 타일들 |
| `board:getAdjacentTiles(q, r, dir)` | 정점 좌표 | table | 정점 인접 타일들 (최대 3개) |

**건물 API:**

| 함수 | 파라미터 | 반환값 | 설명 |
|------|----------|--------|------|
| `board:placeSettlement(playerId, q, r, dir)` | coords | boolean, error | 정착지 배치 |
| `board:placeCity(playerId, q, r, dir)` | coords | boolean, error | 도시 배치 |
| `board:upgradeToCity(q, r, dir)` | coords | boolean, error | 정착지→도시 |
| `board:getBuilding(q, r, dir)` | coords | building or nil | 건물 조회 |
| `board:hasBuilding(q, r, dir)` | coords | boolean | 건물 존재 여부 |
| `board:getPlayerBuildings(playerId)` | playerId: number | table | 플레이어 건물들 |
| `board:getSettlementsOnTile(q, r)` | coords | table | 타일 인접 정착지들 |
| `board:getCitiesOnTile(q, r)` | coords | table | 타일 인접 도시들 |

**도로 API:**

| 함수 | 파라미터 | 반환값 | 설명 |
|------|----------|--------|------|
| `board:placeRoad(playerId, q, r, dir)` | coords | boolean, error | 도로 배치 |
| `board:getRoad(q, r, dir)` | coords | road or nil | 도로 조회 |
| `board:hasRoad(q, r, dir)` | coords | boolean | 도로 존재 여부 |
| `board:getPlayerRoads(playerId)` | playerId: number | table | 플레이어 도로들 |
| `board:isVertexConnectedToRoad(playerId, q, r, dir)` | coords | boolean | 정점-도로 연결 |

### Workflows and Sequencing

**보드 초기화 시퀀스:**

```
1. Board.newStandard() 호출
   ↓
2. 지형 타일 풀 생성 (4+3+4+4+3+1 = 19개)
   ↓
3. 타일 풀 셔플 (Fisher-Yates)
   ↓
4. 좌표에 타일 배치 (나선형 순서)
   ↓
5. 숫자 토큰 풀 생성 (18개, 7 제외)
   ↓
6. 숫자 토큰 배치 (사막 제외)
   ↓
7. 도둑 초기 위치 설정 (사막)
```

**건물 배치 시퀀스:**

```
1. placeSettlement(playerId, q, r, dir) 호출
   ↓
2. 정점 정규화: vertex.normalize(q, r, dir)
   ↓
3. 키 생성: vertex.toString(q, r, dir)
   ↓
4. 중복 체크: self.settlements[key] 또는 self.cities[key]
   ↓
5. 배치: self.settlements[key] = {player = playerId}
```

**자원 분배를 위한 타일-건물 조회:**

```
1. 주사위 결과 num 받음
   ↓
2. board:getTilesWithNumber(num) → 해당 타일들
   ↓
3. 각 타일에 대해:
   → board:getSettlementsOnTile(q, r) → 정착지 목록
   → board:getCitiesOnTile(q, r) → 도시 목록
   ↓
4. 각 건물 소유자에게 자원 지급
```

## Non-Functional Requirements

### Performance

| 항목 | 요구사항 |
|------|----------|
| 타일 조회 | O(1) - Map 키 조회 |
| 건물/도로 조회 | O(1) - 정규화된 키 조회 |
| 플레이어 건물 조회 | O(n) - n=해당 플레이어 건물 수 |
| 숫자별 타일 조회 | O(n) - n=전체 타일 수 (캐시 가능) |

### Security

- 유효하지 않은 좌표 입력 검증
- 플레이어 ID 유효성 검증 (1-4)

### Reliability/Availability

- 중복 배치 방지: 이미 건물/도로가 있는 위치에 배치 시 실패 반환
- 원자적 실패: 배치 실패 시 상태 변경 없음

### Observability

- 디버그용 `board:toString()` 메서드: 전체 보드 상태 출력
- 타일 수, 건물 수, 도로 수 통계 조회

## Dependencies and Integrations

### 내부 의존성

| 모듈 | 버전 | 용도 |
|------|------|------|
| src/game/constants.lua | Epic 2 | 지형/자원 상수, 타일 분포 |
| src/game/hex.lua | Epic 3 | 좌표 변환, 이웃 계산 |
| src/game/vertex.lua | Epic 3 | 정점 정규화, 인접 헥스 조회 |
| src/game/edge.lua | Epic 3 | 변 정규화, 인접 정점 조회 |

### 외부 의존성

| 의존성 | 버전 | 용도 |
|--------|------|------|
| classic.lua | lib/ | 클래스 시스템 (선택적) |

## Acceptance Criteria (Authoritative)

### Story 4-1: 보드 타일 생성

- **AC4-1-1**: Board.newStandard() 호출 시 19개 타일 생성됨
- **AC4-1-2**: 타일 분포가 GDD 명세와 일치 (숲4, 언덕3, 목초지4, 농장4, 산3, 사막1)
- **AC4-1-3**: board:getTile(0, 0) → 중앙 타일 정보 {q, r, terrain, number} 반환
- **AC4-1-4**: board:getAllTiles() → 19개 타일 목록 반환
- **AC4-1-5**: 사막 타일은 number가 nil
- **AC4-1-6**: 테스트 통과: tests/game/board_spec.lua

### Story 4-2: 숫자 토큰 배치

- **AC4-2-1**: 사막 제외 18개 타일에 숫자 토큰 배치
- **AC4-2-2**: 숫자 토큰 분포: 2,12→1개씩, 3-6,8-11→2개씩
- **AC4-2-3**: board:getTilesWithNumber(8) → 숫자 8인 타일들 반환
- **AC4-2-4**: 7은 어떤 타일에도 배치되지 않음
- **AC4-2-5**: 테스트 통과

### Story 4-3: 정착지/도시 배치

- **AC4-3-1**: board:placeSettlement(1, 0, 0, "N") → 정착지 배치, true 반환
- **AC4-3-2**: board:getBuilding(0, 0, "N") → {type="settlement", player=1} 반환
- **AC4-3-3**: 이미 건물 있는 위치에 배치 시 false, 에러 메시지 반환
- **AC4-3-4**: board:upgradeToCity(0, 0, "N") → 정착지→도시 변환
- **AC4-3-5**: board:getPlayerBuildings(1) → 플레이어1의 모든 건물 목록
- **AC4-3-6**: 정규화: (0, -1, "S")와 (0, 0, "N")이 같은 정점이면 중복 감지
- **AC4-3-7**: 테스트 통과

### Story 4-4: 도로 배치

- **AC4-4-1**: board:placeRoad(1, 0, 0, "E") → 도로 배치, true 반환
- **AC4-4-2**: board:getRoad(0, 0, "E") → {player=1} 반환
- **AC4-4-3**: 이미 도로 있는 위치에 배치 시 false, 에러 메시지 반환
- **AC4-4-4**: board:getPlayerRoads(1) → 플레이어1의 모든 도로 목록
- **AC4-4-5**: board:isVertexConnectedToRoad(1, 0, 0, "N") → 해당 정점이 플레이어1 도로와 연결되면 true
- **AC4-4-6**: 정규화: (-1, 0, "W")와 (0, 0, "E")가 같은 변이면 중복 감지
- **AC4-4-7**: 테스트 통과

## Traceability Mapping

| AC | Spec Section | Component/API | Test Idea |
|----|--------------|---------------|-----------|
| AC4-1-1 | Data Models | Board.newStandard() | 타일 수 검증 |
| AC4-1-2 | Data Models | TILE_DISTRIBUTION | 지형별 카운트 검증 |
| AC4-1-3 | APIs | board:getTile() | 중앙 타일 조회 테스트 |
| AC4-1-4 | APIs | board:getAllTiles() | 목록 길이 검증 |
| AC4-1-5 | Workflows | 숫자 토큰 배치 | 사막 타일 number nil 검증 |
| AC4-2-1 | Workflows | 숫자 토큰 배치 | 18개 타일 숫자 존재 검증 |
| AC4-2-2 | Data Models | NUMBER_TOKEN_DISTRIBUTION | 분포 검증 |
| AC4-2-3 | APIs | board:getTilesWithNumber() | 숫자별 조회 테스트 |
| AC4-2-4 | Workflows | 숫자 토큰 배치 | 7이 없음 검증 |
| AC4-3-1 | APIs | board:placeSettlement() | 배치 성공 테스트 |
| AC4-3-2 | APIs | board:getBuilding() | 조회 테스트 |
| AC4-3-3 | Reliability | 중복 방지 | 중복 배치 실패 테스트 |
| AC4-3-4 | APIs | board:upgradeToCity() | 업그레이드 테스트 |
| AC4-3-5 | APIs | board:getPlayerBuildings() | 플레이어별 조회 |
| AC4-3-6 | Data Models | vertex.normalize | 정규화 일관성 |
| AC4-4-1 | APIs | board:placeRoad() | 배치 성공 테스트 |
| AC4-4-2 | APIs | board:getRoad() | 조회 테스트 |
| AC4-4-3 | Reliability | 중복 방지 | 중복 배치 실패 테스트 |
| AC4-4-4 | APIs | board:getPlayerRoads() | 플레이어별 조회 |
| AC4-4-5 | APIs | isVertexConnectedToRoad | 연결 검증 |
| AC4-4-6 | Data Models | edge.normalize | 정규화 일관성 |

## Risks, Assumptions, Open Questions

### Risks

| 리스크 | 영향 | 완화 방안 |
|--------|------|-----------|
| 정점/변 정규화 버그 | 중복 건물 허용 또는 유효 위치 거부 | Epic 3 테스트 철저히, 통합 테스트 추가 |
| 타일-정점 인접 관계 오류 | 자원 분배 오류 | Red Blob Games 참조, 시각화 디버그 |

### Assumptions

| 가정 | 근거 |
|------|------|
| Epic 3 좌표계 모듈이 완료됨 | 선행 의존성 |
| 표준 카탄 보드 레이아웃만 지원 | MVP 범위 |
| 타일/숫자 배치는 랜덤 | GDD 명세 |

### Open Questions

| 질문 | 답변/결정 |
|------|-----------|
| 숫자 토큰 배치 순서 (알파벳 vs 랜덤)? | 랜덤으로 결정 (GDD 참조) |
| 타일 인접 정점 계산 방법? | vertex.getAdjacentHexes 역으로 조회 |

## Test Strategy Summary

### 테스트 파일

```
tests/
└── game/
    └── board_spec.lua  -- Story 4-1, 4-2, 4-3, 4-4
```

### 테스트 구조

```lua
-- tests/game/board_spec.lua
describe("Board", function()
  local Board = require("src.game.board")

  describe("newStandard", function()
    it("should create 19 tiles", function()
      local board = Board.newStandard()
      assert.equals(19, #board:getAllTiles())
    end)

    it("should have correct terrain distribution", function()
      local board = Board.newStandard()
      local counts = {}
      for _, tile in ipairs(board:getAllTiles()) do
        counts[tile.terrain] = (counts[tile.terrain] or 0) + 1
      end
      assert.equals(4, counts.forest)
      assert.equals(3, counts.hills)
      -- ... 나머지 검증
    end)
  end)

  describe("placeSettlement", function()
    it("should place settlement at valid vertex", function()
      local board = Board.new()
      local ok, err = board:placeSettlement(1, 0, 0, "N")
      assert.is_true(ok)
      assert.is_nil(err)
    end)

    it("should reject duplicate placement", function()
      local board = Board.new()
      board:placeSettlement(1, 0, 0, "N")
      local ok, err = board:placeSettlement(2, 0, 0, "N")
      assert.is_false(ok)
      assert.is_not_nil(err)
    end)
  end)

  describe("isVertexConnectedToRoad", function()
    it("should return true when vertex has adjacent road", function()
      local board = Board.new()
      board:placeRoad(1, 0, 0, "E")
      -- E 변의 양 끝 정점 중 하나 확인
      assert.is_true(board:isVertexConnectedToRoad(1, 0, 0, "N"))
    end)
  end)
end)
```

### 커버리지 목표

- board.lua: 90%+
- 모든 AC에 대응하는 테스트 케이스 존재

---

_Generated by BMAD Epic Tech Context Workflow_
_Source: GDD.md, game-architecture.md, epics.md_
