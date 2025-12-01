-- src/scenes/game.lua
-- 게임 플레이 씬 (Story 7-3)
-- hump.gamestate 호환 씬 구조
-- 기존 main.lua 렌더링 로직을 씬으로 이동

local Gamestate = require("lib.hump.gamestate")
local Board = require("src.game.board")
local BoardView = require("src.ui.board_view")
local HUD = require("src.ui.hud")
local Input = require("src.ui.input")
local Rules = require("src.game.rules")

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

  -- 화면 중앙 오프셋
  OFFSET_X = love.graphics.getWidth() / 2
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

  -- 선택 모드 초기화
  selectionMode = "none"
  validVertices = nil
  validEdges = nil
  hoverVertex = nil
  hoverEdge = nil
  selectedVertex = nil
  selectedEdge = nil

  print(string.format("Game started with %d players", gameState.config.playerCount))
end

function game:leave()
  -- 정리
  gameState = nil
  board = nil
  buildings = nil
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

  -- 디버그 정보
  love.graphics.setColor(1, 1, 1, 1)
  local modeText = "Mode: " .. selectionMode .. " (S=Settlement, C=City, R=Road, ESC=None)"
  love.graphics.print(modeText, 10, screenHeight - 60)
  love.graphics.print(string.format("Players: %d | Current: P%d | Round: %d",
    gameState.config.playerCount,
    gameState.turn.current,
    gameState.turn.round), 10, screenHeight - 40)
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
  if button == 1 then
    if selectionMode == "settlement" or selectionMode == "city" then
      local vertex = Input.pixelToVertex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)
      if vertex and isValidVertex(vertex) then
        selectedVertex = vertex
        print(string.format("Selected Vertex: (%d, %d, %s)", vertex.q, vertex.r, vertex.dir))
      end
    elseif selectionMode == "road" then
      local edge = Input.pixelToEdge(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, EDGE_THRESHOLD)
      if edge and isValidEdge(edge) then
        selectedEdge = edge
        print(string.format("Selected Edge: (%d, %d, %s)", edge.q, edge.r, edge.dir))
      end
    else
      -- 디버그 출력
      local hex = Input.pixelToHex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y)
      local vertex = Input.pixelToVertex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)
      local edge = Input.pixelToEdge(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, EDGE_THRESHOLD)

      print(string.format("Click: (%d, %d)", x, y))
      if hex then
        print(string.format("  Hex: (%d, %d)", hex.q, hex.r))
      end
      if vertex then
        print(string.format("  Vertex: (%d, %d, %s)", vertex.q, vertex.r, vertex.dir))
      end
      if edge then
        print(string.format("  Edge: (%d, %d, %s)", edge.q, edge.r, edge.dir))
      end
    end
  end
end

return game
