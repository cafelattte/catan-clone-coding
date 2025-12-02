# Settlus of Catan - Epic Breakdown

**Author:** BMad
**Date:** 2025-11-30
**Project Type:** Game (Love2D)
**Field:** Greenfield

---

## Overview

카탄 클론 게임의 에픽 및 스토리 분해. GDD와 Architecture 문서를 기반으로 TDD 중심 개발을 위한 구현 계획.

**에픽 구조:**

| Epic | 제목 | 스토리 수 | FR 커버리지 |
|:----:|------|:--------:|-------------|
| 1 | Foundation | 4 | FR1 |
| 2 | Core Data Model | 5 | FR2, FR3 |
| 3 | Hex Coordinate System | 5 | FR4, FR5 |
| 4 | Board State | 4 | FR6, FR7 |
| 5 | Game Rules | 6 | FR8-FR12 |
| 6 | Visual Experience | 5 | FR13-FR16 |
| 7 | Complete Game Flow | 4 | FR17, FR18 |
| 8 | UX/UI Improvements | - | 지속적 개선 |

**총 스토리:** 33개 + α (Epic 8은 지속적 추가)

---

## Functional Requirements Inventory

| FR | 설명 |
|-----|------|
| FR1 | 프로젝트 구조 및 환경 설정 (Love2D, busted, 라이브러리) |
| FR2 | 자원 타입(5종) 및 건물 비용 정의 |
| FR3 | 플레이어 자원 관리 (add/remove/has) 및 승리 점수 계산 |
| FR4 | 헥스 좌표계 변환 (Axial ↔ Cube ↔ Pixel) |
| FR5 | 정점/변 정규화 및 이웃 헥스 계산 |
| FR6 | 보드 타일 배치(19개) 및 숫자 토큰 |
| FR7 | 정점에 건물, 변에 도로 배치 |
| FR8 | 주사위(2d6) 굴림 및 자원 분배 |
| FR9 | 건설 가능 위치 검증 (거리 규칙, 연결 규칙) |
| FR10 | 건설 실행 (자원 차감 + 배치) |
| FR11 | 초기 배치 규칙 (무료 정착지 2개 + 도로 2개) |
| FR12 | 승리 조건 체크 (10점 도달) |
| FR13 | 헥스 보드 렌더링 |
| FR14 | 건물/도로 렌더링 |
| FR15 | HUD (자원, 점수 표시) |
| FR16 | 입력 처리 (클릭 → 헥스/정점/변 변환) |
| FR17 | 턴 순서 및 페이즈 관리 |
| FR18 | 게임 시작/종료/메뉴 씬 |

---

## FR Coverage Map

| FR | Epic | Stories |
|-----|------|---------|
| FR1 | Epic 1 | 1.1, 1.2, 1.3, 1.4 |
| FR2 | Epic 2 | 2.1, 2.2 |
| FR3 | Epic 2 | 2.3, 2.4, 2.5 |
| FR4 | Epic 3 | 3.1, 3.2, 3.3 |
| FR5 | Epic 3 | 3.4, 3.5 |
| FR6 | Epic 4 | 4.1, 4.2 |
| FR7 | Epic 4 | 4.3, 4.4 |
| FR8 | Epic 5 | 5.1, 5.2 |
| FR9 | Epic 5 | 5.3 |
| FR10 | Epic 5 | 5.4 |
| FR11 | Epic 5 | 5.5 |
| FR12 | Epic 5 | 5.6 |
| FR13 | Epic 6 | 6.1 |
| FR14 | Epic 6 | 6.2 |
| FR15 | Epic 6 | 6.3 |
| FR16 | Epic 6 | 6.4, 6.5 |
| FR17 | Epic 7 | 7.1, 7.2 |
| FR18 | Epic 7 | 7.3, 7.4 |

---

## Epic 1: Foundation (환경 설정)

**목표:** TDD 환경과 라이브러리 설정으로 모든 후속 개발의 기반 구축

**FR 커버:** FR1

---

### Story 1.1: 프로젝트 구조 생성

**As a** 개발자,
**I want** 표준화된 프로젝트 디렉토리 구조를,
**So that** 모든 코드가 일관된 위치에 정리됨.

**Acceptance Criteria:**

```
Given 빈 프로젝트 디렉토리
When 프로젝트 구조 스크립트 실행
Then 다음 디렉토리가 생성됨:
  - src/game/, src/players/, src/ui/, src/scenes/, src/utils/
  - lib/, tests/game/, assets/images/, assets/fonts/
And main.lua, conf.lua 엔트리포인트 생성됨
And .busted 설정 파일 생성됨
```

**Prerequisites:** 없음

**Technical Notes:** Architecture 문서의 Project Structure 참조

---

### Story 1.2: 외부 라이브러리 설치

**As a** 개발자,
**I want** 필요한 Lua 라이브러리가 설치되어,
**So that** 클래스 시스템, 직렬화, 상태 관리 사용 가능.

**Acceptance Criteria:**

```
Given 프로젝트 구조가 생성됨
When 라이브러리 설치 완료
Then lib/classic.lua 존재 (클래스 시스템)
And lib/serpent.lua 존재 (직렬화)
And lib/hump/gamestate.lua 존재 (상태 관리)
And 각 라이브러리 require 테스트 통과
```

**Prerequisites:** Story 1.1

