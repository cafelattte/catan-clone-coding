# Story 4.4: 도로 배치

Status: done

## Story

As a 게임 시스템,
I want 변에 도로를 배치할 수 있어,
so that 플레이어 도로 네트워크 추적 가능.

## Acceptance Criteria

1. **AC4-4-1**: `board:placeRoad(playerId, q, r, dir)` 호출 시 해당 변에 도로 배치, `true` 반환
2. **AC4-4-2**: `board:getRoad(q, r, dir)` 호출 시 `{player=playerId}` 반환
3. **AC4-4-3**: 이미 도로 있는 위치에 배치 시 `false`, 에러 메시지 반환
4. **AC4-4-4**: `board:getPlayerRoads(playerId)` 호출 시 해당 플레이어의 모든 도로 목록 반환
5. **AC4-4-5**: `board:isVertexConnectedToRoad(playerId, q, r, dir)` 호출 시 해당 정점이 플레이어 도로와 연결되면 `true`
6. **AC4-4-6**: 정규화: `(-1, 0, "W")`와 `(0, 0, "E")`가 같은 변이면 중복 감지
7. **AC4-4-7**: 테스트 통과: `tests/game/board_spec.lua`

## Tasks / Subtasks

- [x] Task 0: vertex.lua에 getAdjacentEdges 추가 (AC: 5 선행 작업)
  - [x] 0.1: `Vertex.getAdjacentEdges(q, r, dir)` 함수 구현
  - [x] 0.2: N 정점 인접 변 계산: 자신의 NE, (q-1,r)의 E, (q,r-1)의 SE
  - [x] 0.3: S 정점 인접 변 계산: 자신의 E, 자신의 SE, (q+1,r)의 NE
  - [x] 0.4: 반환값은 정규화된 변 목록 {{q, r, dir}, ...}
  - [x] 0.5: tests/game/vertex_spec.lua에 getAdjacentEdges 테스트 추가

- [x] Task 1: 도로 저장 구조 구현 (AC: 1, 2, 3)
  - [x] 1.1: `Board` 테이블에 `roads` Map 구조 추가 (`Board.new()` 수정)
  - [x] 1.2: 키 형식: 정규화된 변 문자열 (예: `"0,0,E"`)
  - [x] 1.3: 값 형식: `{player = playerId}`

- [x] Task 2: 도로 배치 API 구현 (AC: 1, 2, 3, 6)
  - [x] 2.1: `board:placeRoad(playerId, q, r, dir)` 메서드 구현
  - [x] 2.2: `edge.normalize(q, r, dir)` 호출하여 정규화
  - [x] 2.3: `edge.toString(q, r, dir)` 또는 직접 키 생성 헬퍼 추가
  - [x] 2.4: 중복 체크 (roads에서 확인)
  - [x] 2.5: 배치 성공 시 `self.roads[key] = {player = playerId}` 저장
  - [x] 2.6: 실패 시 `false, "이미 도로가 있습니다"` 반환

- [x] Task 3: 도로 조회 API 구현 (AC: 2)
  - [x] 3.1: `board:getRoad(q, r, dir)` 메서드 구현
  - [x] 3.2: 정규화 후 roads에서 조회
  - [x] 3.3: 도로 있으면 `{player=playerId}` 반환
  - [x] 3.4: 없으면 `nil` 반환

- [x] Task 4: 도로 존재 확인 API (AC: 3)
  - [x] 4.1: `board:hasRoad(q, r, dir)` 메서드 구현
  - [x] 4.2: 정규화 후 roads에 존재하면 `true`

- [x] Task 5: 플레이어별 도로 조회 API (AC: 4)
  - [x] 5.1: `board:getPlayerRoads(playerId)` 메서드 구현
  - [x] 5.2: roads 순회하며 해당 플레이어 도로 수집
  - [x] 5.3: 반환 형식: `{{q, r, dir}, ...}` 목록

- [x] Task 6: 정점-도로 연결 확인 API (AC: 5)
  - [x] 6.1: `board:isVertexConnectedToRoad(playerId, q, r, dir)` 메서드 구현
  - [x] 6.2: 정점 정규화
  - [x] 6.3: `Vertex.getAdjacentEdges(q, r, dir)` 호출하여 인접 변 3개 조회 (Task 0에서 구현)
  - [x] 6.4: 각 인접 변에 해당 플레이어의 도로가 있는지 확인
  - [x] 6.5: 하나라도 있으면 `true`, 없으면 `false`

