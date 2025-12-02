-- src/ui/hud.lua
-- HUD (Heads-Up Display) 렌더링 모듈

local Colors = require("src.ui.colors")
local Constants = require("src.game.constants")

local HUD = {}

-- 자원 색상 (HUD 전용)
local RESOURCE_COLORS = {
  wood = {0.55, 0.35, 0.2},   -- 갈색
  brick = {0.8, 0.4, 0.2},    -- 주황
  sheep = {0.6, 0.8, 0.4},    -- 연두
  wheat = {0.9, 0.8, 0.3},    -- 노랑
  ore = {0.5, 0.5, 0.5},      -- 회색
}

-- 자원 이름 (한글)
local RESOURCE_NAMES = {
  wood = "Wood",
  brick = "Brick",
  sheep = "Sheep",
  wheat = "Wheat",
  ore = "Ore",
}

-- HUD 설정
local CONFIG = {
  padding = 10,
  panelHeight = 60,
  scoreWidth = 120,
  turnInfoHeight = 30,
  diceWidth = 100,
}

---
-- 자원 패널 렌더링 (화면 하단 중앙)
-- @param player table 플레이어 데이터 {resources = {...}, ...}
-- @param x number 패널 X 좌표
-- @param y number 패널 Y 좌표
-- @param width number 패널 너비
-- @param height number 패널 높이
---
function HUD.drawResourcePanel(player, x, y, width, height)
  if not player or not player.resources then return end

  -- 패널 배경
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle("fill", x, y, width, height, 5, 5)

  -- 자원별 표시
  local resourceCount = #Constants.RESOURCE_TYPES
  local itemWidth = width / resourceCount
  local font = love.graphics.getFont()

  for i, resourceType in ipairs(Constants.RESOURCE_TYPES) do
    local amount = player.resources[resourceType] or 0
    local itemX = x + (i - 1) * itemWidth
    local centerX = itemX + itemWidth / 2

    -- 자원 색상 박스 (상단)
    local boxWidth = 60
    local boxHeight = 14
    local color = RESOURCE_COLORS[resourceType]
    love.graphics.setColor(color[1], color[2], color[3])
    love.graphics.rectangle("fill", centerX - boxWidth / 2, y + 4, boxWidth, boxHeight, 3, 3)

    -- 자원 이름 (중간)
    love.graphics.setColor(1, 1, 1)
    local name = RESOURCE_NAMES[resourceType]
    local nameWidth = font:getWidth(name)
    love.graphics.print(name, centerX - nameWidth / 2, y + 20)

    -- 자원 수량 (하단)
    local amountText = tostring(amount)
    local amountWidth = font:getWidth(amountText)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(amountText, centerX - amountWidth / 2, y + 34)
  end
end

---
-- 점수 패널 렌더링 (화면 우측 상단)
-- @param players table 플레이어 배열
-- @param currentPlayerId number 현재 턴 플레이어 ID
-- @param x number 패널 X 좌표
-- @param y number 패널 Y 좌표
---
function HUD.drawScorePanel(players, currentPlayerId, x, y, adminMode)
  if not players then return end

  local font = love.graphics.getFont()
  local lineHeight = font:getHeight() + 4
  local panelWidth = 200  -- 확장된 너비
  
  -- 패널 높이 계산 (플레이어당 라인 수 증가)
  local linesPerPlayer = adminMode and 3 or 2  -- admin: VP + 자원상세 + 건물, 일반: VP+카드수 + 건물
  local panelHeight = #players * (linesPerPlayer * lineHeight + 8) + CONFIG.padding * 2

  -- 패널 배경
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.rectangle("fill", x, y, panelWidth, panelHeight, 5, 5)

  local currentY = y + CONFIG.padding

  for i, player in ipairs(players) do
    local playerId = player.id or i
    local vp = player.victoryPoints or 0

    -- 현재 턴 플레이어 강조 (배경)
    local playerBlockHeight = linesPerPlayer * lineHeight + 4
    if playerId == currentPlayerId then
      love.graphics.setColor(1, 1, 1, 0.15)
      love.graphics.rectangle("fill", x + 2, currentY - 2, panelWidth - 4, playerBlockHeight, 3, 3)
    end

    -- 플레이어 색상 마커 + 이름/VP
    local playerColor = Colors.PLAYER[playerId] or {0.5, 0.5, 0.5}
    love.graphics.setColor(playerColor[1], playerColor[2], playerColor[3])
    love.graphics.rectangle("fill", x + CONFIG.padding, currentY + 2, 12, 12, 2, 2)

    love.graphics.setColor(1, 1, 1)
    local headerText = string.format("P%d: %d VP", playerId, vp)
    love.graphics.print(headerText, x + CONFIG.padding + 18, currentY)
    currentY = currentY + lineHeight

    -- 자원 표시
    if player.resources then
      local resourceText
      if adminMode then
        -- Admin 모드: 각 자원 상세 표시
        local parts = {}
        for _, resType in ipairs(Constants.RESOURCE_TYPES) do
          local amount = player.resources[resType] or 0
          if amount > 0 then
            local initial = resType:sub(1, 1):upper()
            table.insert(parts, initial .. ":" .. amount)
          end
        end
        resourceText = #parts > 0 and table.concat(parts, " ") or "(no cards)"
      else
        -- 일반 모드: 총 카드 수만
        local total = 0
        for _, resType in ipairs(Constants.RESOURCE_TYPES) do
          total = total + (player.resources[resType] or 0)
        end
        resourceText = string.format("%d cards", total)
      end
      love.graphics.setColor(0.8, 0.8, 0.8)
      love.graphics.print("  " .. resourceText, x + CONFIG.padding, currentY)
      currentY = currentY + lineHeight
    end

    -- 건물 현황 표시
    if player.buildings then
      local b = player.buildings
      local buildText = string.format("  R:%d S:%d C:%d", 
        b.roads or 0, b.settlements or 0, b.cities or 0)
      love.graphics.setColor(0.7, 0.7, 0.7)
      love.graphics.print(buildText, x + CONFIG.padding, currentY)
      currentY = currentY + lineHeight
    end

    currentY = currentY + 4  -- 플레이어 간 간격
  end
