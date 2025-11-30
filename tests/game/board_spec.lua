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

  -- Story 4-2: 숫자 토큰 배치

  describe("number tokens", function()
    it("should have 18 tiles with numbers", function()
      local board = Board.newStandard()
      local tiles = board:getAllTiles()

      local tilesWithNumber = 0
      for _, tile in ipairs(tiles) do
        if tile.number ~= nil then
          tilesWithNumber = tilesWithNumber + 1
        end
      end

      assert.equals(18, tilesWithNumber)
    end)

    it("should have correct number distribution", function()
      local board = Board.newStandard()
      local tiles = board:getAllTiles()

      -- 숫자별 카운트
      local counts = {}
      for _, tile in ipairs(tiles) do
        if tile.number ~= nil then
          counts[tile.number] = (counts[tile.number] or 0) + 1
        end
      end

      -- GDD 명세: 2, 12: 1개씩 / 3-6, 8-11: 2개씩
      assert.equals(1, counts[2])
      assert.equals(2, counts[3])
      assert.equals(2, counts[4])
      assert.equals(2, counts[5])
      assert.equals(2, counts[6])
      assert.is_nil(counts[7])  -- 7은 없음
      assert.equals(2, counts[8])
      assert.equals(2, counts[9])
      assert.equals(2, counts[10])
      assert.equals(2, counts[11])
      assert.equals(1, counts[12])
    end)

    it("should have numbers in valid range (2-6, 8-12)", function()
      local board = Board.newStandard()
      local tiles = board:getAllTiles()

      for _, tile in ipairs(tiles) do
        if tile.number ~= nil then
          local valid = (tile.number >= 2 and tile.number <= 6) or
                        (tile.number >= 8 and tile.number <= 12)
          assert.is_true(valid, "Number " .. tile.number .. " is out of valid range")
        end
      end
    end)

    it("should not have number 7", function()
      local board = Board.newStandard()
      local tiles = board:getAllTiles()

      for _, tile in ipairs(tiles) do
        assert.is_not_equal(7, tile.number)
      end
    end)
  end)

  describe("getTilesWithNumber", function()
    it("should return tiles with specific number", function()
      local board = Board.newStandard()

      -- 숫자 8은 2개 있어야 함
      local tiles8 = board:getTilesWithNumber(8)
      assert.equals(2, #tiles8)

      for _, tile in ipairs(tiles8) do
        assert.equals(8, tile.number)
      end
    end)

    it("should return 1 tile for numbers 2 and 12", function()
      local board = Board.newStandard()

      local tiles2 = board:getTilesWithNumber(2)
      local tiles12 = board:getTilesWithNumber(12)

      assert.equals(1, #tiles2)
      assert.equals(1, #tiles12)
    end)

    it("should return 2 tiles for numbers 3-6 and 8-11", function()
      local board = Board.newStandard()

      local numbersWithTwo = {3, 4, 5, 6, 8, 9, 10, 11}
      for _, num in ipairs(numbersWithTwo) do
        local tiles = board:getTilesWithNumber(num)
        assert.equals(2, #tiles, "Expected 2 tiles for number " .. num)
      end
    end)

    it("should return empty list for number 7", function()
      local board = Board.newStandard()

      local tiles7 = board:getTilesWithNumber(7)
      assert.equals(0, #tiles7)
    end)

    it("should return empty list for invalid numbers", function()
      local board = Board.newStandard()

      local tiles1 = board:getTilesWithNumber(1)
      local tiles13 = board:getTilesWithNumber(13)

      assert.equals(0, #tiles1)
      assert.equals(0, #tiles13)
    end)
  end)

end)
