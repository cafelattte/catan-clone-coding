# Story 4.3: 정착지/도시 배치

Status: done

## Story

As a 게임 시스템,
I want 정점에 정착지와 도시를 배치할 수 있어,
so that 플레이어 건물 위치 추적 가능.

## Acceptance Criteria

1. **AC4-3-1**: `board:placeSettlement(playerId, q, r, dir)` 호출 시 해당 정점에 정착지 배치, `true` 반환
2. **AC4-3-2**: `board:getBuilding(q, r, dir)` 호출 시 `{type="settlement", player=playerId}` 반환
3. **AC4-3-3**: 이미 건물 있는 위치에 배치 시 `false`, 에러 메시지 반환
4. **AC4-3-4**: `board:upgradeToCity(q, r, dir)` 호출 시 정착지→도시 변환
5. **AC4-3-5**: `board:getPlayerBuildings(playerId)` 호출 시 해당 플레이어의 모든 건물 목록 반환
6. **AC4-3-6**: 정규화: `(0, -1, "S")`와 `(0, 0, "N")`이 같은 정점이면 중복 감지
7. **AC4-3-7**: 테스트 통과: `tests/game/board_spec.lua`

## Tasks / Subtasks

- [x] Task 1: 건물 저장 구조 구현 (AC: 1, 2, 3)
  - [x] 1.1: `Board` 테이블에 `settlements`, `cities` Map 구조 추가 (`Board.new()` 수정)
  - [x] 1.2: 키 형식: 정규화된 정점 문자열 (예: `"0,0,N"`)
  - [x] 1.3: 값 형식: `{player = playerId}`

- [x] Task 2: 정착지 배치 API 구현 (AC: 1, 2, 3, 6)
  - [x] 2.1: `board:placeSettlement(playerId, q, r, dir)` 메서드 구현
  - [x] 2.2: `vertex.normalize(q, r, dir)` 호출하여 정규화
  - [x] 2.3: `vertex.toString(q, r, dir)` 또는 직접 키 생성
  - [x] 2.4: 중복 체크 (settlements와 cities 모두 확인)
  - [x] 2.5: 배치 성공 시 `self.settlements[key] = {player = playerId}` 저장
  - [x] 2.6: 실패 시 `false, "이미 건물이 있습니다"` 반환

- [x] Task 3: 건물 조회 API 구현 (AC: 2)
  - [x] 3.1: `board:getBuilding(q, r, dir)` 메서드 구현
  - [x] 3.2: 정규화 후 settlements 및 cities에서 조회
  - [x] 3.3: 정착지면 `{type="settlement", player=playerId}` 반환
  - [x] 3.4: 도시면 `{type="city", player=playerId}` 반환
  - [x] 3.5: 없으면 `nil` 반환

- [x] Task 4: 도시 업그레이드 API 구현 (AC: 4)
  - [x] 4.1: `board:upgradeToCity(q, r, dir)` 메서드 구현
  - [x] 4.2: 정규화 후 해당 위치에 정착지가 있는지 확인
  - [x] 4.3: 정착지 있으면 settlements에서 제거, cities에 추가
  - [x] 4.4: 정착지 없으면 `false, "정착지가 없습니다"` 반환
  - [x] 4.5: 이미 도시면 `false, "이미 도시입니다"` 반환

- [x] Task 5: 플레이어별 건물 조회 API (AC: 5)
  - [x] 5.1: `board:getPlayerBuildings(playerId)` 메서드 구현
  - [x] 5.2: settlements와 cities 순회하며 해당 플레이어 건물 수집
  - [x] 5.3: 반환 형식: `{{q, r, dir, type}, ...}` 목록

- [x] Task 6: 추가 유틸리티 메서드 (기술 사양 참조)
  - [x] 6.1: `board:hasBuilding(q, r, dir)` - 건물 존재 여부 boolean
  - [x] 6.2: `board:placeCity(playerId, q, r, dir)` - 직접 도시 배치 (선택적)
  - [x] 6.3: `board:getSettlementsOnTile(q, r)` - 타일 인접 정착지 조회
  - [x] 6.4: `board:getCitiesOnTile(q, r)` - 타일 인접 도시 조회

