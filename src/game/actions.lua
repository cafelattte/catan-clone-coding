-- src/game/actions.lua
-- 건설 실행 액션 (Story 5-4)

local Rules = require("src.game.rules")
local Constants = require("src.game.constants")

local Actions = {}

---
-- 플레이어 조회 헬퍼
-- @param game table 게임 상태
-- @param playerId number 플레이어 ID
-- @return Player 플레이어 인스턴스
---
local function getPlayer(game, playerId)
  return game.players[playerId]
end

---
-- 정착지 건설 (자원 소비)
-- @param game table 게임 상태 {board, players}
-- @param playerId number 플레이어 ID
-- @param vertex table {q, r, dir} 정점 좌표
-- @return boolean, string|nil 성공 시 true, 실패 시 false와 에러 메시지
---
function Actions.buildSettlement(game, playerId, vertex)
  local player = getPlayer(game, playerId)
  local board = game.board

  -- 1. 자원 확인
  local cost = Constants.BUILD_COSTS.settlement
  if not player:hasResources(cost) then
    return false, "Not enough resources"
  end

  -- 2. 규칙 검증
  local canBuild, err = Rules.canBuildSettlement(board, playerId, vertex, false)
  if not canBuild then
    return false, err
  end

  -- 3. 자원 차감
  for resource, amount in pairs(cost) do
    player:removeResource(resource, amount)
  end

  -- 4. 보드에 배치
  board:placeSettlement(playerId, vertex.q, vertex.r, vertex.dir)

  -- 5. 플레이어 건물 카운트 증가
  player.buildings.settlements = player.buildings.settlements + 1

  return true
end

---
-- 도로 건설 (자원 소비)
-- @param game table 게임 상태
-- @param playerId number 플레이어 ID
-- @param edge table {q, r, dir} 변 좌표
-- @return boolean, string|nil
---
function Actions.buildRoad(game, playerId, edge)
  local player = getPlayer(game, playerId)
  local board = game.board

  -- 1. 자원 확인
  local cost = Constants.BUILD_COSTS.road
  if not player:hasResources(cost) then
    return false, "Not enough resources"
  end

  -- 2. 규칙 검증
  local canBuild, err = Rules.canBuildRoad(board, playerId, edge)
  if not canBuild then
    return false, err
  end

  -- 3. 자원 차감
  for resource, amount in pairs(cost) do
    player:removeResource(resource, amount)
  end

  -- 4. 보드에 배치
  board:placeRoad(playerId, edge.q, edge.r, edge.dir)

  -- 5. 플레이어 도로 카운트 증가
  player.buildings.roads = player.buildings.roads + 1

  return true
end

---
-- 도시 업그레이드 (자원 소비)
-- @param game table 게임 상태
-- @param playerId number 플레이어 ID
-- @param vertex table {q, r, dir} 정점 좌표
-- @return boolean, string|nil
---
function Actions.buildCity(game, playerId, vertex)
  local player = getPlayer(game, playerId)
  local board = game.board

  -- 1. 자원 확인
  local cost = Constants.BUILD_COSTS.city
  if not player:hasResources(cost) then
    return false, "Not enough resources"
  end

  -- 2. 규칙 검증
  local canBuild, err = Rules.canBuildCity(board, playerId, vertex)
  if not canBuild then
    return false, err
  end

  -- 3. 자원 차감
  for resource, amount in pairs(cost) do
    player:removeResource(resource, amount)
  end

  -- 4. 보드에서 업그레이드
  board:upgradeToCity(vertex.q, vertex.r, vertex.dir)

  -- 5. 플레이어 건물 카운트 업데이트
  player.buildings.settlements = player.buildings.settlements - 1
  player.buildings.cities = player.buildings.cities + 1

  return true
end

---
-- 무료 정착지 건설 (초기 배치용)
-- @param game table 게임 상태
-- @param playerId number 플레이어 ID
-- @param vertex table {q, r, dir} 정점 좌표
-- @return boolean, string|nil
---
function Actions.buildSettlementFree(game, playerId, vertex)
  local player = getPlayer(game, playerId)
  local board = game.board

  -- 규칙 검증 (초기 배치 모드)
  local canBuild, err = Rules.canBuildSettlement(board, playerId, vertex, true)
  if not canBuild then
    return false, err
  end

  -- 보드에 배치
  board:placeSettlement(playerId, vertex.q, vertex.r, vertex.dir)

  -- 플레이어 건물 카운트 증가
  player.buildings.settlements = player.buildings.settlements + 1

  return true
end

---
-- 무료 도로 건설 (초기 배치용)
-- @param game table 게임 상태
-- @param playerId number 플레이어 ID
-- @param edge table {q, r, dir} 변 좌표
-- @return boolean, string|nil
-- TODO: 초기 배치 시 Rules.canBuildInitialRoad 사용 고려 (정착지 인접 검증)
--       현재는 정착지 배치 직후 호출되어 정상 동작하지만, 명시적 분리가 더 안전
---
function Actions.buildRoadFree(game, playerId, edge)
  local player = getPlayer(game, playerId)
  local board = game.board

  -- 규칙 검증
  local canBuild, err = Rules.canBuildRoad(board, playerId, edge)
  if not canBuild then
    return false, err
  end

  -- 보드에 배치
  board:placeRoad(playerId, edge.q, edge.r, edge.dir)

  -- 플레이어 도로 카운트 증가
  player.buildings.roads = player.buildings.roads + 1

  return true
end

return Actions