**Technical Notes:** GitHub에서 다운로드 또는 LuaRocks

---

### Story 1.3: 테스트 환경 설정

**As a** 개발자,
**I want** busted 테스트 프레임워크가 작동하여,
**So that** TDD로 게임 로직 개발 가능.

**Acceptance Criteria:**

```
Given 프로젝트 구조와 라이브러리 설치됨
When busted tests/ 실행
Then 샘플 테스트 통과 (tests/game/sample_spec.lua)
And "0 failures" 메시지 출력
And .busted 설정으로 tests/ 디렉토리 자동 탐색
```

**Prerequisites:** Story 1.2

**Technical Notes:** `luarocks install busted` 필요

---

### Story 1.4: Love2D 기본 설정

**As a** 개발자,
**I want** Love2D가 실행되어 빈 창이 표시되어,
**So that** 게임 엔진 환경이 준비됨.

**Acceptance Criteria:**

```
Given 프로젝트 구조 완성
When love . 실행
Then 1280x720 창이 열림
And 타이틀바에 "Settlus of Catan" 표시
And conf.lua에 기본 설정 정의됨:
  - window.width = 1280
  - window.height = 720
  - window.title = "Settlus of Catan"
```

**Prerequisites:** Story 1.1

**Technical Notes:** conf.lua에서 Love2D 설정

---

## Epic 2: Core Data Model (핵심 데이터 모델)

**목표:** 게임 경제 시스템의 핵심 데이터 구조 - 자원과 플레이어 관리

**FR 커버:** FR2, FR3

---

### Story 2.1: 자원 타입 및 상수 정의

**As a** 게임 시스템,
**I want** 5종 자원 타입과 관련 상수가 정의되어,
**So that** 게임 전체에서 일관된 자원 시스템 사용.

**Acceptance Criteria:**

```
Given constants.lua 모듈
When RESOURCE_TYPES 조회
Then 5개 자원 반환: wood, brick, sheep, wheat, ore

Given constants.lua 모듈
When TERRAIN_TYPES 조회
Then 6개 지형 반환: forest, hills, pasture, fields, mountains, desert

Given constants.lua 모듈
When TERRAIN_RESOURCE 매핑 조회
Then forest→wood, hills→brick, pasture→sheep, fields→wheat, mountains→ore, desert→nil
```

**Prerequisites:** Story 1.3

**Technical Notes:** src/game/constants.lua, 순수 Lua (Love2D 의존 X)

---

### Story 2.2: 건물 비용 정의

**As a** 게임 시스템,
**I want** 각 건물의 건설 비용이 정의되어,
**So that** 건설 시 정확한 자원 차감 가능.

**Acceptance Criteria:**

```
Given constants.lua 모듈
When BUILD_COSTS.road 조회
Then {wood=1, brick=1} 반환

Given constants.lua 모듈
When BUILD_COSTS.settlement 조회
Then {wood=1, brick=1, sheep=1, wheat=1} 반환

Given constants.lua 모듈
When BUILD_COSTS.city 조회
Then {wheat=2, ore=3} 반환

Given constants.lua 모듈
When BUILD_COSTS.development_card 조회
Then {sheep=1, wheat=1, ore=1} 반환
```

**Prerequisites:** Story 2.1

**Technical Notes:** BUILDING_POINTS도 정의 (settlement=1, city=2)

---

### Story 2.3: 플레이어 자원 관리 - 기본

**As a** 플레이어,
**I want** 자원을 추가하고 조회할 수 있어,
**So that** 게임 중 자원 획득 추적 가능.

**Acceptance Criteria:**

```
Given 새 Player 생성 (id=1)
When player:getResource("wood") 호출
Then 0 반환 (초기값)

Given Player with id=1
When player:addResource("wood", 3) 호출
Then player:getResource("wood") = 3

Given Player with wood=3
When player:addResource("wood", 2) 호출
Then player:getResource("wood") = 5 (누적)

Given Player
When player:getAllResources() 호출
Then {wood=0, brick=0, sheep=0, wheat=0, ore=0} 형태 반환
```

**Prerequisites:** Story 2.1

**Technical Notes:** src/game/player.lua, classic 클래스 사용

---

### Story 2.4: 플레이어 자원 관리 - 차감

**As a** 플레이어,
**I want** 자원을 차감하고 보유 여부를 확인할 수 있어,
**So that** 건설 시 비용 지불 가능.

**Acceptance Criteria:**

```
Given Player with wood=3, brick=2
When player:hasResources({wood=2, brick=1}) 호출
Then true 반환

Given Player with wood=3, brick=2
When player:hasResources({wood=5}) 호출
Then false 반환

Given Player with wood=3
When player:removeResource("wood", 2) 호출
Then player:getResource("wood") = 1
And true 반환

Given Player with wood=1
When player:removeResource("wood", 5) 호출
Then false 반환 (자원 부족)
And player:getResource("wood") = 1 (변경 없음)
```

**Prerequisites:** Story 2.3

**Technical Notes:** removeResource는 실패 시 원자적으로 롤백

---

### Story 2.5: 플레이어 승리 점수 계산

**As a** 게임 시스템,
**I want** 플레이어의 승리 점수를 계산할 수 있어,
**So that** 승리 조건(10점) 체크 가능.

**Acceptance Criteria:**

