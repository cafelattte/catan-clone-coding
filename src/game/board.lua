-- src/game/board.lua
-- 카탄 게임 보드 상태 관리

local Constants = require("src.game.constants")
local Vertex = require("src.game.vertex")

local Board = {}
Board.__index = Board

-- 19개 헥스 좌표 (나선형 순서: 중심 → 내부 링 → 외부 링)
local BOARD_COORDS = {
  -- 중심 (1개)
  {q = 0, r = 0},
  -- 내부 링 (6개, 시계방향)
  {q = 1, r = 0}, {q = 1, r = -1}, {q = 0, r = -1},
  {q = -1, r = 0}, {q = -1, r = 1}, {q = 0, r = 1},
  -- 외부 링 (12개, 시계방향)
  {q = 2, r = 0}, {q = 2, r = -1}, {q = 2, r = -2},
  {q = 1, r = -2}, {q = 0, r = -2}, {q = -1, r = -1},
  {q = -2, r = 0}, {q = -2, r = 1}, {q = -2, r = 2},
  {q = -1, r = 2}, {q = 0, r = 2}, {q = 1, r = 1}
}

---
-- 타일 키 생성 헬퍼
-- @param q number Axial q 좌표
-- @param r number Axial r 좌표
-- @return string "q,r" 형식
---
local function tileKey(q, r)
  return q .. "," .. r
end

---
-- Fisher-Yates 셔플 알고리즘
-- @param t table 셔플할 배열
-- @return table 셔플된 배열 (원본 수정)
---
local function shuffle(t)
  for i = #t, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
  return t
end

