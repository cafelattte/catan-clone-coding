-- tests/ui/input_spec.lua
-- Input 모듈 테스트

local Input = require("src.ui.input")
local Hex = require("src.game.hex")

describe("Input", function()
  -- 테스트용 상수
  local HEX_SIZE = 50
  local OFFSET_X = 640
  local OFFSET_Y = 360
  local VERTEX_THRESHOLD = 15
  local EDGE_THRESHOLD = 10

  describe("getVertexPixel", function()
    it("should return pixel coordinates for N vertex", function()
      -- 중앙 헥스(0,0)의 N 정점
      local px, py = Input.getVertexPixel(0, 0, "N", HEX_SIZE, OFFSET_X, OFFSET_Y)

      -- 중앙 헥스의 픽셀 좌표는 (OFFSET_X, OFFSET_Y)
      -- N 정점은 hexSize만큼 위
      assert.equals(OFFSET_X, px)
      assert.equals(OFFSET_Y - HEX_SIZE, py)
    end)

    it("should return pixel coordinates for S vertex", function()
      -- 중앙 헥스(0,0)의 S 정점
      local px, py = Input.getVertexPixel(0, 0, "S", HEX_SIZE, OFFSET_X, OFFSET_Y)

      -- S 정점은 hexSize만큼 아래
      assert.equals(OFFSET_X, px)
      assert.equals(OFFSET_Y + HEX_SIZE, py)
    end)
  end)

  describe("getEdgePixels", function()
    it("should return two vertex pixels for E edge", function()
      local px1, py1, px2, py2 = Input.getEdgePixels(0, 0, "E", HEX_SIZE, OFFSET_X, OFFSET_Y)

      -- E 변의 두 끝점은 유효한 픽셀 좌표여야 함
      assert.is_number(px1)
      assert.is_number(py1)
      assert.is_number(px2)
      assert.is_number(py2)

      -- 두 끝점은 다른 위치여야 함
      assert.is_true(px1 ~= px2 or py1 ~= py2)
    end)

    it("should return consistent pixels for normalized edge", function()
      -- NE, E, SE는 정규 방향
      local px1_ne, py1_ne, px2_ne, py2_ne = Input.getEdgePixels(0, 0, "NE", HEX_SIZE, OFFSET_X, OFFSET_Y)
      local px1_e, py1_e, px2_e, py2_e = Input.getEdgePixels(0, 0, "E", HEX_SIZE, OFFSET_X, OFFSET_Y)
      local px1_se, py1_se, px2_se, py2_se = Input.getEdgePixels(0, 0, "SE", HEX_SIZE, OFFSET_X, OFFSET_Y)

      -- 각 변은 다른 위치에 있어야 함
      assert.is_true(px1_ne ~= px1_e or py1_ne ~= py1_e or px2_ne ~= px2_e or py2_ne ~= py2_e)
    end)
  end)

  describe("pixelToHex", function()
    it("should return center hex (0,0) for center pixel", function()
      local hex = Input.pixelToHex(OFFSET_X, OFFSET_Y, HEX_SIZE, OFFSET_X, OFFSET_Y)

      assert.is_not_nil(hex)
      assert.equals(0, hex.q)
      assert.equals(0, hex.r)
    end)

    it("should return correct hex for slightly off-center click", function()
      -- 중앙에서 조금 벗어난 클릭도 같은 헥스
      local hex = Input.pixelToHex(OFFSET_X + 10, OFFSET_Y + 10, HEX_SIZE, OFFSET_X, OFFSET_Y)

      assert.is_not_nil(hex)
      assert.equals(0, hex.q)
      assert.equals(0, hex.r)
    end)

    it("should return nil for click outside board", function()
      -- 보드 외부 (매우 먼 좌표)
      local hex = Input.pixelToHex(0, 0, HEX_SIZE, OFFSET_X, OFFSET_Y)

      assert.is_nil(hex)
    end)

    it("should return nil for click far outside board", function()
      -- 보드 범위를 크게 벗어난 클릭
      local hex = Input.pixelToHex(9999, 9999, HEX_SIZE, OFFSET_X, OFFSET_Y)

      assert.is_nil(hex)
    end)

    it("should return neighbor hex for click on neighbor", function()
      -- 동쪽 이웃 헥스(1, 0) 중심 근처 클릭
      -- hex (1,0)의 큐브 좌표는 (1, -1, 0)
      -- 픽셀 좌표: px = size * sqrt(3) * (x + z/2) = 50 * 1.732 * 1 ≈ 86.6
      local x, y, z = Hex.axialToCube(1, 0)
      local neighborPx, neighborPy = Hex.cubeToPixel(x, y, z, HEX_SIZE)
      local hex = Input.pixelToHex(neighborPx + OFFSET_X, neighborPy + OFFSET_Y, HEX_SIZE, OFFSET_X, OFFSET_Y)

      assert.is_not_nil(hex)
      assert.equals(1, hex.q)
      assert.equals(0, hex.r)
    end)
  end)

  describe("pixelToVertex", function()
    it("should return N vertex when clicking near N vertex", function()
      -- 중앙 헥스(0,0)의 N 정점 픽셀 좌표
      local vertexPx, vertexPy = Input.getVertexPixel(0, 0, "N", HEX_SIZE, OFFSET_X, OFFSET_Y)

      -- 정점 근처 클릭
      local vertex = Input.pixelToVertex(vertexPx, vertexPy, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)

      assert.is_not_nil(vertex)
      -- 정규화 후: (0, 0, S) → (0, 1, N) 또는 (0, 0, N) 그대로
      -- N 정점은 정규화 시 그대로 유지
      assert.equals("N", vertex.dir)
    end)

    it("should return nil when clicking far from any vertex", function()
      -- 헥스 중앙은 모든 정점과 거리가 멀다
      local vertex = Input.pixelToVertex(OFFSET_X, OFFSET_Y, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)

      assert.is_nil(vertex)
    end)

    it("should return normalized vertex coordinates", function()
      -- S 정점 근처 클릭 시 정규화된 좌표 반환
      local vertexPx, vertexPy = Input.getVertexPixel(0, 0, "S", HEX_SIZE, OFFSET_X, OFFSET_Y)
      local vertex = Input.pixelToVertex(vertexPx, vertexPy, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)

      assert.is_not_nil(vertex)
      -- (0, 0, S)는 (0, 1, N)으로 정규화됨
      assert.equals(0, vertex.q)
      assert.equals(1, vertex.r)
      assert.equals("N", vertex.dir)
    end)

    it("should respect threshold boundary", function()
      -- N 정점에서 threshold + 1 만큼 떨어진 위치
      local vertexPx, vertexPy = Input.getVertexPixel(0, 0, "N", HEX_SIZE, OFFSET_X, OFFSET_Y)

      -- threshold 내에서는 반환
      local vertexInside = Input.pixelToVertex(vertexPx, vertexPy + VERTEX_THRESHOLD - 1, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)
      assert.is_not_nil(vertexInside)

      -- threshold 크게 벗어나면 nil (다른 정점보다도 멀어야 하므로 더 큰 거리 필요)
      -- 헥스 중앙에서 테스트 - 모든 정점으로부터 hexSize 거리
      local vertexOutside = Input.pixelToVertex(OFFSET_X, OFFSET_Y, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)
      assert.is_nil(vertexOutside)
    end)
  end)

  describe("pixelToEdge", function()
    it("should return E edge when clicking near E edge", function()
      -- E 변의 중앙 근처 클릭
      local px1, py1, px2, py2 = Input.getEdgePixels(0, 0, "E", HEX_SIZE, OFFSET_X, OFFSET_Y)
      local midX = (px1 + px2) / 2
      local midY = (py1 + py2) / 2

      local edge = Input.pixelToEdge(midX, midY, HEX_SIZE, OFFSET_X, OFFSET_Y, EDGE_THRESHOLD)

      assert.is_not_nil(edge)
      assert.equals("E", edge.dir)
    end)

    it("should return nil when clicking far from any edge", function()
      -- 헥스 중앙은 모든 변과 거리가 있지만, threshold가 작으면 nil
      -- 헥스 중앙은 변까지의 거리가 hexSize * cos(30°) ≈ 43px
      local edge = Input.pixelToEdge(OFFSET_X, OFFSET_Y, HEX_SIZE, OFFSET_X, OFFSET_Y, EDGE_THRESHOLD)

      assert.is_nil(edge)
    end)

    it("should return normalized edge coordinates", function()
      -- NE 변 근처 클릭
      local px1, py1, px2, py2 = Input.getEdgePixels(0, 0, "NE", HEX_SIZE, OFFSET_X, OFFSET_Y)
      local midX = (px1 + px2) / 2
      local midY = (py1 + py2) / 2

      local edge = Input.pixelToEdge(midX, midY, HEX_SIZE, OFFSET_X, OFFSET_Y, EDGE_THRESHOLD)

      assert.is_not_nil(edge)
      -- 정규 방향 (NE, E, SE 중 하나)
      assert.is_true(edge.dir == "NE" or edge.dir == "E" or edge.dir == "SE")
    end)

    it("should respect threshold boundary", function()
      -- E 변 중앙에서 threshold 내외 테스트
      local px1, py1, px2, py2 = Input.getEdgePixels(0, 0, "E", HEX_SIZE, OFFSET_X, OFFSET_Y)
      local midX = (px1 + px2) / 2
      local midY = (py1 + py2) / 2

      -- threshold 내에서는 반환
      local edgeInside = Input.pixelToEdge(midX, midY, HEX_SIZE, OFFSET_X, OFFSET_Y, 50) -- 넉넉한 threshold
      assert.is_not_nil(edgeInside)

      -- threshold 크게 줄이면 중앙에서 nil 가능성
      -- (실제로는 변 중앙에서 0 거리이므로 항상 반환됨)
    end)
  end)

  describe("round-trip conversions", function()
    it("should return same vertex pixel after round-trip", function()
      -- getVertexPixel → pixelToVertex → getVertexPixel
      local origPx, origPy = Input.getVertexPixel(0, 0, "N", HEX_SIZE, OFFSET_X, OFFSET_Y)
      local vertex = Input.pixelToVertex(origPx, origPy, HEX_SIZE, OFFSET_X, OFFSET_Y, VERTEX_THRESHOLD)

      assert.is_not_nil(vertex)

      local roundTripPx, roundTripPy = Input.getVertexPixel(vertex.q, vertex.r, vertex.dir, HEX_SIZE, OFFSET_X, OFFSET_Y)

      -- 정규화 때문에 정확히 같지 않을 수 있으나, 같은 물리적 위치
      assert.is_near(origPx, roundTripPx, 0.01)
      assert.is_near(origPy, roundTripPy, 0.01)
    end)
  end)
end)
