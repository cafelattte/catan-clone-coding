# Story 7.1: 턴 순서 관리

Status: review

## Story

As a 게임 시스템,
I want 플레이어 턴 순서를 관리할 수 있어,
so that 공정한 게임 진행 가능.

## Acceptance Criteria

### AC 7-1.1: 현재 플레이어 조회
- [x] GameState with 4 players일 때 game:getCurrentPlayer() 호출 시 현재 턴 플레이어 반환
- [x] 2인, 3인, 4인 게임 모두 지원

### AC 7-1.2: 턴 종료 및 다음 플레이어
- [x] 플레이어1 턴에서 game:endTurn() 호출 시 현재 플레이어 = 플레이어2
- [x] 플레이어2 턴에서 game:endTurn() 호출 시 현재 플레이어 = 플레이어3
- [x] 플레이어3 턴에서 game:endTurn() 호출 시 현재 플레이어 = 플레이어4

### AC 7-1.3: 순환 (Wrap-around)
- [x] 플레이어4 턴에서 game:endTurn() 호출 시 현재 플레이어 = 플레이어1 (순환)
- [x] 2인 게임: 플레이어2 → 플레이어1
- [x] 3인 게임: 플레이어3 → 플레이어1

### AC 7-1.4: 라운드 카운터
- [x] 모든 플레이어가 한 번씩 턴을 마치면 라운드 증가
- [x] game:getRound() 함수로 현재 라운드 조회 가능

## Tasks / Subtasks

- [x] Task 1: GameState 기본 구조 구현 (AC: 7-1.1, 7-1.2, 7-1.3, 7-1.4)
  - [x] 1.1 src/game/game_state.lua 파일 생성
  - [x] 1.2 GameState.new(playerCount) 생성자 구현
  - [x] 1.3 turn 구조체 초기화 (current, phase, round)
  - [x] 1.4 players 배열 초기화 (Player 객체들)
  - [x] 1.5 config 구조체 초기화 (playerCount, victoryTarget)

- [x] Task 2: 플레이어 조회 API 구현 (AC: 7-1.1)
  - [x] 2.1 getCurrentPlayer() 함수 구현 - Player 객체 반환
  - [x] 2.2 getCurrentPlayerId() 함수 구현 - 플레이어 인덱스 반환
  - [x] 2.3 getPlayer(id) 함수 구현 - 특정 플레이어 조회

- [x] Task 3: 턴 종료 및 순환 구현 (AC: 7-1.2, 7-1.3, 7-1.4)
  - [x] 3.1 nextPlayer() 함수 구현 - 모듈로 연산으로 순환
  - [x] 3.2 endTurn() 함수 구현 - nextPlayer 호출 + 라운드 증가 체크
  - [x] 3.3 getRound() 함수 구현

- [x] Task 4: 테스트 작성 (AC: All)
  - [x] 4.1 tests/game/game_state_spec.lua 생성
  - [x] 4.2 2인 게임 턴 순환 테스트
  - [x] 4.3 3인 게임 턴 순환 테스트
  - [x] 4.4 4인 게임 턴 순환 테스트
  - [x] 4.5 라운드 카운터 테스트
  - [x] 4.6 경계값 테스트 (플레이어4 → 플레이어1)

## Dev Notes

### 기술적 고려사항

- tech-spec-epic-7.md의 GameState 구조 참조
- 기존 모듈들과의 의존성: Board, Player, Dice, Rules
- 이 스토리는 GameState의 기초 - 페이즈 관리(7-2)의 선행 작업

### GameState 구조 (tech-spec 참조)

```lua
local GameState = {
  board = nil,           -- Board 객체 (Story 7-2에서 연결)
  players = {},          -- Player 객체 배열
  mode = "playing",      -- "setup" | "playing" | "finished"

  turn = {
    current = 1,         -- 현재 플레이어 인덱스 (1-based)
    phase = "roll",      -- "roll" | "main" (Story 7-2에서 구현)
    round = 1,           -- 현재 라운드
  },

  config = {
    playerCount = 4,
    victoryTarget = 10,
  },
}
```

### 핵심 로직 (nextPlayer)

```lua
function GameState:nextPlayer()
  local prevPlayer = self.turn.current
  self.turn.current = (self.turn.current % self.config.playerCount) + 1

  -- 플레이어1로 돌아오면 라운드 증가
  if self.turn.current == 1 then
    self.turn.round = self.turn.round + 1
  end
end
```

### 의존성

- Player 모듈 (Epic 2): 플레이어 객체 생성
- classic.lua: 클래스 시스템

### Project Structure Notes

- 새 파일 위치: `src/game/game_state.lua`
- 테스트 파일 위치: `tests/game/game_state_spec.lua`
- Architecture 문서 경로 준수: src/game/ 디렉토리

### References

