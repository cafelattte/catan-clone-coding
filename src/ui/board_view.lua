-- src/ui/board_view.lua
-- 헥스 보드 렌더링 모듈

local Hex = require("src.game.hex")
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
-- 보드 전체 렌더링
-- @param board table Board 인스턴스
-- @param hexSize number 헥스 크기 (픽셀)
-- @param offsetX number 보드 중심 X 오프셋
-- @param offsetY number 보드 중심 Y 오프셋
---
function BoardView.draw(board, hexSize, offsetX, offsetY)
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

  -- 색상 리셋
  love.graphics.setColor(1, 1, 1, 1)
end

return BoardView
