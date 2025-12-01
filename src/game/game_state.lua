-- src/game/game_state.lua
-- 게임 상태 관리 (턴 순서, 플레이어, 라운드)

local Class = require("lib.classic")
local Player = require("src.game.player")

local GameState = Class:extend()

--- GameState 생성자
-- @param playerCount number 플레이어 수 (2-4)
function GameState:new(playerCount)
  -- config 초기화
  self.config = {
    playerCount = playerCount,
    victoryTarget = 10,
  }

  -- players 배열 초기화 (Player 객체들)
  self.players = {}
  for i = 1, playerCount do
    self.players[i] = Player(i)
  end

  -- turn 구조체 초기화
  self.turn = {
    current = 1,      -- 현재 플레이어 인덱스 (1-based)
    phase = nil,      -- "roll" | "main" (Story 7-2에서 구현)
    round = 1,        -- 현재 라운드
  }

  -- 게임 모드 (Story 7-2에서 활용)
  self.mode = "playing"  -- "setup" | "playing" | "finished"

  -- Board 연결은 Story 7-2에서
  self.board = nil

  -- Setup 구조체 (Story 7-2에서 구현)
  self.setup = nil

  -- 주사위 결과 (Story 7-2에서 구현)
  self.diceResult = nil

  -- 승자 (Story 7-4에서 구현)
  self.winner = nil
end

--- 현재 턴 플레이어 객체 반환
-- @return Player 현재 플레이어 객체
function GameState:getCurrentPlayer()
  return self.players[self.turn.current]
end

--- 현재 턴 플레이어 인덱스 반환
-- @return number 현재 플레이어 인덱스 (1-based)
function GameState:getCurrentPlayerId()
  return self.turn.current
end

--- 특정 플레이어 조회
-- @param id number 플레이어 인덱스 (1-based)
-- @return Player|nil 플레이어 객체 또는 nil
function GameState:getPlayer(id)
  if id < 1 or id > self.config.playerCount then
    return nil
  end
  return self.players[id]
end

--- 다음 플레이어로 전환 (내부 헬퍼)
-- 모듈로 연산으로 순환, 플레이어1로 돌아오면 라운드 증가
function GameState:nextPlayer()
  self.turn.current = (self.turn.current % self.config.playerCount) + 1

  -- 플레이어1로 돌아오면 라운드 증가
  if self.turn.current == 1 then
    self.turn.round = self.turn.round + 1
  end
end

--- 턴 종료 (공개 API)
-- nextPlayer() 호출하여 다음 플레이어로 전환
function GameState:endTurn()
  self:nextPlayer()
end

--- 현재 라운드 조회
-- @return number 현재 라운드
function GameState:getRound()
  return self.turn.round
end

return GameState
