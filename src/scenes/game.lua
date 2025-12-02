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

-- Setup 모드 상태 (Story 7-6)
local lastPlacedSettlement = nil  -- 도로 배치용 마지막 정착지 위치

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

-- 툴팁 상태 (AC 8-1.3)
local tooltip = {
  visible = false,
  x = 0,
  y = 0,
  text = "",
}

-- 타일 하이라이트 상태 (AC 8-1.5)
local highlightedNumber = nil  -- 하이라이트할 숫자
local resourceGains = nil      -- 자원 획득 정보 {{playerId, resources}, ...}

-- 피드백 메시지 상태 (AC 8-1.6)
local feedbackMessage = nil    -- 표시할 메시지
local feedbackTimer = 0        -- 메시지 표시 시간

-- Forward declarations (BUG-005 fix: local 함수 순서 문제 해결)
local getSetupRoadLocations
local updateValidLocations

-- Admin 모드 (개발용: 모든 플레이어 자원 상세 표시)
local adminMode = true

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
  local startY = 320  -- 점수 패널 아래로 이동 (점수 패널 높이 약 280)

  actionButtons = {
    {id = "roll", label = "Roll Dice", x = buttonX, y = startY, w = BUTTON_WIDTH, h = BUTTON_HEIGHT},
    {id = "settlement", label = "Settlement", x = buttonX, y = startY + (BUTTON_HEIGHT + BUTTON_SPACING), w = BUTTON_WIDTH, h = BUTTON_HEIGHT},
    {id = "city", label = "City", x = buttonX, y = startY + (BUTTON_HEIGHT + BUTTON_SPACING) * 2, w = BUTTON_WIDTH, h = BUTTON_HEIGHT},
    {id = "road", label = "Road", x = buttonX, y = startY + (BUTTON_HEIGHT + BUTTON_SPACING) * 3, w = BUTTON_WIDTH, h = BUTTON_HEIGHT},
    {id = "endturn", label = "End Turn", x = buttonX, y = startY + (BUTTON_HEIGHT + BUTTON_SPACING) * 4 + 20, w = BUTTON_WIDTH, h = BUTTON_HEIGHT},
  }
end

---
-- 버튼 활성화 여부 확인 (Story 7-5: Task 2, Story 7-6: Setup 모드)
-- @param buttonId string 버튼 ID
-- @return boolean
---
local function isButtonEnabled(buttonId)
  if not gameState then return false end

  local mode = gameState.mode

  -- Setup 모드에서는 모든 액션 버튼 비활성화 (Story 7-6)
  if mode == "setup" then return false end
  if mode ~= "playing" then return false end

  local phase = gameState:getPhase()
  local currentPlayer = gameState:getCurrentPlayer()

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
-- 부족한 자원 목록 가져오기 (AC 8-1.4)
-- @param buildType string 건물 타입
-- @param player table 현재 플레이어
-- @return table 부족한 자원 목록 {type, need, have}
---
local function getMissingResources(buildType, player)
  if not player or not buildType then return {} end
  local cost = Constants.BUILD_COSTS[buildType]
  if not cost then return {} end

  local missing = {}
  for resType, need in pairs(cost) do
    local have = player.resources and player.resources[resType] or 0
    if have < need then
      table.insert(missing, {type = resType, need = need, have = have})
    end
  end
  return missing
end

---
-- 버튼 렌더링 (Story 7-5: Task 1, AC 8-1.4: 부족 자원 표시)
-- @param btn table 버튼 정보
-- @param isEnabled boolean 활성화 상태
-- @param isHovered boolean 호버 상태
-- @param missingRes table|nil 부족한 자원 목록
---
local function drawActionButton(btn, isEnabled, isHovered, missingRes)
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
  local textY = btn.y + (btn.h - font:getHeight()) / 2 - 5
  love.graphics.printf(btn.label, btn.x, textY, btn.w, "center")

  -- 부족한 자원 표시 (AC 8-1.4)
  if not isEnabled and missingRes and #missingRes > 0 then
    local parts = {}
    for _, res in ipairs(missingRes) do
      local initial = res.type:sub(1, 1):upper()
      table.insert(parts, initial .. ":" .. res.have .. "/" .. res.need)
    end
    local missingText = table.concat(parts, " ")
    love.graphics.setColor(0.9, 0.4, 0.4, 1)  -- 빨간색
    love.graphics.printf(missingText, btn.x, textY + font:getHeight() + 2, btn.w, "center")
  end