- [x] Task 7: 테스트 작성 (AC: 7)
  - [x] 7.1: 정착지 배치 성공 테스트
  - [x] 7.2: 정착지 조회 테스트 (getBuilding)
  - [x] 7.3: 중복 배치 실패 테스트 (같은 위치)
  - [x] 7.4: 정규화 일관성 테스트 ((0,-1,"S") == (0,0,"N"))
  - [x] 7.5: 도시 업그레이드 테스트
  - [x] 7.6: 업그레이드 실패 테스트 (정착지 없음, 이미 도시)
  - [x] 7.7: getPlayerBuildings 테스트
  - [x] 7.8: hasBuilding 테스트
  - [x] 7.9: 타일 인접 건물 조회 테스트
  - [x] 7.10: 모든 테스트 통과 확인

## Dev Notes

### Architecture Alignment

- **파일 위치**: `src/game/board.lua`
- **의존성**: `src/game/vertex.lua` (정점 정규화), Story 4-1, 4-2 (Board 기본 구현)
- **제약**: `src/game/`은 Love2D 의존 없음 [Source: docs/game-architecture.md#ADR-001]
- **저장 구조**: Map 기반 - ADR-003 준수 [Source: docs/game-architecture.md#ADR-003]

### Key Implementation Details

1. **Map 구조** (Architecture GameState 참조):
   ```lua
   self.settlements = {}  -- settlements["0,1,N"] = {player = 1}
   self.cities = {}       -- cities["0,0,N"] = {player = 1}
   ```

2. **정점 정규화** (Epic 3 vertex.lua 활용):
   - 동일한 물리적 정점의 다른 표현을 통일
   - 예: `(0, -1, "S")`와 `(0, 0, "N")`은 같은 정점

3. **API 시그니처** (Tech-Spec 참조):
   - `board:placeSettlement(playerId, q, r, dir)` → boolean, error
   - `board:getBuilding(q, r, dir)` → building or nil
   - `board:upgradeToCity(q, r, dir)` → boolean, error
   - `board:getPlayerBuildings(playerId)` → table

### Learnings from Previous Story

**From Story 4-2-number-tokens (Status: done)**

- **기존 Board 구조**: `Board.new()`와 `Board.newStandard()` 구현 완료
- **createTilePool/createNumberPool 패턴**: 헬퍼 함수 패턴 활용 가능
- **테스트 패턴**: `tests/game/board_spec.lua`에 BDD 스타일 테스트 추가
- **파일 수정**: `src/game/board.lua`에 메서드 추가하는 증분 작업
- **TODO 참고**: 향후 규칙 보강 (6/8 비인접 등) - 이 스토리와 무관

[Source: docs/sprint-artifacts/4-2-number-tokens.md#Dev-Agent-Record]

### Testing Strategy

- busted BDD 스타일 테스트
- 기존 `tests/game/board_spec.lua`에 테스트 추가
- 엣지 케이스: 정규화 일관성, 중복 배치, 업그레이드 조건

### References

- [Source: docs/epics.md#Story-4.3]
- [Source: docs/sprint-artifacts/tech-spec-epic-4.md#Story-4-3]
- [Source: docs/game-architecture.md#Data-Architecture]
- [Source: docs/game-architecture.md#ADR-003]

## Dev Agent Record

### Context Reference

- docs/sprint-artifacts/4-3-settlement-city-placement.context.xml

### Agent Model Used

Claude Opus 4.5 (claude-opus-4-5-20251101)

### Debug Log References

- Task 1: Board.new()에 settlements, cities Map 추가. 키는 정규화된 정점 문자열 "q,r,dir", 값은 {player = playerId}.
- Task 2-6: placeSettlement, getBuilding, upgradeToCity, getPlayerBuildings, hasBuilding, placeCity, getSettlementsOnTile, getCitiesOnTile 메서드 구현. 정규화를 위해 vertexKey 헬퍼 함수 추가.
- Task 7: 31개 테스트 추가 (56개 총 board 테스트), 전체 176개 테스트 통과

### Completion Notes List

- ✅ 모든 AC 충족 확인
- ✅ 정점 정규화를 통한 중복 감지 정상 동작 ((0,-1,S) == (0,0,N))
- ✅ getSettlementsOnTile/getCitiesOnTile에 중복 방지 로직 추가 (seen 테이블)
- ✅ 기존 타일 관련 테스트 모두 통과 (회귀 없음)

### File List

**Modified:**
- src/game/board.lua - settlements/cities Map 추가, 건물 배치/조회/업그레이드 API 구현
- tests/game/board_spec.lua - Story 4-3 테스트 31개 추가

## Senior Developer Review (AI)

### Reviewer
BMad

### Date
2025-12-01

### Outcome
**✅ APPROVE**

모든 Acceptance Criteria 구현 확인, 모든 Task 검증 완료, 테스트 통과, Architecture 준수.

### Summary

Story 4-3 정착지/도시 배치 기능이 완전히 구현되었습니다:
- `Board.new()`에 `settlements`, `cities` Map 구조 추가
- 정점 정규화를 통한 중복 감지 정상 동작
- 모든 API (placeSettlement, getBuilding, upgradeToCity, getPlayerBuildings 등) 구현
- 56개 테스트 모두 통과 (31개 신규 + 25개 기존)

### Key Findings

**HIGH severity: 없음**
**MEDIUM severity: 없음**
**LOW severity:**
- Note: `getSettlementsOnTile`/`getCitiesOnTile` 정점 목록 중복 → 헬퍼 추출 가능하나 현재 명확함

### Acceptance Criteria Coverage

| AC | Description | Status | Evidence |
|---|---|---|---|
| AC4-3-1 | placeSettlement 배치 및 true 반환 | ✅ IMPLEMENTED | `board.lua:192-206` |
| AC4-3-2 | getBuilding 반환 형식 | ✅ IMPLEMENTED | `board.lua:215-226` |
| AC4-3-3 | 중복 배치 시 false + 에러 | ✅ IMPLEMENTED | `board.lua:195-201` |
| AC4-3-4 | upgradeToCity 정착지→도시 | ✅ IMPLEMENTED | `board.lua:235-254` |
| AC4-3-5 | getPlayerBuildings 목록 | ✅ IMPLEMENTED | `board.lua:261-281` |
| AC4-3-6 | 정규화 중복 감지 | ✅ IMPLEMENTED | `board.lua:179-182` |
| AC4-3-7 | 테스트 통과 | ✅ IMPLEMENTED | 56개 테스트 통과 |

**Summary: 7 of 7 acceptance criteria fully implemented**

### Task Completion Validation

| Task | Marked | Verified | Evidence |
|---|---|---|---|
| Task 1: 건물 저장 구조 | [x] | ✅ | `board.lua:77-86` |
| Task 2: placeSettlement API | [x] | ✅ | `board.lua:192-206` |
| Task 3: getBuilding API | [x] | ✅ | `board.lua:215-226` |
| Task 4: upgradeToCity API | [x] | ✅ | `board.lua:235-254` |
| Task 5: getPlayerBuildings API | [x] | ✅ | `board.lua:261-281` |
| Task 6: 유틸리티 메서드 | [x] | ✅ | `board.lua:290-389` |
| Task 7: 테스트 작성 | [x] | ✅ | `board_spec.lua:296-659` |

**Summary: 31 of 31 completed tasks verified, 0 questionable, 0 false completions**

### Test Coverage and Gaps

- ✅ 모든 AC에 대응하는 테스트 존재
- ✅ 정규화 일관성 테스트 포함
- ✅ 엣지 케이스 (중복 배치, 업그레이드 실패 등) 커버

### Architectural Alignment

- ✅ ADR-001: src/game/ 순수 Lua (Love2D 의존 없음)
- ✅ ADR-003: Map 기반 건물 저장, 정규화된 키
- ✅ 함수명 camelCase 준수
- ✅ 에러 핸들링 패턴 (false, error_message)

### Security Notes

- N/A (게임 로직, 외부 입력 없음)

### Best-Practices and References

- Red Blob Games 헥스 좌표계: https://www.redblobgames.com/grids/hexagons/
- Lua 5.1 Reference: https://www.lua.org/manual/5.1/

### Action Items

**Code Changes Required:**
- 없음

**Advisory Notes:**
- Note: `getSettlementsOnTile`/`getCitiesOnTile` 정점 목록을 별도 헬퍼로 추출하면 코드 중복 감소 가능 (선택적 리팩토링)

