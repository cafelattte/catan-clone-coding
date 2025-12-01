# Story 7.5: 게임 플레이 통합

Status: done

## Story

As a 플레이어,
I want UI 버튼으로 게임을 진행할 수 있어,
so that 마우스만으로 카탄 게임을 플레이 가능.

## Acceptance Criteria

### AC 7-5.1: Roll Dice 버튼
- [x] "Roll Dice" 버튼 표시
- [x] 버튼 클릭 시 gameState:rollDice() 호출
- [x] 주사위 결과 HUD에 표시 (기존 HUD 활용)
- [x] roll 페이즈가 아니면 버튼 비활성화 (회색 처리)

### AC 7-5.2: Settlement 버튼
- [x] "Settlement" 버튼 표시
- [x] 버튼 클릭 시 settlement 선택 모드 진입
- [x] 유효한 정점 하이라이트 (기존 하이라이트 시스템 활용)
- [x] 자원 부족 시 버튼 비활성화

### AC 7-5.3: Settlement 건설 실행
- [x] settlement 선택 모드에서 유효한 정점 클릭
- [x] Actions.buildSettlement() 실행
- [x] 건물 렌더링 업데이트 (board.buildings 반영)
- [x] 승리 체크 후 필요 시 game_over 전환

### AC 7-5.4: City 버튼
- [x] "City" 버튼 표시
- [x] 버튼 클릭 시 city 선택 모드 진입
- [x] 업그레이드 가능한 정착지 하이라이트
- [x] 자원 부족 시 버튼 비활성화

### AC 7-5.5: City 건설 실행
- [x] city 선택 모드에서 유효한 정점 클릭 (기존 정착지)
- [x] Actions.buildCity() 실행
- [x] 건물 렌더링 업데이트 (settlement → city)
- [x] 승리 체크 후 필요 시 game_over 전환

### AC 7-5.6: Road 버튼
- [x] "Road" 버튼 표시
- [x] 버튼 클릭 시 road 선택 모드 진입
- [x] 유효한 변 하이라이트 (기존 하이라이트 시스템 활용)
- [x] 자원 부족 시 버튼 비활성화

### AC 7-5.7: Road 건설 실행
- [x] road 선택 모드에서 유효한 변 클릭
- [x] Actions.buildRoad() 실행
- [x] 건물 렌더링 업데이트 (board.roads 반영)

### AC 7-5.8: End Turn 버튼
- [x] "End Turn" 버튼 표시
- [x] 버튼 클릭 시 gameState:endTurn() 호출
- [x] 다음 플레이어로 전환 (HUD 업데이트)
- [x] roll 페이즈가 아닌 경우에만 활성화 (main 페이즈)

## Tasks / Subtasks

- [x] Task 1: 액션 버튼 패널 구현 (AC: 7-5.1, 7-5.2, 7-5.4, 7-5.6, 7-5.8)
  - [x] 1.1 game.lua에 버튼 정의 테이블 추가 (buttons = {})
  - [x] 1.2 버튼 위치/크기 설정 (화면 우측 또는 하단)
  - [x] 1.3 버튼 렌더링 함수 구현 (drawActionButtons)
  - [x] 1.4 버튼 호버 상태 추적 (hoverButtonIndex)
  - [x] 1.5 비활성화 상태 렌더링 (회색 + 투명도)

- [x] Task 2: 버튼 활성화 조건 로직 (AC: 7-5.1, 7-5.2, 7-5.4, 7-5.6, 7-5.8)
  - [x] 2.1 isButtonEnabled(buttonId) 함수 구현
  - [x] 2.2 Roll Dice: phase == "roll" 체크
  - [x] 2.3 Settlement: phase == "main" AND 자원 충분 체크
  - [x] 2.4 City: phase == "main" AND 자원 충분 AND 업그레이드 가능 정착지 존재
  - [x] 2.5 Road: phase == "main" AND 자원 충분 체크
  - [x] 2.6 End Turn: phase == "main" 체크

- [x] Task 3: 버튼 클릭 핸들링 (AC: All)
  - [x] 3.1 game:mousepressed()에서 버튼 영역 체크
  - [x] 3.2 버튼 클릭 시 해당 액션 실행 또는 선택 모드 진입
  - [x] 3.3 선택 모드 상태 변수 관리 (currentSelectionMode)
  - [x] 3.4 선택 모드 취소 처리 (ESC 키 또는 빈 영역 클릭)