end

---
-- 모든 액션 버튼 렌더링 (Story 7-5, AC 8-1.4)
---
local function drawActionButtons()
  -- Setup 모드에서는 버튼 숨김 (Story 7-6)
  if gameState and gameState:isSetup() then
    return
  end

  local currentPlayer = gameState and gameState:getCurrentPlayer()

  for i, btn in ipairs(actionButtons) do
    local isEnabled = isButtonEnabled(btn.id)
    local isHovered = (hoverButtonIndex == i)
    -- 부족한 자원 계산 (AC 8-1.4)
    local missingRes = nil
    if not isEnabled and (btn.id == "settlement" or btn.id == "city" or btn.id == "road") then
      missingRes = getMissingResources(btn.id, currentPlayer)
    end
    drawActionButton(btn, isEnabled, isHovered and isEnabled, missingRes)
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
-- Setup 모드 안내 UI 렌더링 (Story 7-6: AC 7-6.1, 7-6.2, 7-6.3)
-- @param screenWidth number 화면 너비
---
local function drawSetupUI(screenWidth)
  if not gameState or not gameState:isSetup() then return end

  local setup = gameState.setup
  local currentPlayer = setup.currentPlayer
  local phase = setup.phase

  -- 안내 텍스트 배경
  local boxX = screenWidth - 200
  local boxY = 100
  local boxW = 180
  local boxH = 120

  love.graphics.setColor(0.15, 0.2, 0.25, 0.95)
  love.graphics.rectangle("fill", boxX, boxY, boxW, boxH, 8, 8)
  love.graphics.setColor(0.4, 0.6, 0.8, 1)
  love.graphics.rectangle("line", boxX, boxY, boxW, boxH, 8, 8)

  -- 라운드/방향 정보
  love.graphics.setColor(0.7, 0.8, 0.9, 1)
  love.graphics.printf(string.format("Setup Round %d", setup.round), boxX, boxY + 10, boxW, "center")

  -- 플레이어 표시
  local playerColors = {
    {0.9, 0.3, 0.3, 1},  -- Red
    {0.3, 0.5, 0.9, 1},  -- Blue
    {0.3, 0.8, 0.3, 1},  -- Green
    {0.9, 0.7, 0.2, 1},  -- Yellow
  }
  love.graphics.setColor(playerColors[currentPlayer])
  love.graphics.printf(string.format("Player %d", currentPlayer), boxX, boxY + 35, boxW, "center")

  -- 페이즈 안내
  love.graphics.setColor(1, 1, 1, 1)
  local phaseText = phase == "settlement" and "Place Settlement" or "Place Road"
  love.graphics.printf(phaseText, boxX, boxY + 60, boxW, "center")

  -- 힌트
  love.graphics.setColor(0.6, 0.6, 0.6, 1)
  local hintText = phase == "settlement" and "Click on a vertex" or "Click on an edge"
  love.graphics.printf(hintText, boxX, boxY + 85, boxW, "center")
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
-- 건설 비용 문자열 생성 (AC 8-1.3)
-- @param buildType string 건물 타입 ("road", "settlement", "city")
-- @return string 비용 문자열 (예: "Wood 1, Brick 1")
---
local function getBuildCostText(buildType)
  local cost = Constants.BUILD_COSTS[buildType]
  if not cost then return "" end

  local parts = {}
  local order = {"wood", "brick", "sheep", "wheat", "ore"}
  for _, resType in ipairs(order) do
    local amount = cost[resType]
    if amount and amount > 0 then
      local name = resType:sub(1,1):upper() .. resType:sub(2)
      table.insert(parts, name .. " " .. amount)
    end
  end
  return table.concat(parts, ", ")
end

