-- src/game/game_state.lua
-- 게임 상태 관리 (턴 순서, 플레이어, 라운드, 페이즈)
-- Story 7-1: 턴 순서 관리
-- Story 7-2: 페이즈 관리, 주사위 굴림, 승리 체크

local Class = require("lib.classic")
local Player = require("src.game.player")
local Dice = require("src.game.dice")
local Rules = require("src.game.rules")

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
    phase = "roll",   -- "roll" | "main"
    round = 1,        -- 현재 라운드
  }

  -- 게임 모드 (Story 7-6: 게임은 setup 모드로 시작)
  self.mode = "setup"  -- "setup" | "playing" | "finished"

  -- Board 연결은 Story 7-2에서
  self.board = nil

  -- Setup 구조체 (Story 7-6)
  self.setup = {
    round = 1,                    -- 1 또는 2
    direction = "forward",        -- "forward" | "reverse"
    phase = "settlement",         -- "settlement" | "road"
    currentPlayer = 1,            -- 현재 배치할 플레이어 (1-based)
    lastPlacedSettlement = nil,   -- 마지막 배치한 정착지 위치 (도로 연결용)
  }

  -- 주사위 결과 (Story 7-2에서 구현)
  self.diceResult = nil

  -- 승자 (Story 7-4에서 구현)
  self.winner = nil
end

--- Setup 모드인지 확인 (Story 7-6)
-- @return boolean mode == "setup"
function GameState:isSetup()
  return self.mode == "setup"
end

--- Setup 모드에서 현재 배치할 플레이어 ID 반환 (Story 7-6)
-- @return number 플레이어 ID (1-based)
function GameState:getSetupPlayer()
  return self.setup.currentPlayer
end

--- Setup 모드에서 현재 페이즈 반환 (Story 7-6)
-- @return string "settlement" | "road"
function GameState:getSetupPhase()
  return self.setup.phase
end

--- Setup 페이즈 진행 (Story 7-6)
-- settlement → road, road → 다음 플레이어, Round 전환, playing 모드 전환
function GameState:advanceSetup()
  if self.setup.phase == "settlement" then
    -- settlement -> road 페이즈로 전환
    self.setup.phase = "road"
  else
    -- road 페이즈 완료 후 다음 단계로
    self.setup.phase = "settlement"
    self.setup.lastPlacedSettlement = nil  -- 도로 배치용 정착지 위치 초기화

    if self.setup.direction == "forward" then
      -- Round 1: 정순 (1 → 2 → 3 → 4)
      if self.setup.currentPlayer < self.config.playerCount then
        self.setup.currentPlayer = self.setup.currentPlayer + 1
      else
        -- Round 1 완료 → Round 2 시작 (마지막 플레이어부터 역순)
        self.setup.round = 2
        self.setup.direction = "reverse"
        -- currentPlayer는 그대로 유지 (마지막 플레이어가 다시 시작)
      end
    else
      -- Round 2: 역순 (4 → 3 → 2 → 1)
      if self.setup.currentPlayer > 1 then
        self.setup.currentPlayer = self.setup.currentPlayer - 1
      else
        -- Round 2 완료 → playing 모드로 전환
        self.mode = "playing"
        self.turn.current = 1
        self.turn.phase = "roll"
        self.setup = nil  -- Setup 구조체 정리
      end
    end
  end
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
-- phase를 "roll"로 리셋, diceResult를 nil로 초기화
function GameState:endTurn()
  self:nextPlayer()
  self.turn.phase = "roll"
  self.diceResult = nil
end

--- 현재 라운드 조회
-- @return number 현재 라운드
function GameState:getRound()
  return self.turn.round
end

--- 현재 페이즈 조회
-- @return string "roll" | "main"
function GameState:getPhase()
  return self.turn.phase
end

--- 페이즈 설정 (내부 헬퍼)
-- @param phase string "roll" | "main"
function GameState:setPhase(phase)
  self.turn.phase = phase
end

--- 주사위 굴림 가능 여부
-- @return boolean mode == "playing" AND phase == "roll"
function GameState:canRoll()
  return self.mode == "playing" and self.turn.phase == "roll"
end

--- 건설 가능 여부
-- @return boolean mode == "playing" AND phase == "main"
function GameState:canBuild()
  return self.mode == "playing" and self.turn.phase == "main"
end

--- 주사위 굴림
-- @return table {die1, die2, sum} | nil, string 에러 메시지
function GameState:rollDice()
  if not self:canRoll() then
    return nil, "Cannot roll in current phase"
  end

  local result = Dice.roll()
  self.diceResult = result
  self.turn.phase = "main"

  -- 7이 아닌 경우 자원 분배
  if result.sum ~= 7 and self.board then
    Rules.distributeResources(self.board, self.players, result.sum)
  end

  return result
end

--- 승리 체크
-- @return number|nil 승자 플레이어 ID 또는 nil
function GameState:checkVictory()
  local winnerId = Rules.checkVictory(self.players, self.config.victoryTarget)
  if winnerId then
    self.mode = "finished"
    self.winner = winnerId
  end
  return winnerId
end

return GameState
