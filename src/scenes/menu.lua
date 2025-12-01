-- src/scenes/menu.lua
-- 메인 메뉴 씬 (Story 7-3)
-- hump.gamestate 호환 씬 구조

local Gamestate = require("lib.hump.gamestate")
local GameState = require("src.game.game_state")

local menu = {}

-- 메뉴 상태
local showPlayerSelect = false

-- 화면 크기 (enter에서 설정)
local screenWidth, screenHeight

-- 버튼 설정
local BUTTON_WIDTH = 200
local BUTTON_HEIGHT = 50
local BUTTON_SPACING = 20

-- 버튼 목록 (메인 메뉴)
local mainButtons = {}

-- 버튼 목록 (플레이어 수 선택)
local playerSelectButtons = {}

-- 마우스 호버 상태
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
-- 버튼 렌더링
-- @param text string 버튼 텍스트
-- @param x number x 좌표
-- @param y number y 좌표
-- @param w number 너비
-- @param h number 높이
-- @param isHovered boolean 호버 상태
---
local function drawButton(text, x, y, w, h, isHovered)
  -- 배경색
  if isHovered then
    love.graphics.setColor(0.4, 0.4, 0.5, 1)
  else
    love.graphics.setColor(0.2, 0.2, 0.3, 1)
  end
  love.graphics.rectangle("fill", x, y, w, h, 8, 8)

  -- 테두리
  love.graphics.setColor(0.6, 0.6, 0.7, 1)
  love.graphics.rectangle("line", x, y, w, h, 8, 8)

  -- 텍스트
  love.graphics.setColor(1, 1, 1, 1)
  local font = love.graphics.getFont()
  local textY = y + (h - font:getHeight()) / 2
  love.graphics.printf(text, x, textY, w, "center")
end

---
-- 버튼 목록 초기화
---
local function initButtons()
  local centerX = screenWidth / 2 - BUTTON_WIDTH / 2
  local startY = screenHeight / 2

  -- 메인 메뉴 버튼
  mainButtons = {
    {text = "New Game", x = centerX, y = startY, w = BUTTON_WIDTH, h = BUTTON_HEIGHT, action = "new_game"},
    {text = "Exit", x = centerX, y = startY + BUTTON_HEIGHT + BUTTON_SPACING, w = BUTTON_WIDTH, h = BUTTON_HEIGHT, action = "exit"},
  }

  -- 플레이어 수 선택 버튼
  local smallWidth = 80
  local totalWidth = smallWidth * 3 + BUTTON_SPACING * 2
  local selectStartX = screenWidth / 2 - totalWidth / 2

  playerSelectButtons = {
    {text = "2", x = selectStartX, y = startY, w = smallWidth, h = BUTTON_HEIGHT, action = "select_2"},
    {text = "3", x = selectStartX + smallWidth + BUTTON_SPACING, y = startY, w = smallWidth, h = BUTTON_HEIGHT, action = "select_3"},
    {text = "4", x = selectStartX + smallWidth * 2 + BUTTON_SPACING * 2, y = startY, w = smallWidth, h = BUTTON_HEIGHT, action = "select_4"},
    {text = "Back", x = centerX, y = startY + BUTTON_HEIGHT + BUTTON_SPACING, w = BUTTON_WIDTH, h = BUTTON_HEIGHT, action = "back"},
  }
end

---
-- 현재 활성 버튼 목록 반환
-- @return table 버튼 배열
---
local function getCurrentButtons()
  if showPlayerSelect then
    return playerSelectButtons
  else
    return mainButtons
  end
end

---
-- 마우스 위치에 있는 버튼 인덱스 찾기
-- @param x number 마우스 x
-- @param y number 마우스 y
-- @return number|nil 버튼 인덱스
---
local function findHoveredButton(x, y)
  local buttons = getCurrentButtons()
  for i, btn in ipairs(buttons) do
    if isPointInRect(x, y, btn.x, btn.y, btn.w, btn.h) then
      return i
    end
  end
  return nil
end

---
-- 선택된 플레이어 수로 게임 시작
-- @param playerCount number 플레이어 수
---
local function startGame(playerCount)
  local game = require("src.scenes.game")
  local gameState = GameState(playerCount)
  Gamestate.switch(game, gameState)
end

---
-- 버튼 액션 처리
-- @param action string 액션 이름
---
local function handleAction(action)
  if action == "new_game" then
    showPlayerSelect = true
    hoverButtonIndex = nil
  elseif action == "exit" then
    love.event.quit()
  elseif action == "select_2" then
    startGame(2)
  elseif action == "select_3" then
    startGame(3)
  elseif action == "select_4" then
    startGame(4)
  elseif action == "back" then
    showPlayerSelect = false
    hoverButtonIndex = nil
  end
end

-- hump.gamestate 콜백들 --

function menu:enter(previous) -- luacheck: ignore previous
  showPlayerSelect = false
  hoverButtonIndex = nil

  -- 화면 크기 설정
  screenWidth = love.graphics.getWidth()
  screenHeight = love.graphics.getHeight()

  -- 버튼 초기화
  initButtons()
end

function menu:leave()
  -- 정리 (현재 필요 없음)
end

function menu:update(dt) -- luacheck: ignore dt
  -- 업데이트 로직 (현재 필요 없음)
end

function menu:draw()
  -- 배경
  love.graphics.clear(0.1, 0.15, 0.2)

  -- 타이틀
  love.graphics.setColor(1, 1, 1, 1)
  local titleY = screenHeight / 4
  love.graphics.printf("Settlus of Catan", 0, titleY, screenWidth, "center")

  -- 현재 모드에 따른 서브타이틀
  if showPlayerSelect then
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.printf("Select Number of Players", 0, titleY + 40, screenWidth, "center")
  end

  -- 버튼 렌더링
  local buttons = getCurrentButtons()
  for i, btn in ipairs(buttons) do
    local isHovered = (hoverButtonIndex == i)
    drawButton(btn.text, btn.x, btn.y, btn.w, btn.h, isHovered)
  end

  -- 하단 안내
  love.graphics.setColor(0.6, 0.6, 0.6, 1)
  love.graphics.printf("Press ESC to exit, Enter to start new game", 0, screenHeight - 30, screenWidth, "center")
end

function menu:mousemoved(x, y)
  hoverButtonIndex = findHoveredButton(x, y)
end

function menu:mousepressed(x, y, button)
  if button == 1 then -- 좌클릭
    local idx = findHoveredButton(x, y)
    if idx then
      local buttons = getCurrentButtons()
      handleAction(buttons[idx].action)
    end
  end
end

function menu:keypressed(key)
  if key == "escape" then
    if showPlayerSelect then
      showPlayerSelect = false
      hoverButtonIndex = nil
    else
      love.event.quit()
    end
  elseif key == "return" or key == "kpenter" then
    if not showPlayerSelect then
      showPlayerSelect = true
      hoverButtonIndex = nil
    end
  end
end

return menu
