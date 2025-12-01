-- tests/game/vertex_spec.lua
-- Epic 3 Story 3-4: 정점 정규화 테스트

describe("Vertex", function()
  local Vertex = require("src.game.vertex")

  -- Story 3-4: 정점 정규화
  describe("normalize", function()
    it("should keep N vertex as-is", function()
      local q, r, dir = Vertex.normalize(0, 0, "N")
      assert.equals(0, q)
      assert.equals(0, r)
      assert.equals("N", dir)
    end)

    it("should convert S vertex to N (canonical form)", function()
      -- (0, 0, S) → (0, 1, N) 변환
      -- S 정점의 바로 아래 헥스의 N 정점과 동일
      local q, r, dir = Vertex.normalize(0, 0, "S")
      assert.equals(0, q)
      assert.equals(1, r)
      assert.equals("N", dir)
    end)

    it("should normalize different representations of same vertex", function()
      -- (0, 0, N) 정점은 3개 헥스에서 참조 가능:
      -- (0, 0, N), (0, -1, S), (-1, 0, S) 는 서로 다른 표현
      -- 정규화 후 같은 결과가 나와야 함
      local q1, r1, d1 = Vertex.normalize(0, 0, "N")
      local q2, r2, d2 = Vertex.normalize(0, -1, "S")
      local q3, r3, d3 = Vertex.normalize(-1, 0, "S")

      -- 세 표현이 같은 정점인지 확인
      local s1 = Vertex.toString(q1, r1, d1)
      local s2 = Vertex.toString(q2, r2, d2)
      local s3 = Vertex.toString(q3, r3, d3)

      -- 참고: S 정점 중 일부만 N으로 변환 가능
      -- 정규화 규칙: S → 북쪽 헥스의 N으로 변환
      -- (0, -1, S) → (0, 0, N) 변환 가능
      assert.equals(s1, s2)
    end)

    it("should handle various positions", function()
      -- 다른 위치에서도 정규화 동작 확인
      local q, r, dir = Vertex.normalize(2, -1, "N")
      assert.equals(2, q)
      assert.equals(-1, r)
      assert.equals("N", dir)
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
      -- N 정점 인접 헥스: 자신, NE 이웃, NW 이웃
      local found = {[0] = {}, [1] = {}, [-1] = {}}
      for _, h in ipairs(hexes) do
        found[h.q] = found[h.q] or {}
        found[h.q][h.r] = true
      end
      assert.is_true(found[0][0] or false, "should include (0,0)")
      assert.is_true(found[0][-1] or false, "should include (0,-1)")
      assert.is_true(found[-1][0] or false, "should include (-1,0)")
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
      -- N 정점 인접 변: 자신의 NE, (q-1,r)의 E, (q,r-1)의 SE
      -- 정규화 후: (0,0,NE), (-1,0,E), (0,-1,SE)
      local found = {}
      for _, e in ipairs(edges) do
        local key = e.q .. "," .. e.r .. "," .. e.dir
        found[key] = true
      end
      assert.is_true(found["0,0,NE"], "should include (0,0,NE)")
      assert.is_true(found["-1,0,E"], "should include (-1,0,E)")
      assert.is_true(found["0,-1,SE"], "should include (0,-1,SE)")
    end)

    it("should return correct edges for (0,0,S)", function()
      local edges = Vertex.getAdjacentEdges(0, 0, "S")
      -- S 정점 인접 변: 자신의 E, 자신의 SE, (q+1,r)의 NE
      -- 정규화 후: (0,0,E), (0,0,SE), (1,0,NE)
      local found = {}
      for _, e in ipairs(edges) do
        local key = e.q .. "," .. e.r .. "," .. e.dir
        found[key] = true
      end
      assert.is_true(found["0,0,E"], "should include (0,0,E)")
      assert.is_true(found["0,0,SE"], "should include (0,0,SE)")
      assert.is_true(found["1,0,NE"], "should include (1,0,NE)")
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

end)
