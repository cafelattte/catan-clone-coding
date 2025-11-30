-- tests/game/hex_spec.lua
-- Epic 3 Story 3-1, 3-2, 3-3: Hex 좌표계 테스트

describe("Hex", function()
  local Hex = require("src.game.hex")

  -- Story 3-1: Axial ↔ Cube 좌표 변환
  describe("axialToCube", function()
    it("should convert origin (0,0)", function()
      local x, y, z = Hex.axialToCube(0, 0)
      assert.equals(0, x)
      assert.equals(0, y)
      assert.equals(0, z)
    end)

    it("should convert (1, -1) to cube", function()
      local x, y, z = Hex.axialToCube(1, -1)
      assert.equals(1, x)
      assert.equals(0, y)
      assert.equals(-1, z)
    end)

    it("should maintain x + y + z = 0 invariant", function()
      local testCases = {
        {q = 0, r = 0},
        {q = 1, r = -1},
        {q = 2, r = 1},
        {q = -3, r = 2},
        {q = 5, r = -3},
      }
      for _, tc in ipairs(testCases) do
        local x, y, z = Hex.axialToCube(tc.q, tc.r)
        assert.equals(0, x + y + z, "invariant failed for q=" .. tc.q .. ", r=" .. tc.r)
      end
    end)
  end)

  describe("cubeToAxial", function()
    it("should convert origin (0,0,0)", function()
      local q, r = Hex.cubeToAxial(0, 0, 0)
      assert.equals(0, q)
      assert.equals(0, r)
    end)

    it("should convert (1, 0, -1) to axial", function()
      local q, r = Hex.cubeToAxial(1, 0, -1)
      assert.equals(1, q)
      assert.equals(-1, r)
    end)

    it("should roundtrip with axialToCube", function()
      local testCases = {
        {q = 0, r = 0},
        {q = 3, r = -2},
        {q = -1, r = 4},
        {q = 2, r = 2},
      }
      for _, tc in ipairs(testCases) do
        local x, y, z = Hex.axialToCube(tc.q, tc.r)
        local q2, r2 = Hex.cubeToAxial(x, y, z)
        assert.equals(tc.q, q2)
        assert.equals(tc.r, r2)
      end
    end)
  end)

  -- Story 3-2: Cube ↔ Pixel 좌표 변환
  describe("cubeToPixel", function()
    it("should convert origin to (0, 0)", function()
      local px, py = Hex.cubeToPixel(0, 0, 0, 50)
      assert.equals(0, px)
      assert.equals(0, py)
    end)

    it("should convert E neighbor correctly", function()
      -- E neighbor is (1, -1, 0) in cube from (0,0,0)
      -- For pointy-top: px = size * sqrt(3) * (x + z/2)
      --                 py = size * 3/2 * z
      local px, py = Hex.cubeToPixel(1, -1, 0, 50)
      -- x=1, z=0: px = 50 * sqrt(3) * 1 ≈ 86.6
      assert.is_true(px > 80 and px < 90)
      assert.equals(0, py)
    end)

    it("should scale with hex size", function()
      local px1, py1 = Hex.cubeToPixel(1, 0, -1, 50)
      local px2, py2 = Hex.cubeToPixel(1, 0, -1, 100)
      assert.near(px1 * 2, px2, 0.001)
      assert.near(py1 * 2, py2, 0.001)
    end)
  end)

  describe("pixelToCube", function()
    it("should convert origin pixel to origin cube", function()
      local x, y, z = Hex.pixelToCube(0, 0, 50)
      assert.equals(0, x)
      assert.equals(0, y)
      assert.equals(0, z)
    end)

    it("should roundtrip with cubeToPixel", function()
      local testCases = {
        {x = 0, y = 0, z = 0},
        {x = 1, y = -1, z = 0},
        {x = 2, y = -1, z = -1},
        {x = -1, y = 2, z = -1},
      }
      for _, tc in ipairs(testCases) do
        local px, py = Hex.cubeToPixel(tc.x, tc.y, tc.z, 50)
        local x2, y2, z2 = Hex.pixelToCube(px, py, 50)
        assert.equals(tc.x, x2, "x mismatch")
        assert.equals(tc.y, y2, "y mismatch")
        assert.equals(tc.z, z2, "z mismatch")
      end
    end)
  end)

  describe("cubeRound", function()
    it("should round to nearest cube coordinate", function()
      local x, y, z = Hex.cubeRound(0.3, -0.5, 0.2)
      assert.equals(0, x + y + z, "invariant broken")
    end)

    it("should handle exact coordinates", function()
      local x, y, z = Hex.cubeRound(1, -1, 0)
      assert.equals(1, x)
      assert.equals(-1, y)
      assert.equals(0, z)
    end)
  end)

  -- Story 3-3: 이웃 헥스 계산
  describe("getNeighbors", function()
    it("should return 6 neighbors", function()
      local neighbors = Hex.getNeighbors(0, 0)
      assert.equals(6, #neighbors)
    end)

    it("should return correct neighbors for origin", function()
      local neighbors = Hex.getNeighbors(0, 0)
      local expected = {
        {q = 1, r = 0},   -- E
        {q = 1, r = -1},  -- NE
        {q = 0, r = -1},  -- NW
        {q = -1, r = 0},  -- W
        {q = -1, r = 1},  -- SW
        {q = 0, r = 1},   -- SE
      }
      for i, exp in ipairs(expected) do
        assert.equals(exp.q, neighbors[i].q, "q mismatch at " .. i)
        assert.equals(exp.r, neighbors[i].r, "r mismatch at " .. i)
      end
    end)

    it("should work for non-origin hex", function()
      local neighbors = Hex.getNeighbors(2, -1)
      assert.equals(6, #neighbors)
      -- Check one specific neighbor
      assert.equals(3, neighbors[1].q)  -- E neighbor
      assert.equals(-1, neighbors[1].r)
    end)
  end)

  describe("getNeighbor", function()
    it("should return E neighbor with index", function()
      local q, r = Hex.getNeighbor(0, 0, 1)
      assert.equals(1, q)
      assert.equals(0, r)
    end)

    it("should return E neighbor with string", function()
      local q, r = Hex.getNeighbor(0, 0, "E")
      assert.equals(1, q)
      assert.equals(0, r)
    end)

    it("should return NE neighbor", function()
      local q, r = Hex.getNeighbor(0, 0, "NE")
      assert.equals(1, q)
      assert.equals(-1, r)
    end)

    it("should return W neighbor", function()
      local q, r = Hex.getNeighbor(0, 0, "W")
      assert.equals(-1, q)
      assert.equals(0, r)
    end)

    it("should return nil for invalid direction", function()
      local q, r = Hex.getNeighbor(0, 0, "INVALID")
      assert.is_nil(q)
      assert.is_nil(r)
    end)
  end)

  describe("hexToString", function()
    it("should format as (q,r)", function()
      assert.equals("(0,0)", Hex.hexToString(0, 0))
      assert.equals("(1,-1)", Hex.hexToString(1, -1))
      assert.equals("(-2,3)", Hex.hexToString(-2, 3))
    end)
  end)

  describe("DIRECTIONS", function()
    it("should have 6 directions", function()
      assert.equals(6, #Hex.DIRECTIONS)
    end)

    it("should have direction names", function()
      assert.equals(6, #Hex.DIRECTION_NAMES)
      assert.equals("E", Hex.DIRECTION_NAMES[1])
      assert.equals("NE", Hex.DIRECTION_NAMES[2])
    end)
  end)

end)