---
-- 툴팁 렌더링 (AC 8-1.3)
---
local function drawTooltip()
  if not tooltip.visible or tooltip.text == "" then return end

  local font = love.graphics.getFont()
  local textWidth = font:getWidth(tooltip.text)
  local textHeight = font:getHeight()
  local padding = 6
  local boxWidth = textWidth + padding * 2
  local boxHeight = textHeight + padding * 2

  -- 툴팁 위치 (버튼 왼쪽에 표시)
  local boxX = tooltip.x - boxWidth - 5
  local boxY = tooltip.y

  -- 배경
  love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
  love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 4, 4)

  -- 테두리
  love.graphics.setColor(0.6, 0.6, 0.6, 1)
  love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 4, 4)

  -- 텍스트
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(tooltip.text, boxX + padding, boxY + padding)
end

---
-- 피드백 메시지 렌더링 (AC 8-1.6)
---
local function drawFeedbackMessage()
  if not feedbackMessage then return end

  local font = love.graphics.getFont()
  local textWidth = font:getWidth(feedbackMessage)
  local textHeight = font:getHeight()
  local padding = 10
  local boxWidth = textWidth + padding * 2
  local boxHeight = textHeight + padding * 2

  -- 화면 중앙 상단
  local screenWidth = love.graphics.getWidth()
  local boxX = (screenWidth - boxWidth) / 2
  local boxY = 60

  -- 배경 (빨간 테두리)
  love.graphics.setColor(0.15, 0.1, 0.1, 0.95)
  love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 6, 6)
  love.graphics.setColor(0.9, 0.3, 0.3, 1)
  love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 6, 6)

  -- 텍스트
  love.graphics.setColor(1, 0.8, 0.8, 1)
  love.graphics.print(feedbackMessage, boxX + padding, boxY + padding)
end

---
-- 자원 획득 정보 오버레이 렌더링 (AC 8-1.5)
---
local function drawResourceGains()
  if not resourceGains or #resourceGains == 0 then return end

  local font = love.graphics.getFont()
  local lineHeight = font:getHeight() + 2
  local padding = 10
  local boxX = 10
  local boxY = 50  -- 주사위 결과 아래

  -- 획득 정보 문자열 생성
  local lines = {"Resources Gained:"}
  for _, gain in ipairs(resourceGains) do
    local parts = {}
    for resType, amount in pairs(gain.resources) do
      if amount > 0 then
        local initial = resType:sub(1, 1):upper()
        table.insert(parts, initial .. ":" .. amount)
      end
    end
    if #parts > 0 then
      table.insert(lines, string.format("  P%d: %s", gain.playerId, table.concat(parts, " ")))
    end
  end

  -- 아무도 획득 못했으면 표시 안함
  if #lines == 1 then return end

  local maxWidth = 0
  for _, line in ipairs(lines) do
    local w = font:getWidth(line)
    if w > maxWidth then maxWidth = w end
  end

  local boxWidth = maxWidth + padding * 2
  local boxHeight = #lines * lineHeight + padding * 2

  -- 배경
  love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
  love.graphics.rectangle("fill", boxX, boxY, boxWidth, boxHeight, 6, 6)

  -- 테두리 (노란색)
  love.graphics.setColor(1, 0.8, 0, 1)
  love.graphics.rectangle("line", boxX, boxY, boxWidth, boxHeight, 6, 6)

  -- 텍스트
  local y = boxY + padding
  for i, line in ipairs(lines) do
    if i == 1 then
      love.graphics.setColor(1, 0.9, 0.3, 1)  -- 제목: 노란색
    else
      love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.print(line, boxX + padding, y)
    y = y + lineHeight
  end
end

