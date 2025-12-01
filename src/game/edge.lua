-- src/game/edge.lua
-- 변(Edge) 정규화 및 관련 함수

local Hex = require("src.game.hex")
local Vertex = require("src.game.vertex")

local Edge = {}

-- 변 방향 (정규화 후 NE, E, SE만 사용)
Edge.DIRECTIONS = {"NE", "E", "SE"}

-- 비정규 방향 → 정규 방향 변환 테이블
-- {dq, dr, newDir}: 이웃 헥스 오프셋과 새 방향
local NORMALIZE_MAP = {
  NW = {dq = 0, dr = -1, dir = "SE"},  -- NW → 북쪽 헥스의 SE
  W  = {dq = -1, dr = 0, dir = "E"},   -- W → 서쪽 헥스의 E
  SW = {dq = -1, dr = 1, dir = "NE"},  -- SW → 남서 헥스의 NE
}

---
-- 변 정규화
-- 동일한 물리적 변의 다른 표현을 통일
-- 정규 방향: NE, E, SE (유지)
-- 비정규 방향: NW, W, SW (이웃 헥스 기준으로 변환)
-- @param q number
-- @param r number
-- @param dir string
-- @return q, r, dir 정규화된 좌표
---
function Edge.normalize(q, r, dir)
  local mapping = NORMALIZE_MAP[dir]
  if mapping then
    return q + mapping.dq, r + mapping.dr, mapping.dir
  end
  -- NE, E, SE는 그대로 유지
  return q, r, dir
end

---
-- 변 → 문자열 변환 (Map 키용)
-- @param q number
-- @param r number
-- @param dir string
-- @return string "q,r,dir" 형식
---
function Edge.toString(q, r, dir)
  return q .. "," .. r .. "," .. dir
end

---
-- 문자열 → 변 변환
-- @param str string "q,r,dir" 형식
-- @return q, r, dir
---
function Edge.fromString(str)
  local q, r, dir = str:match("([%-]?%d+),([%-]?%d+),(%a+)")
  return tonumber(q), tonumber(r), dir
end

---
-- 변의 양 끝 정점 조회
-- @param q number
-- @param r number
-- @param dir string
-- @return v1, v2 양 끝 정점 {q, r, dir}
---
function Edge.getVertices(q, r, dir)
  -- 먼저 정규화
  local nq, nr, ndir = Edge.normalize(q, r, dir)

  local v1, v2
  if ndir == "NE" then
    -- NE 변: 헥스의 N 정점과 NE 이웃의 S 정점 (=N 정점의 오른쪽)
    v1 = {q = nq, r = nr, dir = "N"}
    v2 = {q = nq + 1, r = nr - 1, dir = "S"}
  elseif ndir == "E" then
    -- E 변: NE 이웃의 S 정점과 SE 이웃의 N 정점을 연결
    v1 = {q = nq + 1, r = nr - 1, dir = "S"}
    v2 = {q = nq, r = nr + 1, dir = "N"}
  elseif ndir == "SE" then
    -- SE 변: 헥스의 S 정점과 SE 이웃의 N 정점
    v1 = {q = nq, r = nr, dir = "S"}
    v2 = {q = nq, r = nr + 1, dir = "N"}
  end

  return v1, v2
end

---
-- 변에 인접한 4개 변 조회
-- @param q number
-- @param r number
-- @param dir string
-- @return table 인접 변 목록 (정규화됨)
---
function Edge.getAdjacentEdges(q, r, dir)
  -- 먼저 정규화
  local nq, nr, ndir = Edge.normalize(q, r, dir)

  local edges = {}
  if ndir == "NE" then
    -- NE 변에 인접한 4개 변
    edges[1] = Edge.normalizeEdge(nq, nr, "E")
    edges[2] = Edge.normalizeEdge(nq, nr - 1, "E")
    edges[3] = Edge.normalizeEdge(nq, nr - 1, "SE")
    edges[4] = Edge.normalizeEdge(nq - 1, nr, "E")
  elseif ndir == "E" then
    -- E 변에 인접한 4개 변
    edges[1] = Edge.normalizeEdge(nq, nr, "NE")
    edges[2] = Edge.normalizeEdge(nq, nr, "SE")
    edges[3] = Edge.normalizeEdge(nq + 1, nr - 1, "SE")
    edges[4] = Edge.normalizeEdge(nq + 1, nr, "NE")
  elseif ndir == "SE" then
    -- SE 변에 인접한 4개 변
    edges[1] = Edge.normalizeEdge(nq, nr, "E")
    edges[2] = Edge.normalizeEdge(nq, nr + 1, "E")
    edges[3] = Edge.normalizeEdge(nq, nr + 1, "NE")
    edges[4] = Edge.normalizeEdge(nq + 1, nr, "E")
  end

  return edges
end

-- 헬퍼: 변 정규화 후 테이블로 반환
function Edge.normalizeEdge(q, r, dir)
  local nq, nr, ndir = Edge.normalize(q, r, dir)
  return {q = nq, r = nr, dir = ndir}
end

return Edge
