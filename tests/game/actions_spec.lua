-- tests/game/actions_spec.lua
-- 건설 실행 테스트 (Story 5-4)

describe("Actions", function()
  local Actions
  local Board
  local Player
  local Constants

  setup(function()
    Actions = require("src.game.actions")
    Board = require("src.game.board")
    Player = require("src.game.player")
    Constants = require("src.game.constants")
  end)

  -- 테스트용 게임 상태 생성 헬퍼
  local function createGameState()
    local board = Board.new()
    board.tiles["0,0"] = {q = 0, r = 0, terrain = "forest", number = 8}
    board.tiles["1,0"] = {q = 1, r = 0, terrain = "hills", number = 6}
    board.tiles["0,1"] = {q = 0, r = 1, terrain = "pasture", number = 5}

    local players = {
      Player(1),
      Player(2)
    }

    return {
      board = board,
      players = players
    }
  end

  describe("buildSettlement", function()
    -- AC-5.4.16: 정착지 건설 시 자원 차감
    it("should deduct correct resources (wood, brick, sheep, wheat)", function()
      local game = createGameState()
      local player = game.players[1]
      -- 자원 지급
      player:addResource("wood", 2)
      player:addResource("brick", 2)
      player:addResource("sheep", 2)
      player:addResource("wheat", 2)
      -- 도로 배치 (연결 조건)
      game.board:placeRoad(1, 0, 0, "NE")

      local success, err = Actions.buildSettlement(game, 1, {q = 0, r = 0, dir = "N"})

      assert.is_true(success)
      assert.are.equal(1, player:getResource("wood"))
      assert.are.equal(1, player:getResource("brick"))
      assert.are.equal(1, player:getResource("sheep"))
      assert.are.equal(1, player:getResource("wheat"))
    end)

    -- AC-5.4.20: 건설 성공 시 보드에 배치
    it("should place settlement on board", function()
      local game = createGameState()
      local player = game.players[1]
      player:addResource("wood", 1)
      player:addResource("brick", 1)
      player:addResource("sheep", 1)
      player:addResource("wheat", 1)
      game.board:placeRoad(1, 0, 0, "NE")

      Actions.buildSettlement(game, 1, {q = 0, r = 0, dir = "N"})

      local building = game.board:getBuilding(0, 0, "N")
      assert.is_not_nil(building)
      assert.are.equal("settlement", building.type)
      assert.are.equal(1, building.player)
    end)

    -- AC-5.4.20: 플레이어 건물 카운트 증가
    it("should increment player settlement count", function()
      local game = createGameState()
      local player = game.players[1]
      player:addResource("wood", 1)
      player:addResource("brick", 1)
      player:addResource("sheep", 1)
      player:addResource("wheat", 1)
      game.board:placeRoad(1, 0, 0, "NE")

      Actions.buildSettlement(game, 1, {q = 0, r = 0, dir = "N"})

      assert.are.equal(1, player.buildings.settlements)
    end)

    -- AC-5.4.19: 자원 부족 시 실패
    it("should fail if insufficient resources", function()
      local game = createGameState()
      local player = game.players[1]
      player:addResource("wood", 1)
      -- brick, sheep, wheat 없음
      game.board:placeRoad(1, 0, 0, "NE")

      local success, err = Actions.buildSettlement(game, 1, {q = 0, r = 0, dir = "N"})

      assert.is_false(success)
      assert.are.equal("Not enough resources", err)
      -- 자원 변경 없음
      assert.are.equal(1, player:getResource("wood"))
    end)

    it("should fail if rules validation fails", function()
      local game = createGameState()
      local player = game.players[1]
      player:addResource("wood", 1)
      player:addResource("brick", 1)
      player:addResource("sheep", 1)
      player:addResource("wheat", 1)
      -- 도로 없음 → 연결 규칙 위반

      local success, err = Actions.buildSettlement(game, 1, {q = 0, r = 0, dir = "N"})

      assert.is_false(success)
      assert.are.equal("Not connected to road", err)
    end)
  end)

  describe("buildRoad", function()
    -- AC-5.4.17: 도로 건설 시 자원 차감
    it("should deduct wood and brick", function()
      local game = createGameState()
      local player = game.players[1]
      player:addResource("wood", 2)
      player:addResource("brick", 2)
      -- 정착지 배치 (연결 조건)
      game.board:placeSettlement(1, 0, 0, "N")

      local success, err = Actions.buildRoad(game, 1, {q = 0, r = 0, dir = "NE"})

      assert.is_true(success)
      assert.are.equal(1, player:getResource("wood"))
      assert.are.equal(1, player:getResource("brick"))
    end)

    it("should place road on board", function()
      local game = createGameState()
      local player = game.players[1]
      player:addResource("wood", 1)
      player:addResource("brick", 1)
      game.board:placeSettlement(1, 0, 0, "N")

      Actions.buildRoad(game, 1, {q = 0, r = 0, dir = "NE"})

      local road = game.board:getRoad(0, 0, "NE")
      assert.is_not_nil(road)
      assert.are.equal(1, road.player)
    end)

    it("should increment player road count", function()
      local game = createGameState()
      local player = game.players[1]
      player:addResource("wood", 1)
      player:addResource("brick", 1)
      game.board:placeSettlement(1, 0, 0, "N")

      Actions.buildRoad(game, 1, {q = 0, r = 0, dir = "NE"})

      assert.are.equal(1, player.buildings.roads)
    end)

    it("should fail if insufficient resources", function()
      local game = createGameState()
      local player = game.players[1]
      player:addResource("wood", 1)
      -- brick 없음
      game.board:placeSettlement(1, 0, 0, "N")

      local success, err = Actions.buildRoad(game, 1, {q = 0, r = 0, dir = "NE"})

      assert.is_false(success)
      assert.are.equal("Not enough resources", err)
    end)
  end)

  describe("buildCity", function()
    -- AC-5.4.18: 도시 업그레이드 시 자원 차감
    it("should deduct wheat and ore", function()
      local game = createGameState()
      local player = game.players[1]
      player:addResource("wheat", 3)
      player:addResource("ore", 4)
      game.board:placeSettlement(1, 0, 0, "N")
      player.buildings.settlements = 1

      local success, err = Actions.buildCity(game, 1, {q = 0, r = 0, dir = "N"})

      assert.is_true(success)
      assert.are.equal(1, player:getResource("wheat"))  -- 3 - 2
      assert.are.equal(1, player:getResource("ore"))    -- 4 - 3
    end)

    it("should upgrade settlement to city on board", function()
      local game = createGameState()
      local player = game.players[1]
      player:addResource("wheat", 2)
      player:addResource("ore", 3)
      game.board:placeSettlement(1, 0, 0, "N")
      player.buildings.settlements = 1

      Actions.buildCity(game, 1, {q = 0, r = 0, dir = "N"})

      local building = game.board:getBuilding(0, 0, "N")
      assert.are.equal("city", building.type)
    end)

    it("should update player building counts", function()
      local game = createGameState()
      local player = game.players[1]
      player:addResource("wheat", 2)
      player:addResource("ore", 3)
      game.board:placeSettlement(1, 0, 0, "N")
      player.buildings.settlements = 1

      Actions.buildCity(game, 1, {q = 0, r = 0, dir = "N"})

      assert.are.equal(0, player.buildings.settlements)
      assert.are.equal(1, player.buildings.cities)
    end)

    it("should fail if insufficient resources", function()
      local game = createGameState()
      local player = game.players[1]
      player:addResource("wheat", 1)  -- 2 필요
      player:addResource("ore", 3)
      game.board:placeSettlement(1, 0, 0, "N")
      player.buildings.settlements = 1

      local success, err = Actions.buildCity(game, 1, {q = 0, r = 0, dir = "N"})

      assert.is_false(success)
      assert.are.equal("Not enough resources", err)
    end)

    it("should fail if no settlement at vertex", function()
      local game = createGameState()
      local player = game.players[1]
      player:addResource("wheat", 2)
      player:addResource("ore", 3)

      local success, err = Actions.buildCity(game, 1, {q = 0, r = 0, dir = "N"})

      assert.is_false(success)
      assert.are.equal("No settlement at vertex", err)
    end)
  end)

  describe("buildSettlementFree (initial placement)", function()
    it("should not deduct resources", function()
      local game = createGameState()
      local player = game.players[1]
      -- 자원 없음

      local success, err = Actions.buildSettlementFree(game, 1, {q = 0, r = 0, dir = "N"})

      assert.is_true(success)
      assert.are.equal(0, player:getResource("wood"))
    end)

    it("should place settlement and increment count", function()
      local game = createGameState()
      local player = game.players[1]

      Actions.buildSettlementFree(game, 1, {q = 0, r = 0, dir = "N"})

      local building = game.board:getBuilding(0, 0, "N")
      assert.is_not_nil(building)
      assert.are.equal(1, player.buildings.settlements)
    end)

    it("should still enforce distance rule", function()
      local game = createGameState()
      game.board:placeSettlement(2, 0, 0, "N")

      -- (0,-1,S)는 (0,0,N)의 실제 인접 정점 (BUG-004 수정 후)
      local success, err = Actions.buildSettlementFree(game, 1, {q = 0, r = -1, dir = "S"})

      assert.is_false(success)
      assert.are.equal("Distance rule violated", err)
    end)
  end)

  describe("buildRoadFree (initial placement)", function()
    it("should not deduct resources", function()
      local game = createGameState()
      local player = game.players[1]
      game.board:placeSettlement(1, 0, 0, "N")
      player.buildings.settlements = 1

      local success, err = Actions.buildRoadFree(game, 1, {q = 0, r = 0, dir = "NE"})

      assert.is_true(success)
      assert.are.equal(0, player:getResource("wood"))
      assert.are.equal(0, player:getResource("brick"))
    end)

    it("should place road and increment count", function()
      local game = createGameState()
      local player = game.players[1]
      game.board:placeSettlement(1, 0, 0, "N")
      player.buildings.settlements = 1

      Actions.buildRoadFree(game, 1, {q = 0, r = 0, dir = "NE"})

      local road = game.board:getRoad(0, 0, "NE")
      assert.is_not_nil(road)
      assert.are.equal(1, player.buildings.roads)
    end)
  end)
end)
