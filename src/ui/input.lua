-- src/ui/input.lua
-- 마우스 입력 → 헥스/정점/변 좌표 변환 모듈

local Hex = require("src.game.hex")
local Vertex = require("src.game.vertex")
local Edge = require("src.game.edge")

local Input = {}

-- 19개 보드 헥스 좌표 (board.lua와 동일)
local BOARD_COORDS = {
  -- 중심 (1개)
  {q = 0, r = 0},
  -- 내부 링 (6개)
  {q = 1, r = 0}, {q = 1, r = -1}, {q = 0, r = -1},
  {q = -1, r = 0}, {q = -1, r = 1}, {q = 0, r = 1},
  -- 외부 링 (12개)
  {q = 2, r = 0}, {q = 2, r = -1}, {q = 2, r = -2},
  {q = 1, r = -2}, {q = 0, r = -2}, {q = -1, r = -1},
  {q = -2, r = 0}, {q = -2, r = 1}, {q = -2, r = 2},
  {q = -1, r = 2}, {q = 0, r = 2}, {q = 1, r = 1}
}

-- 보드 좌표 빠른 조회용 Set
local BOARD_COORD_SET = {}
for _, coord in ipairs(BOARD_COORDS) do
  BOARD_COORD_SET[coord.q .. "," .. coord.r] = true
end

---
-- 헥스가 보드 내에 있는지 확인
-- @param q number
-- @param r number
-- @return boolean
---
local function isOnBoard(q, r)
  return BOARD_COORD_SET[q .. "," .. r] ~= nil
end

---
-- 두 점 사이의 거리 계산
-- @param x1 number
-- @param y1 number
-- @param x2 number
-- @param y2 number
-- @return number
---
local function distance(x1, y1, x2, y2)
  local dx = x2 - x1
  local dy = y2 - y1
  return math.sqrt(dx * dx + dy * dy)
end

---
-- 점에서 선분까지의 최단 거리 계산
-- @param px number 점 X
-- @param py number 점 Y
-- @param x1 number 선분 시작점 X
-- @param y1 number 선분 시작점 Y
-- @param x2 number 선분 끝점 X
-- @param y2 number 선분 끝점 Y
-- @return number 최단 거리
---
local function pointToSegmentDistance(px, py, x1, y1, x2, y2)
  local dx = x2 - x1
  local dy = y2 - y1
  local lengthSq = dx * dx + dy * dy

  if lengthSq == 0 then
    -- 선분이 점인 경우
    return distance(px, py, x1, y1)
  end

  -- 선분 위의 가장 가까운 점 파라미터 t (0~1)
  local t = ((px - x1) * dx + (py - y1) * dy) / lengthSq
  t = math.max(0, math.min(1, t))

  -- 가장 가까운 점 좌표
  local nearestX = x1 + t * dx
  local nearestY = y1 + t * dy

  return distance(px, py, nearestX, nearestY)
end

---
-- 정점 픽셀 좌표 계산
-- @param q number 헥스 q 좌표
-- @param r number 헥스 r 좌표
-- @param dir string 정점 방향 ("N" 또는 "S")
-- @param hexSize number 헥스 크기
-- @param offsetX number X 오프셋
-- @param offsetY number Y 오프셋
-- @return px, py 픽셀 좌표
---
function Input.getVertexPixel(q, r, dir, hexSize, offsetX, offsetY)
  local x, y, z = Hex.axialToCube(q, r)
  local px, py = Hex.cubeToPixel(x, y, z, hexSize)

  -- Pointy-top: N 정점은 위쪽, S 정점은 아래쪽
  if dir == "N" then
    py = py - hexSize
  else -- "S"
    py = py + hexSize
  end

  return px + offsetX, py + offsetY
end

---
-- 변 픽셀 좌표 계산 (양 끝점)
-- @param q number 헥스 q 좌표
-- @param r number 헥스 r 좌표
-- @param dir string 변 방향
-- @param hexSize number 헥스 크기
-- @param offsetX number X 오프셋
-- @param offsetY number Y 오프셋
-- @return px1, py1, px2, py2 양 끝점 픽셀 좌표
---
function Input.getEdgePixels(q, r, dir, hexSize, offsetX, offsetY)
  local v1, v2 = Edge.getVertices(q, r, dir)
  local px1, py1 = Input.getVertexPixel(v1.q, v1.r, v1.dir, hexSize, offsetX, offsetY)
  local px2, py2 = Input.getVertexPixel(v2.q, v2.r, v2.dir, hexSize, offsetX, offsetY)
  return px1, py1, px2, py2
end

