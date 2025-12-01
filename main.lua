-- main.lua
-- Love2D 엔트리포인트

local Board = require("src.game.board")
local BoardView = require("src.ui.board_view")
local HUD = require("src.ui.hud")
local Input = require("src.ui.input")
local Rules = require("src.game.rules")

-- 게임 상태
local board
local testBuildings
local testGameState
local HEX_SIZE = 50
local OFFSET_X, OFFSET_Y

-- 선택 모드 상태 (Task 3)
-- none: 선택 모드 없음
-- settlement: 정착지 건설 모드
-- city: 도시 건설 모드
-- road: 도로 건설 모드
local selectionMode = "none"

-- 유효한 건설 위치 (선택 모드에 따라 계산됨)
local validVertices = nil  -- 정착지/도시용
local validEdges = nil     -- 도로용

-- 호버 상태 (Task 4)
local hoverVertex = nil    -- 현재 호버된 정점
local hoverEdge = nil      -- 현재 호버된 변

-- 선택된 좌표 (게임 로직에 전달용)
local selectedVertex = nil
local selectedEdge = nil

-- 임계값 상수 (tech-spec)
local VERTEX_THRESHOLD = 15
local EDGE_THRESHOLD = 10

---
-- 선택 모드에 따른 유효 위치 계산 (Task 3.2)
-- @param mode string 선택 모드
---
local function updateValidLocations(mode)
  local currentPlayer = testGameState.turn.current

  if mode == "settlement" then
    -- 정착지 건설 가능 위치 계산
    validVertices = Rules.getValidSettlementLocations(board, currentPlayer, false)
    validEdges = nil
  elseif mode == "city" then
    -- 도시 건설 가능 위치 (기존 정착지 위치) - Rules에 함수가 없으므로 임시 구현
    validVertices = {}
    if testBuildings and testBuildings.settlements then
      for key, data in pairs(testBuildings.settlements) do
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
    -- 도로 건설 가능 위치 계산
    validEdges = Rules.getValidRoadLocations(board, currentPlayer)
    validVertices = nil
  else
    -- none 모드
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

function love.load()
  -- 보드 생성
  board = Board.newStandard()

  -- 화면 중앙 오프셋 계산
  OFFSET_X = love.graphics.getWidth() / 2
  OFFSET_Y = love.graphics.getHeight() / 2

  -- 테스트용 건물/도로 데이터 (Architecture 문서 구조 참조)
  -- 다양한 위치와 방향으로 렌더링 검증
  testBuildings = {
    settlements = {
      -- 중앙 헥스(0,0) 주변 정점들
      ["0,0,N"] = {player = 1},   -- Player 1 빨강 - 중앙 헥스 북쪽 정점
      ["0,0,S"] = {player = 2},   -- Player 2 파랑 - 중앙 헥스 남쪽 정점
      -- 외곽 헥스 정점들
      ["1,-1,N"] = {player = 3},  -- Player 3 초록 - 북동 헥스
      ["-1,1,S"] = {player = 4},  -- Player 4 노랑 - 남서 헥스
      ["2,-1,N"] = {player = 1},  -- Player 1 빨강 - 더 외곽
    },
    cities = {
      ["0,-1,S"] = {player = 2},  -- Player 2 파랑 - 북쪽 헥스 남쪽 정점
      ["-1,0,N"] = {player = 4},  -- Player 4 노랑 - 서쪽 헥스
    },
    roads = {
      -- 중앙 헥스(0,0)의 모든 방향 테스트
      ["0,0,NE"] = {player = 1},  -- Player 1 빨강 - NE 방향
      ["0,0,E"] = {player = 1},   -- Player 1 빨강 - E 방향
      ["0,0,SE"] = {player = 1},  -- Player 1 빨강 - SE 방향

      -- 다른 헥스들의 다양한 방향
      ["1,-1,NE"] = {player = 2}, -- Player 2 파랑 - 북동 헥스 NE
      ["1,-1,E"] = {player = 2},  -- Player 2 파랑 - 북동 헥스 E
      ["1,-1,SE"] = {player = 2}, -- Player 2 파랑 - 북동 헥스 SE

      ["-1,1,NE"] = {player = 3}, -- Player 3 초록 - 남서 헥스 NE
      ["-1,1,E"] = {player = 3},  -- Player 3 초록 - 남서 헥스 E
      ["-1,1,SE"] = {player = 3}, -- Player 3 초록 - 남서 헥스 SE

      ["0,-1,E"] = {player = 4},  -- Player 4 노랑 - 북쪽 헥스 E
      ["1,0,NE"] = {player = 4},  -- Player 4 노랑 - 동쪽 헥스 NE
      ["-1,0,SE"] = {player = 4}, -- Player 4 노랑 - 서쪽 헥스 SE
    },
  }

  -- 테스트용 게임 상태 (HUD 렌더링 검증용)
  testGameState = {
    players = {
      {id = 1, resources = {wood = 3, brick = 2, sheep = 1, wheat = 4, ore = 0}, victoryPoints = 3},
      {id = 2, resources = {wood = 1, brick = 1, sheep = 2, wheat = 1, ore = 3}, victoryPoints = 5},
      {id = 3, resources = {wood = 0, brick = 3, sheep = 0, wheat = 2, ore = 1}, victoryPoints = 2},
      {id = 4, resources = {wood = 2, brick = 0, sheep = 3, wheat = 0, ore = 2}, victoryPoints = 4},
    },
    turn = {
      current = 1,
      phase = "build",
    },
    diceResult = {die1 = 3, die2 = 4},  -- 합계 7 테스트하려면 {die1 = 3, die2 = 4} 또는 nil
  }

  -- Board에 건물 데이터 직접 설정 (Rules 함수가 board.settlements, board.roads 사용)
  board.settlements = testBuildings.settlements
  board.cities = testBuildings.cities
  board.roads = testBuildings.roads
