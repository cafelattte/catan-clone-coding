-- tests/game/player_spec.lua
-- Epic 2 Story 2-3, 2-4, 2-5: Player 테스트

describe("Player", function()
  local Player = require("src.game.player")
  local Constants = require("src.game.constants")
  local player

  before_each(function()
    player = Player(1)
  end)

  -- Story 2-3: 플레이어 기본 + 자원 추가
  describe("new", function()
    it("should create player with id", function()
      assert.equals(1, player.id)
    end)

    it("should initialize all resources to 0", function()
      for _, resource in ipairs(Constants.RESOURCE_TYPES) do
        assert.equals(0, player:getResource(resource))
      end
    end)

    it("should initialize buildings to 0", function()
      assert.equals(0, player.buildings.settlements)
      assert.equals(0, player.buildings.cities)
      assert.equals(0, player.buildings.roads)
    end)
  end)

  describe("getResource", function()
    it("should return resource amount", function()
      assert.equals(0, player:getResource("wood"))
    end)

    it("should return nil for invalid resource type", function()
      assert.is_nil(player:getResource("gold"))
    end)
  end)

  describe("getAllResources", function()
    it("should return copy of all resources", function()
      player:addResource("wood", 3)
      local resources = player:getAllResources()
      assert.equals(3, resources.wood)
      -- Verify it's a copy
      resources.wood = 999
      assert.equals(3, player:getResource("wood"))
    end)
  end)

  describe("addResource", function()
    it("should add resources correctly", function()
      local success = player:addResource("wood", 2)
      assert.is_true(success)
      assert.equals(2, player:getResource("wood"))
    end)

    it("should accumulate resources", function()
      player:addResource("brick", 2)
      player:addResource("brick", 3)
      assert.equals(5, player:getResource("brick"))
    end)

    it("should return false for invalid resource type", function()
      local success = player:addResource("gold", 1)
      assert.is_false(success)
    end)

    it("should return false for negative amount", function()
      local success = player:addResource("wood", -1)
      assert.is_false(success)
    end)
  end)

  -- Story 2-4: 자원 차감 + 검증
  describe("removeResource", function()
    it("should remove resources correctly", function()
      player:addResource("wood", 5)
      local success = player:removeResource("wood", 3)
      assert.is_true(success)
      assert.equals(2, player:getResource("wood"))
    end)

    it("should fail if not enough resources", function()
      player:addResource("wood", 2)
      local success, err = player:removeResource("wood", 5)
      assert.is_nil(success)
      assert.equals("Not enough wood", err)
    end)

    it("should fail for invalid resource type", function()
      local success, err = player:removeResource("gold", 1)
      assert.is_nil(success)
      assert.matches("Invalid resource type", err)
    end)

    it("should allow removing exact amount", function()
      player:addResource("ore", 3)
      local success = player:removeResource("ore", 3)
      assert.is_true(success)
      assert.equals(0, player:getResource("ore"))
    end)
  end)

  describe("hasResources", function()
    it("should return true when player has enough resources", function()
      player:addResource("wood", 2)
      player:addResource("brick", 2)
      assert.is_true(player:hasResources({wood = 1, brick = 1}))
    end)

    it("should return false when player lacks resources", function()
      player:addResource("wood", 1)
      assert.is_false(player:hasResources({wood = 2}))
    end)

    it("should return true for empty cost table", function()
      assert.is_true(player:hasResources({}))
    end)

    it("should check all required resources", function()
      player:addResource("wood", 5)
      -- Missing brick
      assert.is_false(player:hasResources({wood = 1, brick = 1}))
    end)
  end)

  describe("canBuild", function()
    it("should return true when can build road", function()
      player:addResource("wood", 1)
      player:addResource("brick", 1)
      assert.is_true(player:canBuild("road"))
    end)

    it("should return false when cannot build road", function()
      player:addResource("wood", 1)
      -- Missing brick
      assert.is_false(player:canBuild("road"))
    end)

    it("should check settlement cost correctly", function()
      player:addResource("wood", 1)
      player:addResource("brick", 1)
      player:addResource("sheep", 1)
      player:addResource("wheat", 1)
      assert.is_true(player:canBuild("settlement"))
    end)

    it("should check city cost correctly", function()
      player:addResource("wheat", 2)
      player:addResource("ore", 3)
      assert.is_true(player:canBuild("city"))
    end)

    it("should check devcard cost correctly", function()
      player:addResource("sheep", 1)
      player:addResource("wheat", 1)
      player:addResource("ore", 1)
      assert.is_true(player:canBuild("devcard"))
    end)

    it("should return false for invalid building type", function()
      assert.is_false(player:canBuild("castle"))
    end)
  end)

  -- Observability: 디버그 출력
  describe("toString", function()
    it("should return formatted string", function()
      player:addResource("wood", 3)
      player.buildings.settlements = 2
      local str = player:toString()
      assert.matches("Player 1", str)
      assert.matches("wood=3", str)
      assert.matches("settlements=2", str)
      assert.matches("VP: 2", str)
    end)
  end)

  -- Story 2-5: 승리 점수 계산
  describe("getVictoryPoints", function()
    it("should return 0 for new player", function()
      assert.equals(0, player:getVictoryPoints())
    end)

    it("should give 1 point per settlement", function()
      player.buildings.settlements = 3
      assert.equals(3, player:getVictoryPoints())
    end)

    it("should give 2 points per city", function()
      player.buildings.cities = 2
      assert.equals(4, player:getVictoryPoints())
    end)

    it("should calculate combined points correctly", function()
      player.buildings.settlements = 2
      player.buildings.cities = 1
      assert.equals(4, player:getVictoryPoints())  -- 2*1 + 1*2
    end)

    it("should not count roads as points", function()
      player.buildings.roads = 10
      assert.equals(0, player:getVictoryPoints())
    end)
  end)

end)
