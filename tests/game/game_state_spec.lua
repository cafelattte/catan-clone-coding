-- tests/game/game_state_spec.lua
-- GameState 모듈 테스트

describe("GameState", function()
  local GameState

  before_each(function()
    GameState = require("src.game.game_state")
  end)

  describe("new(playerCount)", function()
    it("should create GameState with 4 players", function()
      local game = GameState(4)

      assert.is_not_nil(game)
      assert.equals(4, game.config.playerCount)
      assert.equals(10, game.config.victoryTarget)
      assert.equals(4, #game.players)
    end)

    it("should create GameState with 3 players", function()
      local game = GameState(3)

      assert.equals(3, game.config.playerCount)
      assert.equals(3, #game.players)
    end)

    it("should create GameState with 2 players", function()
      local game = GameState(2)

      assert.equals(2, game.config.playerCount)
      assert.equals(2, #game.players)
    end)

    it("should initialize turn state correctly", function()
      local game = GameState(4)

      assert.equals(1, game.turn.current)
      assert.equals(1, game.turn.round)
      assert.is_nil(game.turn.phase)
    end)

    it("should initialize mode as playing", function()
      local game = GameState(4)

      assert.equals("playing", game.mode)
    end)

    it("should create Player objects with correct ids", function()
      local game = GameState(4)

      for i = 1, 4 do
        assert.equals(i, game.players[i].id)
      end
    end)
  end)

  describe("getCurrentPlayer()", function()
    it("should return Player object for current turn", function()
      local game = GameState(4)
      local player = game:getCurrentPlayer()

      assert.is_not_nil(player)
      assert.equals(1, player.id)
    end)

    it("should work with 2 player game", function()
      local game = GameState(2)
      local player = game:getCurrentPlayer()

      assert.equals(1, player.id)
    end)

    it("should work with 3 player game", function()
      local game = GameState(3)
      local player = game:getCurrentPlayer()

      assert.equals(1, player.id)
    end)
  end)

  describe("getCurrentPlayerId()", function()
    it("should return 1 at game start", function()
      local game = GameState(4)

      assert.equals(1, game:getCurrentPlayerId())
    end)

    it("should return current player index after turn changes", function()
      local game = GameState(4)
      game:endTurn()

      assert.equals(2, game:getCurrentPlayerId())
    end)
  end)

  describe("getPlayer(id)", function()
    it("should return correct player by id", function()
      local game = GameState(4)

      for i = 1, 4 do
        local player = game:getPlayer(i)
        assert.is_not_nil(player)
        assert.equals(i, player.id)
      end
    end)

    it("should return nil for invalid id 0", function()
      local game = GameState(4)

      assert.is_nil(game:getPlayer(0))
    end)

    it("should return nil for id greater than playerCount", function()
      local game = GameState(4)

      assert.is_nil(game:getPlayer(5))
    end)

    it("should return nil for negative id", function()
      local game = GameState(4)

      assert.is_nil(game:getPlayer(-1))
    end)
  end)

  describe("endTurn() - 4 player game", function()
    it("should advance to player 2 from player 1", function()
      local game = GameState(4)

      game:endTurn()

      assert.equals(2, game:getCurrentPlayerId())
    end)

    it("should advance to player 3 from player 2", function()
      local game = GameState(4)
      game:endTurn()  -- 1 -> 2

      game:endTurn()  -- 2 -> 3

      assert.equals(3, game:getCurrentPlayerId())
    end)

    it("should advance to player 4 from player 3", function()
      local game = GameState(4)
      game:endTurn()  -- 1 -> 2
      game:endTurn()  -- 2 -> 3

      game:endTurn()  -- 3 -> 4

      assert.equals(4, game:getCurrentPlayerId())
    end)

    it("should wrap around to player 1 from player 4", function()
      local game = GameState(4)
      game:endTurn()  -- 1 -> 2
      game:endTurn()  -- 2 -> 3
      game:endTurn()  -- 3 -> 4

      game:endTurn()  -- 4 -> 1 (wrap)

      assert.equals(1, game:getCurrentPlayerId())
    end)
  end)

  describe("endTurn() - 3 player game", function()
    it("should cycle through 3 players correctly", function()
      local game = GameState(3)

      assert.equals(1, game:getCurrentPlayerId())
      game:endTurn()
      assert.equals(2, game:getCurrentPlayerId())
      game:endTurn()
      assert.equals(3, game:getCurrentPlayerId())
    end)

    it("should wrap around to player 1 from player 3", function()
      local game = GameState(3)
      game:endTurn()  -- 1 -> 2
      game:endTurn()  -- 2 -> 3

      game:endTurn()  -- 3 -> 1 (wrap)

      assert.equals(1, game:getCurrentPlayerId())
    end)
  end)

  describe("endTurn() - 2 player game", function()
    it("should cycle between 2 players correctly", function()
      local game = GameState(2)

      assert.equals(1, game:getCurrentPlayerId())
      game:endTurn()
      assert.equals(2, game:getCurrentPlayerId())
    end)

    it("should wrap around to player 1 from player 2", function()
      local game = GameState(2)
      game:endTurn()  -- 1 -> 2

      game:endTurn()  -- 2 -> 1 (wrap)

      assert.equals(1, game:getCurrentPlayerId())
    end)
  end)

  describe("getRound()", function()
    it("should return 1 at game start", function()
      local game = GameState(4)

      assert.equals(1, game:getRound())
    end)

    it("should remain 1 until all players finish turn (4 player)", function()
      local game = GameState(4)

      game:endTurn()  -- player 1 done
      assert.equals(1, game:getRound())

      game:endTurn()  -- player 2 done
      assert.equals(1, game:getRound())

      game:endTurn()  -- player 3 done
      assert.equals(1, game:getRound())
    end)

    it("should increment to 2 after all 4 players finish turn", function()
      local game = GameState(4)

      game:endTurn()  -- 1 -> 2
      game:endTurn()  -- 2 -> 3
      game:endTurn()  -- 3 -> 4
      game:endTurn()  -- 4 -> 1, round++

      assert.equals(2, game:getRound())
    end)

    it("should increment to 2 after all 3 players finish turn", function()
      local game = GameState(3)

      game:endTurn()  -- 1 -> 2
      game:endTurn()  -- 2 -> 3
      game:endTurn()  -- 3 -> 1, round++

      assert.equals(2, game:getRound())
    end)

    it("should increment to 2 after all 2 players finish turn", function()
      local game = GameState(2)

      game:endTurn()  -- 1 -> 2
      game:endTurn()  -- 2 -> 1, round++

      assert.equals(2, game:getRound())
    end)

    it("should reach round 3 after 8 endTurn calls (4 player)", function()
      local game = GameState(4)

      for _ = 1, 8 do
        game:endTurn()
      end

      assert.equals(3, game:getRound())
      assert.equals(1, game:getCurrentPlayerId())
    end)

    it("should reach round 5 after 16 endTurn calls (4 player)", function()
      local game = GameState(4)

      for _ = 1, 16 do
        game:endTurn()
      end

      assert.equals(5, game:getRound())
      assert.equals(1, game:getCurrentPlayerId())
    end)
  end)

  describe("integration scenarios", function()
    it("should maintain consistency between getCurrentPlayer and getCurrentPlayerId", function()
      local game = GameState(4)

      for _ = 1, 10 do
        local player = game:getCurrentPlayer()
        local playerId = game:getCurrentPlayerId()
        assert.equals(playerId, player.id)
        game:endTurn()
      end
    end)

    it("should have correct playerCount in config for all game sizes", function()
      for playerCount = 2, 4 do
        local game = GameState(playerCount)
        assert.equals(playerCount, game.config.playerCount)
        assert.equals(playerCount, #game.players)
      end
    end)
  end)
end)
