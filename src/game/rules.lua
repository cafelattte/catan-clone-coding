-- src/game/rules.lua
-- Story 5-2: 자원 분배
-- Story 5-3: 건설 검증 규칙
-- Story 5-5: 초기 배치 규칙
-- Story 5-6: 승리 체크

local Vertex = require("src.game.vertex")
local Edge = require("src.game.edge")
local Constants = require("src.game.constants")

local Rules = {}

-- Story 5-2: 자원 분배

--- 주사위 결과에 따른 자원 분배
-- @param board Board 보드 객체
-- @param players table Player 객체 배열
-- @param rolledNumber number 주사위 합계 (2-12)
function Rules.distributeResources(board, players, rolledNumber)
    -- 해당 숫자의 타일들 조회
    local tiles = board:getTilesWithNumber(rolledNumber)

    for _, tile in ipairs(tiles) do
        local resource = Constants.TERRAIN_RESOURCE[tile.terrain]

        -- 사막은 자원 생산 없음
        if resource then
            -- 정착지: 1개 자원
            local settlements = board:getSettlementsOnTile(tile.q, tile.r)
            for _, settlement in ipairs(settlements) do
                local player = players[settlement.player]
                if player then
                    player:addResource(resource, 1)
                end
            end

            -- 도시: 2개 자원
            local cities = board:getCitiesOnTile(tile.q, tile.r)
            for _, city in ipairs(cities) do
                local player = players[city.player]
                if player then
                    player:addResource(resource, 2)
                end
            end
        end
    end
end

-- Story 5-6: 승리 조건 체크

--- 승리 조건 체크
-- @param players table Player 객체 배열
-- @param victoryTarget number 승리 점수 (기본 10)
-- @return number|nil 승자 플레이어 ID, 없으면 nil
function Rules.checkVictory(players, victoryTarget)
    victoryTarget = victoryTarget or 10

    for i, player in ipairs(players) do
        local points = player:getVictoryPoints()
        if points >= victoryTarget then
            return i
        end
    end

    return nil
end

-- Story 5-3: 건설 검증 규칙

---
-- 정착지 건설 가능 여부 검증
-- @param board Board 보드 인스턴스
-- @param playerId number 플레이어 ID
-- @param vertex table {q, r, dir} 정점 좌표
-- @param isInitialPlacement boolean 초기 배치 여부
-- @return boolean, string|nil 성공 시 true, 실패 시 false와 에러 메시지
---
function Rules.canBuildSettlement(board, playerId, vertex, isInitialPlacement)
  local q, r, dir = vertex.q, vertex.r, vertex.dir

  -- 1. 정점이 비어있는지 확인
  if board:hasBuilding(q, r, dir) then
    return false, "Vertex is occupied"
  end

  -- 2. 거리 규칙: 인접 정점에 건물이 없어야 함
  local adjacentVertices = Vertex.getAdjacentVertices(q, r, dir)
  for _, adjVertex in ipairs(adjacentVertices) do
    if board:hasBuilding(adjVertex.q, adjVertex.r, adjVertex.dir) then
      return false, "Distance rule violated"
    end
  end

  -- 3. 연결 규칙: 본인 도로와 연결 (초기 배치 시 무시)
  if not isInitialPlacement then
    if not board:isVertexConnectedToRoad(playerId, q, r, dir) then
      return false, "Not connected to road"
    end
  end

  return true
end