---
-- 버튼 클릭 핸들러 (Story 7-5: Task 3, 4, 5, 6)
-- @param buttonId string 버튼 ID
---
local function handleButtonClick(buttonId)
  if not isButtonEnabled(buttonId) then return end

  if buttonId == "roll" then
    -- Roll Dice (Task 4, AC 8-1.5: 타일 하이라이트)
    -- 분배 전 자원 저장
    local beforeResources = {}
    for _, player in ipairs(gameState.players) do
      beforeResources[player.id] = {}
      for resType, amount in pairs(player.resources) do
        beforeResources[player.id][resType] = amount
      end
    end

    local result = gameState:rollDice()
    if result then
      print(string.format("Dice rolled: %d + %d = %d", result.die1, result.die2, result.sum))

      -- 타일 하이라이트 설정 (7이 아닌 경우만)
      if result.sum ~= 7 then
        highlightedNumber = result.sum

        -- 자원 획득 정보 계산
        resourceGains = {}
        for _, player in ipairs(gameState.players) do
          local gains = {}
          local hasGain = false
          for resType, amount in pairs(player.resources) do
            local before = beforeResources[player.id][resType] or 0
            local diff = amount - before
            if diff > 0 then
              gains[resType] = diff
              hasGain = true
            end
          end
          if hasGain then
            table.insert(resourceGains, {playerId = player.id, resources = gains})
          end
        end
      else
        highlightedNumber = nil
        resourceGains = nil
      end
    end
    -- 선택 모드 해제
    selectionMode = "none"
    validVertices = nil
    validEdges = nil
  elseif buttonId == "settlement" then
    -- Settlement 선택 모드 진입 (Task 5)
    -- 다른 액션 시 하이라이트 해제 (AC 8-1.5)
    highlightedNumber = nil
    resourceGains = nil
    if selectionMode == "settlement" then
      selectionMode = "none"
    else
      selectionMode = "settlement"
    end
    updateValidLocations(selectionMode)

    -- 배치 가능 위치 체크 (AC 8-1.6)
    if selectionMode == "settlement" and (not validVertices or #validVertices == 0) then
      feedbackMessage = "No valid settlement locations"
      feedbackTimer = 2.5
      selectionMode = "none"
    end

    hoverVertex = nil
    hoverEdge = nil
  elseif buttonId == "city" then
    -- City 선택 모드 진입 (Task 5)
    -- 다른 액션 시 하이라이트 해제 (AC 8-1.5)
    highlightedNumber = nil
    resourceGains = nil
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
    -- 다른 액션 시 하이라이트 해제 (AC 8-1.5)
    highlightedNumber = nil
    resourceGains = nil
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
    -- 다른 액션 시 하이라이트 해제 (AC 8-1.5)
    highlightedNumber = nil
    resourceGains = nil
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
-- Setup 모드에서 도로 배치 가능 위치 계산 (Story 7-6: AC 7-6.3)
-- 마지막 정착지에 인접한 변만 반환
-- @param settlement table {q, r, dir} 마지막 배치 정착지
-- @return table 유효한 변 목록
---
getSetupRoadLocations = function(settlement)
  local Vertex = require("src.game.vertex")
  local Edge = require("src.game.edge") -- luacheck: ignore Edge
  local validEdges = {}

  local adjacentEdges = Vertex.getAdjacentEdges(settlement.q, settlement.r, settlement.dir)
  for _, edge in ipairs(adjacentEdges) do
    -- 변이 보드 내에 있고 비어있는지 확인 (BUG-007)
    if board:isValidEdge(edge.q, edge.r, edge.dir) and not board:hasRoad(edge.q, edge.r, edge.dir) then
      validEdges[#validEdges + 1] = {q = edge.q, r = edge.r, dir = edge.dir}
    end
  end

  return validEdges
end

---
-- 선택 모드에 따른 유효 위치 계산 (Story 7-6 수정)
-- @param mode string 선택 모드
---
updateValidLocations = function(mode)
  -- Setup 모드 처리 (Story 7-6)
  if gameState and gameState:isSetup() then
    local setupPhase = gameState:getSetupPhase()
    local setupPlayer = gameState:getSetupPlayer()

    if setupPhase == "settlement" then
      -- 초기 배치: 거리 규칙만 적용 (isInitialPlacement = true)
      validVertices = Rules.getValidSettlementLocations(board, setupPlayer, true)
      validEdges = nil
    elseif setupPhase == "road" then
      -- 도로 배치: 마지막 정착지에 인접한 변만
      if lastPlacedSettlement then
        validEdges = getSetupRoadLocations(lastPlacedSettlement)
      else
        validEdges = {}
      end
      validVertices = nil
    end
    return
  end

  -- Playing 모드 (기존 로직)
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
  lastPlacedSettlement = nil

  -- Setup 모드 초기화 (Story 7-6)
  if gameState:isSetup() then
    updateValidLocations()  -- 초기 정착지 배치 가능 위치 계산
    print(string.format("Game started in Setup mode - Player %d: Place Settlement", gameState:getSetupPlayer()))
  else
    print(string.format("Game started with %d players", gameState.config.playerCount))
  end
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

function game:update(dt)
  if not gameState then return end

  -- 피드백 메시지 타이머 (AC 8-1.6)
  if feedbackMessage and feedbackTimer > 0 then
    feedbackTimer = feedbackTimer - dt
    if feedbackTimer <= 0 then
      feedbackMessage = nil
      feedbackTimer = 0
    end
  end

  -- 게임 모드가 finished면 즉시 전환
  if gameState.mode == "finished" and gameState.winner then
    local game_over = require("src.scenes.game_over")
    Gamestate.switch(game_over, gameState.winner, gameState.players)
  end
end

function game:draw()
  -- 배경
  love.graphics.clear(0.1, 0.15, 0.2)

  -- 보드 렌더링 (AC 8-1.5: 하이라이트 숫자 전달)
  BoardView.draw(board, HEX_SIZE, OFFSET_X, OFFSET_Y, buildings, highlightedNumber)

  -- 하이라이트 렌더링 (Setup 모드 또는 선택 모드)
  if gameState:isSetup() or selectionMode ~= "none" then
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
    adminMode = adminMode,
    isSetup = gameState:isSetup(),  -- Setup 모드 플래그
  }

  for i, player in ipairs(gameState.players) do
    hudState.players[i] = {
      id = player.id,
      resources = player.resources,
      victoryPoints = player:getVictoryPoints(),
      buildings = player.buildings,  -- 건물 현황
    }
  end

  HUD.draw(hudState, screenWidth, screenHeight)

  -- 액션 버튼 렌더링 (Story 7-5)
  drawActionButtons()

  -- Setup 모드 UI 렌더링 (Story 7-6)
  drawSetupUI(screenWidth)

  -- 툴팁 렌더링 (AC 8-1.3)
  drawTooltip()

  -- 자원 획득 정보 오버레이 (AC 8-1.5)
  drawResourceGains()

  -- 피드백 메시지 (AC 8-1.6)
  drawFeedbackMessage()

  -- 디버그 정보
  love.graphics.setColor(1, 1, 1, 1)
  if gameState:isSetup() then
    love.graphics.print(string.format("Mode: Setup | Round: %d | Player: %d | Phase: %s",
      gameState.setup.round,
      gameState:getSetupPlayer(),
      gameState:getSetupPhase()), 10, screenHeight - 40)
  else
    love.graphics.print(string.format("Players: %d | Current: P%d | Round: %d | Phase: %s",
      gameState.config.playerCount,
      gameState.turn.current,
      gameState.turn.round,
      gameState.turn.phase), 10, screenHeight - 40)
  end
  love.graphics.print("Settlus of Catan - FPS: " .. love.timer.getFPS(), 10, screenHeight - 20)
end

function game:keypressed(key)
  -- F1: Admin 모드 토글 (AC 8-1.1)
  if key == "1" then
    adminMode = not adminMode
    print("Admin mode: " .. (adminMode and "ON" or "OFF"))
    return
  end

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

  -- 툴팁 업데이트 (AC 8-1.3)
  tooltip.visible = false
  if hoverButtonIndex then
    local btn = actionButtons[hoverButtonIndex]
    if btn.id == "settlement" or btn.id == "city" or btn.id == "road" then
      tooltip.visible = true
      tooltip.x = btn.x
      tooltip.y = btn.y + btn.h / 2 - 10
      tooltip.text = getBuildCostText(btn.id)
    end
  end

  -- Setup 모드 호버 처리 (Story 7-6)
  if gameState and gameState:isSetup() then
    local setupPhase = gameState:getSetupPhase()
    if setupPhase == "settlement" then
      local vertex = Input.pixelToVertex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)
      if vertex and isValidVertex(vertex) then
        hoverVertex = vertex
      else
        hoverVertex = nil
      end
      hoverEdge = nil
    elseif setupPhase == "road" then
      local edge = Input.pixelToEdge(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, EDGE_THRESHOLD)
      if edge and isValidEdge(edge) then
        hoverEdge = edge
      else
        hoverEdge = nil
      end
      hoverVertex = nil
    end
    return
  end

  -- Playing 모드 (기존 로직)
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

