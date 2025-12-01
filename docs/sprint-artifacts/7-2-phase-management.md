# Story 7.2: 페이즈 관리

Status: done

## Story

As a 게임 시스템,
I want 턴 내 페이즈(roll, main)를 관리할 수 있어,
so that 정해진 순서로 액션 수행 가능.

## Acceptance Criteria

### AC 7-2.1: 초기 페이즈 상태
- [ ] 턴 시작 시 game:getPhase() 호출 → "roll" 반환
- [ ] 새 게임 시작 시 mode = "playing", phase = "roll"

### AC 7-2.2: 주사위 굴림 및 페이즈 전환
- [ ] roll 페이즈에서 game:rollDice() 호출 시 {die1, die2, sum} 반환
- [ ] rollDice() 완료 후 페이즈 = "main"
- [ ] 주사위 결과가 game.diceResult에 저장됨
- [ ] 7이 아닌 숫자일 때 자원 분배 실행 (Rules.distributeResources 연동)

### AC 7-2.3: 턴 종료 시 페이즈 리셋
- [ ] main 페이즈에서 game:endTurn() 호출 시 다음 플레이어로 전환
- [ ] endTurn() 후 페이즈 = "roll"로 리셋
- [ ] diceResult = nil로 초기화

### AC 7-2.4: 페이즈 기반 액션 제한
- [ ] game:canRoll() - mode == "playing" AND phase == "roll"일 때만 true
- [ ] game:canBuild() - mode == "playing" AND phase == "main"일 때만 true
- [ ] roll 페이즈에서 건설 시도 시 실패 (canBuild() = false)
- [ ] main 페이즈에서 주사위 굴림 시도 시 실패 (canRoll() = false)

### AC 7-2.5: 승리 체크 연동
- [ ] 건설 완료 직후 game:checkVictory() 호출
- [ ] 승자 있으면 mode = "finished", winner 설정
- [ ] 승자 없으면 게임 계속

## Tasks / Subtasks

- [x] Task 1: 페이즈 관리 기본 구현 (AC: 7-2.1, 7-2.3)
  - [x] 1.1 GameState에 getPhase() 함수 추가
  - [x] 1.2 GameState에 setPhase() 함수 추가
  - [x] 1.3 endTurn()에서 phase = "roll" 리셋 추가
  - [x] 1.4 endTurn()에서 diceResult = nil 초기화 추가

- [x] Task 2: 주사위 굴림 및 자원 분배 연동 (AC: 7-2.2)
  - [x] 2.1 GameState에 rollDice() 함수 구현
  - [x] 2.2 rollDice()에서 Dice 모듈 호출
  - [x] 2.3 rollDice()에서 diceResult 저장
  - [x] 2.4 rollDice()에서 phase = "main" 설정
  - [x] 2.5 rollDice()에서 Rules.distributeResources 연동 (7 제외)

- [x] Task 3: 페이즈 기반 액션 제한 (AC: 7-2.4)
  - [x] 3.1 GameState에 canRoll() 함수 구현
  - [x] 3.2 GameState에 canBuild() 함수 구현
  - [x] 3.3 각 함수에서 mode와 phase 체크 로직

- [x] Task 4: 승리 체크 연동 (AC: 7-2.5)
  - [x] 4.1 GameState에 checkVictory() 함수 구현
  - [x] 4.2 checkVictory()에서 Rules.checkVictory 연동
  - [x] 4.3 승자 발견 시 mode = "finished", winner 설정

- [x] Task 5: 테스트 작성 (AC: All)
  - [x] 5.1 game_state_spec.lua에 페이즈 관리 테스트 추가
  - [x] 5.2 초기 페이즈 상태 테스트
  - [x] 5.3 rollDice 후 페이즈 전환 테스트
  - [x] 5.4 endTurn 후 페이즈 리셋 테스트
  - [x] 5.5 canRoll/canBuild 테스트
  - [x] 5.6 승리 체크 연동 테스트
  - [x] 5.7 자원 분배 연동 테스트 (mock 또는 통합)

## Dev Notes

### 기술적 고려사항

- Story 7-1에서 구현한 GameState 확장
- Dice 모듈 (src/game/dice.lua) 연동 필요
- Rules 모듈 (src/game/rules.lua) 연동 필요:
  - Rules.distributeResources(board, players, number)
  - Rules.checkVictory(players, victoryTarget)
- Board 연결 필요 - GameState.board 필드 활용

### GameState 확장 구조 (tech-spec 참조)

