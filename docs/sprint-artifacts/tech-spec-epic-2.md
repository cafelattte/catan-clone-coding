# Epic Technical Specification: Core Data Model (핵심 데이터 모델)

Date: 2025-11-30
Author: BMad
Epic ID: 2
Status: Draft

---

## Overview

Epic 2는 카탄 게임의 핵심 데이터 모델을 정의합니다. 5종 자원 타입, 건물 비용 상수, 플레이어 자원 관리(추가/차감/조회), 승리 점수 계산을 구현합니다.

이 에픽은 GDD의 "Phase 1: 데이터 모델" 요구사항과 Architecture 문서의 `src/game/constants.lua`, `src/game/player.lua` 모듈을 구현합니다. TDD First 원칙에 따라 모든 함수는 테스트 먼저 작성됩니다.

## Objectives and Scope

### In-Scope

- 5종 자원 타입 상수 정의 (wood, brick, sheep, wheat, ore)
- 4종 건물 비용 상수 정의 (road, settlement, city, devcard)
- Player 클래스 생성 및 자원 관리 메서드
- 자원 추가 (addResource)
- 자원 차감 (removeResource) 및 충분 여부 검증
- 자원 보유량 조회 (getResource, hasResources)
- 승리 점수 계산 (getVictoryPoints)

### Out-of-Scope

- 건물 배치 로직 (Epic 4에서 진행)
- 게임 상태 직렬화 (Epic 5에서 진행)
- 개발 카드 사용 로직 (2차 구현)
- 거래 시스템 (3차 구현)

## System Architecture Alignment

이 에픽은 Architecture 문서의 다음 섹션과 정렬됩니다:

- **Project Structure**: `src/game/constants.lua`, `src/game/player.lua`
- **Module Dependencies**: constants.lua는 의존성 없음, player.lua는 constants.lua에 의존
- **ADR-001**: 순수 Lua로 구현, Love2D 의존성 없음

**제약 사항:**
- `src/game/` 내 모든 모듈은 Love2D 의존성 없이 순수 Lua로 구현
- busted로 독립 테스트 가능해야 함
- Naming Convention: 상수는 UPPER_SNAKE_CASE, 함수는 camelCase

## Detailed Design

### Services and Modules

| 모듈 | 파일 | 책임 | 의존성 |
|------|------|------|--------|
| Constants | src/game/constants.lua | 자원 타입, 건물 비용 상수 | 없음 |
| Player | src/game/player.lua | 플레이어 데이터, 자원 관리 | constants.lua, classic.lua |

### Data Models and Contracts

**constants.lua 구조:**

```lua
local Constants = {}

-- 자원 타입
Constants.RESOURCE_TYPES = {
  "wood",
  "brick",
  "sheep",
  "wheat",
  "ore"
}

-- 자원 타입 검증용 Set
Constants.RESOURCE_SET = {
  wood = true,
  brick = true,
  sheep = true,
  wheat = true,
  ore = true
}

-- 건물 비용
Constants.BUILD_COSTS = {
  road = {wood = 1, brick = 1},
  settlement = {wood = 1, brick = 1, sheep = 1, wheat = 1},
  city = {wheat = 2, ore = 3},
  devcard = {sheep = 1, wheat = 1, ore = 1}
}

-- 건물 점수
Constants.BUILDING_POINTS = {
  settlement = 1,
  city = 2
}

return Constants
```

**player.lua 구조:**

```lua
local Class = require("lib.classic")
local Constants = require("src.game.constants")

local Player = Class:extend()

function Player:new(id)
  self.id = id
  self.resources = {
    wood = 0,
    brick = 0,
    sheep = 0,
    wheat = 0,
    ore = 0
  }
  self.buildings = {
    settlements = 0,
    cities = 0,
    roads = 0
  }
end

return Player
```

### APIs and Interfaces

**Player 클래스 API:**

| 메서드 | 파라미터 | 반환값 | 설명 |
|--------|----------|--------|------|
| `new(id)` | id: number | Player | 플레이어 생성 |
| `getResource(type)` | type: string | number | 특정 자원 보유량 |
| `getAllResources()` | - | table | 전체 자원 테이블 복사본 |
| `addResource(type, amount)` | type: string, amount: number | boolean | 자원 추가 |
| `removeResource(type, amount)` | type: string, amount: number | boolean, string? | 자원 차감 (실패 시 nil, error) |
| `hasResources(costs)` | costs: table | boolean | 비용 충족 여부 |
| `canBuild(buildingType)` | buildingType: string | boolean | 건설 가능 여부 |
| `getVictoryPoints()` | - | number | 현재 승리 점수 |