---
-- Setup 모드 클릭 처리 (Story 7-6: Task 4, 5, 6)
-- @param x number 마우스 x
-- @param y number 마우스 y
-- @return boolean 클릭이 처리되었으면 true
---
local function handleSetupClick(x, y)
  if not gameState:isSetup() then return false end

  local setupPhase = gameState:getSetupPhase()
  local setupPlayer = gameState:getSetupPlayer()
  local setupRound = gameState.setup.round
  local game_obj = {board = board, players = gameState.players}

  if setupPhase == "settlement" then
    -- 정착지 배치 (AC 7-6.2)
    local vertex = Input.pixelToVertex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)
    if vertex and isValidVertex(vertex) then
      local success, err = Actions.buildSettlementFree(game_obj, setupPlayer, vertex)
      if success then
        print(string.format("Setup: Player %d placed settlement at (%d, %d, %s)",
          setupPlayer, vertex.q, vertex.r, vertex.dir))

        -- 마지막 배치 정착지 저장 (도로 연결용)
        lastPlacedSettlement = {q = vertex.q, r = vertex.r, dir = vertex.dir}
        gameState.setup.lastPlacedSettlement = lastPlacedSettlement

        -- Round 2에서는 자원 지급 (AC 7-6.5)
        if setupRound == 2 then
          local resources = Rules.getInitialResources(board, vertex)
          local player = gameState.players[setupPlayer]
          for resourceType, amount in pairs(resources) do
            player:addResource(resourceType, amount)
            print(string.format("  -> Player %d received %d %s", setupPlayer, amount, resourceType))
          end
        end

        -- phase 전환: settlement → road
        gameState:advanceSetup()

        -- 도로 배치 가능 위치 계산
        updateValidLocations()
        hoverVertex = nil
        hoverEdge = nil

        return true
      else
        print("Setup: Failed to place settlement - " .. (err or "Unknown error"))
      end
    end
  elseif setupPhase == "road" then
    -- 도로 배치 (AC 7-6.3)
    local edge = Input.pixelToEdge(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, EDGE_THRESHOLD)
    if edge and isValidEdge(edge) then
      local success, err = Actions.buildRoadFree(game_obj, setupPlayer, edge)
      if success then
        print(string.format("Setup: Player %d placed road at (%d, %d, %s)",
          setupPlayer, edge.q, edge.r, edge.dir))

        -- 마지막 정착지 초기화
        lastPlacedSettlement = nil

        -- phase 전환: road → 다음 플레이어 또는 다음 라운드 또는 playing
        gameState:advanceSetup()

        -- 상태 확인 및 다음 위치 계산
        if gameState:isSetup() then
          updateValidLocations()
          print(string.format("Setup: Now Player %d - %s phase (Round %d)",
            gameState:getSetupPlayer(),
            gameState:getSetupPhase(),
            gameState.setup.round))
        else
          -- Setup 완료, Playing 모드로 전환됨
          validVertices = nil
          validEdges = nil
          print(string.format("Setup complete! Game starts - Player %d's turn",
            gameState:getCurrentPlayerId()))
        end

        hoverVertex = nil
        hoverEdge = nil

        return true
      else
        print("Setup: Failed to place road - " .. (err or "Unknown error"))
      end
    end
  end

  return false
end

function game:mousepressed(x, y, button)
  if button ~= 1 then return end  -- 좌클릭만 처리

  -- 0. Setup 모드 클릭 처리 (Story 7-6)
  if gameState and gameState:isSetup() then
    handleSetupClick(x, y)
    return
  end

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