---
-- 도로 건설 가능 여부 검증
-- @param board Board 보드 인스턴스
-- @param playerId number 플레이어 ID
-- @param edge table {q, r, dir} 변 좌표
-- @return boolean, string|nil 성공 시 true, 실패 시 false와 에러 메시지
---
function Rules.canBuildRoad(board, playerId, edge)
  local q, r, dir = edge.q, edge.r, edge.dir

  -- 0. 변이 보드 내에 있는지 확인 (BUG-007: 경계 조건)
  if not board:isValidEdge(q, r, dir) then
    return false, "Edge is outside board"
  end

  -- 1. 변이 비어있는지 확인
  if board:hasRoad(q, r, dir) then
    return false, "Edge is occupied"
  end

  -- 2. 연결 규칙: 본인 건물 또는 도로와 연결되어야 함
  local isConnected = false

  -- 변의 양 끝 정점 확인
  local v1, v2 = Edge.getVertices(q, r, dir)

  -- 양 끝 정점에 본인 건물이 있는지 확인
  local building1 = board:getBuilding(v1.q, v1.r, v1.dir)
  local building2 = board:getBuilding(v2.q, v2.r, v2.dir)

  if building1 and building1.player == playerId then
    isConnected = true
  elseif building2 and building2.player == playerId then
    isConnected = true
  end

  -- 인접 변에 본인 도로가 있는지 확인
  if not isConnected then
    local adjacentEdges = Edge.getAdjacentEdges(q, r, dir)
    for _, adjEdge in ipairs(adjacentEdges) do
      local road = board:getRoad(adjEdge.q, adjEdge.r, adjEdge.dir)
      if road and road.player == playerId then
        isConnected = true
        break
      end
    end
  end

  if not isConnected then
    return false, "Not connected to building or road"
  end

  return true
end

---
-- 도시 업그레이드 가능 여부 검증
-- @param board Board 보드 인스턴스
-- @param playerId number 플레이어 ID
-- @param vertex table {q, r, dir} 정점 좌표
-- @return boolean, string|nil 성공 시 true, 실패 시 false와 에러 메시지
---
function Rules.canBuildCity(board, playerId, vertex)
  local q, r, dir = vertex.q, vertex.r, vertex.dir

  local building = board:getBuilding(q, r, dir)

  -- 1. 건물이 없는 경우
  if not building then
    return false, "No settlement at vertex"
  end

  -- 2. 이미 도시인 경우
  if building.type == "city" then
    return false, "Already a city"
  end

  -- 3. 다른 플레이어 정착지인 경우
  if building.player ~= playerId then
    return false, "Not your settlement"
  end

  return true
end

