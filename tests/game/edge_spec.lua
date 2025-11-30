-- tests/game/edge_spec.lua
-- Epic 3 Story 3-5: 변 정규화 테스트

describe("Edge", function()
  local Edge = require("src.game.edge")

  -- Story 3-5: 변 정규화 및 인접 정점
  describe("normalize", function()
    it("should keep NE edge as-is", function()
      local q, r, dir = Edge.normalize(0, 0, "NE")
      assert.equals(0, q)
      assert.equals(0, r)
      assert.equals("NE", dir)
    end)

    it("should keep E edge as-is", function()
      local q, r, dir = Edge.normalize(0, 0, "E")
      assert.equals(0, q)
      assert.equals(0, r)
      assert.equals("E", dir)
    end)

    it("should keep SE edge as-is", function()
      local q, r, dir = Edge.normalize(0, 0, "SE")
      assert.equals(0, q)
      assert.equals(0, r)
      assert.equals("SE", dir)
    end)

    it("should convert NW to SE of neighbor", function()
      -- (0, 0, NW) → (0, -1, SE) - 북쪽 헥스의 SE
      local q, r, dir = Edge.normalize(0, 0, "NW")
      -- NW는 북쪽 헥스의 SE와 동일
      assert.equals(0, q)
      assert.equals(-1, r)
      assert.equals("SE", dir)
    end)

    it("should convert W to E of neighbor", function()
      -- (0, 0, W) → (-1, 0, E)
      local q, r, dir = Edge.normalize(0, 0, "W")
      assert.equals(-1, q)
      assert.equals(0, r)
      assert.equals("E", dir)
    end)

    it("should convert SW to NE of neighbor", function()
      -- (0, 0, SW) → (-1, 1, NE)
      local q, r, dir = Edge.normalize(0, 0, "SW")
      assert.equals(-1, q)
      assert.equals(1, r)
      assert.equals("NE", dir)
    end)

    it("should normalize same edge from different hexes", function()
      -- (0, 0, E) 와 (1, 0, W)는 같은 변
      local q1, r1, d1 = Edge.normalize(0, 0, "E")
      local q2, r2, d2 = Edge.normalize(1, 0, "W")
      assert.equals(q1, q2)
      assert.equals(r1, r2)
      assert.equals(d1, d2)
    end)
  end)

  describe("toString", function()
    it("should format as q,r,dir", function()
      assert.equals("0,0,E", Edge.toString(0, 0, "E"))
      assert.equals("1,-1,NE", Edge.toString(1, -1, "NE"))
      assert.equals("-2,3,SE", Edge.toString(-2, 3, "SE"))
    end)
  end)

  describe("fromString", function()
    it("should parse q,r,dir format", function()
      local q, r, dir = Edge.fromString("0,0,E")
      assert.equals(0, q)
      assert.equals(0, r)
      assert.equals("E", dir)
    end)

    it("should parse negative coordinates", function()
      local q, r, dir = Edge.fromString("-1,2,NE")
      assert.equals(-1, q)
      assert.equals(2, r)
      assert.equals("NE", dir)
    end)
  end)

  describe("getVertices", function()
    it("should return 2 vertices for E edge", function()
      local v1, v2 = Edge.getVertices(0, 0, "E")
      assert.is_not_nil(v1)
      assert.is_not_nil(v2)
      -- E 변의 양 끝: 헥스의 오른쪽 위와 오른쪽 아래 정점
      -- (0, 0, N)과 (0, 0, S) 또는 인접 헥스의 정점
    end)

    it("should return 2 vertices for NE edge", function()
      local v1, v2 = Edge.getVertices(0, 0, "NE")
      assert.is_not_nil(v1)
      assert.is_not_nil(v2)
    end)

    it("should return 2 vertices for SE edge", function()
      local v1, v2 = Edge.getVertices(0, 0, "SE")
      assert.is_not_nil(v1)
      assert.is_not_nil(v2)
    end)

    it("should return vertices with valid directions", function()
      local v1, v2 = Edge.getVertices(0, 0, "E")
      assert.is_true(v1.dir == "N" or v1.dir == "S")
      assert.is_true(v2.dir == "N" or v2.dir == "S")
    end)
  end)

  describe("getAdjacentEdges", function()
    it("should return 4 adjacent edges", function()
      local edges = Edge.getAdjacentEdges(0, 0, "E")
      assert.equals(4, #edges)
    end)

    it("should return edges with valid directions", function()
      local edges = Edge.getAdjacentEdges(0, 0, "E")
      for _, e in ipairs(edges) do
        local validDir = e.dir == "NE" or e.dir == "E" or e.dir == "SE"
        assert.is_true(validDir, "invalid direction: " .. tostring(e.dir))
      end
    end)
  end)

  describe("DIRECTIONS", function()
    it("should have NE, E, SE (canonical directions)", function()
      assert.equals(3, #Edge.DIRECTIONS)
      assert.equals("NE", Edge.DIRECTIONS[1])
      assert.equals("E", Edge.DIRECTIONS[2])
      assert.equals("SE", Edge.DIRECTIONS[3])
    end)
  end)

end)
