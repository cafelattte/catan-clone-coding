# Story 4.1: 보드 타일 생성

Status: done

## Story

As a 게임 시스템,
I want 19개 헥스 타일로 구성된 보드를 생성할 수 있어,
so that 카탄 표준 보드 레이아웃 사용 가능.

## Acceptance Criteria

1. **AC4-1-1**: `Board.new()` 호출 시 빈 보드 생성, `Board.newStandard()` 호출 시 19개 타일 생성
2. **AC4-1-2**: 타일 분포가 GDD 명세와 일치 (숲 4, 언덕 3, 목초지 4, 농장 4, 산 3, 사막 1)
3. **AC4-1-3**: `board:getTile(0, 0)` → 중앙 타일 정보 `{q, r, terrain, number}` 반환
4. **AC4-1-4**: `board:getAllTiles()` → 19개 타일 목록 반환
5. **AC4-1-5**: 사막 타일은 `number`가 `nil`
6. **AC4-1-6**: 테스트 통과: `tests/game/board_spec.lua`

## Tasks / Subtasks

- [x] Task 1: Board 모듈 기본 구조 생성 (AC: 1)
  - [x] 1.1: `src/game/board.lua` 파일 생성
  - [x] 1.2: Board 메타테이블 및 `Board.new()` 구현 (빈 보드)
  - [x] 1.3: `self.tiles = {}` Map 구조 초기화

- [x] Task 2: 표준 보드 좌표 정의 (AC: 1, 3, 4)
  - [x] 2.1: 19개 헥스 좌표 상수 정의 (중심 + 내부링 6개 + 외부링 12개)
  - [x] 2.2: `BOARD_COORDS` 테이블 구현
  ```lua
  -- 나선형 순서
  BOARD_COORDS = {
    {q=0, r=0},      -- 중심
    {q=1, r=0}, {q=1, r=-1}, {q=0, r=-1}, {q=-1, r=0}, {q=-1, r=1}, {q=0, r=1},  -- 내부
    {q=2, r=0}, {q=2, r=-1}, {q=2, r=-2}, {q=1, r=-2}, {q=0, r=-2}, {q=-1, r=-1},
    {q=-2, r=0}, {q=-2, r=1}, {q=-2, r=2}, {q=-1, r=2}, {q=0, r=2}, {q=1, r=1}   -- 외부
  }
  ```

- [x] Task 3: 타일 분포 상수 추가 (AC: 2)
  - [x] 3.1: `src/game/constants.lua`에 `TILE_DISTRIBUTION` 추가
  ```lua
  TILE_DISTRIBUTION = {
    forest = 4,    -- 목재
    hills = 3,     -- 벽돌
    pasture = 4,   -- 양모
    fields = 4,    -- 밀
    mountains = 3, -- 광석
    desert = 1,    -- 없음
  }
  ```
  - [x] 3.2: `TERRAIN_TYPES` 배열 추가 (순회용)

- [x] Task 4: 타일 풀 생성 및 셔플 (AC: 2)
  - [x] 4.1: `createTilePool()` 함수 - 분포대로 지형 목록 생성
  - [x] 4.2: `shuffle(table)` 함수 - Fisher-Yates 알고리즘

- [x] Task 5: Board.newStandard() 구현 (AC: 1, 2, 3, 4, 5)
  - [x] 5.1: 타일 풀 생성 및 셔플
  - [x] 5.2: 좌표에 타일 배치 (Map 키: "q,r")
  - [x] 5.3: 사막 타일 `number = nil` 처리
  - [x] 5.4: 도둑 초기 위치 설정 (사막 좌표)

- [x] Task 6: 타일 조회 API 구현 (AC: 3, 4)
  - [x] 6.1: `board:getTile(q, r)` - Map에서 조회
  - [x] 6.2: `board:getAllTiles()` - 전체 목록 반환
  - [x] 6.3: 키 생성 헬퍼 `tileKey(q, r)` → "q,r"

- [x] Task 7: 테스트 작성 (AC: 6)
  - [x] 7.1: `tests/game/board_spec.lua` 파일 생성
  - [x] 7.2: "Board.new()" 빈 보드 테스트
  - [x] 7.3: "Board.newStandard()" 19개 타일 테스트
  - [x] 7.4: 지형 분포 검증 테스트
  - [x] 7.5: `getTile(0, 0)` 중앙 타일 테스트
  - [x] 7.6: `getAllTiles()` 목록 길이 테스트
  - [x] 7.7: 사막 타일 number nil 테스트
  - [x] 7.8: 모든 테스트 통과 확인: `busted tests/game/board_spec.lua`