---
-- 정착지 건설 가능 위치 목록
-- @param board Board 보드 인스턴스
-- @param playerId number 플레이어 ID
-- @param isInitialPlacement boolean 초기 배치 여부
-- @return table 건설 가능 정점 목록 {{q, r, dir}, ...}
---
function Rules.getValidSettlementLocations(board, playerId, isInitialPlacement)
  local validLocations = {}
  local seen = {}

  if isInitialPlacement then
    -- 초기 배치: 보드의 모든 타일의 6개 정점 중 거리 규칙 만족하는 것들
    for _, tile in pairs(board.tiles) do
      local vertices = Vertex.getHexVertices(tile.q, tile.r)
      for _, v in ipairs(vertices) do
        local key = Vertex.toString(v.q, v.r, v.dir)
        if not seen[key] then
          seen[key] = true
          local canBuild, _ = Rules.canBuildSettlement(board, playerId, v, true)
          if canBuild then
            validLocations[#validLocations + 1] = {q = v.q, r = v.r, dir = v.dir}
          end
        end
      end
    end
  else
    -- 일반 배치: 본인 도로에 연결된 정점 중 건설 가능한 것들
    local playerRoads = board:getPlayerRoads(playerId)
    for _, road in ipairs(playerRoads) do
      local v1, v2 = Edge.getVertices(road.q, road.r, road.dir)
      for _, v in ipairs({v1, v2}) do
        local nq, nr, ndir = Vertex.normalize(v.q, v.r, v.dir)
        local key = Vertex.toString(nq, nr, ndir)
        if not seen[key] then
          seen[key] = true
          local canBuild, _ = Rules.canBuildSettlement(board, playerId, {q = nq, r = nr, dir = ndir}, false)
          if canBuild then
            validLocations[#validLocations + 1] = {q = nq, r = nr, dir = ndir}
          end
        end
      end
    end
  end

  return validLocations
end

---
-- 도로 건설 가능 위치 목록
-- @param board Board 보드 인스턴스
-- @param playerId number 플레이어 ID
-- @return table 건설 가능 변 목록 {{q, r, dir}, ...}
---
function Rules.getValidRoadLocations(board, playerId)
  local validLocations = {}
  local seen = {}

  -- 1. 본인 건물 인접 변
  local playerBuildings = board:getPlayerBuildings(playerId)
  for _, building in ipairs(playerBuildings) do
    local adjacentEdges = Vertex.getAdjacentEdges(building.q, building.r, building.dir)
    for _, edge in ipairs(adjacentEdges) do
      local key = Edge.toString(edge.q, edge.r, edge.dir)
      if not seen[key] then
        seen[key] = true
        local canBuild, _ = Rules.canBuildRoad(board, playerId, edge)
        if canBuild then
          validLocations[#validLocations + 1] = {q = edge.q, r = edge.r, dir = edge.dir}
        end
      end
    end
  end

  -- 2. 본인 도로 인접 변
  local playerRoads = board:getPlayerRoads(playerId)
  for _, road in ipairs(playerRoads) do
    local adjacentEdges = Edge.getAdjacentEdges(road.q, road.r, road.dir)
    for _, edge in ipairs(adjacentEdges) do
      local key = Edge.toString(edge.q, edge.r, edge.dir)
      if not seen[key] then
        seen[key] = true
        local canBuild, _ = Rules.canBuildRoad(board, playerId, edge)
        if canBuild then
          validLocations[#validLocations + 1] = {q = edge.q, r = edge.r, dir = edge.dir}
        end
      end
    end
  end

  return validLocations
end

-- Story 5-5: 초기 배치 규칙

---
-- 초기 배치 순서 반환
-- @param round number 라운드 (1 또는 2)
-- @param numPlayers number 플레이어 수 (2-4)
-- @return table 플레이어 ID 순서 목록
---
function Rules.getInitialPlacementOrder(round, numPlayers)
  local order = {}
  if round == 1 then
    -- 정순: 1, 2, 3, 4
    for i = 1, numPlayers do
      order[i] = i
    end
  else
    -- 역순: 4, 3, 2, 1
    for i = numPlayers, 1, -1 do
      order[#order + 1] = i
    end
  end
  return order
end

---
-- 정점 인접 타일에서 초기 자원 획득
-- @param board Board 보드 인스턴스
-- @param vertex table {q, r, dir} 정점 좌표
-- @return table 자원 테이블 {wood=n, brick=n, ...}
---
function Rules.getInitialResources(board, vertex)
  local resources = {}
  local adjacentHexes = Vertex.getAdjacentHexes(vertex.q, vertex.r, vertex.dir)

  for _, hex in ipairs(adjacentHexes) do
    local key = hex.q .. "," .. hex.r
    local tile = board.tiles[key]
    if tile then
      local resourceType = Constants.TERRAIN_RESOURCE[tile.terrain]
      if resourceType then
        resources[resourceType] = (resources[resourceType] or 0) + 1
      end
    end
  end

  return resources
end

---
-- 초기 배치 도로 건설 가능 여부 (방금 놓은 정착지에 인접해야 함)
-- @param board Board 보드 인스턴스
-- @param playerId number 플레이어 ID (현재 미사용, 향후 확장용)
-- @param edge table {q, r, dir} 변 좌표
-- @param settlement table {q, r, dir} 방금 배치한 정착지 좌표
-- @return boolean 건설 가능 여부
---
function Rules.canBuildInitialRoad(board, playerId, edge, settlement) -- luacheck: ignore playerId
  -- 0. 변이 보드 내에 있는지 확인 (BUG-007: 경계 조건)
  if not board:isValidEdge(edge.q, edge.r, edge.dir) then
    return false
  end

  -- 1. 변이 비어있는지 확인
  if board:hasRoad(edge.q, edge.r, edge.dir) then
    return false
  end

  -- 2. 변이 정착지에 인접한지 확인
  local adjacentEdges = Vertex.getAdjacentEdges(settlement.q, settlement.r, settlement.dir)
  local edgeNq, edgeNr, edgeNdir = Edge.normalize(edge.q, edge.r, edge.dir)
  local edgeKey = Edge.toString(edgeNq, edgeNr, edgeNdir)

  for _, adjEdge in ipairs(adjacentEdges) do
    local adjKey = Edge.toString(adjEdge.q, adjEdge.r, adjEdge.dir)
    if adjKey == edgeKey then
      return true
    end
  end

  return false
end

return Rules
