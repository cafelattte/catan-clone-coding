# Story 7.6: 초기 배치 UI

Status: done

## Story

As a 플레이어,
I want 게임 시작 시 초기 정착지와 도로를 배치할 수 있어,
so that 카탄 규칙에 맞는 완전한 게임 플레이 가능.

## Acceptance Criteria

### AC 7-6.1: Setup 모드 진입
- [x] 새 게임 시작 시 mode = "setup"
- [x] setup.round = 1, setup.direction = "forward"
- [x] setup.currentPlayer = 1, setup.phase = "settlement"
- [x] "Player X: Place Settlement" 안내 표시

### AC 7-6.2: 정착지 배치 (Setup)
- [x] 유효한 정점 하이라이트 (distance rule 적용, 연결 규칙 무시)
- [x] 정점 클릭 시 Actions.buildSettlementFree() 실행
- [x] 배치 성공 후 setup.phase = "road"로 전환
- [x] "Player X: Place Road" 안내 표시

### AC 7-6.3: 도로 배치 (Setup)
- [x] 방금 배치한 정착지에 연결된 변만 하이라이트
- [x] 변 클릭 시 Actions.buildRoadFree() 실행
- [x] 배치 성공 후 advanceSetup() 호출

### AC 7-6.4: Snake Draft 순서 (Round 1)
- [x] Round 1: 플레이어 1 → 2 → 3 → 4 순서
- [x] 각 플레이어: 정착지 1개 + 도로 1개 배치
- [x] 플레이어 4 완료 시 Round 2 시작

### AC 7-6.5: Snake Draft 순서 (Round 2)
- [x] Round 2: 플레이어 4 → 3 → 2 → 1 역순
- [x] 각 플레이어: 정착지 1개 + 도로 1개 배치
- [x] 두 번째 정착지 인접 타일 자원 지급

### AC 7-6.6: Setup 완료 및 Playing 전환
- [x] 플레이어 1의 Round 2 배치 완료 시
- [x] mode = "playing", turn.current = 1, phase = "roll"
- [x] 일반 게임 플로우 시작

## Tasks / Subtasks

- [x] Task 1: GameState setup 구조체 구현 (AC: 7-6.1)
  - [x] 1.1 GameState:new()에서 mode = "setup" 초기화
  - [x] 1.2 setup 구조체 초기화 (round, direction, phase, currentPlayer)
  - [x] 1.3 GameState:isSetup() 헬퍼 함수

- [x] Task 2: advanceSetup() 상태 전이 로직 (AC: 7-6.3, 7-6.4, 7-6.5, 7-6.6)
  - [x] 2.1 settlement → road 페이즈 전환
  - [x] 2.2 road → 다음 플레이어 전환 (forward)
  - [x] 2.3 Round 1 → Round 2 전환 (direction = "reverse")
  - [x] 2.4 Round 2 완료 → mode = "playing" 전환

- [x] Task 3: Setup UI 표시 (AC: 7-6.1, 7-6.2, 7-6.3)
  - [x] 3.1 setup 모드 안내 텍스트 표시 ("Player X: Place Settlement/Road")
  - [x] 3.2 액션 버튼 숨김 (setup 모드에서는 버튼 불필요)
  - [x] 3.3 현재 라운드/플레이어 정보 표시

- [x] Task 4: Setup 정착지 배치 연동 (AC: 7-6.2)
  - [x] 4.1 setup 모드에서 유효 정점 계산 (isInitialPlacement = true)
  - [x] 4.2 정점 클릭 시 Actions.buildSettlementFree() 호출
  - [x] 4.3 마지막 배치 정착지 위치 저장 (도로 연결용)
  - [x] 4.4 배치 성공 후 setup.phase = "road"

- [x] Task 5: Setup 도로 배치 연동 (AC: 7-6.3)
  - [x] 5.1 마지막 정착지 인접 변만 유효 위치로 필터링
  - [x] 5.2 변 클릭 시 Actions.buildRoadFree() 호출
  - [x] 5.3 배치 성공 후 advanceSetup() 호출

- [x] Task 6: Round 2 자원 지급 (AC: 7-6.5)
  - [x] 6.1 Round 2 정착지 배치 시 인접 타일 확인
  - [x] 6.2 각 인접 타일의 자원 1개씩 플레이어에게 지급
  - [x] 6.3 사막 타일은 자원 없음 처리

- [x] Task 7: 테스트 및 검증 (AC: All)
  - [x] 7.1 2인/3인/4인 게임 각각 setup 순서 확인
  - [x] 7.2 Round 1 → Round 2 전환 확인
  - [x] 7.3 Round 2 자원 지급 확인
  - [x] 7.4 setup 완료 후 playing 모드 전환 확인
  - [x] 7.5 전체 게임 플로우 테스트 (setup → roll → build → end turn)

## Dev Notes

### 기술적 고려사항

- **GameState.setup 구조체**: tech-spec-epic-7.md에 이미 정의됨
- **Snake Draft 로직**: advanceSetup() 함수로 상태 전이
- **기존 Actions 활용**: buildSettlementFree(), buildRoadFree() (Story 5-5에서 구현됨)
- **distance rule**: 초기 배치 시에도 적용 (다른 정착지와 2칸 이상 거리)
- **연결 규칙**: 초기 배치 시 도로 연결 불필요 (정착지 먼저 배치)

### Setup 상태 구조 (tech-spec-epic-7.md 참조)

```lua
setup = {
  round = 1,             -- 1 또는 2
  direction = "forward", -- "forward" | "reverse"
  phase = "settlement",  -- "settlement" | "road"
  currentPlayer = 1,     -- 현재 배치할 플레이어
}
```

