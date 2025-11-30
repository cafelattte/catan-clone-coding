-- src/game/hex.lua
-- 헥스 좌표계 변환 및 이웃 계산

local Hex = {}

-- 방향 상수 (Pointy-top, 시계방향: E부터 시작)
Hex.DIRECTIONS = {
  {q = 1, r = 0},   -- E
  {q = 1, r = -1},  -- NE
  {q = 0, r = -1},  -- NW
  {q = -1, r = 0},  -- W
  {q = -1, r = 1},  -- SW
  {q = 0, r = 1},   -- SE
}

Hex.DIRECTION_NAMES = {"E", "NE", "NW", "W", "SW", "SE"}

-- 방향 이름 → 인덱스 매핑
local directionIndex = {}
for i, name in ipairs(Hex.DIRECTION_NAMES) do
  directionIndex[name] = i
end

-- sqrt(3) 상수
local SQRT3 = math.sqrt(3)

---
-- Axial → Cube 변환
-- @param q number Axial q 좌표
-- @param r number Axial r 좌표
-- @return x, y, z Cube 좌표 (x + y + z = 0)
---
function Hex.axialToCube(q, r)
  local x = q
  local z = r
  local y = -x - z
  return x, y, z
end

---
-- Cube → Axial 변환
-- @param x number Cube x 좌표
-- @param y number Cube y 좌표 (사용되지 않음, 검증용)
-- @param z number Cube z 좌표
-- @return q, r Axial 좌표
---
function Hex.cubeToAxial(x, y, z)
  return x, z
end

---
-- Cube 좌표 반올림 (부동소수점 → 정수)
-- @param x number
-- @param y number
-- @param z number
-- @return x, y, z 반올림된 정수 좌표
---
function Hex.cubeRound(x, y, z)
  local rx = math.floor(x + 0.5)
  local ry = math.floor(y + 0.5)
  local rz = math.floor(z + 0.5)

  local xDiff = math.abs(rx - x)
  local yDiff = math.abs(ry - y)
  local zDiff = math.abs(rz - z)

  -- x + y + z = 0 불변식 유지: 가장 큰 오차를 재계산
  if xDiff > yDiff and xDiff > zDiff then
    rx = -ry - rz
  elseif yDiff > zDiff then
    ry = -rx - rz
  else
    rz = -rx - ry
  end

  return rx, ry, rz
end

---
-- Cube → Pixel 변환 (Pointy-top 레이아웃)
-- @param x number Cube x 좌표
-- @param y number Cube y 좌표
-- @param z number Cube z 좌표
-- @param size number 헥스 크기 (중심에서 꼭지점까지)
-- @return px, py 픽셀 좌표
---
function Hex.cubeToPixel(x, y, z, size)
  -- Pointy-top: px = size * sqrt(3) * (x + z/2)
  --             py = size * 3/2 * z
  local px = size * SQRT3 * (x + z / 2)
  local py = size * (3 / 2) * z
  return px, py
end

---
-- Pixel → Cube 변환 (Pointy-top 레이아웃)
-- @param px number 픽셀 x 좌표
-- @param py number 픽셀 y 좌표
-- @param size number 헥스 크기
-- @return x, y, z Cube 좌표 (반올림됨)
---
function Hex.pixelToCube(px, py, size)
  -- 역변환
  local z = py / (size * 3 / 2)
  local x = (px / (size * SQRT3)) - z / 2
  local y = -x - z
  return Hex.cubeRound(x, y, z)
end

---
-- 특정 방향의 이웃 헥스 조회
-- @param q number 헥스 q 좌표
-- @param r number 헥스 r 좌표
-- @param direction number|string 방향 (1-6 또는 "E", "NE", 등)
-- @return q, r 이웃 헥스 좌표 (잘못된 방향이면 nil)
---
function Hex.getNeighbor(q, r, direction)
  local idx = direction
  if type(direction) == "string" then
    idx = directionIndex[direction]
  end

  if not idx or idx < 1 or idx > 6 then
    return nil, nil
  end

  local dir = Hex.DIRECTIONS[idx]
  return q + dir.q, r + dir.r
end

---
-- 모든 이웃 헥스 조회
-- @param q number 헥스 q 좌표
-- @param r number 헥스 r 좌표
-- @return table 6개 이웃 좌표 목록 {{q, r}, ...}
---
function Hex.getNeighbors(q, r)
  local neighbors = {}
  for i, dir in ipairs(Hex.DIRECTIONS) do
    neighbors[i] = {q = q + dir.q, r = r + dir.r}
  end
  return neighbors
end

---
-- 헥스 좌표 문자열 변환
-- @param q number
-- @param r number
-- @return string "(q,r)" 형식
---
function Hex.hexToString(q, r)
  return "(" .. q .. "," .. r .. ")"
end

return Hex