```lua
-- Story 7-1에서 구현된 구조에 추가
local GameState = {
  board = nil,           -- Board 객체 (이 스토리에서 연결)
  players = {},          -- Player 객체 배열
  mode = "playing",      -- "setup" | "playing" | "finished"

  turn = {
    current = 1,         -- 현재 플레이어 인덱스 (Story 7-1)
    phase = "roll",      -- "roll" | "main" (이 스토리에서 구현)
    round = 1,           -- 현재 라운드 (Story 7-1)
  },

  diceResult = nil,      -- {die1, die2, sum} 또는 nil
  winner = nil,          -- 승자 플레이어 ID

  config = {
    playerCount = 4,
    victoryTarget = 10,
  },
}
```

### 핵심 API 구현

```lua
function GameState:rollDice()
  if not self:canRoll() then
    return nil, "Cannot roll in current phase"
  end

  local result = Dice.roll()
  self.diceResult = result
  self.turn.phase = "main"

  -- 7이 아닌 경우 자원 분배
  if result.sum ~= 7 and self.board then
    Rules.distributeResources(self.board, self.players, result.sum)
  end

  return result
end

function GameState:canRoll()
  return self.mode == "playing" and self.turn.phase == "roll"
end

function GameState:canBuild()
  return self.mode == "playing" and self.turn.phase == "main"
end

function GameState:checkVictory()
  local winnerId = Rules.checkVictory(self.players, self.config.victoryTarget)
  if winnerId then
    self.mode = "finished"
    self.winner = winnerId
  end
  return winnerId
end
```

### 의존성

- GameState (Story 7-1): 기반 클래스
- Dice 모듈 (Epic 5): 주사위 굴림
- Rules 모듈 (Epic 5): 자원 분배, 승리 체크
- Board 모듈 (Epic 4): 자원 분배에 필요
- Player 모듈 (Epic 2): 자원/점수 관리

### Project Structure Notes

- 수정 파일: `src/game/game_state.lua`
- 테스트 파일: `tests/game/game_state_spec.lua` (확장)
- Architecture 문서 경로 준수: src/game/ 디렉토리

### References