```
Given 새 Player
When player:getVictoryPoints() 호출
Then 0 반환

Given Player
When player:addBuilding("settlement") 호출
Then player:getVictoryPoints() = 1

Given Player with 1 settlement
When player:addBuilding("city") 호출
Then player:getVictoryPoints() = 3 (1+2)

Given Player with 2 settlements, 1 city
When player:getBuildingCount("settlement") 호출
Then 2 반환
```

**Prerequisites:** Story 2.2, Story 2.3

**Technical Notes:** 건물 개수 추적, BUILDING_POINTS 참조

---

## Epic 3: Hex Coordinate System (헥스 좌표계)

**목표:** 보드 게임의 공간 시스템 구현 - 헥스 좌표 변환 및 정점/변 관리

**FR 커버:** FR4, FR5

---

### Story 3.1: Axial ↔ Cube 좌표 변환

**As a** 게임 시스템,
**I want** Axial과 Cube 좌표를 상호 변환할 수 있어,
**So that** 저장은 Axial, 계산은 Cube로 사용 가능.

**Acceptance Criteria:**

```
Given hex.lua 모듈
When axialToCube(0, 0) 호출
Then {x=0, y=0, z=0} 반환

Given hex.lua 모듈
When axialToCube(1, -1) 호출
Then {x=1, y=0, z=-1} 반환 (x + y + z = 0)

Given hex.lua 모듈
When cubeToAxial(1, 0, -1) 호출
Then {q=1, r=-1} 반환

Given 임의의 Axial 좌표
When axialToCube → cubeToAxial 연속 변환
Then 원래 좌표와 동일
```

**Prerequisites:** Story 1.3

**Technical Notes:** src/game/hex.lua, Cube: x + y + z = 0 불변식

---

### Story 3.2: Cube ↔ Pixel 좌표 변환

**As a** 렌더링 시스템,
**I want** Cube 좌표를 화면 픽셀 좌표로 변환할 수 있어,
**So that** 헥스 타일을 올바른 위치에 그릴 수 있음.

**Acceptance Criteria:**

```
Given hex.lua 모듈과 hexSize=50
When cubeToPixel(0, 0, 0, 50) 호출
Then 중심점 픽셀 좌표 반환

Given hex.lua 모듈과 hexSize=50
When cubeToPixel(1, 0, -1, 50) 호출
Then 오른쪽 헥스의 픽셀 좌표 반환

Given hex.lua 모듈
When pixelToCube(px, py, hexSize) 호출
Then 해당 픽셀을 포함하는 헥스의 Cube 좌표 반환

Given 임의의 헥스 중심 픽셀
When pixelToCube → cubeToPixel 연속 변환
Then 원래 중심 픽셀과 근사 (반올림 오차 이내)
```

**Prerequisites:** Story 3.1

**Technical Notes:** Pointy-top 헥스 레이아웃 사용, Red Blob Games 공식 참조

---

### Story 3.3: 이웃 헥스 계산

**As a** 게임 시스템,
**I want** 특정 헥스의 6개 이웃을 조회할 수 있어,
**So that** 인접 타일 탐색 가능.

**Acceptance Criteria:**

```
Given hex.lua 모듈
When getNeighbors(0, 0) 호출 (Axial)
Then 6개 이웃 좌표 반환:
  - (1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)

Given hex.lua 모듈
When getNeighbor(0, 0, direction) 호출
Then 해당 방향의 이웃 1개 반환

Given 보드 가장자리 헥스
When getNeighbors 호출
Then 모든 6개 이웃 반환 (보드 범위 체크는 Board에서)
```

**Prerequisites:** Story 3.1

**Technical Notes:** 방향 인덱스 0-5 또는 방향명 (E, NE, NW, W, SW, SE)

---

### Story 3.4: 정점 정규화

**As a** 게임 시스템,
**I want** 동일한 정점을 가리키는 다른 표현을 통일할 수 있어,
**So that** 건물 배치 시 중복 방지 가능.

**Acceptance Criteria:**

```
Given vertex.lua 모듈
When normalizeVertex(0, 0, "N") 호출
Then 정규화된 {q, r, dir} 반환

Given vertex.lua 모듈
When normalizeVertex(0, -1, "S") 호출
Then (0, 0, "N")과 동일한 정규화 결과 반환
  (같은 정점의 다른 표현)

Given vertex.lua 모듈
When vertexToString(0, 0, "N") 호출
Then "0,0,N" 반환 (Map 키로 사용)

Given 동일한 물리적 정점의 다른 표현들
When 각각 정규화
Then 모두 동일한 문자열 키 생성
```

**Prerequisites:** Story 3.1

**Technical Notes:** src/game/vertex.lua, 정점은 N/S 방향만 사용

---

### Story 3.5: 변 정규화 및 인접 정점

**As a** 게임 시스템,
**I want** 변(Edge)을 정규화하고 인접 정점을 조회할 수 있어,
**So that** 도로 배치 및 연결 검증 가능.

**Acceptance Criteria:**

```
Given edge.lua 모듈
When normalizeEdge(0, 0, "E") 호출
Then 정규화된 {q, r, dir} 반환

Given edge.lua 모듈
When normalizeEdge(-1, 0, "W") 호출
Then (0, 0, "E")과 동일한 정규화 결과 반환

Given edge.lua 모듈
When getEdgeVertices(0, 0, "E") 호출
Then 해당 변의 양 끝 정점 2개 반환

Given edge.lua 모듈
When edgeToString(0, 0, "E") 호출
Then "0,0,E" 반환 (Map 키로 사용)
```

