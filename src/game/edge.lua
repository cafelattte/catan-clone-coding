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
  -- Edge의 양 끝 정점에서 나가는 edge들 (자신 제외)
  -- BUG-001 좌표 체계와 일치하도록 Vertex.getAdjacentEdges 기반으로 계산
  local nq, nr, ndir = Edge.normalize(q, r, dir)
  local v1, v2 = Edge.getVertices(nq, nr, ndir)
  
  local edges = {}
  local seen = {}
  local selfKey = Edge.toString(nq, nr, ndir)
  seen[selfKey] = true
  
  -- v1에서 나가는 edge들
  local v1Edges = Vertex.getAdjacentEdges(v1.q, v1.r, v1.dir)
  for _, e in ipairs(v1Edges) do
    local key = Edge.toString(e.q, e.r, e.dir)
    if not seen[key] then
      seen[key] = true
      edges[#edges + 1] = e
    end
  end
  
  -- v2에서 나가는 edge들
  local v2Edges = Vertex.getAdjacentEdges(v2.q, v2.r, v2.dir)
  for _, e in ipairs(v2Edges) do
    local key = Edge.toString(e.q, e.r, e.dir)
    if not seen[key] then
      seen[key] = true
      edges[#edges + 1] = e
    end
  end
  
  return edges
end

-- 헬퍼: 변 정규화 후 테이블로 반환
function Edge.normalizeEdge(q, r, dir)
  local nq, nr, ndir = Edge.normalize(q, r, dir)
  return {q = nq, r = nr, dir = ndir}
end

return Edge