- [x] Task 7: 테스트 작성 (AC: 7)
  - [x] 7.1: 도로 배치 성공 테스트
  - [x] 7.2: 도로 조회 테스트 (getRoad)
  - [x] 7.3: 중복 배치 실패 테스트 (같은 위치)
  - [x] 7.4: 정규화 일관성 테스트 ((-1,0,"W") == (0,0,"E"))
  - [x] 7.5: hasRoad 테스트
  - [x] 7.6: getPlayerRoads 테스트
  - [x] 7.7: isVertexConnectedToRoad 테스트 (연결됨)
  - [x] 7.8: isVertexConnectedToRoad 테스트 (연결 안됨)
  - [x] 7.9: isVertexConnectedToRoad 테스트 (다른 플레이어 도로)
  - [x] 7.10: 모든 테스트 통과 확인

## Dev Notes

### Architecture Alignment

- **파일 위치**: `src/game/board.lua`
- **의존성**: `src/game/edge.lua` (변 정규화), `src/game/vertex.lua` (정점-변 인접 계산), Story 4-3 (Board 건물 구현)
- **제약**: `src/game/`은 Love2D 의존 없음 [Source: docs/game-architecture.md#ADR-001]
- **저장 구조**: Map 기반 - ADR-003 준수 [Source: docs/game-architecture.md#ADR-003]

### Key Implementation Details

1. **Map 구조** (Architecture GameState 참조):
   ```lua
   self.roads = {}  -- roads["0,0,E"] = {player = 1}
   ```

2. **변 정규화** (Epic 3 edge.lua 활용):
   - 동일한 물리적 변의 다른 표현을 통일
   - 예: `(-1, 0, "W")`와 `(0, 0, "E")`는 같은 변
   - 정규화 방향: NE, E, SE만 사용

3. **정점-변 인접 관계** (isVertexConnectedToRoad용):
   - 각 정점은 3개의 변과 인접
   - `vertex.getAdjacentEdges(q, r, dir)` 또는 직접 계산 필요
   - edge.lua의 `getEdgeVertices(q, r, dir)` 역으로 활용 가능

4. **API 시그니처** (Tech-Spec 참조):
   - `board:placeRoad(playerId, q, r, dir)` → boolean, error
   - `board:getRoad(q, r, dir)` → road or nil
   - `board:hasRoad(q, r, dir)` → boolean
   - `board:getPlayerRoads(playerId)` → table
   - `board:isVertexConnectedToRoad(playerId, q, r, dir)` → boolean

### Project Structure Notes

- `src/game/edge.lua` - 변 정규화 및 인접 정점 계산 (Epic 3-5에서 구현됨)
- `src/game/vertex.lua` - 정점 정규화 (Epic 3-4에서 구현됨), **이 스토리에서 getAdjacentEdges 추가**
- `src/game/board.lua` - 도로 배치 로직 추가 대상

### vertex.lua 확장 (Task 0)

**배경:** vertex.lua에 `getAdjacentHexes`, `getAdjacentVertices`는 있으나 `getAdjacentEdges`가 누락됨. `isVertexConnectedToRoad` 구현에 필요하므로 이 스토리에서 추가.

**구현 로직:**
```lua
function Vertex.getAdjacentEdges(q, r, dir)
  local Edge = require("src.game.edge")
  local edges = {}
  if dir == "N" then
    -- N 정점의 3개 인접 변
    edges[1] = Edge.normalizeEdge(q, r, "NE")      -- 자신의 NE
    edges[2] = Edge.normalizeEdge(q - 1, r, "E")  -- 왼쪽 헥스의 E
    edges[3] = Edge.normalizeEdge(q, r - 1, "SE") -- 위쪽 헥스의 SE
  else -- S
    -- S 정점의 3개 인접 변
    edges[1] = Edge.normalizeEdge(q, r, "E")      -- 자신의 E
    edges[2] = Edge.normalizeEdge(q, r, "SE")     -- 자신의 SE
    edges[3] = Edge.normalizeEdge(q + 1, r, "NE") -- 오른쪽 헥스의 NE
  end
  return edges
end
```

**주의:** Edge 모듈을 require하므로 순환 의존성 주의. Edge→Vertex 의존은 있으나 Vertex→Edge는 이 함수에서만 사용.

### Learnings from Previous Story

**From Story 4-3-settlement-city-placement (Status: done)**

- **기존 Board 구조**: `settlements`, `cities` Map 추가됨 - 동일 패턴으로 `roads` 추가
- **vertexKey 헬퍼 함수**: 정점 정규화 키 생성 - 변용 `edgeKey` 헬퍼 추가 필요
- **API 패턴**: `boolean, error` 반환 패턴 확립 - 동일하게 적용
- **테스트 패턴**: `tests/game/board_spec.lua`에 BDD 스타일 테스트 추가
- **정규화 중복 감지**: (0,-1,S) == (0,0,N) 정상 동작 확인 - 변도 동일 패턴 적용
- **getSettlementsOnTile/getCitiesOnTile**: seen 테이블로 중복 방지 - 참고 가능

**구현 시 주의사항:**
- `vertexKey` 패턴 참고하여 `edgeKey` 구현
- Board.new()에 roads = {} 추가
- getPlayerBuildings 패턴 참고하여 getPlayerRoads 구현
- 정점-변 인접 관계 계산 시 edge.lua의 기존 함수 활용

[Source: docs/sprint-artifacts/4-3-settlement-city-placement.md#Dev-Agent-Record]

### Testing Strategy

- busted BDD 스타일 테스트
- 기존 `tests/game/board_spec.lua`에 테스트 추가
- 엣지 케이스: 정규화 일관성, 중복 배치, 정점-도로 연결

### References

- [Source: docs/epics.md#Story-4.4]
- [Source: docs/sprint-artifacts/tech-spec-epic-4.md#Story-4-4]
- [Source: docs/game-architecture.md#Data-Architecture]
- [Source: docs/game-architecture.md#ADR-003]
- [Source: docs/sprint-artifacts/4-3-settlement-city-placement.md#Dev-Agent-Record]

## Dev Agent Record

### Context Reference

- docs/sprint-artifacts/4-4-road-placement.context.xml

### Agent Model Used

Claude Opus 4.5 (claude-opus-4-5-20251101)

### Debug Log References

- Task 0: vertex.lua에 Vertex.getAdjacentEdges(q, r, dir) 함수 추가. N 정점은 (0,0,NE), (-1,0,E), (0,-1,SE) 인접 변, S 정점은 (0,0,E), (0,0,SE), (1,0,NE) 인접 변 계산. Edge.normalizeEdge로 정규화된 변 반환.
- Task 1: Board.new()에 self.roads = {} Map 구조 추가.
- Task 2-4: placeRoad, getRoad, hasRoad 메서드 구현. edgeKey 헬퍼 함수로 정규화 후 문자열 키 생성.
- Task 5: getPlayerRoads 메서드 구현. roads Map 순회하며 해당 플레이어 도로 수집.
- Task 6: isVertexConnectedToRoad 메서드 구현. 정점 정규화 후 Vertex.getAdjacentEdges로 인접 변 조회, 각 변에 플레이어 도로 존재 확인.
- Task 7: 18개 도로 테스트 추가 (board_spec.lua), 6개 getAdjacentEdges 테스트 추가 (vertex_spec.lua). 총 200개 테스트 통과.

### Completion Notes List

- ✅ 모든 AC 충족 확인
- ✅ 변 정규화를 통한 중복 감지 정상 동작 ((0,0,W) → (-1,0,E) 정규화)
- ✅ 정점-도로 연결 확인 시 정점 정규화 후 인접 변 계산 (S 정점은 N으로 정규화됨)
- ✅ vertex.lua에 getAdjacentEdges 추가 (순환 의존성 방지를 위해 함수 내부에서 Edge require)
- ✅ 기존 테스트 모두 통과 (회귀 없음)

### File List

**Modified:**
- src/game/vertex.lua - getAdjacentEdges 함수 추가
- src/game/board.lua - roads Map 추가, 도로 배치/조회 API 구현 (placeRoad, getRoad, hasRoad, getPlayerRoads, isVertexConnectedToRoad)
- tests/game/vertex_spec.lua - getAdjacentEdges 테스트 6개 추가
- tests/game/board_spec.lua - Story 4-4 도로 테스트 18개 추가

## Senior Developer Review (AI)

### Reviewer
BMad

### Date
2025-12-01

### Outcome
**✅ APPROVE**

모든 Acceptance Criteria 구현 확인, 모든 Task 검증 완료, 테스트 통과, Architecture 준수.

### Summary

Story 4-4 도로 배치 기능이 완전히 구현되었습니다:
- `Vertex.getAdjacentEdges` 함수 추가 (순환 의존성 방지를 위해 함수 내부에서 Edge require)
- `Board.new()`에 `roads` Map 구조 추가
- 모든 도로 API (placeRoad, getRoad, hasRoad, getPlayerRoads, isVertexConnectedToRoad) 구현
- 변 정규화를 통한 중복 감지 정상 동작
- 200개 테스트 모두 통과 (24개 신규)

### Key Findings

**HIGH severity: 없음**
**MEDIUM severity: 없음**
**LOW severity: 없음**

### Acceptance Criteria Coverage

| AC | Description | Status | Evidence |
|---|---|---|---|
| AC4-4-1 | placeRoad 배치 및 true 반환 | ✅ IMPLEMENTED | `board.lua:417-428` |
| AC4-4-2 | getRoad 반환 형식 | ✅ IMPLEMENTED | `board.lua:437-440` |
| AC4-4-3 | 중복 배치 시 false + 에러 | ✅ IMPLEMENTED | `board.lua:420-423` |
| AC4-4-4 | getPlayerRoads 목록 | ✅ IMPLEMENTED | `board.lua:459-470` |
| AC4-4-5 | isVertexConnectedToRoad 연결 확인 | ✅ IMPLEMENTED | `board.lua:480-497` |
| AC4-4-6 | 정규화 중복 감지 | ✅ IMPLEMENTED | `board.lua:404-407` (edgeKey) |
| AC4-4-7 | 테스트 통과 | ✅ IMPLEMENTED | 200개 테스트 통과 |

**Summary: 7 of 7 acceptance criteria fully implemented**

### Task Completion Validation

| Task | Marked | Verified | Evidence |
|---|---|---|---|
| Task 0: getAdjacentEdges | [x] | ✅ | `vertex.lua:108-124` |
| Task 0.1: 함수 구현 | [x] | ✅ | `vertex.lua:108` |
| Task 0.2: N 정점 인접 변 | [x] | ✅ | `vertex.lua:112-116` |
| Task 0.3: S 정점 인접 변 | [x] | ✅ | `vertex.lua:117-122` |
| Task 0.4: 정규화된 변 반환 | [x] | ✅ | `vertex.lua:114-121` (Edge.normalizeEdge 사용) |
| Task 0.5: 테스트 추가 | [x] | ✅ | `vertex_spec.lua:125-181` (6개 테스트) |
| Task 1: roads Map | [x] | ✅ | `board.lua:86-88` |
| Task 1.1: Board.new 수정 | [x] | ✅ | `board.lua:88` |
| Task 1.2: 키 형식 | [x] | ✅ | `board.lua:404-407` (edgeKey) |
| Task 1.3: 값 형식 | [x] | ✅ | `board.lua:426` |
| Task 2: placeRoad API | [x] | ✅ | `board.lua:417-428` |
| Task 2.1-2.6: 세부 구현 | [x] | ✅ | 정규화, 중복체크, 저장, 에러반환 모두 구현 |
| Task 3: getRoad API | [x] | ✅ | `board.lua:437-440` |
| Task 4: hasRoad API | [x] | ✅ | `board.lua:449-452` |
| Task 5: getPlayerRoads API | [x] | ✅ | `board.lua:459-470` |
| Task 6: isVertexConnectedToRoad | [x] | ✅ | `board.lua:480-497` |
| Task 7: 테스트 작성 | [x] | ✅ | `board_spec.lua:659-861` (18개 테스트) |

**Summary: 31 of 31 completed tasks verified, 0 questionable, 0 falsely marked complete**

### Test Coverage and Gaps

- ✅ 모든 AC에 대응하는 테스트 존재
- ✅ 정규화 일관성 테스트 포함 ((-1,0,W) vs (0,0,E))
- ✅ 엣지 케이스 (중복 배치, 정점-도로 연결, 다른 플레이어 도로) 커버
- ✅ getAdjacentEdges N/S 정점별 테스트 포함

### Architectural Alignment

- ✅ ADR-001: src/game/ 순수 Lua (Love2D 의존 없음)
- ✅ ADR-003: Map 기반 도로 저장, 정규화된 키
- ✅ 함수명 camelCase 준수
- ✅ 에러 핸들링 패턴 (false, error_message)
- ✅ 순환 의존성 방지: Vertex.getAdjacentEdges 내부에서 Edge require

### Security Notes

- N/A (게임 로직, 외부 입력 없음)

### Best-Practices and References

- Red Blob Games 헥스 좌표계: https://www.redblobgames.com/grids/hexagons/
- Lua 5.1 Reference: https://www.lua.org/manual/5.1/

### Action Items

**Code Changes Required:**
- 없음

**Advisory Notes:**
- Note: 향후 도로 연결 규칙 검증 (정착지/도로 인접 필수) 구현 시 isVertexConnectedToRoad 활용 가능