---
-- 타일 풀 생성 (분포대로 지형 목록)
-- @return table 지형 문자열 목록
---
local function createTilePool()
  local pool = {}
  for terrain, count in pairs(Constants.TILE_DISTRIBUTION) do
    for _ = 1, count do
      pool[#pool + 1] = terrain
    end
  end
  return pool
end

---
-- 숫자 토큰 풀 생성 (18개)
-- @return table 숫자 목록
---
local function createNumberPool()
  local pool = {}
  for _, num in ipairs(Constants.NUMBER_TOKENS) do
    pool[#pool + 1] = num
  end
  return pool
end

---
-- 빈 보드 생성
-- @return Board 새 보드 인스턴스
---
function Board.new()
  local self = setmetatable({}, Board)
  self.tiles = {}
  self.robber = nil
  -- Story 4-3: 건물 저장 구조
  -- 키: 정규화된 정점 문자열 "q,r,dir", 값: {player = playerId}
  self.settlements = {}
  self.cities = {}
  return self
end

---
-- 표준 카탄 보드 생성 (19개 타일)
-- @return Board 초기화된 보드 인스턴스
---
function Board.newStandard()
  local self = Board.new()

  -- 타일 풀 생성 및 셔플
  local terrainPool = createTilePool()
  shuffle(terrainPool)

  -- 숫자 토큰 풀 생성 및 셔플
  local numberPool = createNumberPool()
  shuffle(numberPool)
  local numberIndex = 1

  -- 좌표에 타일 배치
  for i, coord in ipairs(BOARD_COORDS) do
    local terrain = terrainPool[i]
    local key = tileKey(coord.q, coord.r)
    local number = nil

    -- 사막이 아닌 타일에만 숫자 토큰 배치
    if terrain ~= "desert" then
      number = numberPool[numberIndex]
      numberIndex = numberIndex + 1
    end

    self.tiles[key] = {
      q = coord.q,
      r = coord.r,
      terrain = terrain,
      number = number
    }

    -- 사막 타일에 도둑 배치
    if terrain == "desert" then
      self.robber = {q = coord.q, r = coord.r}
    end
  end

  return self
end

---
-- 특정 좌표의 타일 조회
-- @param q number Axial q 좌표
-- @param r number Axial r 좌표
-- @return table|nil 타일 정보 {q, r, terrain, number} 또는 nil
---
function Board:getTile(q, r)
  local key = tileKey(q, r)
  return self.tiles[key]
end

---
-- 모든 타일 목록 반환
-- @return table 타일 목록
---
function Board:getAllTiles()
  local result = {}
  for _, tile in pairs(self.tiles) do
    result[#result + 1] = tile
  end
  return result
end

---
-- 특정 숫자 토큰이 있는 타일들 반환
-- @param n number 찾을 숫자 (2-6, 8-12)
-- @return table 해당 숫자를 가진 타일 목록
---
function Board:getTilesWithNumber(n)
  local result = {}
  for _, tile in pairs(self.tiles) do
    if tile.number == n then
      result[#result + 1] = tile
    end
  end
  return result
end

-- Story 4-3: 정착지/도시 배치 API

---
-- 정점 키 생성 헬퍼 (정규화 후 문자열 변환)
-- @param q number
-- @param r number
-- @param dir string "N" 또는 "S"
-- @return string 정규화된 정점 키
---
local function vertexKey(q, r, dir)
  local nq, nr, ndir = Vertex.normalize(q, r, dir)
  return Vertex.toString(nq, nr, ndir)
end

---
-- 정착지 배치
-- @param playerId number 플레이어 ID (1-4)
-- @param q number
-- @param r number
-- @param dir string "N" 또는 "S"
-- @return boolean, string|nil 성공 시 true, 실패 시 false와 에러 메시지
---
function Board:placeSettlement(playerId, q, r, dir)
  local key = vertexKey(q, r, dir)

  -- 중복 체크 (settlements와 cities 모두 확인)
  if self.settlements[key] then
    return false, "이미 건물이 있습니다"
  end
  if self.cities[key] then
    return false, "이미 건물이 있습니다"
  end

  -- 배치
  self.settlements[key] = {player = playerId}
  return true
end

---
-- 건물 조회
-- @param q number
-- @param r number
-- @param dir string "N" 또는 "S"
-- @return table|nil {type, player} 또는 nil
---
function Board:getBuilding(q, r, dir)
  local key = vertexKey(q, r, dir)

  if self.settlements[key] then
    return {type = "settlement", player = self.settlements[key].player}
  end
  if self.cities[key] then
    return {type = "city", player = self.cities[key].player}
  end

  return nil
end

---
-- 도시 업그레이드 (정착지 → 도시)
-- @param q number
-- @param r number
-- @param dir string "N" 또는 "S"
-- @return boolean, string|nil 성공 시 true, 실패 시 false와 에러 메시지
---
function Board:upgradeToCity(q, r, dir)
  local key = vertexKey(q, r, dir)

  -- 이미 도시인 경우
  if self.cities[key] then
    return false, "이미 도시입니다"
  end

  -- 정착지가 없는 경우
  if not self.settlements[key] then
    return false, "정착지가 없습니다"
  end

  -- 정착지를 도시로 업그레이드
  local playerId = self.settlements[key].player
  self.settlements[key] = nil
  self.cities[key] = {player = playerId}

  return true
end

---
-- 플레이어별 건물 목록 조회
-- @param playerId number
-- @return table {{q, r, dir, type}, ...}
---
function Board:getPlayerBuildings(playerId)
  local buildings = {}

  -- 정착지 수집
  for key, data in pairs(self.settlements) do
    if data.player == playerId then
      local q, r, dir = Vertex.fromString(key)
      buildings[#buildings + 1] = {q = q, r = r, dir = dir, type = "settlement"}
    end
  end

  -- 도시 수집
  for key, data in pairs(self.cities) do
    if data.player == playerId then
      local q, r, dir = Vertex.fromString(key)
      buildings[#buildings + 1] = {q = q, r = r, dir = dir, type = "city"}
    end
  end

  return buildings
end

---
-- 건물 존재 여부 확인
-- @param q number
-- @param r number
-- @param dir string "N" 또는 "S"
-- @return boolean
---
function Board:hasBuilding(q, r, dir)
  local key = vertexKey(q, r, dir)
  return self.settlements[key] ~= nil or self.cities[key] ~= nil
end

---
-- 직접 도시 배치 (초기 설정 또는 특수 룰용)
-- @param playerId number
-- @param q number
-- @param r number
-- @param dir string "N" 또는 "S"
-- @return boolean, string|nil
---
function Board:placeCity(playerId, q, r, dir)
  local key = vertexKey(q, r, dir)

  -- 중복 체크
  if self.settlements[key] then
    return false, "이미 건물이 있습니다"
  end
  if self.cities[key] then
    return false, "이미 건물이 있습니다"
  end

  -- 배치
  self.cities[key] = {player = playerId}
  return true
end

---
-- 타일 인접 정착지 조회
-- @param q number 타일 q 좌표
-- @param r number 타일 r 좌표
-- @return table 인접 정착지 목록 {{q, r, dir, player}, ...}
---
function Board:getSettlementsOnTile(q, r)
  local settlements = {}
  local seen = {}  -- 중복 방지

  -- 타일의 6개 정점 순회 (N, S 각각 자신과 인접 헥스)
  -- 헥스의 정점: N(상단), S(하단)
  -- 그리고 인접 헥스의 정점들도 이 타일에 접함
  local vertices = {
    {q = q, r = r, dir = "N"},
    {q = q, r = r, dir = "S"},
    {q = q, r = r - 1, dir = "S"},  -- 위쪽 헥스의 S 정점
    {q = q + 1, r = r - 1, dir = "S"},  -- 오른쪽 위 헥스의 S 정점
    {q = q + 1, r = r, dir = "N"},  -- 오른쪽 아래 헥스의 N 정점
    {q = q - 1, r = r + 1, dir = "N"}  -- 왼쪽 아래 헥스의 N 정점
  }

  for _, v in ipairs(vertices) do
    local key = vertexKey(v.q, v.r, v.dir)
    if self.settlements[key] and not seen[key] then
      seen[key] = true
      local nq, nr, ndir = Vertex.normalize(v.q, v.r, v.dir)
      settlements[#settlements + 1] = {
        q = nq, r = nr, dir = ndir,
        player = self.settlements[key].player
      }
    end
  end

  return settlements
end

---
-- 타일 인접 도시 조회
-- @param q number 타일 q 좌표
-- @param r number 타일 r 좌표
-- @return table 인접 도시 목록 {{q, r, dir, player}, ...}
---
function Board:getCitiesOnTile(q, r)
  local cities = {}
  local seen = {}  -- 중복 방지

  -- 타일의 6개 정점 순회
  local vertices = {
    {q = q, r = r, dir = "N"},
    {q = q, r = r, dir = "S"},
    {q = q, r = r - 1, dir = "S"},
    {q = q + 1, r = r - 1, dir = "S"},
    {q = q + 1, r = r, dir = "N"},
    {q = q - 1, r = r + 1, dir = "N"}
  }

  for _, v in ipairs(vertices) do
    local key = vertexKey(v.q, v.r, v.dir)
    if self.cities[key] and not seen[key] then
      seen[key] = true
      local nq, nr, ndir = Vertex.normalize(v.q, v.r, v.dir)
      cities[#cities + 1] = {
        q = nq, r = nr, dir = ndir,
        player = self.cities[key].player
      }
    end
  end

  return cities
end

return Board
