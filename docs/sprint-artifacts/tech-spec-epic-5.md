# Epic Technical Specification: Game Rules (게임 규칙)

Date: 2025-12-01
Author: BMad
Epic ID: 5
Status: Draft

---

## Overview

Epic 5는 카탄 게임의 핵심 규칙을 구현하는 에픽으로, 주사위 굴림부터 자원 분배, 건설 검증/실행, 초기 배치, 승리 조건까지 게임 플레이의 모든 메커닉을 담당한다. 이 에픽은 GDD의 Core Gameplay Loop에서 정의된 "턴 시작 → 주사위 → 자원 생산 → 건설 → 승리 체크" 사이클을 완전히 구현하며, Epic 2(데이터 모델)와 Epic 4(보드 상태)에서 구축한 기반 위에 게임 로직 계층을 추가한다.

TDD 기반 개발 원칙에 따라 `src/game/dice.lua`, `src/game/rules.lua`, `src/game/actions.lua` 모듈에서 Love2D 의존성 없이 순수 Lua로 구현되며, 모든 규칙은 원작 카탄의 공식 룰북을 충실히 따른다.

## Objectives and Scope

**In-Scope:**
- 주사위 굴림 시스템 (2d6, 합계 2-12)
- 주사위 결과에 따른 자원 분배 로직
- 건설 가능 위치 검증 (거리 규칙, 연결 규칙)
- 건설 실행 (자원 차감 + 건물/도로 배치)
- 초기 배치 규칙 (무료 정착지 2개 + 도로 2개, snake draft)
- 승리 조건 체크 (10점 도달)

**Out-of-Scope:**
- 도둑 메커닉 (7 굴림 시 처리) - 2차 구현
- 개발 카드 구매 및 사용 - 2차 구현
- 거래 시스템 (플레이어 간, 항구) - 3차 구현
- 최장 도로 / 최대 군대 보너스 점수 - 3차 구현
- AI 플레이어 로직

## System Architecture Alignment

**아키텍처 참조:** game-architecture.md의 Module Dependencies 및 Implementation Patterns

**컴포넌트 매핑:**
- `src/game/dice.lua` - 주사위 로직 (의존성 없음)
- `src/game/rules.lua` - 건설 규칙, 승리 조건 (`board.lua`, `player.lua`, `constants.lua` 의존)
- `src/game/actions.lua` - 게임 액션 실행 (`rules.lua` 의존)

**패턴 준수:**
- Command 패턴 라이트: 모든 액션은 `{type, player, ...}` 테이블로 표현
- 에러 핸들링: 실패 시 `nil, "error message"` 반환
- TDD First: 모든 모듈은 테스트 먼저 작성

**의존성 계층:**
```
dice.lua (의존성 없음)
     ↓
rules.lua ← board, player, constants
     ↓
actions.lua ← rules
```

## Detailed Design

### Services and Modules

| 모듈 | 책임 | 입력 | 출력 |
|------|------|------|------|
| `dice.lua` | 주사위 굴림 | 없음 | `{die1, die2, sum}` |
| `rules.lua` | 게임 규칙 검증 | Board, Player, 위치 | boolean, error message |
| `actions.lua` | 게임 액션 실행 | GameState, Action | 수정된 GameState |

**dice.lua:**
- `roll()` - 2d6 굴림, 합계 반환
- 테스트 가능한 시드 설정 지원

**rules.lua:**
- `distributeResources(board, players, rolledNumber)` - 자원 분배
- `canBuildSettlement(board, playerId, vertex, isInitialPlacement)` - 정착지 건설 가능 여부
- `canBuildRoad(board, playerId, edge)` - 도로 건설 가능 여부
- `canBuildCity(board, playerId, vertex)` - 도시 업그레이드 가능 여부
- `getValidSettlementLocations(board, playerId, isInitialPlacement)` - 건설 가능 위치 목록
- `getValidRoadLocations(board, playerId)` - 도로 건설 가능 위치 목록
- `checkVictory(players, victoryTarget)` - 승리자 확인

**actions.lua:**
- `buildSettlement(game, playerId, vertex)` - 정착지 건설 실행
- `buildRoad(game, playerId, edge)` - 도로 건설 실행
- `buildCity(game, playerId, vertex)` - 도시 업그레이드 실행