### advanceSetup() 상태 전이

```lua
function GameState:advanceSetup()
  if self.setup.phase == "settlement" then
    self.setup.phase = "road"
  else
    self.setup.phase = "settlement"
    if self.setup.direction == "forward" then
      if self.setup.currentPlayer < self.config.playerCount then
        self.setup.currentPlayer = self.setup.currentPlayer + 1
      else
        self.setup.round = 2
        self.setup.direction = "reverse"
      end
    else
      if self.setup.currentPlayer > 1 then
        self.setup.currentPlayer = self.setup.currentPlayer - 1
      else
        self.mode = "playing"
        self.turn.current = 1
        self.turn.phase = "roll"
      end
    end
  end
end
```

### 의존성

- GameState (src/game/game_state.lua) - setup 구조체, advanceSetup()
- Actions (src/game/actions.lua) - buildSettlementFree(), buildRoadFree()
- Rules (src/game/rules.lua) - getValidSettlementLocations(board, playerId, true)
- Board (src/game/board.lua) - getAdjacentTiles()
- game.lua (src/scenes/game.lua) - UI 통합

### References

- [Source: docs/sprint-artifacts/tech-spec-epic-7.md#Setup-Mode]
- [Source: docs/epics.md#Story-7.6]

---

## Dev Agent Record

### Context Reference

- docs/sprint-artifacts/7-6-setup-phase-ui.context.xml

### Agent Model Used

- Claude Opus 4.5

### Debug Log References

- TDD 방식으로 테스트 먼저 작성 후 구현
- 기존 테스트에서 mode가 "playing"을 기대하던 부분 수정

### Completion Notes List

- GameState에 setup 구조체 및 advanceSetup() 메서드 구현
- Snake Draft 로직 (Round 1: forward, Round 2: reverse) 완료
- Setup UI: 안내 텍스트, 버튼 숨김, 하이라이트 기능 구현
- Round 2 정착지 배치 시 인접 타일 자원 자동 지급
- 2인/3인/4인 게임 모두 통합 테스트 통과

### File List

- src/game/game_state.lua (수정: setup 구조체, isSetup(), getSetupPlayer(), getSetupPhase(), advanceSetup())
- src/scenes/game.lua (수정: Setup UI 표시, 클릭 핸들링, 자원 지급 연동)
- tests/game/game_state_spec.lua (수정: Setup 모드 테스트 87개 추가)

---

## Code Review

### Review Date
2025-12-02

### Reviewer
Claude Opus 4.5 (Link Freeman - Senior Game Developer)

### Review Result
✅ **APPROVE**

### Summary
Story 7-6 "초기 배치 UI"가 성공적으로 구현되었습니다. Snake Draft 패턴(Round 1: 정순, Round 2: 역순)이 올바르게 작동하며, 모든 AC와 Task가 완료되었습니다.

### AC Verification

| AC | Status | Evidence |
|----|--------|----------|
| AC 7-6.1: Setup 모드 진입 | ✅ Pass | `game_state.lua:36` - mode = "setup" 초기화, `game_state.lua:42-48` - setup 구조체 |
| AC 7-6.2: 정착지 배치 | ✅ Pass | `game.lua` handleSetupClick() - buildSettlementFree() 호출 및 phase 전환 |
| AC 7-6.3: 도로 배치 | ✅ Pass | `game.lua` getSetupRoadLocations() - 마지막 정착지 인접 변만 하이라이트 |
| AC 7-6.4: Snake Draft Round 1 | ✅ Pass | `game_state.lua:86-95` - forward 방향 로직 |
| AC 7-6.5: Snake Draft Round 2 | ✅ Pass | `game_state.lua:96-106` - reverse 방향 및 자원 지급 |
| AC 7-6.6: Playing 전환 | ✅ Pass | `game_state.lua:101-105` - mode = "playing" 설정 |

### Task Verification

| Task | Status | Evidence |
|------|--------|----------|
| Task 1: setup 구조체 | ✅ Complete | `game_state.lua:42-48`, `isSetup()`, `getSetupPlayer()`, `getSetupPhase()` |
| Task 2: advanceSetup() | ✅ Complete | `game_state.lua:77-109` - 완전한 상태 전이 로직 |
| Task 3: Setup UI | ✅ Complete | `game.lua` drawSetupUI() - 라운드/플레이어/페이즈 표시 |
| Task 4: 정착지 배치 연동 | ✅ Complete | updateValidLocations(), handleSetupClick() |
| Task 5: 도로 배치 연동 | ✅ Complete | getSetupRoadLocations(), handleSetupClick() |
| Task 6: Round 2 자원 지급 | ✅ Complete | Rules.getInitialResources() 호출 |
| Task 7: 테스트 | ✅ Complete | 87개 Setup 테스트, 380개 전체 테스트 통과 |

### Code Quality

- **Architecture**: GameState의 setup 구조체가 tech-spec과 일치
- **Patterns**: 기존 코드베이스 패턴 준수
- **Testing**: 포괄적인 테스트 커버리지 (2/3/4인 게임 통합 테스트 포함)
- **Error Handling**: 적절한 nil 체크 및 상태 검증

### Observations (Non-blocking)

1. `lastPlacedSettlement`가 game.lua의 모듈 로컬 변수로 선언됨 - GameState.setup에 저장하는 것도 고려할 수 있음 (현재 구현도 정상 동작)

### Action Items
없음

### Conclusion
모든 Acceptance Criteria가 충족되고, 모든 Task가 완료되었으며, 테스트가 통과합니다. 코드 품질이 우수하고 기존 아키텍처와 일관됩니다. **APPROVE** 합니다.