**Prerequisites:** Story 3.4

**Technical Notes:** src/game/edge.lua, 변은 NE/E/SE 방향만 사용

---

## Epic 4: Board State (보드 상태)

**목표:** 게임 보드와 건물 배치 관리 - 타일, 숫자 토큰, 건물/도로

**FR 커버:** FR6, FR7

---

### Story 4.1: 보드 타일 생성

**As a** 게임 시스템,
**I want** 19개 헥스 타일로 구성된 보드를 생성할 수 있어,
**So that** 카탄 표준 보드 레이아웃 사용 가능.

**Acceptance Criteria:**

```
Given board.lua 모듈
When Board.new() 호출
Then 19개 타일이 생성됨:
  - 숲 4개, 언덕 3개, 목초지 4개, 농장 4개, 산 3개, 사막 1개

Given 새 Board
When board:getTile(0, 0) 호출
Then 중앙 타일 정보 반환 {q, r, terrain, number}

Given 새 Board
When board:getAllTiles() 호출
Then 19개 타일 목록 반환

Given Board 생성
When 타일 지형 분포 확인
Then GDD 명세와 일치 (숲4, 언덕3, 목초지4, 농장4, 산3, 사막1)
```

**Prerequisites:** Story 3.1

**Technical Notes:** src/game/board.lua, 지형 랜덤 셔플

---

### Story 4.2: 숫자 토큰 배치

**As a** 게임 시스템,
**I want** 각 타일에 숫자 토큰(2-12, 7 제외)이 배치되어,
**So that** 주사위 결과에 따른 자원 생산 가능.

**Acceptance Criteria:**

```
Given 새 Board
When 숫자 토큰 배치 완료
Then 사막 타일은 숫자 없음 (nil)
And 나머지 18개 타일에 숫자 배치

Given Board
When board:getTilesWithNumber(8) 호출
Then 숫자 8인 타일들 반환

Given Board
When 숫자 토큰 분포 확인
Then 2, 12: 1개씩 / 3-6, 8-11: 2개씩 / 7: 0개

Given Board
When board:getTile(q, r).number 조회
Then 2-6 또는 8-12 범위의 숫자 (사막 제외)
```

**Prerequisites:** Story 4.1

**Technical Notes:** 숫자 토큰 랜덤 또는 알파벳 순서 배치

---

### Story 4.3: 정착지/도시 배치

**As a** 게임 시스템,
**I want** 정점에 정착지와 도시를 배치할 수 있어,
**So that** 플레이어 건물 위치 추적 가능.

**Acceptance Criteria:**

```
Given Board
When board:placeSettlement(playerId, q, r, dir) 호출
Then 해당 정점에 정착지 배치됨

Given Board with settlement at (0, 0, "N")
When board:getBuilding(0, 0, "N") 호출
Then {type="settlement", player=playerId} 반환

Given Board with settlement
When board:upgradeToCity(q, r, dir) 호출
Then 해당 위치가 city로 변경됨

Given Board
When board:getPlayerBuildings(playerId) 호출
Then 해당 플레이어의 모든 건물 목록 반환
```

**Prerequisites:** Story 3.4, Story 4.1

**Technical Notes:** Map 구조 사용 - settlements["0,0,N"] = {player=1}

---

### Story 4.4: 도로 배치

**As a** 게임 시스템,
**I want** 변에 도로를 배치할 수 있어,
**So that** 플레이어 도로 네트워크 추적 가능.

**Acceptance Criteria:**

```
Given Board
When board:placeRoad(playerId, q, r, dir) 호출
Then 해당 변에 도로 배치됨

Given Board with road at (0, 0, "E")
When board:getRoad(0, 0, "E") 호출
Then {player=playerId} 반환

Given Board
When board:getPlayerRoads(playerId) 호출
Then 해당 플레이어의 모든 도로 목록 반환

Given Board with roads
When board:isVertexConnectedToRoad(playerId, q, r, dir) 호출
Then 해당 정점이 플레이어 도로와 연결되어 있으면 true
```

**Prerequisites:** Story 3.5, Story 4.3

**Technical Notes:** Map 구조 사용 - roads["0,0,E"] = {player=1}

---

## Epic 5: Game Rules (게임 규칙)

**목표:** 카탄 게임 규칙 완전 구현 - 주사위, 자원 분배, 건설, 승리 조건

**FR 커버:** FR8, FR9, FR10, FR11, FR12

---

### Story 5.1: 주사위 굴림

**As a** 플레이어,
**I want** 2d6 주사위를 굴려 합계를 얻을 수 있어,
**So that** 턴 시작 시 자원 생산 숫자 결정.

**Acceptance Criteria:**

```
Given dice.lua 모듈
When dice.roll() 호출
Then {die1, die2, sum} 반환
And die1, die2는 각각 1-6 범위
And sum = die1 + die2 (2-12 범위)

Given 1000번 주사위 굴림
When 분포 확인
Then 7이 가장 빈번 (약 16.67%)
And 2, 12가 가장 희귀 (약 2.78%)
```

**Prerequisites:** Story 1.3

**Technical Notes:** src/game/dice.lua, math.random 사용