end

---
-- 턴 정보 패널 렌더링 (화면 상단 중앙)
-- @param currentPlayer number 현재 턴 플레이어 ID
-- @param phase string 현재 페이즈 ("roll", "build", "trade")
-- @param x number 패널 중앙 X 좌표
-- @param y number 패널 Y 좌표
---
function HUD.drawTurnInfo(currentPlayer, phase, x, y)
  if not currentPlayer then return end

  local font = love.graphics.getFont()
  local text = string.format("Player %d's Turn", currentPlayer)
  local phaseText = phase and string.format("(%s)", phase) or ""
  local fullText = text .. " " .. phaseText

  local textWidth = font:getWidth(fullText)
  local textHeight = font:getHeight()
  local panelWidth = textWidth + CONFIG.padding * 4
  local panelHeight = textHeight + CONFIG.padding * 2
  local panelX = x - panelWidth / 2

  -- 플레이어 색상으로 배경
  local playerColor = Colors.PLAYER[currentPlayer] or {0.5, 0.5, 0.5}
  love.graphics.setColor(playerColor[1], playerColor[2], playerColor[3], 0.8)
  love.graphics.rectangle("fill", panelX, y, panelWidth, panelHeight, 5, 5)

  -- 텍스트 (검정 테두리 효과)
  love.graphics.setColor(0, 0, 0)
  love.graphics.print(fullText, panelX + CONFIG.padding * 2 + 1, y + CONFIG.padding + 1)

  -- 텍스트 (흰색)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print(fullText, panelX + CONFIG.padding * 2, y + CONFIG.padding)
end

---
-- 주사위 결과 렌더링 (화면 좌측 상단)
-- @param die1 number 첫 번째 주사위 값
-- @param die2 number 두 번째 주사위 값
-- @param x number 패널 X 좌표
-- @param y number 패널 Y 좌표
---
function HUD.drawDiceResult(die1, die2, x, y)
  if not die1 or not die2 then return end

  local sum = die1 + die2
  local font = love.graphics.getFont()
  local text = string.format("[%d] + [%d] = %d", die1, die2, sum)
  local textWidth = font:getWidth(text)
  local textHeight = font:getHeight()
  local panelWidth = textWidth + CONFIG.padding * 4
  local panelHeight = textHeight + CONFIG.padding * 2

  -- 패널 배경
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.rectangle("fill", x, y, panelWidth, panelHeight, 5, 5)

  -- 7인 경우 특별 색상 (도둑 활성화)
  if sum == 7 then
    love.graphics.setColor(0.9, 0.2, 0.2)  -- 빨간색
  else
    love.graphics.setColor(1, 1, 1)
  end

  love.graphics.print(text, x + CONFIG.padding * 2, y + CONFIG.padding)
end

---
-- 전체 HUD 렌더링
-- @param gameState table 게임 상태 {players, turn, diceResult}
-- @param screenWidth number 화면 너비
-- @param screenHeight number 화면 높이
---
function HUD.draw(gameState, screenWidth, screenHeight)
  if not gameState then return end

  local players = gameState.players
  local turn = gameState.turn
  local diceResult = gameState.diceResult

  -- 현재 플레이어 정보
  local currentPlayerId = turn and turn.current or 1
  local currentPlayer = players and players[currentPlayerId]
  local phase = turn and turn.phase

  -- 자원 패널 (하단 중앙)
  local resourcePanelWidth = 600
  local resourcePanelHeight = CONFIG.panelHeight
  local resourcePanelX = (screenWidth - resourcePanelWidth) / 2
  local resourcePanelY = screenHeight - resourcePanelHeight - CONFIG.padding
  HUD.drawResourcePanel(currentPlayer, resourcePanelX, resourcePanelY, resourcePanelWidth, resourcePanelHeight)

  -- 점수 패널 (우측 상단)
  local scorePanelX = screenWidth - CONFIG.scoreWidth - CONFIG.padding
  local scorePanelY = CONFIG.padding
  HUD.drawScorePanel(players, currentPlayerId, scorePanelX, scorePanelY, gameState.adminMode)

  -- 턴 정보 (상단 중앙)
  local turnInfoX = screenWidth / 2
  local turnInfoY = CONFIG.padding
  HUD.drawTurnInfo(currentPlayerId, phase, turnInfoX, turnInfoY)

  -- 주사위 결과 (좌측 상단) - 결과가 있을 때만
  if diceResult then
    local diceX = CONFIG.padding
    local diceY = CONFIG.padding
    HUD.drawDiceResult(diceResult.die1, diceResult.die2, diceX, diceY)
  end

  -- 색상 리셋
  love.graphics.setColor(1, 1, 1, 1)
end

return HUD
