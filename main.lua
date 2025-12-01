-- main.lua
-- Love2D 엔트리포인트

local Board = require("src.game.board")
local BoardView = require("src.ui.board_view")

-- 게임 상태
local board
local testBuildings
local HEX_SIZE = 50
local OFFSET_X, OFFSET_Y

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
end

function love.update(dt)
  -- 업데이트 로직 (나중에 구현)
end

function love.draw()
  -- 배경 색상
  love.graphics.clear(0.1, 0.15, 0.2)

  -- 보드 렌더링 (건물 포함)
  BoardView.draw(board, HEX_SIZE, OFFSET_X, OFFSET_Y, testBuildings)

  -- 디버그 정보
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Settlus of Catan", 10, 10)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 30)
end