---

### Story 5.2: 자원 분배

**As a** 게임 시스템,
**I want** 주사위 결과에 따라 자원을 분배할 수 있어,
**So that** 해당 숫자 타일 인접 건물 소유자가 자원 획득.

**Acceptance Criteria:**

```
Given Board with tiles and buildings, Players
When rules.distributeResources(board, players, rolledNumber) 호출
Then 해당 숫자 타일 인접 정착지 소유자: 해당 자원 1개 획득
And 해당 숫자 타일 인접 도시 소유자: 해당 자원 2개 획득

Given 숫자 8 타일이 숲(wood)이고, 플레이어1 정착지 인접
When 8이 굴려짐
Then 플레이어1의 wood += 1

Given 숫자 6 타일이 산(ore)이고, 플레이어2 도시 인접
When 6이 굴려짐
Then 플레이어2의 ore += 2

Given 사막 타일
When 어떤 숫자가 굴려져도
Then 사막에서는 자원 생산 없음
```

**Prerequisites:** Story 5.1, Story 4.3, Story 2.3

**Technical Notes:** src/game/rules.lua, 타일-정점 인접 관계 활용

---

### Story 5.3: 건설 가능 위치 검증

**As a** 플레이어,
**I want** 건설 가능한 위치를 확인할 수 있어,
**So that** 규칙에 맞는 곳에만 건설 시도.

**Acceptance Criteria:**

```
Given Board, Player
When rules.canBuildSettlement(board, playerId, vertex) 호출
Then 다음 조건 모두 만족 시 true:
  - 해당 정점이 비어있음
  - 거리 규칙: 인접 정점에 다른 건물 없음
  - 연결 규칙: 본인 도로와 연결됨 (초기 배치 제외)

Given Board, Player
When rules.canBuildRoad(board, playerId, edge) 호출
Then 다음 조건 모두 만족 시 true:
  - 해당 변이 비어있음
  - 본인 건물 또는 도로와 연결됨

Given Board, Player
When rules.canBuildCity(board, playerId, vertex) 호출
Then 해당 정점에 본인 정착지가 있으면 true

Given Board
When rules.getValidSettlementLocations(board, playerId) 호출
Then 건설 가능한 모든 정점 목록 반환
```

**Prerequisites:** Story 4.3, Story 4.4

**Technical Notes:** 거리 규칙 - 인접 정점 계산 필요

---

### Story 5.4: 건설 실행

**As a** 플레이어,
**I want** 자원을 소비하여 건물을 건설할 수 있어,
**So that** 게임 진행 중 영역 확장 가능.

**Acceptance Criteria:**

```
Given Player with 충분한 자원, valid location
When actions.buildSettlement(game, playerId, vertex) 호출
Then 자원 차감 (wood, brick, sheep, wheat 각 1)
And 정착지 배치
And 플레이어 건물 카운트 증가
And 승리 점수 +1

Given Player with 충분한 자원, valid edge
When actions.buildRoad(game, playerId, edge) 호출
Then 자원 차감 (wood 1, brick 1)
And 도로 배치

Given Player with 정착지 위치, 충분한 자원
When actions.buildCity(game, playerId, vertex) 호출
Then 자원 차감 (wheat 2, ore 3)
And 정착지 → 도시 업그레이드
And 승리 점수 +1 (2-1=1 추가)

Given Player with 자원 부족
When 건설 시도
Then 실패, 자원 변화 없음
```

**Prerequisites:** Story 5.3, Story 2.4

**Technical Notes:** src/game/actions.lua, Command 패턴

---

### Story 5.5: 초기 배치 규칙

**As a** 게임 시스템,
**I want** 게임 시작 시 초기 배치 페이즈를 진행할 수 있어,
**So that** 각 플레이어가 무료로 정착지 2개 + 도로 2개 배치.

**Acceptance Criteria:**

```
Given 게임 시작
When 초기 배치 페이즈
Then 플레이어 순서대로 정착지+도로 배치 (1→2→3→4)
And 역순으로 두 번째 정착지+도로 배치 (4→3→2→1)
And 자원 소비 없음 (무료 배치)

Given 초기 배치 중
When 정착지 배치
Then 연결 규칙 무시 (도로 연결 불필요)
And 거리 규칙은 적용 (인접 정점에 건물 없어야 함)

Given 두 번째 정착지 배치 완료
When 해당 정착지 인접 타일 확인
Then 각 인접 타일의 자원 1개씩 초기 자원으로 획득
```

**Prerequisites:** Story 5.3, Story 5.4

**Technical Notes:** 역순 배치 (snake draft) 구현

---

### Story 5.6: 승리 조건 체크

**As a** 게임 시스템,
**I want** 승리 조건(10점)을 체크할 수 있어,
**So that** 게임 종료 시점 판단 가능.

**Acceptance Criteria:**

```
Given GameState
When rules.checkVictory(game) 호출
Then 10점 이상 플레이어 있으면 해당 플레이어 ID 반환
And 없으면 nil 반환

Given 플레이어 점수 = 9
When 정착지 건설 (1점)
Then rules.checkVictory() = 해당 플레이어 ID

Given 플레이어 점수 = 8
When 도시 업그레이드 (1점 추가)
Then 총 9점, 아직 승리 아님
```

**Prerequisites:** Story 2.5

