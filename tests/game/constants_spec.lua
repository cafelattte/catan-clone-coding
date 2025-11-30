-- tests/game/constants_spec.lua
-- Epic 2 Story 2-1, 2-2: Constants 테스트

describe("Constants", function()
  local Constants = require("src.game.constants")

  -- Story 2-1: 자원 타입 상수
  describe("RESOURCE_TYPES", function()
    it("should contain 5 resource types", function()
      assert.equals(5, #Constants.RESOURCE_TYPES)
    end)

    it("should include all resource types", function()
      local expected = {"wood", "brick", "sheep", "wheat", "ore"}
      for i, resource in ipairs(expected) do
        assert.equals(resource, Constants.RESOURCE_TYPES[i])
      end
    end)
  end)

  describe("RESOURCE_SET", function()
    it("should validate wood as resource", function()
      assert.is_true(Constants.RESOURCE_SET.wood)
    end)

    it("should validate brick as resource", function()
      assert.is_true(Constants.RESOURCE_SET.brick)
    end)

    it("should validate sheep as resource", function()
      assert.is_true(Constants.RESOURCE_SET.sheep)
    end)

    it("should validate wheat as resource", function()
      assert.is_true(Constants.RESOURCE_SET.wheat)
    end)

    it("should validate ore as resource", function()
      assert.is_true(Constants.RESOURCE_SET.ore)
    end)

    it("should return nil for invalid resource", function()
      assert.is_nil(Constants.RESOURCE_SET.gold)
    end)
  end)

  -- Story 2-2: 건물 비용 상수
  describe("BUILD_COSTS", function()
    it("should define road cost", function()
      local cost = Constants.BUILD_COSTS.road
      assert.is_not_nil(cost)
      assert.equals(1, cost.wood)
      assert.equals(1, cost.brick)
    end)

    it("should define settlement cost", function()
      local cost = Constants.BUILD_COSTS.settlement
      assert.is_not_nil(cost)
      assert.equals(1, cost.wood)
      assert.equals(1, cost.brick)
      assert.equals(1, cost.sheep)
      assert.equals(1, cost.wheat)
    end)

    it("should define city cost", function()
      local cost = Constants.BUILD_COSTS.city
      assert.is_not_nil(cost)
      assert.equals(2, cost.wheat)
      assert.equals(3, cost.ore)
    end)

    it("should define devcard cost", function()
      local cost = Constants.BUILD_COSTS.devcard
      assert.is_not_nil(cost)
      assert.equals(1, cost.sheep)
      assert.equals(1, cost.wheat)
      assert.equals(1, cost.ore)
    end)
  end)

  describe("BUILDING_POINTS", function()
    it("should give 1 point for settlement", function()
      assert.equals(1, Constants.BUILDING_POINTS.settlement)
    end)

    it("should give 2 points for city", function()
      assert.equals(2, Constants.BUILDING_POINTS.city)
    end)
  end)

end)