**에러 핸들링 규칙:**

```lua
-- 실패 시 nil + error message 반환
function Player:removeResource(type, amount)
  if not Constants.RESOURCE_SET[type] then
    return nil, "Invalid resource type: " .. tostring(type)
  end
  if self.resources[type] < amount then
    return nil, "Not enough " .. type
  end
  self.resources[type] = self.resources[type] - amount
  return true
end
```

### Workflows and Sequencing

```
Story 2-1: 자원 타입 상수 정의 (constants.lua)
    ↓
Story 2-2: 건물 비용 상수 정의 (constants.lua)
    ↓
Story 2-3: Player 기본 + 자원 추가 (player.lua)
    ↓
Story 2-4: 자원 차감 + 검증 (player.lua)
    ↓
Story 2-5: 승리 점수 계산 (player.lua)
```

**TDD 흐름:**

1. 테스트 작성 (tests/game/constants_spec.lua 또는 player_spec.lua)
2. 테스트 실패 확인 (Red)
3. 최소 구현 (Green)
4. 리팩토링 (Refactor)
5. 다음 테스트

## Non-Functional Requirements

### Performance

- 자원 조회: O(1) - 테이블 키 접근
- 자원 추가/차감: O(1)
- 승리 점수 계산: O(1) - 건물 수만 계산

### Security

- 입력 검증: 유효하지 않은 자원 타입은 거부
- 음수 자원 방지: removeResource에서 검증

### Reliability/Availability

- 불변 상수: Constants 테이블은 수정 불가능하게 설계
- 방어적 복사: getAllResources()는 복사본 반환

### Observability

- serpent으로 Player 상태 직렬화 가능
- 디버그 출력: Player:toString() 메서드 제공

## Dependencies and Integrations

### 내부 의존성

| 의존성 | 버전 | 용도 |
|--------|------|------|
| lib/classic.lua | - | 클래스 시스템 |
| src/game/constants.lua | - | 자원/비용 상수 (Story 2-1, 2-2에서 생성) |

### 외부 의존성

없음 (순수 Lua)

## Acceptance Criteria (Authoritative)

### Story 2-1: 자원 타입 상수

- **AC2-1-1**: RESOURCE_TYPES 배열에 5종 자원 포함 (wood, brick, sheep, wheat, ore)
- **AC2-1-2**: RESOURCE_SET으로 자원 타입 유효성 검증 가능
- **AC2-1-3**: 테스트 통과: tests/game/constants_spec.lua

### Story 2-2: 건물 비용 상수

- **AC2-2-1**: BUILD_COSTS에 4종 건물 비용 정의 (road, settlement, city, devcard)
- **AC2-2-2**: BUILDING_POINTS에 점수 정의 (settlement=1, city=2)
- **AC2-2-3**: 테스트 통과

### Story 2-3: 플레이어 자원 추가

- **AC2-3-1**: Player.new(id)로 플레이어 생성, 초기 자원 0
- **AC2-3-2**: addResource(type, amount)로 자원 추가
- **AC2-3-3**: getResource(type)으로 특정 자원 조회
- **AC2-3-4**: 유효하지 않은 자원 타입은 false 반환
- **AC2-3-5**: 테스트 통과: tests/game/player_spec.lua

### Story 2-4: 플레이어 자원 차감

- **AC2-4-1**: removeResource(type, amount)로 자원 차감
- **AC2-4-2**: 자원 부족 시 nil, "Not enough {type}" 반환
- **AC2-4-3**: hasResources(costs)로 비용 충족 여부 확인
- **AC2-4-4**: canBuild(buildingType)으로 건설 가능 여부 확인
- **AC2-4-5**: 테스트 통과

### Story 2-5: 승리 점수 계산

- **AC2-5-1**: getVictoryPoints()로 현재 점수 반환
- **AC2-5-2**: 정착지 1점, 도시 2점 계산
- **AC2-5-3**: buildings.settlements, buildings.cities 업데이트 시 점수 반영
- **AC2-5-4**: 테스트 통과

## Traceability Mapping