**Technical Notes:** 턴 종료 시 체크, 점수 계산은 Player 모듈

---

## Epic 6: Visual Experience (시각적 경험)

**목표:** 보고 상호작용할 수 있는 게임 UI - 렌더링과 입력 처리

**FR 커버:** FR13, FR14, FR15, FR16

---

### Story 6.1: 헥스 보드 렌더링

**As a** 플레이어,
**I want** 헥스 보드가 화면에 표시되어,
**So that** 게임 상태를 시각적으로 확인 가능.

**Acceptance Criteria:**

```
Given GameState with Board
When board_view.draw(board) 호출
Then 19개 헥스 타일이 화면에 렌더링됨
And 각 타일은 지형에 맞는 색상으로 표시
And 각 타일 중앙에 숫자 토큰 표시 (사막 제외)
And 6, 8은 빨간색으로 강조 (높은 확률)

Given 타일 색상 팔레트
When 렌더링
Then forest=녹색, hills=주황, pasture=연두, fields=노랑, mountains=회색, desert=베이지
```

**Prerequisites:** Story 3.2, Story 4.1, Story 1.4

**Technical Notes:** src/ui/board_view.lua, Love2D love.graphics 사용

---

### Story 6.2: 건물/도로 렌더링

**As a** 플레이어,
**I want** 건물과 도로가 보드 위에 표시되어,
**So that** 각 플레이어의 영역을 확인 가능.

**Acceptance Criteria:**

```
Given Board with buildings
When board_view.draw(board) 호출
Then 정착지는 작은 집 모양 (또는 삼각형)으로 표시
And 도시는 큰 건물 모양 (또는 사각형)으로 표시
And 도로는 선으로 표시
And 각 플레이어별 고유 색상 적용

Given 4명 플레이어
When 렌더링
Then 플레이어1=빨강, 2=파랑, 3=초록, 4=노랑 (또는 config 설정)
```

**Prerequisites:** Story 6.1, Story 4.3, Story 4.4

**Technical Notes:** src/ui/colors.lua에 플레이어 색상 정의

---

### Story 6.3: HUD 표시

**As a** 플레이어,
**I want** 자원과 점수가 화면에 표시되어,
**So that** 현재 보유 상태를 확인 가능.

**Acceptance Criteria:**

```
Given GameState
When hud.draw(game) 호출
Then 현재 플레이어의 자원 5종 표시 (아이콘 + 숫자)
And 현재 플레이어의 승리 점수 표시
And 현재 턴 플레이어 표시
And 주사위 결과 표시 (굴린 후)

Given 자원 변동
When 화면 갱신
Then HUD에 즉시 반영
```

**Prerequisites:** Story 2.3, Story 1.4

**Technical Notes:** src/ui/hud.lua, 화면 하단 또는 측면에 배치

---

### Story 6.4: 마우스 입력 → 헥스 변환

**As a** 플레이어,
**I want** 마우스 클릭 위치가 헥스 좌표로 변환되어,
**So that** 타일을 선택할 수 있음.

**Acceptance Criteria:**

```
Given 마우스 클릭 이벤트
When input.getClickedHex(mouseX, mouseY) 호출
Then 클릭된 헥스의 Axial 좌표 반환
And 보드 바깥 클릭 시 nil 반환

Given 헥스 위에 마우스 호버
When 매 프레임
Then 해당 헥스 하이라이트 표시 가능
```

**Prerequisites:** Story 3.2

**Technical Notes:** src/ui/input.lua, pixelToCube 활용

---

### Story 6.5: 정점/변 선택

**As a** 플레이어,
**I want** 정점과 변을 클릭하여 선택할 수 있어,
**So that** 건물과 도로를 배치할 위치 지정 가능.

**Acceptance Criteria:**

```
Given 마우스 클릭 이벤트
When input.getClickedVertex(mouseX, mouseY) 호출
Then 가장 가까운 정점의 좌표 반환 (거리 임계값 이내)
And 임계값 밖이면 nil 반환

Given 마우스 클릭 이벤트
When input.getClickedEdge(mouseX, mouseY) 호출
Then 가장 가까운 변의 좌표 반환 (거리 임계값 이내)
And 임계값 밖이면 nil 반환

Given 건설 모드 활성화
When 유효한 건설 위치들
Then 해당 정점/변 하이라이트 표시
```

**Prerequisites:** Story 6.4, Story 3.4, Story 3.5

**Technical Notes:** 정점/변 중심 픽셀 계산 후 거리 비교

---

## Epic 7: Complete Game Flow (완전한 게임 플로우)

**목표:** 처음부터 끝까지 완전한 게임 경험 - 메뉴, 턴 관리, 게임 종료

**FR 커버:** FR17, FR18

---

### Story 7.1: 턴 순서 관리

**As a** 게임 시스템,
**I want** 플레이어 턴 순서를 관리할 수 있어,
**So that** 공정한 게임 진행 가능.

**Acceptance Criteria:**

```
Given GameState with 4 players
When game:getCurrentPlayer() 호출
Then 현재 턴 플레이어 반환

Given 플레이어1 턴
When game:endTurn() 호출
Then 현재 플레이어 = 플레이어2

Given 플레이어4 턴
When game:endTurn() 호출
Then 현재 플레이어 = 플레이어1 (순환)
```

**Prerequisites:** Story 4.1