### Data Models and Contracts

**DiceResult:**
```lua
{
  die1 = 1-6,       -- 첫 번째 주사위
  die2 = 1-6,       -- 두 번째 주사위
  sum = 2-12        -- 합계
}
```

**Action (Command 패턴):**
```lua
{
  type = "BUILD_SETTLEMENT" | "BUILD_ROAD" | "BUILD_CITY",
  player = playerId,
  vertex = {q, r, dir},  -- 정착지/도시용
  edge = {q, r, dir},    -- 도로용
  timestamp = os.time(),
  source = "human" | "ai" | "network"
}
```

**ValidationResult:**
```lua
-- 성공 시
true

-- 실패 시
nil, "error message"
-- 예: nil, "Distance rule violated"
-- 예: nil, "Not connected to road"
-- 예: nil, "Not enough resources"
```

**InitialPlacementState:**
```lua
{
  phase = "initial",
  round = 1 | 2,           -- 1차/2차 배치
  currentIndex = 1-4,      -- 현재 배치 플레이어 인덱스
  order = {1,2,3,4},       -- 1차: 정순
  reverseOrder = {4,3,2,1} -- 2차: 역순
}
```

### APIs and Interfaces

**dice.lua API:**
```lua
-- 주사위 굴림
local Dice = require("src.game.dice")
local result = Dice.roll()
-- result = {die1=3, die2=4, sum=7}

-- 테스트용 시드 설정
Dice.setSeed(12345)
```

**rules.lua API:**
```lua
local Rules = require("src.game.rules")

-- 자원 분배
Rules.distributeResources(board, players, 8)

-- 건설 가능 여부 검증
local canBuild, err = Rules.canBuildSettlement(board, 1, {q=0, r=1, dir="N"}, false)
local canBuild, err = Rules.canBuildRoad(board, 1, {q=0, r=0, dir="E"})
local canBuild, err = Rules.canBuildCity(board, 1, {q=0, r=1, dir="N"})

-- 건설 가능 위치 목록
local locations = Rules.getValidSettlementLocations(board, 1, false)
local edges = Rules.getValidRoadLocations(board, 1)

-- 승리 체크
local winnerId = Rules.checkVictory(players, 10)
```

**actions.lua API:**
```lua
local Actions = require("src.game.actions")

-- 건설 실행 (자원 차감 + 배치)
local success, err = Actions.buildSettlement(game, 1, {q=0, r=1, dir="N"})
local success, err = Actions.buildRoad(game, 1, {q=0, r=0, dir="E"})
local success, err = Actions.buildCity(game, 1, {q=0, r=1, dir="N"})
```

### Workflows and Sequencing

**주사위 → 자원 분배 플로우:**
```
1. 플레이어가 주사위 굴림 요청
2. Dice.roll() 호출 → {die1, die2, sum} 반환
3. Rules.distributeResources(board, players, sum) 호출
4. 각 타일 순회:
   - board:getTilesWithNumber(sum) 으로 해당 숫자 타일 조회
   - 각 타일의 인접 정점 확인
   - 정점에 건물이 있으면:
     - 정착지: 소유자에게 자원 1개 추가
     - 도시: 소유자에게 자원 2개 추가
   - 자원 종류는 TERRAIN_RESOURCE[타일.terrain] 참조
```

**건설 실행 플로우:**
```
1. 플레이어가 건설 위치 선택
2. Rules.canBuild*(board, playerId, location) 호출
3. 검증 실패 시 → nil, "error" 반환
4. 검증 성공 시:
   a. player:hasResources(BUILD_COSTS[buildingType]) 확인
   b. 자원 부족 시 → nil, "Not enough resources" 반환
   c. player:removeResources(BUILD_COSTS[buildingType])
   d. board:place*(playerId, location)
   e. player:addBuilding(buildingType)
5. 승리 조건 체크 트리거
```

**초기 배치 플로우 (Snake Draft):**
```
Round 1 (정순): 플레이어 1 → 2 → 3 → 4
  - 각 플레이어: 정착지 1개 + 도로 1개 배치
  - 자원 소비 없음
  - 연결 규칙 무시, 거리 규칙 적용

Round 2 (역순): 플레이어 4 → 3 → 2 → 1
  - 각 플레이어: 정착지 1개 + 도로 1개 배치
  - 자원 소비 없음
  - 두 번째 정착지 인접 타일에서 초기 자원 획득
```

