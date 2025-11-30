-- main.lua
-- Love2D 엔트리포인트

local Board = require("src.game.board")
local BoardView = require("src.ui.board_view")

-- 게임 상태
local board
local HEX_SIZE = 50
local OFFSET_X, OFFSET_Y

function love.load()
  -- 보드 생성
  board = Board.newStandard()

  -- 화면 중앙 오프셋 계산
  OFFSET_X = love.graphics.getWidth() / 2
  OFFSET_Y = love.graphics.getHeight() / 2
end

function love.update(dt)
  -- 업데이트 로직 (나중에 구현)
end

function love.draw()
  -- 배경 색상
  love.graphics.clear(0.1, 0.15, 0.2)

  -- 보드 렌더링
  BoardView.draw(board, HEX_SIZE, OFFSET_X, OFFSET_Y)

  -- 디버그 정보
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Settlus of Catan", 10, 10)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 30)
end