---
-- 픽셀 → 헥스 좌표 변환
-- @param px number 픽셀 X 좌표
-- @param py number 픽셀 Y 좌표
-- @param hexSize number 헥스 크기
-- @param offsetX number 보드 중심 X 오프셋
-- @param offsetY number 보드 중심 Y 오프셋
-- @return table|nil {q, r} 또는 nil (보드 밖)
---
function Input.pixelToHex(px, py, hexSize, offsetX, offsetY)
  -- 오프셋 제거
  local localPx = px - offsetX
  local localPy = py - offsetY

  -- 픽셀 → 큐브 좌표
  local x, y, z = Hex.pixelToCube(localPx, localPy, hexSize)

  -- 큐브 → Axial 좌표
  local q, r = Hex.cubeToAxial(x, y, z)

  -- 보드 범위 체크
  if not isOnBoard(q, r) then
    return nil
  end

  return {q = q, r = r}
end

---
-- 픽셀 → 가장 가까운 정점 좌표 변환
-- @param px number 픽셀 X 좌표
-- @param py number 픽셀 Y 좌표
-- @param hexSize number 헥스 크기
-- @param offsetX number 보드 중심 X 오프셋
-- @param offsetY number 보드 중심 Y 오프셋
-- @param threshold number 임계값 (픽셀)
-- @return table|nil {q, r, dir} (정규화됨) 또는 nil
---
function Input.pixelToVertex(px, py, hexSize, offsetX, offsetY, threshold)
  -- 오프셋 제거
  local localPx = px - offsetX
  local localPy = py - offsetY

  -- 가장 가까운 헥스 찾기
  local x, y, z = Hex.pixelToCube(localPx, localPy, hexSize)
  local q, r = Hex.cubeToAxial(x, y, z)

  -- 해당 헥스와 주변 헥스의 정점들을 검사
  local candidates = {}

  -- 현재 헥스와 6개 이웃 헥스
  local hexesToCheck = {{q = q, r = r}}
  local neighbors = Hex.getNeighbors(q, r)
  for _, n in ipairs(neighbors) do
    hexesToCheck[#hexesToCheck + 1] = n
  end

  -- 각 헥스의 N, S 정점 검사
  for _, hex in ipairs(hexesToCheck) do
    for _, dir in ipairs({"N", "S"}) do
      local vx, vy = Input.getVertexPixel(hex.q, hex.r, dir, hexSize, offsetX, offsetY)
      local dist = distance(px, py, vx, vy)
      candidates[#candidates + 1] = {
        q = hex.q, r = hex.r, dir = dir,
        dist = dist
      }
    end
  end

  -- 가장 가까운 정점 찾기
  local closest = nil
  local minDist = math.huge
  for _, c in ipairs(candidates) do
    if c.dist < minDist then
      minDist = c.dist
      closest = c
    end
  end

  -- threshold 체크
  if closest == nil or minDist > threshold then
    return nil
  end

  -- 정규화
  local nq, nr, ndir = Vertex.normalize(closest.q, closest.r, closest.dir)
  return {q = nq, r = nr, dir = ndir}
end

---
-- 픽셀 → 가장 가까운 변 좌표 변환
-- @param px number 픽셀 X 좌표
-- @param py number 픽셀 Y 좌표
-- @param hexSize number 헥스 크기
-- @param offsetX number 보드 중심 X 오프셋
-- @param offsetY number 보드 중심 Y 오프셋
-- @param threshold number 임계값 (픽셀)
-- @return table|nil {q, r, dir} (정규화됨) 또는 nil
---
function Input.pixelToEdge(px, py, hexSize, offsetX, offsetY, threshold)
  -- 오프셋 제거
  local localPx = px - offsetX
  local localPy = py - offsetY

  -- 가장 가까운 헥스 찾기
  local x, y, z = Hex.pixelToCube(localPx, localPy, hexSize)
  local q, r = Hex.cubeToAxial(x, y, z)

  -- 해당 헥스와 주변 헥스의 변들을 검사
  local candidates = {}

  -- 현재 헥스와 6개 이웃 헥스
  local hexesToCheck = {{q = q, r = r}}
  local neighbors = Hex.getNeighbors(q, r)
  for _, n in ipairs(neighbors) do
    hexesToCheck[#hexesToCheck + 1] = n
  end

  -- 각 헥스의 정규 변 3개 (NE, E, SE) 검사
  for _, hex in ipairs(hexesToCheck) do
    for _, dir in ipairs({"NE", "E", "SE"}) do
      local px1, py1, px2, py2 = Input.getEdgePixels(hex.q, hex.r, dir, hexSize, offsetX, offsetY)
      local dist = pointToSegmentDistance(px, py, px1, py1, px2, py2)
      candidates[#candidates + 1] = {
        q = hex.q, r = hex.r, dir = dir,
        dist = dist
      }
    end
  end

  -- 가장 가까운 변 찾기
  local closest = nil
  local minDist = math.huge
  for _, c in ipairs(candidates) do
    if c.dist < minDist then
      minDist = c.dist
      closest = c
    end
  end

  -- threshold 체크
  if closest == nil or minDist > threshold then
    return nil
  end

  -- 정규화 (이미 정규 방향만 검사했으므로 그대로 반환)
  local nq, nr, ndir = Edge.normalize(closest.q, closest.r, closest.dir)
  return {q = nq, r = nr, dir = ndir}
end

return Input