- [Source: docs/sprint-artifacts/tech-spec-epic-7.md#AC-7-2]
- [Source: docs/sprint-artifacts/tech-spec-epic-7.md#Data-Models-and-Contracts]
- [Source: docs/sprint-artifacts/tech-spec-epic-7.md#Workflows-and-Sequencing]
- [Source: docs/game-architecture.md#GameState-구조]
- [Source: docs/epics.md#Story-7.2]

---

### Learnings from Previous Story

**From Story 7-1-turn-order (Status: review)**

- **GameState 클래스 구현 완료**: src/game/game_state.lua에서 기본 구조 완성
  - 생성자, 플레이어 관리, 턴 순환, 라운드 카운터 구현
  - tech-spec-epic-7.md 구조 100% 준수
- **Story 7-2 대비 필드 미리 정의됨**:
  - `mode`, `phase`, `board`, `diceResult`, `winner` 필드가 nil로 초기화되어 있음
  - 이 스토리에서 해당 필드들의 로직 구현 필요
- **테스트 패턴 확립**: 32개 테스트 케이스, BDD 스타일 (describe/it)
- **전체 테스트**: 325개 테스트 통과 상태
- **코드 품질**: Lua 네이밍 컨벤션 준수 (snake_case 파일, PascalCase 클래스, camelCase 함수)

**Files Created in 7-1:**
- `src/game/game_state.lua` - GameState 클래스 기반 (확장 대상)
- `tests/game/game_state_spec.lua` - GameState 테스트 (확장 대상)

**Key Implementation Notes:**
- `turn.phase` 필드는 이미 "roll" 기본값으로 설정됨
- `mode` 필드는 "playing" 기본값으로 설정됨
- 모듈로 연산 기반 플레이어 순환 로직 재사용 가능

[Source: docs/sprint-artifacts/7-1-turn-order.md#Dev-Agent-Record]

---

## Dev Agent Record

### Context Reference

- docs/sprint-artifacts/7-2-phase-management.context.xml

### Agent Model Used

Claude Opus 4.5 (claude-opus-4-5-20251101)

### Debug Log References

### Completion Notes List

- 페이즈 관리 시스템 구현 완료 (getPhase, setPhase, rollDice, canRoll, canBuild, checkVictory)
- turn.phase를 nil → "roll" 기본값으로 변경
- Dice, Rules 모듈 연동 완료
- 30개 신규 테스트 케이스 추가 (총 355개 테스트 통과)
- rules_spec.lua flaky test 근본적 수정: Board.newForTesting() 팩토리 추가 및 distributeResources 테스트를 고정 보드로 전환

### File List

- Modified: `src/game/game_state.lua` - 페이즈 관리 API 추가
- Modified: `tests/game/game_state_spec.lua` - 페이즈 관리 테스트 추가 (30개)
- Modified: `tests/game/rules_spec.lua` - distributeResources 테스트를 고정 테스트 보드 사용으로 변경
- Modified: `src/game/board.lua` - Board.newForTesting() 팩토리 함수 추가

---

## Senior Developer Review (AI)

### Reviewer
BMad

### Date
2025-12-01

### Outcome
**APPROVE** ✅

모든 Acceptance Criteria와 Tasks가 완전히 구현되고 검증되었습니다.

### Summary

Story 7-2 (페이즈 관리)가 성공적으로 구현되었습니다:
- GameState에 페이즈 관리 시스템 추가 (getPhase, setPhase, canRoll, canBuild)
- 주사위 굴림 기능 구현 (rollDice) with Dice/Rules 모듈 연동
- 승리 체크 기능 구현 (checkVictory)
- 30개 신규 테스트 케이스 추가
- Flaky test 근본적 수정 (Board.newForTesting 팩토리)

### Key Findings

*No HIGH or MEDIUM severity issues found.*

**Low Severity:**
- rollDice()에서 7일 때 robber 이동은 아직 미구현 (향후 스토리 범위 - OK)

### Acceptance Criteria Coverage

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC 7-2.1 | 초기 페이즈 상태 | ✅ IMPLEMENTED | game_state.lua:31,36,101-103 |
| AC 7-2.2 | 주사위 굴림 및 페이즈 전환 | ✅ IMPLEMENTED | game_state.lua:125-140 |
| AC 7-2.3 | 턴 종료 시 페이즈 리셋 | ✅ IMPLEMENTED | game_state.lua:87-91 |
| AC 7-2.4 | 페이즈 기반 액션 제한 | ✅ IMPLEMENTED | game_state.lua:113-121 |
| AC 7-2.5 | 승리 체크 연동 | ✅ IMPLEMENTED | game_state.lua:144-151 |

**Summary: 5/5 acceptance criteria fully implemented**

### Task Completion Validation

| Task | Marked | Verified | Evidence |
|------|--------|----------|----------|
| Task 1: 페이즈 관리 기본 구현 | ✅ | ✅ | game_state.lua:87-109 |
| Task 2: 주사위 굴림/자원 분배 | ✅ | ✅ | game_state.lua:125-140 |
| Task 3: 페이즈 기반 액션 제한 | ✅ | ✅ | game_state.lua:113-121 |
| Task 4: 승리 체크 연동 | ✅ | ✅ | game_state.lua:144-151 |
| Task 5: 테스트 작성 | ✅ | ✅ | game_state_spec.lua:302-608 |

**Summary: 22/22 completed tasks verified, 0 questionable, 0 false completions**

### Test Coverage and Gaps

- ✅ 30개 신규 테스트 케이스 추가
- ✅ 전체 355개 테스트 통과
- ✅ BDD 스타일 일관성 유지
- ✅ Flaky test 수정 완료 (Board.newForTesting)

### Architectural Alignment

- ✅ tech-spec-epic-7.md 구조 100% 준수
- ✅ GameState API 시그니처 정확히 일치
- ✅ 모듈 의존성 정확 (Dice, Rules)

### Security Notes

- 로컬 핫시트 게임으로 보안 위험 최소

### Best-Practices and References

- Lua 네이밍 컨벤션 준수 (snake_case 파일, PascalCase 클래스, camelCase 함수)
- 방어적 프로그래밍 패턴 적용
- 결정적 테스트를 위한 팩토리 패턴 도입 (Board.newForTesting)

### Action Items

**Code Changes Required:**
- None

**Advisory Notes:**
- Note: Story 7-3/7-4에서 UI 씬 구현 시 GameState 연동 필요
- Note: 7이 나왔을 때 robber 이동 로직은 향후 스토리에서 구현

---

## Change Log

| Date | Change | Author |
|------|--------|--------|
| 2025-12-01 | Story implementation completed | Dev Agent (Claude Opus 4.5) |
| 2025-12-01 | Senior Developer Review - APPROVED | BMad (AI) |