**승리 체크 플로우:**
```
1. 건설 완료 후 자동 호출
2. 모든 플레이어 순회
3. player:getVictoryPoints() >= victoryTarget 확인
4. 조건 만족 플레이어 발견 시 해당 ID 반환
5. 없으면 nil 반환
```

## Non-Functional Requirements

### Performance

**GDD 참조:** Technical Specifications - Performance Requirements

| 메트릭 | 목표 | 측정 방법 |
|--------|------|----------|
| 주사위 굴림 | < 1ms | 순수 연산, math.random |
| 자원 분배 계산 | < 5ms | 19 타일 × 6 정점 순회 |
| 건설 검증 | < 2ms | 인접 정점/변 조회 |
| 승리 체크 | < 1ms | 4 플레이어 점수 비교 |

**최적화 고려사항:**
- `src/game/` 모듈은 순수 Lua로 LuaJIT 최적화 대상
- 인접 정점 조회 시 정규화된 Map 키로 O(1) 접근
- 자원 분배 시 `getTilesWithNumber()` 사전 인덱싱 활용

### Security

**로컬 게임 특성상 보안 요구사항 최소화:**

| 항목 | 대응 |
|------|------|
| 입력 검증 | 모든 액션은 `rules.lua`에서 검증 후 실행 |
| 상태 무결성 | 직접 상태 변경 불가, `actions.lua` 통해서만 변경 |
| 난수 예측 | 게임 시작 시 시스템 시간 기반 시드 설정 |

**향후 네트워크 확장 시 고려:**
- 서버 측 규칙 검증 필수
- 클라이언트 입력 신뢰하지 않음
- 액션 로그 서명/검증

### Reliability/Availability

**단일 플레이어/로컬 게임 특성:**

| 항목 | 요구사항 |
|------|----------|
| 크래시 복구 | 게임 상태 직렬화로 저장/로드 가능 (game_state.lua) |
| 데이터 손실 | 턴 단위 자동 저장 고려 (Epic 7에서 구현) |
| 에러 격리 | 규칙 검증 실패는 에러가 아닌 정상 흐름으로 처리 |

**에러 처리 원칙:**
- 예상 가능한 실패(자원 부족, 잘못된 위치)는 `nil, "message"` 반환
- 예상 불가능한 오류만 Lua error 발생
- 게임 진행 불가 버그 0개 목표 (GDD Success Metrics)

### Observability

**개발/디버깅 지원:**

| 신호 | 구현 |
|------|------|
| 로깅 | 액션 실행 시 콘솔 출력 (개발 모드) |
| 상태 덤프 | `serpent.block(gameState)` 로 전체 상태 출력 |
| 테스트 커버리지 | `src/game/` 모듈 90%+ 목표 |

**디버그 유틸리티 (src/utils/debug.lua):**
- `printBoard(board)` - 보드 상태 텍스트 출력
- `printPlayer(player)` - 플레이어 자원/건물 출력
- `printAction(action)` - 액션 내용 포맷팅

## Dependencies and Integrations

### 내부 모듈 의존성

| 모듈 | 의존 대상 | 용도 |
|------|----------|------|
| `dice.lua` | 없음 | 독립 모듈 |
| `rules.lua` | `constants.lua` | BUILD_COSTS, TERRAIN_RESOURCE, BUILDING_POINTS |
| `rules.lua` | `board.lua` | getTilesWithNumber, getBuilding, getRoad, 정점/변 조회 |
| `rules.lua` | `player.lua` | getVictoryPoints, hasResources |
| `rules.lua` | `vertex.lua` | getAdjacentVertices, normalizeVertex |
| `rules.lua` | `edge.lua` | getEdgeVertices, normalizeEdge |
| `actions.lua` | `rules.lua` | canBuild* 검증 함수들 |
| `actions.lua` | `board.lua` | placeSettlement, placeRoad, upgradeToCity |
| `actions.lua` | `player.lua` | removeResources, addBuilding |

