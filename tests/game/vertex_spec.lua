-- tests/game/vertex_spec.lua
-- Epic 3 Story 3-4: 정점 정규화 테스트

describe("Vertex", function()
  local Vertex = require("src.game.vertex")

  -- Story 3-4: 정점 정규화
  -- 참고: Pointy-top 헥스에서 N과 S는 물리적으로 다른 위치
  -- normalize()는 현재 아무 변환도 하지 않음 (정체성 함수)
  describe("normalize", function()
    it("should keep N vertex as-is", function()
      local q, r, dir = Vertex.normalize(0, 0, "N")
      assert.equals(0, q)
      assert.equals(0, r)
      assert.equals("N", dir)
    end)

    it("should keep S vertex as-is (N and S are different positions)", function()
      -- Pointy-top 헥스에서 N과 S는 물리적으로 다른 위치
      -- (0, 0, S)는 (0, 0) 헥스의 아래쪽 꼭지점
      -- (0, 1, N)은 (0, 1) 헥스의 위쪽 꼭지점 - 다른 위치임
      local q, r, dir = Vertex.normalize(0, 0, "S")
      assert.equals(0, q)
      assert.equals(0, r)
      assert.equals("S", dir)
    end)

    it("should handle various positions", function()
      -- 다른 위치에서도 정규화 동작 확인
      local q, r, dir = Vertex.normalize(2, -1, "N")
      assert.equals(2, q)
      assert.equals(-1, r)
      assert.equals("N", dir)

      q, r, dir = Vertex.normalize(-1, 2, "S")
      assert.equals(-1, q)
      assert.equals(2, r)
      assert.equals("S", dir)
    end)
  end)

  describe("toString", function()
    it("should format as q,r,dir", function()
      assert.equals("0,0,N", Vertex.toString(0, 0, "N"))
      assert.equals("1,-1,S", Vertex.toString(1, -1, "S"))
      assert.equals("-2,3,N", Vertex.toString(-2, 3, "N"))
    end)
  end)

  describe("fromString", function()
    it("should parse q,r,dir format", function()
      local q, r, dir = Vertex.fromString("0,0,N")
      assert.equals(0, q)
      assert.equals(0, r)
      assert.equals("N", dir)
    end)

    it("should parse negative coordinates", function()
      local q, r, dir = Vertex.fromString("-1,2,S")
      assert.equals(-1, q)
      assert.equals(2, r)
      assert.equals("S", dir)
    end)
  end)

  describe("getAdjacentHexes", function()
    it("should return 3 adjacent hexes for N vertex", function()
      local hexes = Vertex.getAdjacentHexes(0, 0, "N")
      assert.equals(3, #hexes)
    end)

    it("should return 3 adjacent hexes for S vertex", function()
      local hexes = Vertex.getAdjacentHexes(0, 0, "S")
      assert.equals(3, #hexes)
    end)

    it("should return correct hexes for (0,0,N)", function()
      local hexes = Vertex.getAdjacentHexes(0, 0, "N")
      -- N 정점 인접 헥스: 자신(0,0), 북서쪽(0,-1), 북동쪽(1,-1)
      local found = {[0] = {}, [1] = {}, [-1] = {}}
      for _, h in ipairs(hexes) do
        found[h.q] = found[h.q] or {}
        found[h.q][h.r] = true
      end
      assert.is_true(found[0][0] or false, "should include (0,0)")
      assert.is_true(found[0][-1] or false, "should include (0,-1)")
      assert.is_true(found[1][-1] or false, "should include (1,-1)")
    end)
  end)

  describe("getAdjacentVertices", function()
    it("should return 3 adjacent vertices", function()
      local vertices = Vertex.getAdjacentVertices(0, 0, "N")
      assert.equals(3, #vertices)
    end)

    it("should return vertices in normalized form", function()
      local vertices = Vertex.getAdjacentVertices(0, 0, "N")
      for _, v in ipairs(vertices) do
        assert.is_true(v.dir == "N" or v.dir == "S")
      end
    end)
  end)

  describe("DIRECTIONS", function()
    it("should have N and S", function()
      assert.equals(2, #Vertex.DIRECTIONS)
      assert.equals("N", Vertex.DIRECTIONS[1])
      assert.equals("S", Vertex.DIRECTIONS[2])
    end)
  end)

  -- Story 4-4: 정점 인접 변 조회
  describe("getAdjacentEdges", function()
    it("should return 3 adjacent edges for N vertex", function()
      local edges = Vertex.getAdjacentEdges(0, 0, "N")
      assert.equals(3, #edges)
    end)

    it("should return 3 adjacent edges for S vertex", function()
      local edges = Vertex.getAdjacentEdges(0, 0, "S")
      assert.equals(3, #edges)
    end)

    it("should return normalized edges (NE, E, SE only)", function()
      local edges = Vertex.getAdjacentEdges(0, 0, "N")
      for _, e in ipairs(edges) do
        assert.is_true(e.dir == "NE" or e.dir == "E" or e.dir == "SE",
          "direction should be NE, E, or SE but got " .. e.dir)
      end
    end)

    it("should return correct edges for (0,0,N)", function()
      local edges = Vertex.getAdjacentEdges(0, 0, "N")
      -- N 정점 인접 변 (픽셀 좌표로 검증됨):
      -- (0,0,NE), (0,-1,E), (0,-1,SE)
      local found = {}
      for _, e in ipairs(edges) do
        local key = e.q .. "," .. e.r .. "," .. e.dir
        found[key] = true
      end
      assert.is_true(found["0,0,NE"], "should include (0,0,NE)")
      assert.is_true(found["0,-1,E"], "should include (0,-1,E)")
      assert.is_true(found["0,-1,SE"], "should include (0,-1,SE)")
    end)

    it("should return correct edges for (0,0,S)", function()
      local edges = Vertex.getAdjacentEdges(0, 0, "S")
      -- S 정점 인접 변 (픽셀 좌표로 검증됨):
      -- (-1,1,NE), (-1,1,E), (0,0,SE)
      local found = {}
      for _, e in ipairs(edges) do
        local key = e.q .. "," .. e.r .. "," .. e.dir
        found[key] = true
      end
      assert.is_true(found["-1,1,NE"], "should include (-1,1,NE)")
      assert.is_true(found["-1,1,E"], "should include (-1,1,E)")
      assert.is_true(found["0,0,SE"], "should include (0,0,SE)")
    end)

    it("should return edges at different positions", function()
      -- (1, -1, N) 정점의 인접 변 테스트
      local edges = Vertex.getAdjacentEdges(1, -1, "N")
      assert.equals(3, #edges)
      -- 정규화된 방향만 반환되어야 함
      for _, e in ipairs(edges) do
        assert.is_true(e.dir == "NE" or e.dir == "E" or e.dir == "SE")
      end
    end)
  end)

  -- getHexVertices 회귀 테스트 (픽셀 좌표 기반 검증)
  describe("getHexVertices", function()
    local Hex = require("src.game.hex")

    -- 정점의 픽셀 좌표 계산 헬퍼
    local function getVertexPixel(v, hexSize)
      local x, y, z = Hex.axialToCube(v.q, v.r)
      local px, py = Hex.cubeToPixel(x, y, z, hexSize)
      if v.dir == "N" then
        py = py - hexSize
      else
        py = py + hexSize
      end
      return px, py
    end

    -- 실제 헥스 꼭지점 픽셀 좌표 계산 헬퍼
    local function getActualCorner(q, r, cornerIndex, hexSize)
      local x, y, z = Hex.axialToCube(q, r)
      local cx, cy = Hex.cubeToPixel(x, y, z, hexSize)
      -- Pointy-top: N(위)부터 시계방향
      local angles = {270, -30, 30, 90, 150, 210}  -- N, NE, SE, S, SW, NW
      local angle = math.rad(angles[cornerIndex])
      return cx + hexSize * math.cos(angle), cy + hexSize * math.sin(angle)
    end

    it("should return exactly 6 vertices", function()
      local vertices = Vertex.getHexVertices(0, 0)
      assert.equals(6, #vertices)
    end)

    it("should return vertices with valid directions", function()
      local vertices = Vertex.getHexVertices(0, 0)
      for _, v in ipairs(vertices) do
        assert.is_true(v.dir == "N" or v.dir == "S",
          "direction should be N or S but got " .. tostring(v.dir))
      end
    end)

    it("should return vertices at correct pixel positions for (0,0)", function()
      local hexSize = 50
      local vertices = Vertex.getHexVertices(0, 0)

      -- 각 정점이 실제 꼭지점과 일치하는지 확인
      for i, v in ipairs(vertices) do
        local vx, vy = getVertexPixel(v, hexSize)
        local ax, ay = getActualCorner(0, 0, i, hexSize)

        assert.is_true(math.abs(vx - ax) < 0.1,
          string.format("Vertex %d X mismatch: expected %.1f, got %.1f", i, ax, vx))
        assert.is_true(math.abs(vy - ay) < 0.1,
          string.format("Vertex %d Y mismatch: expected %.1f, got %.1f", i, ay, vy))
      end
    end)

    it("should return vertices at correct pixel positions for various hexes", function()
      local hexSize = 50
      local testHexes = {
        {q = 0, r = 0},
        {q = 1, r = 0},
        {q = 0, r = 1},
        {q = -1, r = 1},
        {q = 1, r = -1},
      }

      for _, hex in ipairs(testHexes) do
        local vertices = Vertex.getHexVertices(hex.q, hex.r)

        for i, v in ipairs(vertices) do
          local vx, vy = getVertexPixel(v, hexSize)
          local ax, ay = getActualCorner(hex.q, hex.r, i, hexSize)

          assert.is_true(math.abs(vx - ax) < 0.1,
            string.format("Hex (%d,%d) Vertex %d X mismatch", hex.q, hex.r, i))
          assert.is_true(math.abs(vy - ay) < 0.1,
            string.format("Hex (%d,%d) Vertex %d Y mismatch", hex.q, hex.r, i))
        end
      end
    end)

    it("should return correct vertex coordinates for (0,0)", function()
      -- 명시적인 좌표 검증 (회귀 방지)
      local vertices = Vertex.getHexVertices(0, 0)

      -- N (위): 자신의 N
      assert.equals(0, vertices[1].q)
      assert.equals(0, vertices[1].r)
      assert.equals("N", vertices[1].dir)

      -- NE (우상): 오른쪽 위 헥스의 S
      assert.equals(1, vertices[2].q)
      assert.equals(-1, vertices[2].r)
      assert.equals("S", vertices[2].dir)

      -- SE (우하): 아래 헥스의 N
      assert.equals(0, vertices[3].q)
      assert.equals(1, vertices[3].r)
      assert.equals("N", vertices[3].dir)

      -- S (아래): 자신의 S
      assert.equals(0, vertices[4].q)
      assert.equals(0, vertices[4].r)
      assert.equals("S", vertices[4].dir)

      -- SW (좌하): 왼쪽 아래 헥스의 N
      assert.equals(-1, vertices[5].q)
      assert.equals(1, vertices[5].r)
      assert.equals("N", vertices[5].dir)

      -- NW (좌상): 위쪽 헥스의 S
      assert.equals(0, vertices[6].q)
      assert.equals(-1, vertices[6].r)
      assert.equals("S", vertices[6].dir)
    end)
  end)

  -- BUG-001/BUG-004 수정 후 좌표 시스템 교차 검증
  describe("coordinate system cross-validation", function()
    local Edge = require("src.game.edge")

    local testVertices = {
      {q=0, r=0, dir='N'}, {q=0, r=0, dir='S'},
      {q=1, r=-1, dir='N'}, {q=-1, r=1, dir='S'}
    }

    it("getHexVertices and getAdjacentHexes should be consistent", function()
      for _, v in ipairs(testVertices) do
        local adjHexes = Vertex.getAdjacentHexes(v.q, v.r, v.dir)
        for _, h in ipairs(adjHexes) do
          local hexVerts = Vertex.getHexVertices(h.q, h.r)
          local found = false
          for _, hv in ipairs(hexVerts) do
            if hv.q == v.q and hv.r == v.r and hv.dir == v.dir then
              found = true
              break
            end
          end
          assert.is_true(found, string.format(
            "Vertex(%d,%d,%s) should be in Hex(%d,%d)'s vertices",
            v.q, v.r, v.dir, h.q, h.r))
        end
      end
    end)

    it("getAdjacentEdges and Edge.getVertices should be consistent", function()
      for _, v in ipairs(testVertices) do
        local adjEdges = Vertex.getAdjacentEdges(v.q, v.r, v.dir)
        for _, e in ipairs(adjEdges) do
          local v1, v2 = Edge.getVertices(e.q, e.r, e.dir)
          local hasVertex = (v1.q == v.q and v1.r == v.r and v1.dir == v.dir) or
                            (v2.q == v.q and v2.r == v.r and v2.dir == v.dir)
          assert.is_true(hasVertex, string.format(
            "Edge(%d,%d,%s) should have Vertex(%d,%d,%s)",
            e.q, e.r, e.dir, v.q, v.r, v.dir))
        end
      end
    end)

    it("getAdjacentVertices should be bidirectional", function()
      for _, v in ipairs(testVertices) do
        local adjVerts = Vertex.getAdjacentVertices(v.q, v.r, v.dir)
        for _, av in ipairs(adjVerts) do
          local reverseAdj = Vertex.getAdjacentVertices(av.q, av.r, av.dir)
          local found = false
          for _, rv in ipairs(reverseAdj) do
            if rv.q == v.q and rv.r == v.r and rv.dir == v.dir then
              found = true
              break
            end
          end
          assert.is_true(found, string.format(
            "Vertex(%d,%d,%s) adjacent to (%d,%d,%s) should be bidirectional",
            v.q, v.r, v.dir, av.q, av.r, av.dir))
        end
      end
    end)
  end)

end)
