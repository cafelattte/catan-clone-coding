-- src/scenes/game_over.lua
-- 게임 종료 씬 (Story 7-4)
-- hump.gamestate 호환 씬 구조

local Gamestate = require("lib.hump.gamestate")
local Colors = require("src.ui.colors")

local game_over = {}

-- 씬 상태
local winner = nil     -- 승자 플레이어 ID
local players = {}     -- 플레이어 목록

-- 화면 크기
local screenWidth, screenHeight

-- 버튼 설정
local BUTTON_WIDTH = 200
local BUTTON_HEIGHT = 50
local BUTTON_SPACING = 20

-- 버튼 목록
local buttons = {}

-- 호버 상태
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
-- 버튼 초기화
---
local function initButtons()
  local centerX = screenWidth / 2 - BUTTON_WIDTH / 2
  -- 버튼 위치: 점수 목록 아래
  local buttonStartY = screenHeight / 2 + 120

  buttons = {
    {text = "New Game", x = centerX, y = buttonStartY, w = BUTTON_WIDTH, h = BUTTON_HEIGHT, action = "new_game"},
    {text = "Exit", x = centerX, y = buttonStartY + BUTTON_HEIGHT + BUTTON_SPACING, w = BUTTON_WIDTH, h = BUTTON_HEIGHT, action = "exit"},
  }
end

---
-- 마우스 위치에 있는 버튼 인덱스 찾기
-- @param x number 마우스 x
-- @param y number 마우스 y
-- @return number|nil 버튼 인덱스
---
local function findHoveredButton(x, y)
  for i, btn in ipairs(buttons) do
    if isPointInRect(x, y, btn.x, btn.y, btn.w, btn.h) then
      return i
    end
  end
  return nil
end

---
-- 버튼 액션 처리
-- @param action string 액션 이름
---
local function handleAction(action)
  if action == "new_game" then
    -- 상태 정리
    winner = nil
    players = {}

    -- 가비지 컬렉션
    collectgarbage("collect")

    -- 메인 메뉴로 전환
    local menu = require("src.scenes.menu")
    Gamestate.switch(menu)
  elseif action == "exit" then
    love.event.quit()
  end
end

-- hump.gamestate 콜백들 --

---
-- 씬 진입
-- @param previous table 이전 씬
-- @param winnerId number 승자 플레이어 ID
-- @param playerList table 플레이어 목록
---
function game_over:enter(previous, winnerId, playerList) -- luacheck: ignore previous
  winner = winnerId
  players = playerList or {}

  -- 화면 크기 설정
  screenWidth = love.graphics.getWidth()
  screenHeight = love.graphics.getHeight()

  -- 버튼 초기화
  initButtons()

  -- 호버 초기화
  hoverButtonIndex = nil

  print(string.format("Game Over! Player %d wins!", winner or 0))
end

---
-- 씬 이탈
---
function game_over:leave()
  -- 상태 정리
  winner = nil
  players = {}
  buttons = {}
  hoverButtonIndex = nil
end

---
-- 업데이트
-- @param dt number 델타 타임
---
function game_over:update(dt) -- luacheck: ignore dt
  -- 애니메이션이 필요하면 여기서 처리
end

---
-- 렌더링
---
function game_over:draw()
  -- 배경
  love.graphics.clear(0.1, 0.1, 0.15)

  -- 승리 타이틀
  local titleY = screenHeight / 6

  -- 승자 색상으로 타이틀 표시
  if winner and Colors.PLAYER[winner] then
    local pc = Colors.PLAYER[winner]
    love.graphics.setColor(pc[1], pc[2], pc[3], 1)
  else
    love.graphics.setColor(1, 0.8, 0.2, 1)  -- 금색 기본값
  end

  local titleText = string.format("Player %d Wins!", winner or 0)
  love.graphics.printf(titleText, 0, titleY, screenWidth, "center")

  -- 서브타이틀
  love.graphics.setColor(0.7, 0.7, 0.7, 1)
  love.graphics.printf("Final Scores", 0, titleY + 50, screenWidth, "center")

  -- 점수 목록
  local scoreY = screenHeight / 3
  local lineHeight = 40

  for i, player in ipairs(players) do
    local isWinner = (i == winner)
    local points = 0

    -- Player 객체의 getVictoryPoints 메소드 호출
    if player.getVictoryPoints then
      points = player:getVictoryPoints()
    elseif player.victoryPoints then
      points = player.victoryPoints
    end

    -- 승자 하이라이트
    if isWinner then
      -- 금색 배경 하이라이트
      love.graphics.setColor(1, 0.8, 0.2, 0.2)
      love.graphics.rectangle("fill", screenWidth / 2 - 150, scoreY - 5, 300, lineHeight - 5, 4, 4)

      -- 금색 텍스트
      love.graphics.setColor(1, 0.8, 0.2, 1)
    else
      -- 일반 텍스트
      love.graphics.setColor(0.8, 0.8, 0.8, 1)
    end

    -- 플레이어 색상 인디케이터
    if Colors.PLAYER[i] then
      local pc = Colors.PLAYER[i]
      love.graphics.setColor(pc[1], pc[2], pc[3], 1)
      love.graphics.rectangle("fill", screenWidth / 2 - 140, scoreY + 5, 20, 20, 3, 3)
    end

    -- 텍스트 색상 복원
    if isWinner then
      love.graphics.setColor(1, 0.8, 0.2, 1)
    else
      love.graphics.setColor(0.8, 0.8, 0.8, 1)
    end

    -- 점수 텍스트
    local scoreText = string.format("Player %d: %d points", i, points)
    if isWinner then
      scoreText = scoreText .. " ★"
    end
    love.graphics.printf(scoreText, screenWidth / 2 - 100, scoreY + 5, 250, "left")

    scoreY = scoreY + lineHeight
  end

  -- 버튼 렌더링
  for i, btn in ipairs(buttons) do
    local isHovered = (hoverButtonIndex == i)
    drawButton(btn.text, btn.x, btn.y, btn.w, btn.h, isHovered)
  end

  -- 하단 안내
  love.graphics.setColor(0.5, 0.5, 0.5, 1)
  love.graphics.printf("Press Enter for New Game, ESC to Exit", 0, screenHeight - 30, screenWidth, "center")
end

---
-- 마우스 이동
-- @param x number 마우스 x
-- @param y number 마우스 y
---
function game_over:mousemoved(x, y)
  hoverButtonIndex = findHoveredButton(x, y)
end

---
-- 마우스 클릭
-- @param x number 마우스 x
-- @param y number 마우스 y
-- @param button number 마우스 버튼
---
function game_over:mousepressed(x, y, button)
  if button == 1 then -- 좌클릭
    local idx = findHoveredButton(x, y)
    if idx then
      handleAction(buttons[idx].action)
    end
  end
end

---
-- 키 입력
-- @param key string 키 이름
---
function game_over:keypressed(key)
  if key == "escape" then
    -- ESC → 메인 메뉴로 이동
    handleAction("new_game")
  elseif key == "return" or key == "kpenter" then
    -- Enter → 새 게임 (메인 메뉴로)
    handleAction("new_game")
  end
end

return game_over