### 외부 라이브러리

| 라이브러리 | 버전 | 용도 | 라이선스 |
|------------|------|------|----------|
| `classic.lua` | latest | 클래스 시스템 (Player 등) | MIT |
| `serpent.lua` | latest | 상태 직렬화/디버깅 | MIT |
| `hump/gamestate.lua` | latest | 씬 관리 (Epic 7) | MIT |

### Epic 의존성

| 선행 Epic | 제공 기능 | Epic 5에서 사용 |
|-----------|----------|----------------|
| Epic 2 | `constants.lua`, `player.lua` | 자원 타입, 건물 비용, 플레이어 자원 관리 |
| Epic 3 | `vertex.lua`, `edge.lua` | 정점/변 정규화, 인접 계산 |
| Epic 4 | `board.lua` | 타일 조회, 건물/도로 배치 |

### 통합 포인트

**Epic 6 (Visual Experience) 연동:**
- `rules.getValidSettlementLocations()` → UI에서 건설 가능 위치 하이라이트
- `rules.getValidRoadLocations()` → UI에서 도로 건설 가능 위치 하이라이트

**Epic 7 (Game Flow) 연동:**
- `Dice.roll()` → 턴 시작 시 호출
- `Rules.distributeResources()` → 주사위 후 자동 호출
- `Rules.checkVictory()` → 건설 후 자동 호출, 게임 종료 트리거

## Acceptance Criteria (Authoritative)

### AC-5.1: 주사위 굴림
1. `Dice.roll()` 호출 시 `{die1, die2, sum}` 형태의 결과 반환
2. `die1`, `die2`는 각각 1-6 범위의 정수
3. `sum`은 `die1 + die2`와 동일 (2-12 범위)
4. 1000회 굴림 시 통계적으로 7이 가장 빈번 (약 16.67%)

### AC-5.2: 자원 분배
5. 주사위 합계와 일치하는 숫자 토큰의 타일에서 자원 생산
6. 정착지 인접 시 해당 자원 1개 획득
7. 도시 인접 시 해당 자원 2개 획득
8. 사막 타일은 자원 생산 없음
9. 한 타일에 여러 건물 인접 시 각각 독립 분배

### AC-5.3: 건설 가능 위치 검증
10. 정착지: 해당 정점이 비어있어야 함
11. 정착지: 거리 규칙 - 인접 정점에 다른 건물 없어야 함
12. 정착지: 연결 규칙 - 본인 도로와 연결 (초기 배치 제외)
13. 도로: 해당 변이 비어있어야 함
14. 도로: 본인 건물 또는 도로와 연결되어야 함
15. 도시: 해당 정점에 본인 정착지가 있어야 함

### AC-5.4: 건설 실행
16. 정착지 건설 시 wood, brick, sheep, wheat 각 1개 차감
17. 도로 건설 시 wood 1, brick 1 차감
18. 도시 업그레이드 시 wheat 2, ore 3 차감
19. 자원 부족 시 건설 실패, 상태 변경 없음
20. 건설 성공 시 건물/도로 배치 및 플레이어 건물 카운트 증가

### AC-5.5: 초기 배치 규칙
21. Round 1: 플레이어 1→2→3→4 순서로 정착지+도로 배치
22. Round 2: 플레이어 4→3→2→1 역순으로 정착지+도로 배치
23. 초기 배치 시 자원 소비 없음
24. 초기 배치 시 연결 규칙 무시, 거리 규칙 적용
25. 두 번째 정착지 배치 완료 시 인접 타일 자원 각 1개 획득

### AC-5.6: 승리 조건 체크
26. `Rules.checkVictory()` 호출 시 10점 이상 플레이어 ID 반환
27. 10점 미만 시 nil 반환
28. 정착지 1점, 도시 2점으로 계산

## Traceability Mapping

