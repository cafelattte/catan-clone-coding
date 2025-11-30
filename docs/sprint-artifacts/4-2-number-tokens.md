# Story 4.2: 숫자 토큰 배치

Status: done

## Story

As a 게임 시스템,
I want 각 타일에 숫자 토큰(2-12, 7 제외)이 배치되어,
so that 주사위 결과에 따른 자원 생산 가능.

## Acceptance Criteria

1. **AC4-2-1**: 사막 타일은 숫자 없음 (`number = nil`)
2. **AC4-2-2**: 나머지 18개 타일에 숫자 토큰 배치됨
3. **AC4-2-3**: `board:getTilesWithNumber(n)` 호출 시 해당 숫자인 타일들 반환
4. **AC4-2-4**: 숫자 토큰 분포: 2, 12: 1개씩 / 3-6, 8-11: 2개씩 / 7: 0개
5. **AC4-2-5**: `board:getTile(q, r).number`는 2-6 또는 8-12 범위 (사막 제외)
6. **AC4-2-6**: 테스트 통과: `tests/game/board_spec.lua`

## Tasks / Subtasks

- [x] Task 1: 숫자 토큰 분포 상수 추가 (AC: 4)
  - [x] 1.1: `src/game/constants.lua`에 `NUMBER_TOKENS` 상수 추가
  - [x] 1.2: 분포 정의: {2, 3, 3, 4, 4, 5, 5, 6, 6, 8, 8, 9, 9, 10, 10, 11, 11, 12}

- [x] Task 2: 숫자 토큰 배치 로직 (AC: 1, 2, 4, 5)
  - [x] 2.1: `createNumberPool()` 함수 - 18개 숫자 토큰 목록 생성
  - [x] 2.2: `Board.newStandard()`에서 숫자 토큰 배치 추가
  - [x] 2.3: 사막 타일 건너뛰기 (number = nil 유지)
  - [x] 2.4: 나머지 타일에 숫자 할당

- [x] Task 3: 숫자 조회 API 추가 (AC: 3)
  - [x] 3.1: `board:getTilesWithNumber(n)` 메서드 구현
  - [x] 3.2: 숫자 n과 일치하는 타일 목록 반환

- [x] Task 4: 테스트 작성 (AC: 6)
  - [x] 4.1: 사막 타일 number nil 테스트 (기존 확인)
  - [x] 4.2: 18개 타일 숫자 배치 테스트
  - [x] 4.3: 숫자 분포 검증 테스트 (2, 12: 1개 / 3-11: 2개)
  - [x] 4.4: `getTilesWithNumber()` 테스트
  - [x] 4.5: 숫자 범위 검증 (2-6, 8-12)
  - [x] 4.6: 모든 테스트 통과 확인

## Dev Notes

### Architecture Alignment

