-- src/scenes/game.lua
-- 게임 플레이 씬 (Story 7-3, 7-5)
-- hump.gamestate 호환 씬 구조
-- Story 7-5: 게임 플레이 통합 - UI 버튼으로 게임 진행

local Gamestate = require("lib.hump.gamestate")
local Board = require("src.game.board")
local BoardView = require("src.ui.board_view")
local HUD = require("src.ui.hud")
local Input = require("src.ui.input")
local Rules = require("src.game.rules")
local Actions = require("src.game.actions")
local Constants = require("src.game.constants")

local game = {}

-- 게임 상태 (menu 씬에서 전달받음)
local gameState

-- 보드
local board

-- 렌더링 설정
local HEX_SIZE = 50
local OFFSET_X, OFFSET_Y

-- 선택 모드 상태
-- none: 선택 모드 없음
-- settlement: 정착지 건설 모드
-- city: 도시 건설 모드
-- road: 도로 건설 모드
local selectionMode = "none"

-- 유효한 건설 위치
local validVertices = nil
local validEdges = nil

-- 호버 상태
local hoverVertex = nil
local hoverEdge = nil

-- 선택된 좌표
local selectedVertex = nil
local selectedEdge = nil

-- 임계값 상수
local VERTEX_THRESHOLD = 15
local EDGE_THRESHOLD = 10

-- 건물 데이터 (Board에 저장됨)
local buildings

-- 버튼 설정 (Story 7-5)
local BUTTON_WIDTH = 120
local BUTTON_HEIGHT = 40
local BUTTON_SPACING = 15
local BUTTON_X = 1100  -- 화면 우측

-- 액션 버튼 목록 (Story 7-5)
local actionButtons = {}

-- 버튼 호버 상태 (Story 7-5)
local hoverButtonIndex = nil

---
-- 점이 사각형 내부에 있는지 확인
-- @param px number 점 x 좌표
-- @param py number 점 y 좌표
-- @param x number 사각형 x
-- @param y number 사각형 y
-- @param w number 사각형 너비
-- @param h number 사각형 높이
-- @return boolean
---
local function isPointInRect(px, py, x, y, w, h)
  return px >= x and px <= x + w and py >= y and py <= y + h
end

---
-- 버튼 초기화 (Story 7-5)
-- @param screenWidth number 화면 너비
---
local function initActionButtons(screenWidth)
  local buttonX = screenWidth - BUTTON_WIDTH - 20
  local startY = 100

  actionButtons = {
    {id = "roll", label = "Roll Dice", x = buttonX, y = startY, w = BUTTON_WIDTH, h = BUTTON_HEIGHT},
    {id = "settlement", label = "Settlement", x = buttonX, y = startY + (BUTTON_HEIGHT + BUTTON_SPACING), w = BUTTON_WIDTH, h = BUTTON_HEIGHT},
    {id = "city", label = "City", x = buttonX, y = startY + (BUTTON_HEIGHT + BUTTON_SPACING) * 2, w = BUTTON_WIDTH, h = BUTTON_HEIGHT},
    {id = "road", label = "Road", x = buttonX, y = startY + (BUTTON_HEIGHT + BUTTON_SPACING) * 3, w = BUTTON_WIDTH, h = BUTTON_HEIGHT},
    {id = "endturn", label = "End Turn", x = buttonX, y = startY + (BUTTON_HEIGHT + BUTTON_SPACING) * 4 + 20, w = BUTTON_WIDTH, h = BUTTON_HEIGHT},
  }
end

---
-- 버튼 활성화 여부 확인 (Story 7-5: Task 2)
-- @param buttonId string 버튼 ID
-- @return boolean
---
local function isButtonEnabled(buttonId)
  if not gameState then return false end

  local phase = gameState:getPhase()
  local mode = gameState.mode
  local currentPlayer = gameState:getCurrentPlayer()

  if mode ~= "playing" then return false end

  if buttonId == "roll" then
    -- Roll Dice: phase == "roll"
    return phase == "roll"
  elseif buttonId == "settlement" then
    -- Settlement: phase == "main" AND 자원 충분
    if phase ~= "main" then return false end
    return currentPlayer:hasResources(Constants.BUILD_COSTS.settlement)
  elseif buttonId == "city" then
    -- City: phase == "main" AND 자원 충분 AND 업그레이드 가능 정착지 존재
    if phase ~= "main" then return false end
    if not currentPlayer:hasResources(Constants.BUILD_COSTS.city) then return false end
    -- 현재 플레이어 정착지가 있는지 확인
    if board and board.settlements then
      local playerId = gameState:getCurrentPlayerId()
      for _, data in pairs(board.settlements) do
        if data.player == playerId then
          return true
        end
      end
    end
    return false
  elseif buttonId == "road" then
    -- Road: phase == "main" AND 자원 충분
    if phase ~= "main" then return false end
    return currentPlayer:hasResources(Constants.BUILD_COSTS.road)
  elseif buttonId == "endturn" then
    -- End Turn: phase == "main"
    return phase == "main"
  end

  return false
