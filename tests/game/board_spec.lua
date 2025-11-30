-- tests/game/board_spec.lua
-- Epic 4 Story 4-1: Board 타일 생성 테스트

describe("Board", function()
  local Board = require("src.game.board")
  local Constants = require("src.game.constants")

  -- Story 4-1: 보드 타일 생성

  describe("new", function()
    it("should create an empty board with no tiles", function()
      local board = Board.new()

      assert.is_not_nil(board)
      assert.is_not_nil(board.tiles)

      local tiles = board:getAllTiles()
      assert.equals(0, #tiles)
    end)

    it("should have robber as nil initially", function()
      local board = Board.new()

      assert.is_nil(board.robber)
    end)
  end)

  describe("newStandard", function()
    it("should create 19 tiles", function()
      local board = Board.newStandard()
      local tiles = board:getAllTiles()

      assert.equals(19, #tiles)
    end)

    it("should have correct terrain distribution", function()
      local board = Board.newStandard()
      local tiles = board:getAllTiles()

      -- 지형별 카운트
      local counts = {}
      for _, tile in ipairs(tiles) do
        counts[tile.terrain] = (counts[tile.terrain] or 0) + 1
      end

      -- GDD 명세: 숲4, 언덕3, 목초지4, 농장4, 산3, 사막1
      assert.equals(4, counts.forest)
      assert.equals(3, counts.hills)
      assert.equals(4, counts.pasture)
      assert.equals(4, counts.fields)
      assert.equals(3, counts.mountains)
      assert.equals(1, counts.desert)
    end)

    it("should place robber on desert tile", function()
      local board = Board.newStandard()

      assert.is_not_nil(board.robber)

      -- 도둑 위치의 타일이 사막인지 확인
      local robberTile = board:getTile(board.robber.q, board.robber.r)
      assert.is_not_nil(robberTile)
      assert.equals("desert", robberTile.terrain)
    end)
  end)

  describe("getTile", function()
    it("should return tile at center (0, 0)", function()
      local board = Board.newStandard()
      local tile = board:getTile(0, 0)

      assert.is_not_nil(tile)
      assert.equals(0, tile.q)
      assert.equals(0, tile.r)
      assert.is_not_nil(tile.terrain)
    end)

    it("should return tile with correct structure", function()
      local board = Board.newStandard()
      local tile = board:getTile(0, 0)

      -- 타일 구조 확인: {q, r, terrain, number}
      assert.is_number(tile.q)
      assert.is_number(tile.r)
      assert.is_string(tile.terrain)
      -- number는 nil 또는 숫자 (이 스토리에서는 아직 nil)
    end)

    it("should return nil for coordinates outside board", function()
      local board = Board.newStandard()
      local tile = board:getTile(10, 10)

      assert.is_nil(tile)
    end)

    it("should return tiles at inner ring coordinates", function()
      local board = Board.newStandard()

      -- 내부 링 좌표들
      local innerRing = {
        {q = 1, r = 0}, {q = 1, r = -1}, {q = 0, r = -1},
        {q = -1, r = 0}, {q = -1, r = 1}, {q = 0, r = 1}
      }

      for _, coord in ipairs(innerRing) do
        local tile = board:getTile(coord.q, coord.r)
        assert.is_not_nil(tile)
      end
    end)

    it("should return tiles at outer ring coordinates", function()
      local board = Board.newStandard()

      -- 외부 링 좌표들
      local outerRing = {
        {q = 2, r = 0}, {q = 2, r = -1}, {q = 2, r = -2},
        {q = 1, r = -2}, {q = 0, r = -2}, {q = -1, r = -1},
        {q = -2, r = 0}, {q = -2, r = 1}, {q = -2, r = 2},
        {q = -1, r = 2}, {q = 0, r = 2}, {q = 1, r = 1}
      }

      for _, coord in ipairs(outerRing) do
        local tile = board:getTile(coord.q, coord.r)
        assert.is_not_nil(tile)
      end
    end)
  end)

  describe("getAllTiles", function()
    it("should return empty list for empty board", function()
      local board = Board.new()
      local tiles = board:getAllTiles()

      assert.equals(0, #tiles)
    end)

    it("should return 19 tiles for standard board", function()
      local board = Board.newStandard()
      local tiles = board:getAllTiles()

      assert.equals(19, #tiles)
    end)

    it("should return tiles with valid terrain types", function()
      local board = Board.newStandard()
      local tiles = board:getAllTiles()

      -- 지형 타입 Set 생성
      local validTerrains = {}
      for _, terrain in ipairs(Constants.TERRAIN_TYPES) do
        validTerrains[terrain] = true
      end

      for _, tile in ipairs(tiles) do
        assert.is_true(validTerrains[tile.terrain])
      end
    end)
  end)

  describe("desert tile", function()
    it("should have number as nil", function()
      local board = Board.newStandard()
      local tiles = board:getAllTiles()

      -- 사막 타일 찾기
      local desertTile = nil
      for _, tile in ipairs(tiles) do
        if tile.terrain == "desert" then
          desertTile = tile
          break
        end
      end

      assert.is_not_nil(desertTile)
      assert.is_nil(desertTile.number)
    end)
  end)

end)