- **파일 위치**: `src/game/board.lua`, `src/game/constants.lua`
- **의존성**: Story 4-1 (Board.newStandard 기존 구현)
- **제약**: `src/game/`은 Love2D 의존 없음 [Source: docs/game-architecture.md#ADR-001]

### Key Implementation Details

1. **숫자 토큰 분포** (GDD 기준):
   - 2: 1개, 3: 2개, 4: 2개, 5: 2개, 6: 2개
   - 8: 2개, 9: 2개, 10: 2개, 11: 2개, 12: 1개
   - 7: 0개 (주사위 합 7은 도둑 이동)
   - 총 18개 (19개 타일 - 1개 사막)

2. **기존 구현 확인 필요**:
   - Story 4-1에서 이미 숫자 배치 구현되었을 수 있음
   - `Board.newStandard()` 현재 상태 확인

### Testing Strategy

- busted BDD 스타일 테스트
- 기존 `tests/game/board_spec.lua`에 테스트 추가

### References

- [Source: docs/epics.md#Story-4.2]
- [Source: docs/game-architecture.md#Data-Architecture]
- [Source: docs/GDD.md]

## Dev Agent Record

### Context Reference

- docs/sprint-artifacts/4-2-number-tokens.context.xml

### Agent Model Used

claude-opus-4-5-20251101

### Completion Notes List

- Story 4-1에서 이미 기본 구조 구현되어 있어 증분 작업으로 완료
- NUMBER_TOKENS 상수 추가 (18개 토큰 분포)
- createNumberPool() 헬퍼 함수 구현
- Board.newStandard()에 숫자 토큰 배치 로직 통합
- getTilesWithNumber(n) API 메서드 구현
- 9개 테스트 추가, 총 143개 테스트 통과

### TODO (Future Enhancement)

- [ ] 숫자 토큰 배치 규칙 보강: 현재는 단순 랜덤 셔플이지만, 공식 카탄 규칙에서는 다음 제약이 있음:
  - 6과 8 (고확률 숫자)이 인접 타일에 배치되지 않아야 함
  - 동일 숫자가 인접하지 않아야 함
  - 나선형 또는 알파벳 순서 배치 방식 (공식 셋업 가이드)

### File List

- src/game/constants.lua (modified: NUMBER_TOKENS 상수 추가)
- src/game/board.lua (modified: createNumberPool, newStandard 수정, getTilesWithNumber 추가)
- tests/game/board_spec.lua (modified: 9개 테스트 추가)

### Change Log

- 2025-11-30: Story file drafted
- 2025-11-30: Implementation complete, all tests passing (143)
- 2025-11-30: Senior Developer Review - APPROVE

## Senior Developer Review (AI)

### Reviewer
BMad

### Date
2025-11-30

### Outcome
**APPROVE** - 모든 AC 구현 완료, 모든 Task 검증됨, 이슈 없음

### Summary
Story 4-2 숫자 토큰 배치가 성공적으로 구현되었습니다. NUMBER_TOKENS 상수 추가, createNumberPool() 헬퍼 함수, Board.newStandard() 수정, getTilesWithNumber() API가 모두 정확하게 구현되었으며, 9개의 테스트가 추가되어 모든 AC를 검증합니다.

### Key Findings

없음 - 모든 구현이 요구사항에 정확히 부합

### Acceptance Criteria Coverage

| AC | Description | Status | Evidence |
|---|---|---|---|
| AC4-2-1 | 사막 타일은 숫자 없음 | ✅ IMPLEMENTED | `board.lua:103-109` |
| AC4-2-2 | 18개 타일에 숫자 토큰 배치 | ✅ IMPLEMENTED | `board.lua:106-108` |
| AC4-2-3 | getTilesWithNumber(n) API | ✅ IMPLEMENTED | `board.lua:155-163` |
| AC4-2-4 | 숫자 토큰 분포 정확 | ✅ IMPLEMENTED | `constants.lua:71-73` |
| AC4-2-5 | 숫자 범위 2-6, 8-12 | ✅ IMPLEMENTED | `constants.lua:71-73` |
| AC4-2-6 | 테스트 통과 | ✅ IMPLEMENTED | 23/23 테스트 통과 |

**Summary: 6 of 6 acceptance criteria fully implemented**

### Task Completion Validation

| Task | Marked As | Verified As | Evidence |
|---|---|---|---|
| Task 1: NUMBER_TOKENS 상수 | [x] | ✅ VERIFIED | `constants.lua:68-73` |
| Task 2: 숫자 토큰 배치 로직 | [x] | ✅ VERIFIED | `board.lua:64-70, 87-125` |
| Task 3: getTilesWithNumber API | [x] | ✅ VERIFIED | `board.lua:155-163` |
| Task 4: 테스트 작성 | [x] | ✅ VERIFIED | `board_spec.lua:179-294` |

**Summary: 18 of 18 completed tasks verified, 0 questionable, 0 false completions**

### Test Coverage and Gaps

**테스트 현황:**
- 사막 타일 number nil: ✅ 테스트됨 (`board_spec.lua:160-177`)
- 18개 타일 숫자 배치: ✅ 테스트됨 (`board_spec.lua:182-194`)
- 숫자 분포 검증: ✅ 테스트됨 (`board_spec.lua:196-220`)
- 숫자 범위 검증: ✅ 테스트됨 (`board_spec.lua:222-242`)
- getTilesWithNumber API: ✅ 테스트됨 (`board_spec.lua:245-294`)

**테스트 품질:** 우수 - 엣지 케이스(7, 1, 13) 포함

### Architectural Alignment

- ✅ ADR-001 준수: `src/game/` 모듈은 Love2D 의존성 없음
- ✅ 네이밍 컨벤션 준수: UPPER_SNAKE (상수), camelCase (함수)
- ✅ 기존 패턴 활용: createTilePool() 패턴으로 createNumberPool() 구현

### Security Notes

해당 없음 - 게임 로직 모듈, 외부 입력 없음

### Best-Practices and References

- Fisher-Yates 셔플 알고리즘 올바르게 구현
- 상수 분리로 유지보수성 확보
- 순수 함수 설계로 테스트 용이

### Action Items

**Code Changes Required:**
없음

**Advisory Notes:**
- Note: 향후 숫자 토큰 배치 규칙 보강 고려 (6/8 비인접, 동일 숫자 비인접) - TODO로 기록됨