| AC | Spec Section | Component | Test Idea |
|----|--------------|-----------|-----------|
| AC2-1-1 | Data Models | constants.lua | RESOURCE_TYPES 길이 = 5 |
| AC2-1-2 | Data Models | constants.lua | RESOURCE_SET["wood"] == true |
| AC2-2-1 | Data Models | constants.lua | BUILD_COSTS.road 존재 |
| AC2-2-2 | Data Models | constants.lua | BUILDING_POINTS.settlement == 1 |
| AC2-3-1 | APIs | player.lua | Player.new(1).id == 1 |
| AC2-3-2 | APIs | player.lua | addResource("wood", 2) 후 getResource("wood") == 2 |
| AC2-4-1 | APIs | player.lua | removeResource("wood", 1) 후 자원 감소 |
| AC2-4-2 | APIs | player.lua | 자원 0일 때 removeResource → nil |
| AC2-4-3 | APIs | player.lua | hasResources({wood=1}) 검증 |
| AC2-5-1 | APIs | player.lua | getVictoryPoints() 반환 |
| AC2-5-2 | APIs | player.lua | settlements=2, cities=1 → 4점 |

## Risks, Assumptions, Open Questions

### Risks

| 리스크 | 영향 | 완화 |
|--------|------|------|
| **R1**: 자원 타입 오타 | 중간 | RESOURCE_SET으로 검증 |
| **R2**: 음수 자원 발생 | 높음 | removeResource에서 검증 |

### Assumptions

| 가정 | 검증 방법 |
|------|----------|
| **A1**: classic.lua 정상 동작 | Story 1-2에서 검증 완료 |
| **A2**: 자원은 정수만 사용 | 테스트에서 확인 |

### Open Questions

*현재 미해결 질문 없음*

## Test Strategy Summary

### 테스트 레벨

| 레벨 | 대상 | 프레임워크 |
|------|------|-----------|
| 단위 테스트 | constants.lua, player.lua | busted |

### 테스트 파일

```
tests/
└── game/
    ├── constants_spec.lua  -- Story 2-1, 2-2
    └── player_spec.lua     -- Story 2-3, 2-4, 2-5
```

### 테스트 예시

```lua
-- tests/game/constants_spec.lua
describe("Constants", function()
  local Constants = require("src.game.constants")

  describe("RESOURCE_TYPES", function()
    it("should contain 5 resource types", function()
      assert.equals(5, #Constants.RESOURCE_TYPES)
    end)

    it("should include wood", function()
      assert.is_true(Constants.RESOURCE_SET.wood)
    end)
  end)

  describe("BUILD_COSTS", function()
    it("should define road cost", function()
      assert.is_not_nil(Constants.BUILD_COSTS.road)
      assert.equals(1, Constants.BUILD_COSTS.road.wood)
      assert.equals(1, Constants.BUILD_COSTS.road.brick)
    end)
  end)
end)
```

```lua
-- tests/game/player_spec.lua
describe("Player", function()
  local Player = require("src.game.player")
  local player

  before_each(function()
    player = Player(1)
  end)

  describe("new", function()
    it("should create player with id", function()
      assert.equals(1, player.id)
    end)

    it("should initialize resources to 0", function()
      assert.equals(0, player:getResource("wood"))
    end)
  end)

  describe("addResource", function()
    it("should add resources correctly", function()
      player:addResource("wood", 2)
      assert.equals(2, player:getResource("wood"))
    end)
  end)

  describe("removeResource", function()
    it("should remove resources correctly", function()
      player:addResource("wood", 3)
      local success = player:removeResource("wood", 2)
      assert.is_true(success)
      assert.equals(1, player:getResource("wood"))
    end)

    it("should fail if not enough resources", function()
      local success, err = player:removeResource("wood", 1)
      assert.is_nil(success)
      assert.equals("Not enough wood", err)
    end)
  end)

  describe("getVictoryPoints", function()
    it("should calculate points from buildings", function()
      player.buildings.settlements = 2
      player.buildings.cities = 1
      assert.equals(4, player:getVictoryPoints())  -- 2*1 + 1*2
    end)
  end)
end)
```

### 커버리지 목표

- constants.lua: 100%
- player.lua: 90%+

---

_Generated by BMAD Epic Tech Context Workflow_
_Source: GDD.md, game-architecture.md_