| AC | Spec Section | Component/API | Test Idea |
|----|--------------|---------------|-----------|
| AC-5.1.1 | Workflows - 주사위 | `Dice.roll()` | roll() 반환값 구조 검증 |
| AC-5.1.2 | Data Models - DiceResult | `Dice.roll()` | die1, die2 범위 검증 (1-6) |
| AC-5.1.3 | Data Models - DiceResult | `Dice.roll()` | sum = die1 + die2 검증 |
| AC-5.1.4 | NFR - Performance | `Dice.roll()` | 1000회 분포 통계 테스트 |
| AC-5.2.5 | Workflows - 자원 분배 | `Rules.distributeResources()` | 숫자 일치 타일에서만 생산 |
| AC-5.2.6 | Workflows - 자원 분배 | `Rules.distributeResources()` | 정착지 인접 시 자원 +1 |
| AC-5.2.7 | Workflows - 자원 분배 | `Rules.distributeResources()` | 도시 인접 시 자원 +2 |
| AC-5.2.8 | Workflows - 자원 분배 | `Rules.distributeResources()` | 사막 타일 자원 생산 없음 |
| AC-5.2.9 | Workflows - 자원 분배 | `Rules.distributeResources()` | 다중 건물 독립 분배 |
| AC-5.3.10 | APIs - rules.lua | `Rules.canBuildSettlement()` | 비어있는 정점 검증 |
| AC-5.3.11 | APIs - rules.lua | `Rules.canBuildSettlement()` | 거리 규칙 위반 검증 |
| AC-5.3.12 | APIs - rules.lua | `Rules.canBuildSettlement()` | 연결 규칙 검증 |
| AC-5.3.13 | APIs - rules.lua | `Rules.canBuildRoad()` | 비어있는 변 검증 |
| AC-5.3.14 | APIs - rules.lua | `Rules.canBuildRoad()` | 연결 규칙 검증 |
| AC-5.3.15 | APIs - rules.lua | `Rules.canBuildCity()` | 본인 정착지 존재 검증 |
| AC-5.4.16 | Workflows - 건설 실행 | `Actions.buildSettlement()` | 자원 차감 검증 |
| AC-5.4.17 | Workflows - 건설 실행 | `Actions.buildRoad()` | 자원 차감 검증 |
| AC-5.4.18 | Workflows - 건설 실행 | `Actions.buildCity()` | 자원 차감 검증 |
| AC-5.4.19 | APIs - actions.lua | `Actions.build*()` | 자원 부족 시 실패 |
| AC-5.4.20 | APIs - actions.lua | `Actions.build*()` | 성공 시 상태 변경 |
| AC-5.5.21 | Workflows - 초기 배치 | 초기 배치 로직 | 정순 배치 순서 |
| AC-5.5.22 | Workflows - 초기 배치 | 초기 배치 로직 | 역순 배치 순서 |
| AC-5.5.23 | Workflows - 초기 배치 | 초기 배치 로직 | 무료 배치 검증 |
| AC-5.5.24 | APIs - rules.lua | `Rules.canBuildSettlement()` | isInitialPlacement 플래그 |
| AC-5.5.25 | Workflows - 초기 배치 | 초기 배치 로직 | 초기 자원 획득 |
| AC-5.6.26 | APIs - rules.lua | `Rules.checkVictory()` | 10점 도달 시 승자 반환 |
| AC-5.6.27 | APIs - rules.lua | `Rules.checkVictory()` | 미달 시 nil |
| AC-5.6.28 | Data Models | `Player.getVictoryPoints()` | 점수 계산 정확성 |

## Risks, Assumptions, Open Questions

### Risks

| ID | Risk | 영향 | 확률 | 완화 방안 |
|----|------|------|------|----------|
| R1 | 정점/변 인접 관계 계산 오류 | 높음 | 중간 | Epic 3에서 충분한 테스트 커버리지 확보, 시각적 디버그 도구 활용 |
| R2 | 거리 규칙 엣지 케이스 누락 | 중간 | 중간 | 보드 경계, 코너 정점 등 모든 케이스 명시적 테스트 |
| R3 | 초기 배치 순서 로직 복잡성 | 중간 | 낮음 | 상태 머신으로 명확히 모델링, 단계별 테스트 |
| R4 | 자원 분배 시 타일-정점 매핑 오류 | 높음 | 중간 | board.lua의 getTileVertices() 철저히 검증 |

### Assumptions

