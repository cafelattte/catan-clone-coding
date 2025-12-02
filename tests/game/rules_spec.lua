-- tests/game/rules_spec.lua
-- Story 5-2: 자원 분배 테스트
-- Story 5-3: 건설 검증 규칙 테스트
-- Story 5-5: 초기 배치 규칙 테스트
-- Story 5-6: 승리 체크 테스트

describe("Rules", function()
  local Rules
  local Board
  local Player
  local Constants
  local Vertex
  local Edge

  setup(function()
    Rules = require("src.game.rules")
    Board = require("src.game.board")
    Player = require("src.game.player")
    Constants = require("src.game.constants")
    Vertex = require("src.game.vertex")
    Edge = require("src.game.edge")
  end)

  -- Story 5-2: 자원 분배 테스트
  describe("distributeResources", function()
    local board
    local players

    before_each(function()
      -- 고정된 테스트 보드 생성 (결정적인 타일 배치)
      -- 각 테스트에서 필요한 타일만 설정
      board = Board.newForTesting({
        {q = 0, r = 0, terrain = "forest", number = 8},    -- wood
        {q = 1, r = 0, terrain = "hills", number = 6},     -- brick
        {q = -1, r = 0, terrain = "pasture", number = 9},  -- wool
        {q = 0, r = 1, terrain = "fields", number = 5},    -- grain
        {q = 1, r = -1, terrain = "mountains", number = 4}, -- ore
        {q = -1, r = 1, terrain = "forest", number = 4},   -- wood (숫자 4 중복)
        {q = 0, r = -1, terrain = "desert", number = nil}, -- desert (숫자 없음)
      })
      -- 4명의 플레이어 생성
      players = {
        Player(1),
        Player(2),
        Player(3),
        Player(4)
      }
    end)

    it("should give 1 resource for settlement adjacent to matching tile", function()
      -- 숫자 8인 타일 (forest, q=0, r=0)
      board:placeSettlement(1, 0, 0, "N")

      local initialAmount = players[1]:getResource("wood")

      -- 자원 분배 실행
      Rules.distributeResources(board, players, 8)

      -- 정착지는 1개 자원 획득
      assert.are.equal(initialAmount + 1, players[1]:getResource("wood"),
        "Settlement should receive 1 wood")
    end)

    it("should give 2 resources for city adjacent to matching tile", function()
      -- 숫자 6인 타일 (hills, q=1, r=0)
      board:placeSettlement(1, 1, 0, "N")
      board:upgradeToCity(1, 0, "N")

      local initialAmount = players[1]:getResource("brick")

      Rules.distributeResources(board, players, 6)

      -- 도시는 2개 자원 획득
      assert.are.equal(initialAmount + 2, players[1]:getResource("brick"),
        "City should receive 2 brick")
    end)

    it("should not include desert in tiles with any number", function()
      -- 사막 타일은 숫자 토큰이 없으므로 어떤 숫자로도 조회되지 않음
      for num = 2, 12 do
        local tiles = board:getTilesWithNumber(num)
        for _, tile in ipairs(tiles) do
          assert.is_not_equal("desert", tile.terrain,
            "Desert should not have number token " .. num)
        end
      end
    end)

    it("should not produce resources from desert terrain", function()
      -- TERRAIN_RESOURCE에서 사막은 nil 반환 확인
      assert.is_nil(Constants.TERRAIN_RESOURCE["desert"],
        "Desert should not map to any resource")
    end)

    it("should distribute to multiple players independently", function()
      -- 숫자 9인 타일 (pasture, q=-1, r=0) - 이 타일만 숫자 9를 가짐
      -- 두 플레이어가 같은 타일에 인접한 다른 정점에 정착지 배치
      board:placeSettlement(1, -1, 0, "N")
      board:placeSettlement(2, -1, 0, "S")

      local initial1 = players[1]:getResource("sheep")
      local initial2 = players[2]:getResource("sheep")

      Rules.distributeResources(board, players, 9)

      -- 각 플레이어가 정확히 1개씩 자원 획득
      assert.are.equal(initial1 + 1, players[1]:getResource("sheep"),
        "Player 1 should receive exactly 1 sheep")
      assert.are.equal(initial2 + 1, players[2]:getResource("sheep"),
        "Player 2 should receive exactly 1 sheep")
    end)

    it("should not distribute for non-matching numbers", function()
      -- 숫자 5인 타일 (fields, q=0, r=1)에 정착지 배치
      board:placeSettlement(1, 0, 1, "N")

      local initialAmount = players[1]:getResource("wheat")

      -- 다른 숫자로 굴림 (10)
      Rules.distributeResources(board, players, 10)

      -- 자원 변화 없음
      assert.are.equal(initialAmount, players[1]:getResource("wheat"))
    end)

    it("should handle multiple tiles with same number", function()
      -- 같은 숫자 4를 가진 두 타일: mountains(q=1,r=-1)와 forest(q=-1,r=1)
      board:placeSettlement(1, 1, -1, "N")  -- ore 타일
      board:placeSettlement(1, -1, 1, "N")  -- wood 타일

      local initialOre = players[1]:getResource("ore")
      local initialWood = players[1]:getResource("wood")

      Rules.distributeResources(board, players, 4)

      -- 각 타일에서 자원 획득
      assert.are.equal(initialOre + 1, players[1]:getResource("ore"),
        "Should receive 1 ore from mountains tile")
      assert.are.equal(initialWood + 1, players[1]:getResource("wood"),
        "Should receive 1 wood from forest tile")
    end)
  end)

  -- Story 5-6: 승리 조건 체크 테스트
  describe("checkVictory", function()
    local players

    before_each(function()
      players = {
        Player(1),
        Player(2),
        Player(3),
        Player(4)
      }
    end)

    it("should return nil if no player has 10+ points", function()
      -- 기본 상태: 모든 플레이어 0점
      local winner = Rules.checkVictory(players, 10)
      assert.is_nil(winner)
    end)

    it("should return player id when player reaches exactly 10 points", function()
      -- 플레이어 1에게 10점 부여 (정착지 10개 = 10점)
      players[1].buildings.settlements = 10

      local winner = Rules.checkVictory(players, 10)
      assert.are.equal(1, winner)
    end)

    it("should return player id when player exceeds 10 points", function()
      -- 플레이어 2에게 12점 부여 (도시 6개 = 12점)
      players[2].buildings.cities = 6

      local winner = Rules.checkVictory(players, 10)
      assert.are.equal(2, winner)
    end)

    it("should use custom victory target", function()
      -- 5점으로 승리 조건 변경
      players[3].buildings.settlements = 5  -- 5점

      local winner = Rules.checkVictory(players, 5)
      assert.are.equal(3, winner)
    end)

    it("should return first player to reach victory in order", function()
      -- 여러 플레이어가 동시에 10점 이상
      players[2].buildings.settlements = 10
      players[3].buildings.cities = 5  -- 10점

      -- 순서대로 체크하므로 플레이어 2가 먼저
      local winner = Rules.checkVictory(players, 10)
      assert.are.equal(2, winner)
    end)
  end)

  -- Story 5-3: 건설 검증 규칙 테스트
  describe("canBuildSettlement", function()
    local board

    before_each(function()
      board = Board.new()
      -- 테스트용 간단 보드
      board.tiles["0,0"] = {q = 0, r = 0, terrain = "forest", number = 8}
      board.tiles["1,0"] = {q = 1, r = 0, terrain = "hills", number = 6}
      board.tiles["0,1"] = {q = 0, r = 1, terrain = "pasture", number = 5}
    end)

    -- AC-5.3.10: 비어있는 정점 검증
    it("should return true if vertex is empty and connected to road", function()
      board:placeRoad(1, 0, 0, "NE")

      local canBuild, err = Rules.canBuildSettlement(board, 1, {q = 0, r = 0, dir = "N"}, false)
      assert.is_true(canBuild)
      assert.is_nil(err)
    end)

    it("should return false if vertex is occupied by settlement", function()
      board:placeSettlement(1, 0, 0, "N")
      board:placeRoad(2, 0, 0, "NE")

      local canBuild, err = Rules.canBuildSettlement(board, 2, {q = 0, r = 0, dir = "N"}, false)
      assert.is_false(canBuild)
      assert.are.equal("Vertex is occupied", err)
    end)

    it("should return false if vertex is occupied by city", function()
      board:placeSettlement(1, 0, 0, "N")
      board:upgradeToCity(0, 0, "N")
      board:placeRoad(2, 0, 0, "NE")

      local canBuild, err = Rules.canBuildSettlement(board, 2, {q = 0, r = 0, dir = "N"}, false)
      assert.is_false(canBuild)
      assert.are.equal("Vertex is occupied", err)
    end)

    -- AC-5.3.11: 거리 규칙 위반 검증
    it("should return false if adjacent vertex has building (distance rule)", function()
      board:placeSettlement(1, 0, 0, "N")
      board:placeRoad(2, -1, 0, "E")

      -- (0,-1,S)는 (0,0,N)의 실제 인접 정점 (BUG-004 수정 후)
      local canBuild, err = Rules.canBuildSettlement(board, 2, {q = 0, r = -1, dir = "S"}, false)
      assert.is_false(canBuild)
      assert.are.equal("Distance rule violated", err)
    end)

    -- AC-5.3.12: 연결 규칙 검증
    it("should return false if not connected to own road", function()
      local canBuild, err = Rules.canBuildSettlement(board, 1, {q = 0, r = 0, dir = "N"}, false)
      assert.is_false(canBuild)
      assert.are.equal("Not connected to road", err)
    end)

    it("should return false if only connected to other player road", function()
      board:placeRoad(2, 0, 0, "NE")

      local canBuild, err = Rules.canBuildSettlement(board, 1, {q = 0, r = 0, dir = "N"}, false)
      assert.is_false(canBuild)
      assert.are.equal("Not connected to road", err)
    end)

    -- AC-5.3.24: 초기 배치 시 연결 규칙 무시
    it("should ignore connection rule during initial placement", function()
      local canBuild, err = Rules.canBuildSettlement(board, 1, {q = 0, r = 0, dir = "N"}, true)
      assert.is_true(canBuild)
      assert.is_nil(err)
    end)

    it("should still enforce distance rule during initial placement", function()
      board:placeSettlement(1, 0, 0, "N")

      -- (0,-1,S)는 (0,0,N)의 실제 인접 정점 (BUG-004 수정 후)
      local canBuild, err = Rules.canBuildSettlement(board, 2, {q = 0, r = -1, dir = "S"}, true)
      assert.is_false(canBuild)
      assert.are.equal("Distance rule violated", err)
    end)
  end)

  describe("canBuildRoad", function()
    local board

    before_each(function()
      board = Board.new()
      board.tiles["0,0"] = {q = 0, r = 0, terrain = "forest", number = 8}
      board.tiles["1,0"] = {q = 1, r = 0, terrain = "hills", number = 6}
    end)

    -- AC-5.3.13: 비어있는 변 검증
    it("should return true if edge is empty and connected to building", function()
      board:placeSettlement(1, 0, 0, "N")

      local canBuild, err = Rules.canBuildRoad(board, 1, {q = 0, r = 0, dir = "NE"})
      assert.is_true(canBuild)
      assert.is_nil(err)
    end)

    it("should return false if edge is occupied", function()
      board:placeSettlement(1, 0, 0, "N")
      board:placeRoad(1, 0, 0, "NE")

      local canBuild, err = Rules.canBuildRoad(board, 2, {q = 0, r = 0, dir = "NE"})
      assert.is_false(canBuild)
      assert.are.equal("Edge is occupied", err)
    end)

    -- AC-5.3.14: 연결 규칙 검증
    it("should return false if not connected to own building or road", function()
      local canBuild, err = Rules.canBuildRoad(board, 1, {q = 0, r = 0, dir = "NE"})
      assert.is_false(canBuild)
      assert.are.equal("Not connected to building or road", err)
    end)

    it("should return true if connected to own road", function()
      board:placeSettlement(1, 0, 0, "N")
      board:placeRoad(1, 0, 0, "NE")

      local canBuild, err = Rules.canBuildRoad(board, 1, {q = 0, r = 0, dir = "E"})
      assert.is_true(canBuild)
    end)

    it("should return false if only connected to other player building", function()
      board:placeSettlement(2, 0, 0, "N")

      local canBuild, err = Rules.canBuildRoad(board, 1, {q = 0, r = 0, dir = "NE"})
      assert.is_false(canBuild)
      assert.are.equal("Not connected to building or road", err)
    end)
  end)

  describe("canBuildCity", function()
    local board

    before_each(function()
      board = Board.new()
      board.tiles["0,0"] = {q = 0, r = 0, terrain = "forest", number = 8}
    end)

    -- AC-5.3.15: 본인 정착지 존재 검증
    it("should return false if no building at vertex", function()
      local canBuild, err = Rules.canBuildCity(board, 1, {q = 0, r = 0, dir = "N"})
      assert.is_false(canBuild)
      assert.are.equal("No settlement at vertex", err)
    end)

    it("should return false if other player settlement at vertex", function()
      board:placeSettlement(2, 0, 0, "N")

      local canBuild, err = Rules.canBuildCity(board, 1, {q = 0, r = 0, dir = "N"})
      assert.is_false(canBuild)
      assert.are.equal("Not your settlement", err)
    end)

    it("should return false if already a city at vertex", function()
      board:placeSettlement(1, 0, 0, "N")
      board:upgradeToCity(0, 0, "N")

      local canBuild, err = Rules.canBuildCity(board, 1, {q = 0, r = 0, dir = "N"})
      assert.is_false(canBuild)
      assert.are.equal("Already a city", err)
    end)

    it("should return true if own settlement exists", function()
      board:placeSettlement(1, 0, 0, "N")

      local canBuild, err = Rules.canBuildCity(board, 1, {q = 0, r = 0, dir = "N"})
      assert.is_true(canBuild)
      assert.is_nil(err)
    end)
  end)

  describe("getValidSettlementLocations", function()
    local board

    before_each(function()
      board = Board.new()
      board.tiles["0,0"] = {q = 0, r = 0, terrain = "forest", number = 8}
    end)

    it("should return empty list if no roads (normal placement)", function()
      local locations = Rules.getValidSettlementLocations(board, 1, false)
      assert.are.equal(0, #locations)
    end)

    it("should return vertices connected to own roads", function()
      board:placeRoad(1, 0, 0, "NE")

      local locations = Rules.getValidSettlementLocations(board, 1, false)
      assert.is_true(#locations >= 1)
    end)

    it("should exclude occupied vertices", function()
      board:placeRoad(1, 0, 0, "NE")
      board:placeSettlement(1, 0, 0, "N")

      local locations = Rules.getValidSettlementLocations(board, 1, false)
      for _, loc in ipairs(locations) do
        local nq, nr, ndir = Vertex.normalize(loc.q, loc.r, loc.dir)
        local key = Vertex.toString(nq, nr, ndir)
        assert.are_not.equal("0,0,N", key)
      end
    end)

    it("should return valid vertices during initial placement without roads", function()
      local locations = Rules.getValidSettlementLocations(board, 1, true)
      assert.is_true(#locations > 0)
    end)
  end)

  describe("getValidRoadLocations", function()
    local board

    before_each(function()
      board = Board.new()
      board.tiles["0,0"] = {q = 0, r = 0, terrain = "forest", number = 8}
    end)

    it("should return empty list if no buildings or roads", function()
      local locations = Rules.getValidRoadLocations(board, 1)
      assert.are.equal(0, #locations)
    end)

    it("should return edges adjacent to own building", function()
      board:placeSettlement(1, 0, 0, "N")

      local locations = Rules.getValidRoadLocations(board, 1)
      assert.are.equal(3, #locations)
    end)

    it("should exclude occupied edges", function()
      board:placeSettlement(1, 0, 0, "N")
      board:placeRoad(1, 0, 0, "NE")

      local locations = Rules.getValidRoadLocations(board, 1)
      for _, loc in ipairs(locations) do
        local nq, nr, ndir = Edge.normalize(loc.q, loc.r, loc.dir)
        local key = Edge.toString(nq, nr, ndir)
        assert.are_not.equal("0,0,NE", key)
      end
    end)
  end)

  -- Story 5-5: 초기 배치 규칙 테스트
  describe("Initial Placement", function()
    describe("getInitialPlacementOrder", function()
      -- AC-5.5.21: Round 1 정순
      it("should return forward order for round 1", function()
        local order = Rules.getInitialPlacementOrder(1, 4)
        assert.are.same({1, 2, 3, 4}, order)
      end)

      -- AC-5.5.22: Round 2 역순
      it("should return reverse order for round 2", function()
        local order = Rules.getInitialPlacementOrder(2, 4)
        assert.are.same({4, 3, 2, 1}, order)
      end)

      it("should work with 3 players", function()
        local order1 = Rules.getInitialPlacementOrder(1, 3)
        local order2 = Rules.getInitialPlacementOrder(2, 3)
        assert.are.same({1, 2, 3}, order1)
        assert.are.same({3, 2, 1}, order2)
      end)
    end)

    -- AC-5.5.25: 두 번째 정착지 인접 타일 자원 획득
    describe("getInitialResources", function()
      local board

      before_each(function()
        board = Board.new()
        -- N 정점 인접 타일: (0,0), (0,-1), (1,-1) - BUG-001 좌표 체계 수정 후
        board.tiles["0,0"] = {q = 0, r = 0, terrain = "forest", number = 8}
        board.tiles["0,-1"] = {q = 0, r = -1, terrain = "hills", number = 6}
        board.tiles["1,-1"] = {q = 1, r = -1, terrain = "pasture", number = 5}
      end)

      it("should return resources from adjacent tiles", function()
        local resources = Rules.getInitialResources(board, {q = 0, r = 0, dir = "N"})

        -- forest → wood, hills → brick, pasture → sheep
        assert.are.equal(1, resources.wood)
        assert.are.equal(1, resources.brick)
        assert.are.equal(1, resources.sheep)
      end)

      it("should not include desert resources", function()
        board.tiles["0,0"] = {q = 0, r = 0, terrain = "desert", number = nil}

        local resources = Rules.getInitialResources(board, {q = 0, r = 0, dir = "N"})

        assert.is_nil(resources.wood)  -- desert 대신 nil
        assert.are.equal(1, resources.brick)
        assert.are.equal(1, resources.sheep)
      end)

      it("should handle edge of board (missing tiles)", function()
        -- 인접 타일 중 일부가 없는 경우
        board.tiles["0,-1"] = nil
        board.tiles["1,-1"] = nil

        local resources = Rules.getInitialResources(board, {q = 0, r = 0, dir = "N"})

        -- 0,0 타일만 존재
        assert.are.equal(1, resources.wood)
        assert.is_nil(resources.brick)
        assert.is_nil(resources.sheep)
      end)
    end)

    describe("canBuildInitialRoad", function()
      local board

      before_each(function()
        board = Board.new()
        board.tiles["0,0"] = {q = 0, r = 0, terrain = "forest", number = 8}
      end)

      -- AC-5.5 (Q2 해결): 초기 도로는 방금 놓은 정착지에 인접해야 함
      it("should return true if edge is adjacent to given settlement", function()
        local canBuild = Rules.canBuildInitialRoad(board, 1,
          {q = 0, r = 0, dir = "NE"},
          {q = 0, r = 0, dir = "N"})
        assert.is_true(canBuild)
      end)

      it("should return false if edge is not adjacent to settlement", function()
        local canBuild = Rules.canBuildInitialRoad(board, 1,
          {q = 0, r = 0, dir = "SE"},  -- N 정점에 인접하지 않음
          {q = 0, r = 0, dir = "N"})
        assert.is_false(canBuild)
      end)

      it("should return false if edge is occupied", function()
        board:placeRoad(2, 0, 0, "NE")

        local canBuild = Rules.canBuildInitialRoad(board, 1,
          {q = 0, r = 0, dir = "NE"},
          {q = 0, r = 0, dir = "N"})
        assert.is_false(canBuild)
      end)
    end)
  end)
end)