end

---
-- 버튼 렌더링 (Story 7-5: Task 1)
-- @param btn table 버튼 정보
-- @param isEnabled boolean 활성화 상태
-- @param isHovered boolean 호버 상태
---
local function drawActionButton(btn, isEnabled, isHovered)
  local bgColor
  if not isEnabled then
    bgColor = {0.3, 0.3, 0.3, 0.5}  -- 비활성화
  elseif isHovered then
    bgColor = {0.4, 0.6, 0.4, 1}  -- 호버
  else
    bgColor = {0.2, 0.4, 0.2, 1}  -- 기본
  end

  -- 배경
  love.graphics.setColor(bgColor)
  love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 6, 6)

  -- 테두리
  if isEnabled then
    love.graphics.setColor(0.6, 0.8, 0.6, 1)
  else
    love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
  end
  love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 6, 6)

  -- 텍스트
  local textColor = isEnabled and {1, 1, 1, 1} or {0.5, 0.5, 0.5, 0.7}
  love.graphics.setColor(textColor)
  local font = love.graphics.getFont()
  local textY = btn.y + (btn.h - font:getHeight()) / 2
  love.graphics.printf(btn.label, btn.x, textY, btn.w, "center")
end

---
-- 모든 액션 버튼 렌더링 (Story 7-5)
---
local function drawActionButtons()
  for i, btn in ipairs(actionButtons) do
    local isEnabled = isButtonEnabled(btn.id)
    local isHovered = (hoverButtonIndex == i)
    drawActionButton(btn, isEnabled, isHovered and isEnabled)
  end

  -- 현재 선택 모드 표시
  if selectionMode ~= "none" then
    love.graphics.setColor(1, 1, 0, 1)
    local modeY = actionButtons[#actionButtons].y + actionButtons[#actionButtons].h + 20
    love.graphics.printf("Mode: " .. selectionMode:upper(), actionButtons[1].x, modeY, BUTTON_WIDTH, "center")
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.printf("ESC to cancel", actionButtons[1].x, modeY + 20, BUTTON_WIDTH, "center")
  end
end

---
-- 마우스 위치에 있는 버튼 인덱스 찾기
-- @param x number 마우스 x
-- @param y number 마우스 y
-- @return number|nil 버튼 인덱스
---
local function findHoveredButton(x, y)
  for i, btn in ipairs(actionButtons) do
    if isPointInRect(x, y, btn.x, btn.y, btn.w, btn.h) then
      return i
    end
  end
  return nil
end

---
-- 버튼 클릭 핸들러 (Story 7-5: Task 3, 4, 5, 6)
-- @param buttonId string 버튼 ID
---
local function handleButtonClick(buttonId)
  if not isButtonEnabled(buttonId) then return end

  if buttonId == "roll" then
    -- Roll Dice (Task 4)
    local result = gameState:rollDice()
    if result then
      print(string.format("Dice rolled: %d + %d = %d", result.die1, result.die2, result.sum))
    end
    -- 선택 모드 해제
    selectionMode = "none"
    validVertices = nil
    validEdges = nil
  elseif buttonId == "settlement" then
    -- Settlement 선택 모드 진입 (Task 5)
    if selectionMode == "settlement" then
      selectionMode = "none"
    else
      selectionMode = "settlement"
    end
    updateValidLocations(selectionMode)
    hoverVertex = nil
    hoverEdge = nil
  elseif buttonId == "city" then
    -- City 선택 모드 진입 (Task 5)
    if selectionMode == "city" then
      selectionMode = "none"
    else
      selectionMode = "city"
    end
    updateValidLocations(selectionMode)
    hoverVertex = nil
    hoverEdge = nil
  elseif buttonId == "road" then
    -- Road 선택 모드 진입 (Task 5)
    if selectionMode == "road" then
      selectionMode = "none"
    else
      selectionMode = "road"
    end
    updateValidLocations(selectionMode)
    hoverVertex = nil
    hoverEdge = nil
  elseif buttonId == "endturn" then
    -- End Turn (Task 6)
    gameState:endTurn()
    selectionMode = "none"
    validVertices = nil
    validEdges = nil
    hoverVertex = nil
    hoverEdge = nil
    print(string.format("Turn ended. Now Player %d's turn (Round %d, Phase: %s)",
      gameState:getCurrentPlayerId(), gameState:getRound(), gameState:getPhase()))
  end
end

---
-- 선택 모드에 따른 유효 위치 계산
-- @param mode string 선택 모드
---
local function updateValidLocations(mode)
  local currentPlayer = gameState:getCurrentPlayerId()

  if mode == "settlement" then
    validVertices = Rules.getValidSettlementLocations(board, currentPlayer, false)
    validEdges = nil
  elseif mode == "city" then
    validVertices = {}
    if board.settlements then
      for key, data in pairs(board.settlements) do
        if data.player == currentPlayer then
          local q, r, dir = key:match("([%-]?%d+),([%-]?%d+),(%a+)")
          if q and r and dir then
            validVertices[#validVertices + 1] = {q = tonumber(q), r = tonumber(r), dir = dir}
          end
        end
      end
    end
    validEdges = nil
  elseif mode == "road" then
    validEdges = Rules.getValidRoadLocations(board, currentPlayer)
    validVertices = nil
  else
    validVertices = nil
    validEdges = nil
  end
end

---
-- 정점이 유효 목록에 있는지 확인
-- @param vertex table {q, r, dir}
-- @return boolean
---
local function isValidVertex(vertex)
  if not validVertices or not vertex then return false end
  for _, v in ipairs(validVertices) do
    if v.q == vertex.q and v.r == vertex.r and v.dir == vertex.dir then
      return true
    end
  end
  return false
end

---
-- 변이 유효 목록에 있는지 확인
-- @param edge table {q, r, dir}
-- @return boolean
---
local function isValidEdge(edge)
  if not validEdges or not edge then return false end
  for _, e in ipairs(validEdges) do
    if e.q == edge.q and e.r == edge.r and e.dir == edge.dir then
      return true
    end
  end
  return false
end

-- hump.gamestate 콜백들 --

function game:enter(previous, passedGameState) -- luacheck: ignore previous
  -- menu 씬에서 전달받은 GameState
  gameState = passedGameState

  -- 보드 생성
  board = Board.newStandard()

  -- GameState에 board 연결 (rollDice에서 자원 분배용)
  gameState.board = board

  -- 화면 크기 및 중앙 오프셋
  local screenWidth = love.graphics.getWidth()
  OFFSET_X = screenWidth / 2
  OFFSET_Y = love.graphics.getHeight() / 2

  -- 건물 데이터 초기화 (빈 상태로 시작)
  buildings = {
    settlements = {},
    cities = {},
    roads = {},
  }

  -- Board에 건물 데이터 연결
  board.settlements = buildings.settlements
  board.cities = buildings.cities
  board.roads = buildings.roads

  -- 액션 버튼 초기화 (Story 7-5)
  initActionButtons(screenWidth)

  -- 선택 모드 초기화
  selectionMode = "none"
  validVertices = nil
  validEdges = nil
  hoverVertex = nil
  hoverEdge = nil
  selectedVertex = nil
  selectedEdge = nil
  hoverButtonIndex = nil

  print(string.format("Game started with %d players", gameState.config.playerCount))
end

function game:leave()
  -- 정리
  gameState = nil
  board = nil
  buildings = nil
  actionButtons = {}
  hoverButtonIndex = nil
end

---
-- 승리 체크 및 게임 종료 씬 전환
-- 건설 완료 직후 호출됨
---
local function checkVictoryAndTransition()
  if not gameState then return end

  local winnerId = gameState:checkVictory()
  if winnerId then
    -- 게임 종료 씬으로 전환
    local game_over = require("src.scenes.game_over")
    Gamestate.switch(game_over, winnerId, gameState.players)
  end
end

function game:update(dt) -- luacheck: ignore dt
  if not gameState then return end

  -- 게임 모드가 finished면 즉시 전환
  if gameState.mode == "finished" and gameState.winner then
    local game_over = require("src.scenes.game_over")
    Gamestate.switch(game_over, gameState.winner, gameState.players)
  end
end

function game:draw()
  -- 배경
  love.graphics.clear(0.1, 0.15, 0.2)

  -- 보드 렌더링
  BoardView.draw(board, HEX_SIZE, OFFSET_X, OFFSET_Y, buildings)

  -- 하이라이트 렌더링
  if selectionMode ~= "none" then
    BoardView.drawHighlights(validVertices, validEdges, HEX_SIZE, OFFSET_X, OFFSET_Y, hoverVertex, hoverEdge)
  end

  -- HUD 렌더링
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()

  -- gameState를 HUD 형식으로 변환
  local hudState = {
    players = {},
    turn = {
      current = gameState.turn.current,
      phase = gameState.turn.phase,
    },
    diceResult = gameState.diceResult,
  }

  for i, player in ipairs(gameState.players) do
    hudState.players[i] = {
      id = player.id,
      resources = player.resources,
      victoryPoints = player:getVictoryPoints(),
    }
  end

  HUD.draw(hudState, screenWidth, screenHeight)

  -- 액션 버튼 렌더링 (Story 7-5)
  drawActionButtons()

  -- 디버그 정보
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(string.format("Players: %d | Current: P%d | Round: %d | Phase: %s",
    gameState.config.playerCount,
    gameState.turn.current,
    gameState.turn.round,
    gameState.turn.phase), 10, screenHeight - 40)
  love.graphics.print("Settlus of Catan - FPS: " .. love.timer.getFPS(), 10, screenHeight - 20)
end

function game:keypressed(key)
  local newMode = selectionMode

  if key == "s" then
    newMode = (selectionMode == "settlement") and "none" or "settlement"
  elseif key == "c" then
    newMode = (selectionMode == "city") and "none" or "city"
  elseif key == "r" then
    newMode = (selectionMode == "road") and "none" or "road"
  elseif key == "escape" then
    -- 선택 모드 취소
    newMode = "none"
  end

  if newMode ~= selectionMode then
    selectionMode = newMode
    updateValidLocations(selectionMode)
    hoverVertex = nil
    hoverEdge = nil
    selectedVertex = nil
    selectedEdge = nil
    print("Selection mode changed to: " .. selectionMode)
  end
end

function game:mousemoved(x, y)
  -- 버튼 호버 상태 업데이트 (Story 7-5)
  hoverButtonIndex = findHoveredButton(x, y)

  if selectionMode == "none" then
    hoverVertex = nil
    hoverEdge = nil
    return
  end

  if selectionMode == "settlement" or selectionMode == "city" then
    local vertex = Input.pixelToVertex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)
    if vertex and isValidVertex(vertex) then
      hoverVertex = vertex
    else
      hoverVertex = nil
    end
    hoverEdge = nil
  elseif selectionMode == "road" then
    local edge = Input.pixelToEdge(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, EDGE_THRESHOLD)
    if edge and isValidEdge(edge) then
      hoverEdge = edge
    else
      hoverEdge = nil
    end
    hoverVertex = nil
  end
end

function game:mousepressed(x, y, button)
  if button ~= 1 then return end  -- 좌클릭만 처리

  -- 1. 버튼 클릭 체크 (Story 7-5: Task 3)
  local btnIdx = findHoveredButton(x, y)
  if btnIdx then
    local btn = actionButtons[btnIdx]
    handleButtonClick(btn.id)
    return
  end

  -- 2. 선택 모드에 따른 건설 실행 (Story 7-5: Task 5, 7)
  local playerId = gameState:getCurrentPlayerId()

  if selectionMode == "settlement" then
    local vertex = Input.pixelToVertex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)
    if vertex and isValidVertex(vertex) then
      -- Actions.buildSettlement 실행 (AC 7-5.3)
      local game_obj = {board = board, players = gameState.players}
      local success, err = Actions.buildSettlement(game_obj, playerId, vertex)
      if success then
        print(string.format("Settlement built at (%d, %d, %s)", vertex.q, vertex.r, vertex.dir))
        -- 선택 모드 해제
        selectionMode = "none"
        validVertices = nil
        validEdges = nil
        hoverVertex = nil
        -- 승리 체크 (AC 7-5.3)
        checkVictoryAndTransition()
      else
        print("Failed to build settlement: " .. (err or "Unknown error"))
      end
    end
  elseif selectionMode == "city" then
    local vertex = Input.pixelToVertex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)
    if vertex and isValidVertex(vertex) then
      -- Actions.buildCity 실행 (AC 7-5.5)
      local game_obj = {board = board, players = gameState.players}
      local success, err = Actions.buildCity(game_obj, playerId, vertex)
      if success then
        print(string.format("City built at (%d, %d, %s)", vertex.q, vertex.r, vertex.dir))
        -- 선택 모드 해제
        selectionMode = "none"
        validVertices = nil
        validEdges = nil
        hoverVertex = nil
        -- 승리 체크 (AC 7-5.5)
        checkVictoryAndTransition()
      else
        print("Failed to build city: " .. (err or "Unknown error"))
      end
    end
  elseif selectionMode == "road" then
    local edge = Input.pixelToEdge(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, EDGE_THRESHOLD)
    if edge and isValidEdge(edge) then
      -- Actions.buildRoad 실행 (AC 7-5.7)
      local game_obj = {board = board, players = gameState.players}
      local success, err = Actions.buildRoad(game_obj, playerId, edge)
      if success then
        print(string.format("Road built at (%d, %d, %s)", edge.q, edge.r, edge.dir))
        -- 선택 모드 해제
        selectionMode = "none"
        validVertices = nil
        validEdges = nil
        hoverEdge = nil
      else
        print("Failed to build road: " .. (err or "Unknown error"))
      end
    end
  else
    -- 선택 모드가 아닐 때 빈 영역 클릭 - 디버그용
    local hex = Input.pixelToHex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y)
    if hex then
      print(string.format("Click on Hex: (%d, %d)", hex.q, hex.r))
    end
  end
end

return game