**Technical Notes:** src/game/game_state.lua의 turn 관리

---

### Story 7.2: 페이즈 관리

**As a** 게임 시스템,
**I want** 턴 내 페이즈(roll, build, trade)를 관리할 수 있어,
**So that** 정해진 순서로 액션 수행.

**Acceptance Criteria:**

```
Given 턴 시작
When game:getPhase() 호출
Then "roll" 반환

Given roll 페이즈
When 주사위 굴림 완료
Then 페이즈 = "main" (build/trade 가능)

Given main 페이즈
When game:endTurn() 호출
Then 다음 플레이어, 페이즈 = "roll"

Given roll 페이즈
When 건설 시도
Then 실패 (주사위 먼저 굴려야 함)
```

**Prerequisites:** Story 7.1, Story 5.1

**Technical Notes:** 페이즈: roll → main → (end turn)

---

### Story 7.3: 메인 메뉴 씬

**As a** 플레이어,
**I want** 게임 시작 시 메인 메뉴가 표시되어,
**So that** 새 게임을 시작하거나 옵션을 설정할 수 있음.

**Acceptance Criteria:**

```
Given 게임 실행
When 초기 로드 완료
Then 메인 메뉴 씬 표시
And "New Game" 버튼 표시
And "Exit" 버튼 표시

Given 메인 메뉴
When "New Game" 클릭
Then 플레이어 수 선택 (2-4)
And 게임 씬으로 전환

Given 메인 메뉴
When "Exit" 클릭
Then 게임 종료
```

**Prerequisites:** Story 1.4

**Technical Notes:** src/scenes/menu.lua, hump.gamestate 사용

---

### Story 7.4: 게임 종료 처리

**As a** 게임 시스템,
**I want** 승리 조건 달성 시 게임이 종료되어,
**So that** 승자를 발표하고 새 게임 시작 가능.

**Acceptance Criteria:**

```
Given 게임 진행 중
When 플레이어가 10점 달성
Then 게임 종료 씬으로 전환
And "Player X Wins!" 메시지 표시
And 최종 점수 표시

Given 게임 종료 씬
When "New Game" 클릭
Then 메인 메뉴로 이동

Given 게임 종료 씬
When "Exit" 클릭
Then 게임 종료
```

**Prerequisites:** Story 5.6, Story 7.3

**Technical Notes:** src/scenes/game_over.lua

---

### Story 7.5: 게임 플레이 통합

**As a** 플레이어,
**I want** UI 버튼으로 게임을 진행할 수 있어,
**So that** 마우스만으로 카탄 게임을 플레이 가능.

**Acceptance Criteria:**

```
Given game.lua 게임 씬
When "Roll Dice" 버튼 클릭
Then gameState:rollDice() 호출
And 주사위 결과 HUD에 표시
And roll 페이즈가 아니면 버튼 비활성화

Given game.lua 게임 씬
When "Settlement" 버튼 클릭
Then settlement 선택 모드 진입
And 유효한 정점 하이라이트

Given settlement 선택 모드
When 유효한 정점 클릭
Then Actions.buildSettlement() 실행
And 건물 렌더링 업데이트
And 승리 체크

Given game.lua 게임 씬
When "City" 버튼 클릭
Then city 선택 모드 진입
And 업그레이드 가능한 정착지 하이라이트

Given city 선택 모드
When 유효한 정점 클릭 (기존 정착지)
Then Actions.buildCity() 실행
And 건물 렌더링 업데이트
And 승리 체크

Given game.lua 게임 씬
When "Road" 버튼 클릭
Then road 선택 모드 진입
And 유효한 변 하이라이트

Given road 선택 모드
When 유효한 변 클릭
Then Actions.buildRoad() 실행
And 건물 렌더링 업데이트

Given main 페이즈
When "End Turn" 버튼 클릭
Then gameState:endTurn() 호출
And 다음 플레이어로 전환
And roll 페이즈가 아니면 버튼 비활성화
```

**Prerequisites:** Story 7.2, Story 7.3, Story 7.4

**Technical Notes:** game.lua에 액션 버튼 패널 추가, 버튼 상태는 GameState 페이즈/자원에 따라 동적 변경

---

### Story 7.6: 초기 배치 UI

**As a** 플레이어,
**I want** 게임 시작 시 초기 정착지와 도로를 배치할 수 있어,
**So that** 카탄 규칙에 맞는 완전한 게임 플레이 가능.

**Acceptance Criteria:**

```
Given 새 게임 시작
When 게임 씬 진입
Then mode = "setup", 첫 번째 플레이어 초기 배치 시작

Given setup 모드
When 현재 플레이어 차례
Then "Place Settlement" 안내 표시
And 유효한 정점 하이라이트 (distance rule 무시)

Given setup 모드, settlement 배치
When 유효한 정점 클릭
Then Actions.buildSettlementFree() 실행
And "Place Road" 안내 표시

Given setup 모드, road 배치
When 방금 배치한 정착지에 연결된 유효한 변 클릭
Then Actions.buildRoadFree() 실행
And 다음 플레이어로 진행 (Snake Draft)

Given setup Round 1 완료 (1→2→3→4)
When 마지막 플레이어 배치 완료
Then Round 2 시작 (4→3→2→1 역순)

Given setup Round 2, 정착지 배치
When 두 번째 정착지 배치 완료
Then 인접 타일 자원 각 1개씩 지급

Given setup Round 2, 플레이어 1 배치 완료
When 모든 초기 배치 완료
Then mode = "playing", 플레이어 1 턴 시작
```

