# Epic Technical Specification: Hex Coordinate System (헥스 좌표계)

Date: 2025-11-30
Author: BMad
Epic ID: 3
Status: Draft

---

## Overview

Epic 3는 카탄 보드 게임의 공간 시스템을 구현합니다. Axial/Cube/Pixel 좌표 변환, 이웃 헥스 계산, 정점/변 정규화를 구현합니다.

이 에픽은 GDD의 "Phase 2: 좌표계" 요구사항과 Architecture 문서의 `src/game/hex.lua`, `src/game/vertex.lua`, `src/game/edge.lua` 모듈을 구현합니다. Red Blob Games 헥스 좌표계 참조.

## Objectives and Scope

### In-Scope

- Axial ↔ Cube 좌표 상호 변환
- Cube ↔ Pixel 좌표 변환 (렌더링용)
- 6방향 이웃 헥스 계산
- 정점 정규화 (N/S 방향만 사용)
- 변 정규화 (NE/E/SE 방향만 사용)
- 변의 양 끝 정점 조회

### Out-of-Scope

- 보드 타일 배치 (Epic 4)
- 픽셀 → 정점/변 변환 (Epic 6 UI)
- 건물 배치 로직 (Epic 4)

## System Architecture Alignment

이 에픽은 Architecture 문서의 다음 섹션과 정렬됩니다:

- **Project Structure**: `src/game/hex.lua`, `src/game/vertex.lua`, `src/game/edge.lua`
- **Module Dependencies**: hex.lua는 의존성 없음, vertex/edge는 hex.lua에 의존
- **ADR-002**: Axial + Cube 좌표계 (저장은 Axial, 계산은 Cube)

**제약 사항:**
- `src/game/` 내 모든 모듈은 Love2D 의존성 없이 순수 Lua로 구현
- busted로 독립 테스트 가능
- Pointy-top 헥스 레이아웃 사용

## Detailed Design

### Services and Modules

| 모듈 | 파일 | 책임 | 의존성 |
|------|------|------|--------|
| Hex | src/game/hex.lua | 좌표 변환, 이웃 계산 | 없음 |
| Vertex | src/game/vertex.lua | 정점 정규화, 문자열 변환 | hex.lua |
| Edge | src/game/edge.lua | 변 정규화, 정점 조회 | hex.lua, vertex.lua |

### Data Models and Contracts

**hex.lua 구조:**

```lua
local Hex = {}

-- 방향 상수 (Pointy-top, 시계방향)
Hex.DIRECTIONS = {
  {q = 1, r = 0},   -- E
  {q = 1, r = -1},  -- NE
  {q = 0, r = -1},  -- NW
  {q = -1, r = 0},  -- W
  {q = -1, r = 1},  -- SW
  {q = 0, r = 1},   -- SE
}

Hex.DIRECTION_NAMES = {"E", "NE", "NW", "W", "SW", "SE"}

return Hex
```

**vertex.lua 구조:**

```lua
local Vertex = {}

-- 정점 방향 (N, S만 사용)
-- 각 헥스는 위(N)와 아래(S) 정점을 가짐
-- 동일한 물리적 정점은 여러 헥스에서 참조 가능

return Vertex
```

**edge.lua 구조:**

```lua
local Edge = {}

-- 변 방향 (NE, E, SE만 사용)
-- 각 헥스는 3개 변을 "소유" (NE, E, SE)
-- 나머지 3개 변은 이웃 헥스가 소유

return Edge
```

### APIs and Interfaces

**hex.lua API:**

| 함수 | 파라미터 | 반환값 | 설명 |
|------|----------|--------|------|
| `axialToCube(q, r)` | q, r: number | x, y, z | Axial → Cube 변환 |
| `cubeToAxial(x, y, z)` | x, y, z: number | q, r | Cube → Axial 변환 |
| `cubeToPixel(x, y, z, size)` | coords, size: number | px, py | Cube → Pixel 변환 |
| `pixelToCube(px, py, size)` | coords, size: number | x, y, z | Pixel → Cube 변환 |
| `cubeRound(x, y, z)` | x, y, z: number | x, y, z | Cube 좌표 반올림 |
| `getNeighbor(q, r, direction)` | q, r: number, dir: number/string | q, r | 특정 방향 이웃 |
| `getNeighbors(q, r)` | q, r: number | table | 6개 이웃 목록 |
| `hexToString(q, r)` | q, r: number | string | "(q,r)" 형식 |

**vertex.lua API:**

| 함수 | 파라미터 | 반환값 | 설명 |
|------|----------|--------|------|
| `normalize(q, r, dir)` | q, r: number, dir: string | q, r, dir | 정규화된 정점 |
| `toString(q, r, dir)` | coords, dir: string | string | "q,r,dir" 형식 |
| `getAdjacentHexes(q, r, dir)` | coords, dir: string | table | 인접 헥스 3개 |
| `getAdjacentVertices(q, r, dir)` | coords, dir: string | table | 인접 정점 3개 |

**edge.lua API:**

| 함수 | 파라미터 | 반환값 | 설명 |
|------|----------|--------|------|
| `normalize(q, r, dir)` | q, r: number, dir: string | q, r, dir | 정규화된 변 |
| `toString(q, r, dir)` | coords, dir: string | string | "q,r,dir" 형식 |
| `getVertices(q, r, dir)` | coords, dir: string | v1, v2 | 변의 양 끝 정점 |
| `getAdjacentEdges(q, r, dir)` | coords, dir: string | table | 인접 변 4개 |