end

function love.update(dt) -- luacheck: ignore dt
  -- 업데이트 로직 (나중에 구현)
end

function love.draw()
  -- 배경 색상
  love.graphics.clear(0.1, 0.15, 0.2)

  -- 보드 렌더링 (건물 포함)
  BoardView.draw(board, HEX_SIZE, OFFSET_X, OFFSET_Y, testBuildings)

  -- 하이라이트 렌더링 (건물과 HUD 사이) - Task 5.3
  if selectionMode ~= "none" then
    BoardView.drawHighlights(validVertices, validEdges, HEX_SIZE, OFFSET_X, OFFSET_Y, hoverVertex, hoverEdge)
  end

  -- HUD 렌더링 (보드 위에 최상단 레이어)
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  HUD.draw(testGameState, screenWidth, screenHeight)

  -- 디버그 정보 및 선택 모드 표시
  love.graphics.setColor(1, 1, 1, 1)
  local modeText = "Mode: " .. selectionMode .. " (S=Settlement, C=City, R=Road, ESC=None)"
  love.graphics.print(modeText, 10, screenHeight - 40)
  love.graphics.print("Settlus of Catan - FPS: " .. love.timer.getFPS(), 10, screenHeight - 20)
end

-- 키보드 입력 처리 - 선택 모드 토글 (Task 5.1)
function love.keypressed(key)
  local newMode = selectionMode

  if key == "s" then
    newMode = (selectionMode == "settlement") and "none" or "settlement"
  elseif key == "c" then
    newMode = (selectionMode == "city") and "none" or "city"
  elseif key == "r" then
    newMode = (selectionMode == "road") and "none" or "road"
  elseif key == "escape" then
    newMode = "none"
  end

  if newMode ~= selectionMode then
    selectionMode = newMode
    updateValidLocations(selectionMode)
    -- 모드 변경 시 호버 상태 초기화
    hoverVertex = nil
    hoverEdge = nil
    selectedVertex = nil
    selectedEdge = nil
    print("Selection mode changed to: " .. selectionMode)
  end
end

-- 마우스 이동 처리 - 호버 감지 (Task 4.1, 4.3)
function love.mousemoved(x, y)
  if selectionMode == "none" then
    hoverVertex = nil
    hoverEdge = nil
    return
  end

  -- 정점 호버 (settlement, city 모드)
  if selectionMode == "settlement" or selectionMode == "city" then
    local vertex = Input.pixelToVertex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)
    -- 유효한 위치에서만 호버 표시 (Task 4.3)
    if vertex and isValidVertex(vertex) then
      hoverVertex = vertex
    else
      hoverVertex = nil
    end
    hoverEdge = nil
  -- 변 호버 (road 모드)
  elseif selectionMode == "road" then
    local edge = Input.pixelToEdge(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, EDGE_THRESHOLD)
    -- 유효한 위치에서만 호버 표시 (Task 4.3)
    if edge and isValidEdge(edge) then
      hoverEdge = edge
    else
      hoverEdge = nil
    end
    hoverVertex = nil
  end
end

-- 마우스 클릭 처리 - 선택 (Task 5.2)
function love.mousepressed(x, y, button)
  if button == 1 then -- 좌클릭
    -- 선택 모드가 활성화된 경우 선택 처리
    if selectionMode == "settlement" or selectionMode == "city" then
      local vertex = Input.pixelToVertex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)
      if vertex and isValidVertex(vertex) then
        selectedVertex = vertex
        print(string.format("Selected Vertex: (%d, %d, %s)", vertex.q, vertex.r, vertex.dir))
        -- 여기서 게임 로직에 전달 가능 (AC 6-5.3)
        -- 예: game:buildSettlement(selectedVertex)
      end
    elseif selectionMode == "road" then
      local edge = Input.pixelToEdge(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, EDGE_THRESHOLD)
      if edge and isValidEdge(edge) then
        selectedEdge = edge
        print(string.format("Selected Edge: (%d, %d, %s)", edge.q, edge.r, edge.dir))
        -- 여기서 게임 로직에 전달 가능 (AC 6-5.4)
        -- 예: game:buildRoad(selectedEdge)
      end
    else
      -- 선택 모드가 아닌 경우 디버그 출력
      local hex = Input.pixelToHex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y)
      local vertex = Input.pixelToVertex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)
      local edge = Input.pixelToEdge(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, EDGE_THRESHOLD)

      print(string.format("Click: (%d, %d)", x, y))
      if hex then
        print(string.format("  Hex: (%d, %d)", hex.q, hex.r))
      else
        print("  Hex: nil (outside board)")
      end
      if vertex then
        print(string.format("  Vertex: (%d, %d, %s)", vertex.q, vertex.r, vertex.dir))
      else
        print("  Vertex: nil (outside threshold)")
      end
      if edge then
        print(string.format("  Edge: (%d, %d, %s)", edge.q, edge.r, edge.dir))
      else
        print("  Edge: nil (outside threshold)")
      end
      print("")  -- 빈 줄로 구분
    end
  end
end