- [x] Task 4: Roll Dice 연동 (AC: 7-5.1)
  - [x] 4.1 Roll Dice 클릭 시 gameState:rollDice() 호출
  - [x] 4.2 주사위 결과 저장 (lastDiceResult)
  - [x] 4.3 자원 분배 결과 HUD에 표시 (선택)

- [x] Task 5: 건설 액션 연동 (AC: 7-5.3, 7-5.5, 7-5.7)
  - [x] 5.1 Settlement 클릭 시 Actions.buildSettlement(gameState, board, playerId, vertex)
  - [x] 5.2 City 클릭 시 Actions.buildCity(gameState, board, playerId, vertex)
  - [x] 5.3 Road 클릭 시 Actions.buildRoad(gameState, board, playerId, edge)
  - [x] 5.4 건설 성공 후 선택 모드 해제
  - [x] 5.5 건설 성공 후 승리 체크 (checkVictoryAndTransition 활용)

- [x] Task 6: End Turn 연동 (AC: 7-5.8)
  - [x] 6.1 End Turn 클릭 시 gameState:endTurn() 호출
  - [x] 6.2 다음 플레이어 정보 HUD 업데이트
  - [x] 6.3 phase가 "roll"로 리셋됨 확인

- [x] Task 7: 기존 선택 시스템 연동 (AC: 7-5.2, 7-5.3, 7-5.4, 7-5.5, 7-5.6, 7-5.7)
  - [x] 7.1 기존 highlightedVertices/highlightedEdges 활용
  - [x] 7.2 선택 모드에 따른 하이라이트 필터링
  - [x] 7.3 기존 mousepressed의 정점/변 선택 로직과 통합
  - [x] 7.4 선택 성공 시 액션 실행 트리거

- [x] Task 8: 테스트 및 수동 검증 (AC: All)
  - [x] 8.1 Roll Dice 버튼 동작 확인
  - [x] 8.2 각 건설 버튼 → 선택 모드 → 건설 흐름 확인
  - [x] 8.3 End Turn 버튼 동작 확인
  - [x] 8.4 비활성화 상태 시각적 피드백 확인
  - [x] 8.5 전체 게임 플로우 테스트 (setup → playing → finished)

## Dev Notes

### 기술적 고려사항

- **기존 game.lua 구조 활용**: 이미 HUD, 선택 시스템, 렌더링 존재
- **GameState 연동**: gameState 변수로 상태 접근 (이미 game:enter에서 전달받음)
- **Actions 모듈**: src/game/actions.lua에 buildSettlement/City/Road 구현됨 (Story 5-4)
- **승리 체크**: checkVictoryAndTransition() 함수 활용 (Story 7-4에서 정의됨, 미사용)

### 버튼 UI 패턴 (menu.lua, game_over.lua에서 재사용)

```lua
-- 버튼 정의
local buttons = {
  {id = "roll", label = "Roll Dice", x = 1100, y = 100, w = 150, h = 40},
  {id = "settlement", label = "Settlement", x = 1100, y = 160, w = 150, h = 40},
  {id = "city", label = "City", x = 1100, y = 220, w = 150, h = 40},
  {id = "road", label = "Road", x = 1100, y = 280, w = 150, h = 40},
  {id = "endturn", label = "End Turn", x = 1100, y = 360, w = 150, h = 40},
}

-- 버튼 렌더링
local function drawButton(btn, isEnabled, isHovered)
  local bgColor
  if not isEnabled then
    bgColor = {0.3, 0.3, 0.3, 0.5}  -- 비활성화
  elseif isHovered then
    bgColor = {0.4, 0.6, 0.4}  -- 호버
  else
    bgColor = {0.2, 0.4, 0.2}  -- 기본
  end
  love.graphics.setColor(bgColor)
  love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h)

  local textColor = isEnabled and {1, 1, 1} or {0.5, 0.5, 0.5}
  love.graphics.setColor(textColor)
  love.graphics.printf(btn.label, btn.x, btn.y + 10, btn.w, "center")
end
```

### 선택 모드 상태 관리

