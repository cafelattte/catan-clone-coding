-- src/game/vertex.lua
-- 정점(Vertex) 정규화 및 관련 함수

local Hex = require("src.game.hex")

local Vertex = {}

-- 정점 방향 (N, S만 사용)
Vertex.DIRECTIONS = {"N", "S"}

---
-- 정점 정규화
-- 동일한 물리적 정점의 다른 표현을 통일
-- 정규화 규칙: S 방향 정점 중 일부를 N 방향으로 변환
-- (q, r, S) → (q, r+1, N) 변환 (S 정점의 북쪽 헥스 기준)
-- @param q number
-- @param r number
-- @param dir string "N" 또는 "S"
-- @return q, r, dir 정규화된 좌표
---
function Vertex.normalize(q, r, dir)
  -- Pointy-top 헥스에서 N과 S는 서로 다른 물리적 위치
  -- 정규화 없이 그대로 반환
  return q, r, dir
end

---
-- 정점 → 문자열 변환 (Map 키용)
-- @param q number
-- @param r number
-- @param dir string
-- @return string "q,r,dir" 형식
---
function Vertex.toString(q, r, dir)
  return q .. "," .. r .. "," .. dir
end

---
-- 문자열 → 정점 변환
-- @param str string "q,r,dir" 형식
-- @return q, r, dir
---
function Vertex.fromString(str)
  local q, r, dir = str:match("([%-]?%d+),([%-]?%d+),(%a+)")
  return tonumber(q), tonumber(r), dir
end

---
-- 헥스의 6개 정점 조회
-- Pointy-top 헥스에서 6개 정점 반환 (시계방향, N부터)
-- @param q number 헥스 q 좌표
-- @param r number 헥스 r 좌표
-- @return table 정점 목록 {{q, r, dir}, ...}
---
function Vertex.getHexVertices(q, r)
  -- Pointy-top 헥스의 6개 정점
  -- 시계방향: N(위), NE(우상), SE(우하), S(아래), SW(좌하), NW(좌상)
  return {
    {q = q, r = r, dir = "N"},           -- N: 자신의 N 정점
    {q = q + 1, r = r - 1, dir = "S"},   -- NE: 오른쪽 위 헥스의 S 정점
    {q = q, r = r + 1, dir = "N"},       -- SE: 아래 헥스의 N 정점
    {q = q, r = r, dir = "S"},           -- S: 자신의 S 정점
    {q = q - 1, r = r + 1, dir = "N"},   -- SW: 왼쪽 아래 헥스의 N 정점
    {q = q, r = r - 1, dir = "S"},       -- NW: 위쪽 헥스의 S 정점
  }
end

---
-- 정점에 인접한 3개 헥스 조회
-- @param q number
-- @param r number
-- @param dir string "N" 또는 "S"
-- @return table 인접 헥스 목록 {{q, r}, ...}
---
function Vertex.getAdjacentHexes(q, r, dir)
  local hexes = {}
  if dir == "N" then
    -- N 정점 인접 헥스: 자신, NW 이웃(0,-1), W 이웃 기준에서의...
    -- 실제로는: (q, r), (q, r-1), (q-1, r)
    hexes[1] = {q = q, r = r}
    hexes[2] = {q = q, r = r - 1}
    hexes[3] = {q = q - 1, r = r}
  else -- S
    -- S 정점 인접 헥스: (q, r), (q, r+1), (q+1, r)
    hexes[1] = {q = q, r = r}
    hexes[2] = {q = q, r = r + 1}
    hexes[3] = {q = q + 1, r = r}
  end
  return hexes
end

---
-- 정점에 인접한 3개 정점 조회
-- @param q number
-- @param r number
-- @param dir string "N" 또는 "S"
-- @return table 인접 정점 목록 (정규화됨)
---
function Vertex.getAdjacentVertices(q, r, dir)
  local vertices = {}
  if dir == "N" then
    -- N 정점의 3개 인접 정점
    -- 위쪽 정점 주변의 3개 변을 따라 연결된 정점
    vertices[1] = {q = q - 1, r = r, dir = "S"}
    vertices[2] = {q = q, r = r - 1, dir = "S"}
    vertices[3] = {q = q, r = r, dir = "S"}
  else -- S
    -- S 정점의 3개 인접 정점
    vertices[1] = {q = q, r = r, dir = "N"}
    vertices[2] = {q = q + 1, r = r, dir = "N"}
    vertices[3] = {q = q, r = r + 1, dir = "N"}
  end
  return vertices
end

---
-- 정점에 인접한 3개 변 조회
-- @param q number
-- @param r number
-- @param dir string "N" 또는 "S"
-- @return table 인접 변 목록 (정규화됨) {{q, r, dir}, ...}
---
function Vertex.getAdjacentEdges(q, r, dir)
  -- Edge 모듈을 함수 내부에서 require (순환 의존성 방지)
  local Edge = require("src.game.edge")
  local edges = {}
  if dir == "N" then
    -- N 정점의 3개 인접 변 (픽셀 좌표로 검증됨)
    edges[1] = Edge.normalizeEdge(q, r, "NE")      -- 자신의 NE
    edges[2] = Edge.normalizeEdge(q, r - 1, "E")   -- 위쪽 헥스의 E
    edges[3] = Edge.normalizeEdge(q, r - 1, "SE")  -- 위쪽 헥스의 SE
  else -- S
    -- S 정점의 3개 인접 변 (픽셀 좌표로 검증됨)
    edges[1] = Edge.normalizeEdge(q - 1, r + 1, "NE")  -- 왼쪽 아래 헥스의 NE
    edges[2] = Edge.normalizeEdge(q - 1, r + 1, "E")   -- 왼쪽 아래 헥스의 E
    edges[3] = Edge.normalizeEdge(q, r, "SE")          -- 자신의 SE
  end
  return edges
end

return Vertex