**Prerequisites:** Story 7.5, Story 5.5

**Technical Notes:**
- GameState.setup 구조체 활용 (이미 정의됨)
- Snake Draft: Round 1 (1→2→3→4), Round 2 (4→3→2→1)
- Actions.buildSettlementFree(), Actions.buildRoadFree() 활용
- 초기 배치 시 distance rule 무시 (isInitialPlacement = true)
- Round 2 정착지 배치 후 인접 타일 자원 지급

---

## FR Coverage Matrix (최종 검증)

| FR | Epic | Stories | 상태 |
|-----|------|---------|:----:|
| FR1 | Epic 1 | 1.1, 1.2, 1.3, 1.4 | ✅ |
| FR2 | Epic 2 | 2.1, 2.2 | ✅ |
| FR3 | Epic 2 | 2.3, 2.4, 2.5 | ✅ |
| FR4 | Epic 3 | 3.1, 3.2, 3.3 | ✅ |
| FR5 | Epic 3 | 3.4, 3.5 | ✅ |
| FR6 | Epic 4 | 4.1, 4.2 | ✅ |
| FR7 | Epic 4 | 4.3, 4.4 | ✅ |
| FR8 | Epic 5 | 5.1, 5.2 | ✅ |
| FR9 | Epic 5 | 5.3 | ✅ |
| FR10 | Epic 5 | 5.4 | ✅ |
| FR11 | Epic 5 | 5.5 | ✅ |
| FR12 | Epic 5 | 5.6 | ✅ |
| FR13 | Epic 6 | 6.1 | ✅ |
| FR14 | Epic 6 | 6.2 | ✅ |
| FR15 | Epic 6 | 6.3 | ✅ |
| FR16 | Epic 6 | 6.4, 6.5 | ✅ |
| FR17 | Epic 7 | 7.1, 7.2 | ✅ |
| FR18 | Epic 7 | 7.3, 7.4 | ✅ |

**모든 FR 커버 완료** ✅

---

## Summary

**프로젝트:** Settlus of Catan
**총 에픽:** 7개
**총 스토리:** 33개
**FR 커버리지:** 18/18 (100%)

**에픽 순서:**
1. Foundation → 프로젝트 기반
2. Core Data Model → 게임 경제
3. Hex Coordinate System → 공간 시스템
4. Board State → 보드 관리
5. Game Rules → 게임 규칙
6. Visual Experience → UI/UX
7. Complete Game Flow → 전체 흐름
8. UX/UI Improvements → 지속적 개선

**다음 단계:**
- `/bmad:bmgd:workflows:sprint-planning` - 스프린트 상태 추적 파일 생성
- `/bmad:bmgd:workflows:epic-tech-context` - 에픽별 기술 컨텍스트 생성

---

## Epic 8: UX/UI Improvements (사용성 개선)

**목표:** 게임 플레이 경험 향상을 위한 지속적인 UI/UX 개선

**특성:** 기능 완성 후 지속적으로 추가되는 개선 사항들을 관리하는 에픽

---

### Story 8.1: HUD 및 플레이어 정보 개선

**As a** 플레이어,
**I want** 게임 상태와 다른 플레이어 정보를 더 명확하게 볼 수 있어,
**So that** 전략적 의사결정을 더 쉽게 할 수 있음.

**Acceptance Criteria:**

```
AC 8-1.1: Admin 모드 및 플레이어 자원 표시
Given adminMode = true
When HUD 렌더링
Then 모든 플레이어의 자원 상세 표시 (W:2 B:1 S:3 등)

Given adminMode = false
When HUD 렌더링
Then 다른 플레이어는 총 카드 수만 표시 ("5 cards")

AC 8-1.2: 건물 현황 표시
Given HUD 플레이어 패널
When 렌더링
Then 각 플레이어의 도로/정착지/도시 개수 표시 (R:3 S:2 C:1)

AC 8-1.3: 건설 비용 툴팁
Given 건설 버튼 (Settlement/City/Road)
When 마우스 호버
Then 필요 자원 툴팁 표시 (예: "Wood 1, Brick 1, Sheep 1, Wheat 1")

AC 8-1.4: 건설 가능 여부 피드백
Given 자원이 부족한 건설 버튼
When 버튼 표시
Then 부족한 자원 시각적 표시 (빨간색 또는 아이콘)

AC 8-1.5: 주사위 결과 타일 강조
Given 주사위 굴림 결과
When 결과 숫자 표시
Then 해당 숫자의 타일들 하이라이트
And 자원 획득 정보 표시 (누가 무엇을 얻었는지)

AC 8-1.6: Settlement 배치 불가 피드백
Given Settlement 버튼 클릭
When 배치 가능한 위치가 없음
Then 사용자에게 피드백 메시지 표시
```

**Prerequisites:** Epic 6, Epic 7 완료

**Technical Notes:**
- src/ui/hud.lua 확장
- src/scenes/game.lua에 adminMode 플래그 추가
- 툴팁 렌더링 시스템 추가
- BoardView에 타일 하이라이트 기능 추가

---

_Generated by BMAD Epic and Story Workflow_
_Based on: GDD.md, game-architecture.md_