```lua
-- 선택 모드
local currentSelectionMode = nil  -- nil, "settlement", "city", "road"

-- 버튼 클릭 핸들러
local function handleButtonClick(buttonId)
  if buttonId == "roll" then
    gameState:rollDice()
  elseif buttonId == "settlement" then
    currentSelectionMode = "settlement"
  elseif buttonId == "city" then
    currentSelectionMode = "city"
  elseif buttonId == "road" then
    currentSelectionMode = "road"
  elseif buttonId == "endturn" then
    gameState:endTurn()
  end
end
```

### 건설 실행 및 승리 체크

```lua
-- 정점 선택 시 (settlement/city 모드)
local function onVertexSelected(vertex)
  local playerId = gameState:getCurrentPlayer()
  local success = false

  if currentSelectionMode == "settlement" then
    success = Actions.buildSettlement(gameState, board, playerId, vertex)
  elseif currentSelectionMode == "city" then
    success = Actions.buildCity(gameState, board, playerId, vertex)
  end

  if success then
    currentSelectionMode = nil
    checkVictoryAndTransition()  -- Story 7-4에서 정의된 함수 활용
  end
end
```

### 의존성

- GameState (src/game/game_state.lua) - rollDice(), endTurn(), getCurrentPlayer()
- Actions (src/game/actions.lua) - buildSettlement(), buildCity(), buildRoad()
- Rules (src/game/rules.lua) - canBuildSettlement(), canBuildCity(), canBuildRoad()
- Board (src/game/board.lua) - buildings, roads 데이터
- Player (src/game/player.lua) - hasResources()
- game_over 씬 (src/scenes/game_over.lua) - 승리 시 전환 대상

### Project Structure Notes

- **수정 파일:** src/scenes/game.lua (버튼 UI, 액션 연동)
- **신규 파일:** 없음 (기존 game.lua 확장)
- **기존 로직 활용:** 하이라이트 시스템, HUD 렌더링, 선택 로직

### References

- [Source: docs/sprint-artifacts/tech-spec-epic-7.md#AC-7-5]
- [Source: docs/epics.md#Story-7.5]
- [Source: docs/game-architecture.md#Project-Structure]
- [Source: docs/sprint-artifacts/7-4-game-over.md#Dev-Agent-Record]

---

### Learnings from Previous Story

**From Story 7-4-game-over (Status: done)**

- **New File Created:** `src/scenes/game_over.lua` - 게임 종료 씬 (hump.gamestate 호환)
- **Modified File:** `src/scenes/game.lua` - 승리 감지 로직 추가 (update에서 mode 체크)
- **Button UI Pattern:** isPointInRect(), drawButton() 패턴 확립 → 본 스토리에서 재사용
- **Victory Detection:** `checkVictoryAndTransition()` 함수 정의됨 (미사용) → 본 스토리에서 활용
- **Memory Management:** collectgarbage() 패턴 확립
- **Testing:** 355 테스트 통과, UI 씬은 수동 테스트

**Advisory from Review:**
- `checkVictoryAndTransition()` 함수가 game.lua에 정의되었지만 호출되지 않음 → 건설 후 호출하여 활용

[Source: docs/sprint-artifacts/7-4-game-over.md#Dev-Agent-Record]

---

## Dev Agent Record

### Context Reference

- docs/sprint-artifacts/7-5-gameplay-integration.context.xml

### Agent Model Used

Claude Opus 4.5 (claude-opus-4-5-20251101)

### Debug Log References

- 게임 실행 시 Roll Dice → End Turn 반복 동작 확인
- 355 테스트 통과

### Completion Notes List

**Completed:** 2025-12-01
**Definition of Done:** All acceptance criteria met, code reviewed, tests passing

- game.lua에 액션 버튼 패널 추가 (Roll Dice, Settlement, City, Road, End Turn)
- isButtonEnabled() 함수로 페이즈/자원에 따른 버튼 활성화 조건 구현
- handleButtonClick() 함수로 버튼 클릭 시 액션 실행
- 선택 모드에서 유효 위치 클릭 시 Actions 모듈 호출하여 건설 실행
- 건설 성공 후 checkVictoryAndTransition() 호출하여 승리 체크
- GameState.board 연결하여 rollDice 시 자원 분배 동작
- 기존 선택 시스템(validVertices, validEdges, hoverVertex, hoverEdge)과 통합

### File List

- Modified: src/scenes/game.lua (버튼 UI, 액션 연동, 건설 실행)
- Modified: docs/sprint-artifacts/sprint-status.yaml (7-5 status: in-progress → review)
