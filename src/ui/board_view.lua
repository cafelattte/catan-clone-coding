-- src/ui/board_view.lua
-- 헥스 보드 렌더링 모듈

local Hex = require("src.game.hex")
local Edge = require("src.game.edge")
local Colors = require("src.ui.colors")

local BoardView = {}

---
-- 정육각형 6개 정점 계산 (Pointy-top 레이아웃)
-- @param cx number 중심 X 좌표
-- @param cy number 중심 Y 좌표
-- @param size number 헥스 크기 (중심에서 꼭지점까지)
-- @return table 정점 좌표 배열 {x1, y1, x2, y2, ...}
---
local function getHexCorners(cx, cy, size)
  local corners = {}
  for i = 0, 5 do
    local angle = math.rad(60 * i - 30)  -- Pointy-top: -30도 시작
    corners[#corners + 1] = cx + size * math.cos(angle)
    corners[#corners + 1] = cy + size * math.sin(angle)
  end
  return corners
end

---
-- 단일 헥스 타일 렌더링
-- @param px number 픽셀 X 좌표
-- @param py number 픽셀 Y 좌표
-- @param size number 헥스 크기
-- @param color table RGB 색상 {r, g, b}
---
local function drawHexagon(px, py, size, color)
  local corners = getHexCorners(px, py, size)

  -- 채우기
  love.graphics.setColor(color[1], color[2], color[3])
  love.graphics.polygon("fill", corners)

  -- 외곽선
  love.graphics.setColor(Colors.UI.outline[1], Colors.UI.outline[2], Colors.UI.outline[3])
  love.graphics.polygon("line", corners)
end

---
-- 숫자 토큰 렌더링
-- @param px number 픽셀 X 좌표
-- @param py number 픽셀 Y 좌표
-- @param number number|nil 표시할 숫자 (nil이면 건너뜀)
-- @param size number 헥스 크기 (토큰 크기 계산용)
---
local function drawNumberToken(px, py, number, size)
  if number == nil then
    return  -- 사막 타일 등 숫자 없음
  end

  local tokenRadius = size * 0.3

  -- 토큰 배경 원
  love.graphics.setColor(Colors.NUMBER.background[1], Colors.NUMBER.background[2], Colors.NUMBER.background[3])
  love.graphics.circle("fill", px, py, tokenRadius)

  -- 토큰 외곽선
  love.graphics.setColor(Colors.UI.outline[1], Colors.UI.outline[2], Colors.UI.outline[3])
  love.graphics.circle("line", px, py, tokenRadius)

  -- 숫자 텍스트 색상 (6, 8은 빨간색)
  if number == 6 or number == 8 then
    love.graphics.setColor(Colors.NUMBER.hot[1], Colors.NUMBER.hot[2], Colors.NUMBER.hot[3])
  else
    love.graphics.setColor(Colors.NUMBER.normal[1], Colors.NUMBER.normal[2], Colors.NUMBER.normal[3])
  end

  -- 숫자 텍스트 (중앙 정렬)
  local text = tostring(number)
  local font = love.graphics.getFont()
  local textWidth = font:getWidth(text)
  local textHeight = font:getHeight()
  love.graphics.print(text, px - textWidth / 2, py - textHeight / 2)
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
local function getVertexPixel(q, r, dir, hexSize, offsetX, offsetY)
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
-- @param dir string 변 방향 ("NE", "E", "SE")
-- @param hexSize number 헥스 크기
-- @param offsetX number X 오프셋
-- @param offsetY number Y 오프셋
-- @return px1, py1, px2, py2 양 끝점 픽셀 좌표
---
local function getEdgePixels(q, r, dir, hexSize, offsetX, offsetY)
  local v1, v2 = Edge.getVertices(q, r, dir)
  local px1, py1 = getVertexPixel(v1.q, v1.r, v1.dir, hexSize, offsetX, offsetY)
  local px2, py2 = getVertexPixel(v2.q, v2.r, v2.dir, hexSize, offsetX, offsetY)
  return px1, py1, px2, py2
end

---
-- 정착지 렌더링 (삼각형)
-- @param px number 중심 X 좌표
-- @param py number 중심 Y 좌표
-- @param playerId number 플레이어 ID (1-4)
-- @param size number 크기 (기본 10)
---
local function drawSettlement(px, py, playerId, size)
  size = size or 10
  local h = size * math.sqrt(3) / 2
  local color = Colors.PLAYER[playerId] or {0.5, 0.5, 0.5}

  -- 삼각형 채우기
  love.graphics.setColor(color[1], color[2], color[3])
  love.graphics.polygon("fill",
    px, py - h * 2/3,           -- 상단 정점
    px - size/2, py + h * 1/3,  -- 좌하단
    px + size/2, py + h * 1/3   -- 우하단
  )

  -- 외곽선 (검정)
  love.graphics.setColor(0, 0, 0)
  love.graphics.polygon("line",
    px, py - h * 2/3,
    px - size/2, py + h * 1/3,
    px + size/2, py + h * 1/3
  )
end

---
-- 도시 렌더링 (사각형)
-- @param px number 중심 X 좌표
-- @param py number 중심 Y 좌표
-- @param playerId number 플레이어 ID (1-4)
-- @param size number 크기 (기본 15, 정착지의 1.5배)
---
local function drawCity(px, py, playerId, size)
  size = size or 15
  local half = size / 2
  local color = Colors.PLAYER[playerId] or {0.5, 0.5, 0.5}

  -- 사각형 채우기
  love.graphics.setColor(color[1], color[2], color[3])
  love.graphics.rectangle("fill", px - half, py - half, size, size)

  -- 외곽선 (검정)
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle("line", px - half, py - half, size, size)
end

---
-- 도로 렌더링 (선)
-- @param px1 number 시작점 X 좌표
-- @param py1 number 시작점 Y 좌표
-- @param px2 number 끝점 X 좌표
-- @param py2 number 끝점 Y 좌표
-- @param playerId number 플레이어 ID (1-4)
-- @param width number 선 두께 (기본 4)
---
local function drawRoad(px1, py1, px2, py2, playerId, width)
  width = width or 4
  local color = Colors.PLAYER[playerId] or {0.5, 0.5, 0.5}

  love.graphics.setLineWidth(width)
  love.graphics.setColor(color[1], color[2], color[3])
  love.graphics.line(px1, py1, px2, py2)

  -- 외곽선 효과 (더 두꺼운 검정 선 먼저)
  -- 이미 그려진 선 위에 그리므로 순서 조정 필요 없음
  love.graphics.setLineWidth(1) -- 원래 두께로 복원
end

---
-- 건물/도로 전체 렌더링
-- @param buildings table 건물 데이터 {settlements, cities, roads}
-- @param hexSize number 헥스 크기
-- @param offsetX number X 오프셋
-- @param offsetY number Y 오프셋
---
function BoardView.drawBuildings(buildings, hexSize, offsetX, offsetY)
  if not buildings then return end

  local settlementSize = hexSize * 0.25
  local citySize = settlementSize * 1.5
  local roadWidth = 4

  -- 1. 도로 먼저 렌더링 (건물 아래에 위치)
  if buildings.roads then
    for key, data in pairs(buildings.roads) do
      local q, r, dir = Edge.fromString(key)
      if q and r and dir then
        local px1, py1, px2, py2 = getEdgePixels(q, r, dir, hexSize, offsetX, offsetY)
        drawRoad(px1, py1, px2, py2, data.player, roadWidth)
      end
    end
  end

  -- 2. 정착지 렌더링
  if buildings.settlements then
    for key, data in pairs(buildings.settlements) do
      local q, r, dir = key:match("([%-]?%d+),([%-]?%d+),(%a+)")
      if q and r and dir then
        local px, py = getVertexPixel(tonumber(q), tonumber(r), dir, hexSize, offsetX, offsetY)
        drawSettlement(px, py, data.player, settlementSize)
      end
    end
  end

  -- 3. 도시 렌더링 (정착지 위에 위치)
  if buildings.cities then
    for key, data in pairs(buildings.cities) do
      local q, r, dir = key:match("([%-]?%d+),([%-]?%d+),(%a+)")
      if q and r and dir then
        local px, py = getVertexPixel(tonumber(q), tonumber(r), dir, hexSize, offsetX, offsetY)
        drawCity(px, py, data.player, citySize)
      end
    end
  end
end

---
-- 정점 하이라이트 렌더링 (원)
-- @param px number 중심 X 좌표
-- @param py number 중심 Y 좌표
-- @param radius number 원 반지름 (기본 8)
-- @param color table RGBA 색상 (기본 Colors.UI.highlight)
---
function BoardView.drawVertexHighlight(px, py, radius, color)
  radius = radius or 8
  color = color or Colors.UI.highlight
  love.graphics.setColor(color[1], color[2], color[3], color[4] or 0.3)
  love.graphics.circle("fill", px, py, radius)
end

---
-- 변 하이라이트 렌더링 (두꺼운 선)
-- @param px1 number 시작점 X 좌표
-- @param py1 number 시작점 Y 좌표
-- @param px2 number 끝점 X 좌표
-- @param py2 number 끝점 Y 좌표
-- @param width number 선 두께 (기본 6)
-- @param color table RGBA 색상 (기본 Colors.UI.highlight)
---
function BoardView.drawEdgeHighlight(px1, py1, px2, py2, width, color)
  width = width or 6
  color = color or Colors.UI.highlight
  love.graphics.setLineWidth(width)
  love.graphics.setColor(color[1], color[2], color[3], color[4] or 0.3)
  love.graphics.line(px1, py1, px2, py2)
  love.graphics.setLineWidth(1) -- 원래 두께로 복원
end

---
-- 건설 가능 위치 하이라이트 전체 렌더링
-- @param validVertices table|nil 유효한 정점 목록 {{q, r, dir}, ...}
-- @param validEdges table|nil 유효한 변 목록 {{q, r, dir}, ...}
-- @param hexSize number 헥스 크기
-- @param offsetX number X 오프셋
-- @param offsetY number Y 오프셋
-- @param hoverVertex table|nil 현재 호버된 정점 {q, r, dir}
-- @param hoverEdge table|nil 현재 호버된 변 {q, r, dir}
---
function BoardView.drawHighlights(validVertices, validEdges, hexSize, offsetX, offsetY, hoverVertex, hoverEdge)
  local highlightRadius = 8
  local highlightWidth = 6

  -- 정점 하이라이트
  if validVertices then
    for _, v in ipairs(validVertices) do
      local px, py = getVertexPixel(v.q, v.r, v.dir, hexSize, offsetX, offsetY)
      -- 호버된 정점인지 확인
      local isHover = hoverVertex and
                      hoverVertex.q == v.q and
                      hoverVertex.r == v.r and
                      hoverVertex.dir == v.dir
      local color = isHover and Colors.UI.highlight_hover or Colors.UI.highlight
      BoardView.drawVertexHighlight(px, py, highlightRadius, color)
    end
  end

  -- 변 하이라이트
  if validEdges then
    for _, e in ipairs(validEdges) do
      local px1, py1, px2, py2 = getEdgePixels(e.q, e.r, e.dir, hexSize, offsetX, offsetY)
      -- 호버된 변인지 확인
      local isHover = hoverEdge and
                      hoverEdge.q == e.q and
                      hoverEdge.r == e.r and
                      hoverEdge.dir == e.dir
      local color = isHover and Colors.UI.highlight_hover or Colors.UI.highlight
      BoardView.drawEdgeHighlight(px1, py1, px2, py2, highlightWidth, color)
    end
  end
end

---
-- 보드 전체 렌더링
-- @param board table Board 인스턴스
-- @param hexSize number 헥스 크기 (픽셀)
-- @param offsetX number 보드 중심 X 오프셋
-- @param offsetY number 보드 중심 Y 오프셋
-- @param buildings table|nil 건물 데이터 (선택적)
---
function BoardView.draw(board, hexSize, offsetX, offsetY, buildings)
  local tiles = board:getAllTiles()

  -- 모든 타일 렌더링
  for _, tile in ipairs(tiles) do
    -- Axial → Cube → Pixel 변환
    local x, y, z = Hex.axialToCube(tile.q, tile.r)
    local px, py = Hex.cubeToPixel(x, y, z, hexSize)

    -- 오프셋 적용
    px = px + offsetX
    py = py + offsetY

    -- 지형 색상 가져오기
    local color = Colors.TERRAIN[tile.terrain] or Colors.TERRAIN.desert

    -- 헥스 타일 그리기
    drawHexagon(px, py, hexSize, color)

    -- 숫자 토큰 그리기
    drawNumberToken(px, py, tile.number, hexSize)
  end

  -- 건물/도로 렌더링
  if buildings then
    BoardView.drawBuildings(buildings, hexSize, offsetX, offsetY)
  end

  -- 색상 리셋
  love.graphics.setColor(1, 1, 1, 1)
end

return BoardView