### Coordinate System Details

**Pointy-top 헥스 레이아웃:**

```
    /\
   /  \
  |    |
  |    |
   \  /
    \/
```

**Axial → Cube 변환:**
```lua
x = q
z = r
y = -x - z  -- x + y + z = 0 불변식
```

**Cube → Pixel 변환 (Pointy-top):**
```lua
px = size * (sqrt(3) * x + sqrt(3)/2 * z)
py = size * (3/2 * z)
```

**정점 정규화 규칙:**
- N 정점: 정규 형태로 유지
- S 정점: (q, r, S) → (q, r+1, N) 으로 변환 가능한 경우 변환

**변 정규화 규칙:**
- NE, E, SE: 정규 형태로 유지
- NW: (q, r, NW) → (q-1, r, NE) 로 변환
- W: (q, r, W) → (q-1, r, E) 로 변환
- SW: (q, r, SW) → (q, r+1, NE) 로 변환

## Non-Functional Requirements

### Performance

- 좌표 변환: O(1)
- 이웃 조회: O(1)
- 정규화: O(1)

### Reliability

- Cube 불변식 검증: x + y + z = 0
- 반올림 오차 처리: cubeRound 함수

## Acceptance Criteria (Authoritative)

### Story 3-1: Axial ↔ Cube 좌표 변환

- **AC3-1-1**: axialToCube(0, 0) → {x=0, y=0, z=0}
- **AC3-1-2**: axialToCube(1, -1) → {x=1, y=0, z=-1} (x+y+z=0)
- **AC3-1-3**: cubeToAxial(1, 0, -1) → {q=1, r=-1}
- **AC3-1-4**: axialToCube → cubeToAxial 왕복 변환 시 원래 좌표 유지
- **AC3-1-5**: 테스트 통과: tests/game/hex_spec.lua

### Story 3-2: Cube ↔ Pixel 좌표 변환

- **AC3-2-1**: cubeToPixel(0, 0, 0, size) → 중심점 픽셀 좌표
- **AC3-2-2**: pixelToCube(px, py, size) → 해당 픽셀 포함 헥스
- **AC3-2-3**: cubeRound로 부동소수점 반올림 처리
- **AC3-2-4**: Pointy-top 레이아웃 공식 사용
- **AC3-2-5**: 테스트 통과

### Story 3-3: 이웃 헥스 계산

- **AC3-3-1**: getNeighbors(0, 0) → 6개 이웃 좌표 반환
- **AC3-3-2**: getNeighbor(0, 0, "E") → (1, 0)
- **AC3-3-3**: 방향은 인덱스(1-6) 또는 문자열("E", "NE" 등) 지원
- **AC3-3-4**: 테스트 통과

### Story 3-4: 정점 정규화

- **AC3-4-1**: normalize(0, 0, "N") → 정규화된 좌표
- **AC3-4-2**: normalize(0, -1, "S")와 normalize(0, 0, "N")이 동일 정점이면 같은 결과
- **AC3-4-3**: toString(0, 0, "N") → "0,0,N" (Map 키용)
- **AC3-4-4**: 동일 물리적 정점의 다른 표현들이 같은 키 생성
- **AC3-4-5**: 테스트 통과: tests/game/vertex_spec.lua

### Story 3-5: 변 정규화 및 인접 정점

- **AC3-5-1**: normalize(0, 0, "E") → 정규화된 좌표
- **AC3-5-2**: normalize(-1, 0, "W")와 normalize(0, 0, "E")가 동일하면 같은 결과
- **AC3-5-3**: getVertices(0, 0, "E") → 변의 양 끝 정점 2개
- **AC3-5-4**: toString(0, 0, "E") → "0,0,E" (Map 키용)
- **AC3-5-5**: 테스트 통과: tests/game/edge_spec.lua

## Test Strategy Summary

### 테스트 파일

```
tests/
└── game/
    ├── hex_spec.lua      -- Story 3-1, 3-2, 3-3
    ├── vertex_spec.lua   -- Story 3-4
    └── edge_spec.lua     -- Story 3-5
```

### 테스트 예시

```lua
-- tests/game/hex_spec.lua
describe("Hex", function()
  local Hex = require("src.game.hex")

  describe("axialToCube", function()
    it("should convert origin", function()
      local x, y, z = Hex.axialToCube(0, 0)
      assert.equals(0, x)
      assert.equals(0, y)
      assert.equals(0, z)
    end)

    it("should maintain x + y + z = 0", function()
      local x, y, z = Hex.axialToCube(3, -2)
      assert.equals(0, x + y + z)
    end)
  end)

  describe("getNeighbors", function()
    it("should return 6 neighbors", function()
      local neighbors = Hex.getNeighbors(0, 0)
      assert.equals(6, #neighbors)
    end)
  end)
end)
```

### 커버리지 목표

- hex.lua: 100%
- vertex.lua: 100%
- edge.lua: 100%

## References

- Red Blob Games Hexagonal Grids: https://www.redblobgames.com/grids/hexagons/
- Architecture ADR-002: Axial + Cube 좌표계

---

_Generated by BMAD Epic Tech Context Workflow_
_Source: GDD.md, game-architecture.md, epics.md_
