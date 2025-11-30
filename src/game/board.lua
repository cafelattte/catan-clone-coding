-- src/game/board.lua
-- 카탄 게임 보드 상태 관리

local Constants = require("src.game.constants")

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
-- 빈 보드 생성
-- @return Board 새 보드 인스턴스
---
function Board.new()
  local self = setmetatable({}, Board)
  self.tiles = {}
  self.robber = nil
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

  -- 좌표에 타일 배치
  for i, coord in ipairs(BOARD_COORDS) do
    local terrain = terrainPool[i]
    local key = tileKey(coord.q, coord.r)

    self.tiles[key] = {
      q = coord.q,
      r = coord.r,
      terrain = terrain,
      number = nil  -- 숫자 토큰은 Story 4-2에서 구현
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

return Board