- [Source: docs/sprint-artifacts/tech-spec-epic-7.md#Data-Models-and-Contracts]
- [Source: docs/sprint-artifacts/tech-spec-epic-7.md#AC-7-1]
- [Source: docs/game-architecture.md#GameState-구조]
- [Source: docs/epics.md#Story-7.1]

---

### Learnings from Previous Story

**From Story 6-5-vertex-edge-selection (Status: done)**

- **Epic 6 완료**: Visual Experience 에픽의 마지막 스토리 완료
- **New Functions in BoardView**: drawVertexHighlight, drawEdgeHighlight, drawHighlights
- **Colors.UI 확장**: highlight_hover 색상 추가
- **main.lua 선택 모드 시스템**: 키보드 단축키(S/C/R/ESC), 호버 감지, 클릭 처리 구현됨
- **모든 테스트 통과**: 293개 테스트 통과 상태
- **Input 모듈 재사용 패턴**: pixelToVertex, pixelToEdge 등 5개 함수 활용 가능

[Source: docs/sprint-artifacts/6-5-vertex-edge-selection.md#Dev-Agent-Record]

---

## Dev Agent Record

### Context Reference

- docs/sprint-artifacts/7-1-turn-order.context.xml

### Agent Model Used

Claude Opus 4.5 (claude-opus-4-5-20251101)

### Debug Log References

- 2025-12-01: GameState 구현 계획 - tech-spec의 구조 참조, classic.lua 패턴 활용

### Completion Notes List

- **구현 완료**: GameState 클래스 전체 구현
  - 생성자, 플레이어 관리, 턴 순환, 라운드 카운터 모두 구현
  - tech-spec-epic-7.md 구조 100% 준수
  - Story 7-2를 위한 phase/mode/board 필드 미리 정의 (nil 초기화)
- **테스트 완료**: 32개 테스트 케이스 작성 및 통과
  - 2인/3인/4인 게임 모두 커버
  - wrap-around 경계 조건 테스트 완료
  - 라운드 증가 로직 검증 완료
- **전체 테스트**: 325개 테스트 통과 (기존 293 + 신규 32)
- **변경 사항 없음**: 기존 모듈 수정 없이 새 파일만 추가

### File List

**Created:**
- src/game/game_state.lua - GameState 클래스 (턴 순서 관리)
- tests/game/game_state_spec.lua - GameState 테스트 (32개)

---

## Senior Developer Review (AI)

### Reviewer
BMad

### Date
2025-12-01

### Outcome
**✅ APPROVE**

모든 Acceptance Criteria가 충족되었고, 모든 Task가 검증 완료되었습니다. 코드 품질이 우수하고 프로젝트 아키텍처 제약사항을 준수합니다.

### Summary

Story 7-1은 GameState 모듈을 통해 턴 순서 관리 기능을 완전히 구현했습니다:
- 2/3/4인 게임 플레이어 순환
- 모듈로 연산 기반 wrap-around
- 라운드 카운터
- 32개 테스트 케이스 (100% 통과)

### Key Findings

**HIGH Severity:** None

**MEDIUM Severity:** None

**LOW Severity:** None (Advisory notes only)

### Acceptance Criteria Coverage

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| 7-1.1 | 현재 플레이어 조회 | ✅ IMPLEMENTED | `game_state.lua:49-51, 55-57` |
| 7-1.2 | 턴 종료 및 다음 플레이어 | ✅ IMPLEMENTED | `game_state.lua:71-72, 82-84` |
| 7-1.3 | 순환 (Wrap-around) | ✅ IMPLEMENTED | `game_state.lua:72` modulo 연산 |
| 7-1.4 | 라운드 카운터 | ✅ IMPLEMENTED | `game_state.lua:74-77, 88-90` |

**Summary:** 4 of 4 acceptance criteria fully implemented

### Task Completion Validation

| Task | Subtasks | Marked | Verified | Evidence |
|------|----------|--------|----------|----------|
| Task 1: GameState 기본 구조 | 5 | [x] | ✅ | `game_state.lua:11-45` |
| Task 2: 플레이어 조회 API | 3 | [x] | ✅ | `game_state.lua:49-67` |
| Task 3: 턴 종료 및 순환 | 3 | [x] | ✅ | `game_state.lua:71-90` |
| Task 4: 테스트 작성 | 6 | [x] | ✅ | `game_state_spec.lua:1-301` |

**Summary:** 23 of 23 completed tasks verified, 0 questionable, 0 false completions

### Test Coverage and Gaps

- **Unit Tests:** 32개 테스트 케이스 (100% 통과)
- **Coverage Areas:**
  - 생성자 테스트 (2/3/4인)
  - 플레이어 조회 API 테스트
  - 턴 순환 테스트 (모든 게임 사이즈)
  - 라운드 카운터 테스트
  - 경계값 테스트
  - 통합 시나리오 테스트
- **Gaps:** None identified

### Architectural Alignment

- ✅ src/game/ 디렉토리 순수 Lua 구현 (Love2D 의존 없음)
- ✅ classic 라이브러리 클래스 패턴 사용
- ✅ 네이밍 컨벤션 준수 (snake_case 파일, PascalCase 클래스, camelCase 함수)
- ✅ 1-based 인덱스 사용
- ✅ tech-spec-epic-7.md GameState 구조 100% 준수
- ✅ Story 7-2 대비 필드 미리 정의 (mode, phase, board, setup, diceResult, winner)

### Security Notes

보안 우려 사항 없음 - 순수 게임 로직 모듈, 외부 입력/파일/네트워크 없음

### Best-Practices and References

- [Lua Style Guide](https://lua-users.org/wiki/LuaStyleGuide)
- [classic library](https://github.com/rxi/classic) - 클래스 시스템
- [busted](https://lunarmodules.github.io/busted/) - BDD 스타일 테스트

### Action Items

**Code Changes Required:**
(None - story approved)

**Advisory Notes:**
- Note: playerCount 입력 검증은 Story 7-3 메인 메뉴 UI에서 처리 예정 (설계 의도)