| ID | Assumption | 검증 방법 |
|----|------------|----------|
| A1 | Epic 2-4의 모듈들이 정상 작동 | 선행 Epic 테스트 통과 확인 |
| A2 | 플레이어 수는 2-4명으로 고정 | config에서 범위 검증 |
| A3 | 승리 점수 목표는 10점 (기본값) | config로 조정 가능하게 구현 |
| A4 | 도둑, 개발카드, 거래는 이 Epic에서 구현하지 않음 | GDD Out-of-Scope 명시 |
| A5 | 원작 카탄 룰북을 정확히 따름 | 룰북 참조하여 AC 작성 |

### Open Questions

| ID | Question | 답변/해결 방안 | 상태 |
|----|----------|---------------|------|
| Q1 | 7이 굴려졌을 때 어떻게 처리? | 현재 Epic에서는 무시 (도둑 미구현), 2차 구현에서 처리 | 보류 |
| Q2 | 초기 배치 시 도로는 방금 놓은 정착지에 인접해야 하나? | 예, 원작 룰 - 정착지에 인접한 변에만 도로 배치 가능 | 해결 |
| Q3 | 자원이 소진되면 어떻게 처리? | 원작: 은행 자원 무한, 구현에서도 무한 가정 | 해결 |

## Test Strategy Summary

### 테스트 레벨

| 레벨 | 범위 | 프레임워크 | 위치 |
|------|------|------------|------|
| Unit | 개별 함수 | busted | `tests/game/dice_spec.lua` |
| Unit | 개별 함수 | busted | `tests/game/rules_spec.lua` |
| Unit | 개별 함수 | busted | `tests/game/actions_spec.lua` |
| Integration | 모듈 간 연동 | busted | `tests/game/integration_spec.lua` |

### 테스트 커버리지 목표

- `src/game/dice.lua`: 100%
- `src/game/rules.lua`: 95%+
- `src/game/actions.lua`: 95%+
- 전체 `src/game/`: 90%+ (GDD Success Metrics)

### 주요 테스트 케이스

**dice_spec.lua:**
```lua
describe("Dice", function()
  describe("roll", function()
    it("should return die1, die2, sum")
    it("should have die1 and die2 in range 1-6")
    it("should have sum equal to die1 + die2")
    it("should produce expected distribution over 1000 rolls")
  end)
end)
```

**rules_spec.lua:**
```lua
describe("Rules", function()
  describe("distributeResources", function()
    it("should give 1 resource for settlement adjacent to matching tile")
    it("should give 2 resources for city adjacent to matching tile")
    it("should give no resources for desert tile")
    it("should distribute to multiple players independently")
  end)

  describe("canBuildSettlement", function()
    it("should return false if vertex is occupied")
    it("should return false if adjacent vertex has building (distance rule)")
    it("should return false if not connected to own road")
    it("should ignore connection rule during initial placement")
  end)

  describe("canBuildRoad", function()
    it("should return false if edge is occupied")
    it("should return false if not connected to own building or road")
  end)

  describe("canBuildCity", function()
    it("should return false if no own settlement at vertex")
    it("should return true if own settlement exists")
  end)

  describe("checkVictory", function()
    it("should return nil if no player has 10+ points")
    it("should return player id if player has 10+ points")
  end)
end)
```

**actions_spec.lua:**
```lua
describe("Actions", function()
  describe("buildSettlement", function()
    it("should deduct correct resources")
    it("should place settlement on board")
    it("should increment player building count")
    it("should fail if insufficient resources")
  end)

  describe("buildRoad", function()
    it("should deduct wood and brick")
    it("should place road on board")
    it("should fail if insufficient resources")
  end)

  describe("buildCity", function()
    it("should deduct wheat and ore")
    it("should upgrade settlement to city")
    it("should fail if insufficient resources")
  end)
end)
```

### 엣지 케이스 테스트

- 보드 경계 정점에서의 건설 검증
- 여러 플레이어 건물이 같은 타일에 인접한 경우 자원 분배
- 자원 0개에서 차감 시도
- 빈 보드에서 초기 배치
- 정확히 10점 도달 vs 10점 초과

### 테스트 실행

```bash
# 전체 테스트
busted tests/

# Epic 5 관련 테스트만
busted tests/game/dice_spec.lua tests/game/rules_spec.lua tests/game/actions_spec.lua

# 감시 모드
busted --watch tests/
```