## Dev Notes

### Architecture Alignment

- **파일 위치**: `src/game/board.lua` [Source: docs/game-architecture.md#Project-Structure]
- **의존성**: `constants.lua` (TILE_DISTRIBUTION, TERRAIN_TYPES)
- **패턴**: Map 기반 저장 (ADR-003) - 좌표 문자열을 키로 사용
- **제약**: Love2D 의존성 없이 순수 Lua 구현, busted로 독립 테스트

### Data Model

```lua
-- Board 구조
Board = {
  tiles = {},    -- tiles["0,0"] = {q=0, r=0, terrain="forest", number=8}
  robber = nil,  -- {q=0, r=0} 사막 위치
}

-- 타일 구조
tile = {
  q = number,        -- Axial 좌표
  r = number,
  terrain = string,  -- "forest", "hills", "pasture", "fields", "mountains", "desert"
  number = number|nil -- 2-6, 8-12 (사막은 nil)
}
```

### Key Implementation Details

1. **Fisher-Yates 셔플**: 편향 없는 랜덤 배치
```lua
local function shuffle(t)
  for i = #t, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
  return t
end
```

2. **19개 헥스 좌표** (나선형): Red Blob Games 권장 레이아웃
3. **숫자 토큰**: Story 4-2에서 구현 (이 스토리에서는 사막만 nil 처리)

### Testing Standards

- busted BDD 스타일: `describe`, `it`, `assert`
- 테스트 파일: `tests/game/board_spec.lua`
- AAA 패턴: Arrange → Act → Assert

### Project Structure Notes

- 새 파일: `src/game/board.lua`
- 수정 파일: `src/game/constants.lua` (TILE_DISTRIBUTION 추가)
- 테스트: `tests/game/board_spec.lua`

### References

- [Source: docs/sprint-artifacts/tech-spec-epic-4.md#Story-4-1]
- [Source: docs/epics.md#Story-4.1]
- [Source: docs/game-architecture.md#Project-Structure]
- [Source: docs/game-architecture.md#ADR-003]
- [Source: docs/GDD.md#타일-분포]

## Dev Agent Record

### Context Reference

- docs/sprint-artifacts/4-1-board-tiles.context.xml

### Agent Model Used

Claude Opus 4.5 (claude-opus-4-5-20251101)

### Debug Log References

- 2025-11-30: Board 모듈 구현 시작, TDD 접근

### Completion Notes List

- Board.new(): 빈 보드 생성, tiles={} 초기화
- Board.newStandard(): 19개 타일 생성, Fisher-Yates 셔플로 랜덤 배치
- BOARD_COORDS: 나선형 순서로 19개 좌표 정의 (중심→내부링→외부링)
- getTile(q, r): Map 키 "q,r" 형식으로 O(1) 조회
- getAllTiles(): 전체 타일 목록 반환
- 사막 타일 자동 감지하여 도둑(robber) 초기 위치 설정
- constants.lua에 TILE_DISTRIBUTION, TERRAIN_TYPES, TERRAIN_RESOURCE 추가
- 14개 테스트 케이스 작성, 모두 통과
- 전체 회귀 테스트 115개 통과

### File List

**신규 파일:**
- src/game/board.lua
- tests/game/board_spec.lua

**수정 파일:**
- src/game/constants.lua (TILE_DISTRIBUTION, TERRAIN_TYPES, TERRAIN_RESOURCE 추가)

---

## Senior Developer Review (AI)

### Review Metadata
- **Reviewer:** BMad
- **Date:** 2025-11-30
- **Outcome:** ✅ **APPROVE**

### Summary

Story 4-1 (보드 타일 생성) 구현이 모든 Acceptance Criteria를 충족하고, 모든 태스크가 검증되었습니다. 코드 품질이 우수하며, 아키텍처 가이드라인을 준수합니다. 14개 테스트 케이스가 모두 통과했습니다.

### Acceptance Criteria Coverage

| AC# | Description | Status | Evidence |
|-----|-------------|--------|----------|
| AC4-1-1 | Board.new() 빈 보드, Board.newStandard() 19개 타일 | ✅ IMPLEMENTED | board.lua:64-69 (new), board.lua:75-101 (newStandard) |
| AC4-1-2 | 타일 분포 GDD 일치 (숲4, 언덕3, 목초지4, 농장4, 산3, 사막1) | ✅ IMPLEMENTED | constants.lua:49-56 (TILE_DISTRIBUTION), board.lua:50-57 (createTilePool) |
| AC4-1-3 | getTile(0, 0) → {q, r, terrain, number} 반환 | ✅ IMPLEMENTED | board.lua:109-112 (getTile) |
| AC4-1-4 | getAllTiles() → 19개 타일 목록 | ✅ IMPLEMENTED | board.lua:118-124 (getAllTiles) |
| AC4-1-5 | 사막 타일 number = nil | ✅ IMPLEMENTED | board.lua:91 (number = nil) |
| AC4-1-6 | 테스트 통과 | ✅ IMPLEMENTED | board_spec.lua:1-179 (14 tests, 0 failures) |

**Summary:** 6 of 6 acceptance criteria fully implemented ✅

### Task Completion Validation

| Task | Marked | Verified | Evidence |
|------|--------|----------|----------|
| 1.1: board.lua 파일 생성 | [x] | ✅ VERIFIED | src/game/board.lua exists (127 lines) |
| 1.2: Board 메타테이블 및 Board.new() | [x] | ✅ VERIFIED | board.lua:6-7, 64-69 |
| 1.3: self.tiles = {} 초기화 | [x] | ✅ VERIFIED | board.lua:66 |
| 2.1: 19개 헥스 좌표 상수 | [x] | ✅ VERIFIED | board.lua:10-21 (BOARD_COORDS) |
| 2.2: BOARD_COORDS 테이블 | [x] | ✅ VERIFIED | board.lua:10-21 |
| 3.1: TILE_DISTRIBUTION 추가 | [x] | ✅ VERIFIED | constants.lua:49-56 |
| 3.2: TERRAIN_TYPES 추가 | [x] | ✅ VERIFIED | constants.lua:38-46 |
| 4.1: createTilePool() | [x] | ✅ VERIFIED | board.lua:50-58 |
| 4.2: shuffle() Fisher-Yates | [x] | ✅ VERIFIED | board.lua:38-44 |
| 5.1: 타일 풀 생성/셔플 | [x] | ✅ VERIFIED | board.lua:78-80 |
| 5.2: 좌표에 타일 배치 | [x] | ✅ VERIFIED | board.lua:83-92 |
| 5.3: 사막 number = nil | [x] | ✅ VERIFIED | board.lua:91 |
| 5.4: 도둑 초기 위치 | [x] | ✅ VERIFIED | board.lua:94-97 |
| 6.1: getTile(q, r) | [x] | ✅ VERIFIED | board.lua:109-112 |
| 6.2: getAllTiles() | [x] | ✅ VERIFIED | board.lua:118-124 |
| 6.3: tileKey(q, r) | [x] | ✅ VERIFIED | board.lua:29-31 |
| 7.1: board_spec.lua 생성 | [x] | ✅ VERIFIED | tests/game/board_spec.lua exists |
| 7.2-7.7: 테스트 케이스들 | [x] | ✅ VERIFIED | board_spec.lua:10-177 (14 test cases) |
| 7.8: 테스트 통과 | [x] | ✅ VERIFIED | 14 successes / 0 failures |

**Summary:** 19 of 19 completed tasks verified, 0 questionable, 0 false completions ✅

### Test Coverage and Gaps

**Coverage:**
- Board.new(): 2 tests (빈 보드, robber nil)
- Board.newStandard(): 3 tests (19개 타일, 지형 분포, 도둑 위치)
- getTile(): 5 tests (중앙, 구조, 범위 외, 내부/외부 링)
- getAllTiles(): 3 tests (빈 목록, 19개, 유효 지형)
- desert tile: 1 test (number nil)

**Gaps:** None identified. 모든 AC에 대응하는 테스트 존재.

### Architectural Alignment

- ✅ **ADR-001 준수:** src/game/board.lua는 Love2D 의존성 없이 순수 Lua로 구현
- ✅ **ADR-003 준수:** Map 기반 저장 (tiles["q,r"] = {...})
- ✅ **Project Structure:** src/game/ 경로에 올바르게 배치
- ✅ **테스트:** busted BDD 스타일, AAA 패턴 준수

### Security Notes

- 보안 관련 사항 없음 (순수 게임 로직, 외부 입력 없음)

### Best-Practices and References

- Fisher-Yates 셔플: 편향 없는 랜덤 알고리즘 올바르게 구현
- 헥스 좌표: Red Blob Games 권장 레이아웃 준수
- 참조: https://www.redblobgames.com/grids/hexagons/

### Action Items

**Code Changes Required:**
- None

**Advisory Notes:**
- Note: TERRAIN_RESOURCE 추가는 Story 4-2 이후 활용 예정
- Note: robber 위치는 현재 사막에 고정, 향후 도둑 이동 시 활용

