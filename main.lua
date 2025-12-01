-- main.lua
-- Love2D 엔트리포인트

local Board = require("src.game.board")
local BoardView = require("src.ui.board_view")
local HUD = require("src.ui.hud")
local Input = require("src.ui.input")

-- 게임 상태
local board
local testBuildings
local testGameState
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
end

function love.update(dt)
  -- 업데이트 로직 (나중에 구현)
end

function love.draw()
  -- 배경 색상
  love.graphics.clear(0.1, 0.15, 0.2)

  -- 보드 렌더링 (건물 포함)
  BoardView.draw(board, HEX_SIZE, OFFSET_X, OFFSET_Y, testBuildings)

  -- HUD 렌더링 (보드 위에 최상단 레이어)
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  HUD.draw(testGameState, screenWidth, screenHeight)

  -- 디버그 정보 (HUD 아래 좌측 - 주사위 결과와 겹치지 않게 아래쪽으로 이동)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Settlus of Catan - FPS: " .. love.timer.getFPS(), 10, screenHeight - 20)
end

-- 마우스 클릭 처리 (디버그용)
function love.mousepressed(x, y, button)
  if button == 1 then -- 좌클릭
    local VERTEX_THRESHOLD = 15
    local EDGE_THRESHOLD = 10

    -- 헥스 좌표 변환
    local hex = Input.pixelToHex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y)

    -- 정점 좌표 변환
    local vertex = Input.pixelToVertex(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)

    -- 변 좌표 변환
    local edge = Input.pixelToEdge(x, y, HEX_SIZE, OFFSET_X, OFFSET_Y, EDGE_THRESHOLD)

    -- 디버그 출력
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
