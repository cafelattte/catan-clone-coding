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
      assert.equals("roll", game.turn.phase)
    end)

    it("should initialize mode as setup", function()
      local game = GameState(4)

      assert.equals("setup", game.mode)
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

  -- Story 7-2: Phase Management Tests
  describe("getPhase()", function()
    it("should return 'roll' at game start", function()
      local game = GameState(4)

      assert.equals("roll", game:getPhase())
    end)

    it("should match turn.phase directly", function()
      local game = GameState(4)

      assert.equals(game.turn.phase, game:getPhase())
    end)
  end)

  describe("setPhase()", function()
    it("should set phase to main", function()
      local game = GameState(4)

      game:setPhase("main")

      assert.equals("main", game:getPhase())
    end)

    it("should set phase to roll", function()
      local game = GameState(4)
      game:setPhase("main")

      game:setPhase("roll")

      assert.equals("roll", game:getPhase())
    end)
  end)

  describe("canRoll()", function()
    it("should return true when mode=playing and phase=roll", function()
      local game = GameState(4)
      game.mode = "playing"

      assert.is_true(game:canRoll())
    end)

    it("should return false when phase=main", function()
      local game = GameState(4)
      game:setPhase("main")

      assert.is_false(game:canRoll())
    end)

    it("should return false when mode=finished", function()
      local game = GameState(4)
      game.mode = "finished"

      assert.is_false(game:canRoll())
    end)

    it("should return false when mode=setup", function()
      local game = GameState(4)
      game.mode = "setup"

      assert.is_false(game:canRoll())
    end)
  end)

  describe("canBuild()", function()
    it("should return false when phase=roll", function()
      local game = GameState(4)
      game.mode = "playing"

      assert.is_false(game:canBuild())
    end)

    it("should return true when mode=playing and phase=main", function()
      local game = GameState(4)
      game.mode = "playing"
      game:setPhase("main")

      assert.is_true(game:canBuild())
    end)

    it("should return false when mode=finished", function()
      local game = GameState(4)
      game:setPhase("main")
      game.mode = "finished"

      assert.is_false(game:canBuild())
    end)

    it("should return false when mode=setup", function()
      local game = GameState(4)
      game:setPhase("main")
      game.mode = "setup"

      assert.is_false(game:canBuild())
    end)
  end)

  describe("rollDice()", function()
    it("should return dice result with die1, die2, sum", function()
      local game = GameState(4)
      game.mode = "playing"

      local result = game:rollDice()

      assert.is_not_nil(result)
      assert.is_not_nil(result.die1)
      assert.is_not_nil(result.die2)
      assert.is_not_nil(result.sum)
      assert.equals(result.die1 + result.die2, result.sum)
    end)

    it("should store result in diceResult", function()
      local game = GameState(4)
      game.mode = "playing"

      local result = game:rollDice()

      assert.equals(result, game.diceResult)
    end)

    it("should change phase to main after rolling", function()
      local game = GameState(4)
      game.mode = "playing"

      game:rollDice()

      assert.equals("main", game:getPhase())
    end)

    it("should return nil with error when phase is not roll", function()
      local game = GameState(4)
      game:setPhase("main")

      local result, err = game:rollDice()

      assert.is_nil(result)
      assert.equals("Cannot roll in current phase", err)
    end)

    it("should return nil with error when mode is finished", function()
      local game = GameState(4)
      game.mode = "finished"

      local result, err = game:rollDice()

      assert.is_nil(result)
      assert.equals("Cannot roll in current phase", err)
    end)

    it("should return values in valid range (1-6 each die, 2-12 sum)", function()
      local game = GameState(4)
      game.mode = "playing"

      for _ = 1, 50 do
        game:setPhase("roll")
        local result = game:rollDice()

        assert.is_true(result.die1 >= 1 and result.die1 <= 6)
        assert.is_true(result.die2 >= 1 and result.die2 <= 6)
        assert.is_true(result.sum >= 2 and result.sum <= 12)
      end
    end)
  end)

  describe("endTurn() - phase reset", function()
    it("should reset phase to roll after endTurn", function()
      local game = GameState(4)
      game.mode = "playing"
      game:setPhase("main")

      game:endTurn()

      assert.equals("roll", game:getPhase())
    end)

    it("should clear diceResult after endTurn", function()
      local game = GameState(4)
      game.mode = "playing"
      game:rollDice()
      assert.is_not_nil(game.diceResult)

      game:endTurn()

      assert.is_nil(game.diceResult)
    end)

    it("should reset phase and advance player together", function()
      local game = GameState(4)
      game.mode = "playing"
      game:rollDice()

      game:endTurn()

      assert.equals(2, game:getCurrentPlayerId())
      assert.equals("roll", game:getPhase())
      assert.is_nil(game.diceResult)
    end)
  end)

  describe("checkVictory()", function()
    -- Helper: set victory points via buildings (1 settlement = 1 VP, 1 city = 2 VP)
    local function setVP(player, points)
      -- Use cities (2 VP each) and settlements (1 VP each) to reach target
      local cities = math.floor(points / 2)
      local settlements = points % 2
      player.buildings.cities = cities
      player.buildings.settlements = settlements
    end

    it("should return nil when no player has 10 points", function()
      local game = GameState(4)
      game.mode = "playing"

      local winner = game:checkVictory()

      assert.is_nil(winner)
      assert.equals("playing", game.mode)
    end)

    it("should return winner id when player reaches 10 points", function()
      local game = GameState(4)
      -- Player 2 reaches 10 points (5 cities)
      setVP(game.players[2], 10)

      local winner = game:checkVictory()

      assert.equals(2, winner)
    end)

    it("should set mode to finished when winner found", function()
      local game = GameState(4)
      setVP(game.players[3], 10)

      game:checkVictory()

      assert.equals("finished", game.mode)
    end)

    it("should set winner field when winner found", function()
      local game = GameState(4)
      setVP(game.players[1], 10)

      game:checkVictory()

      assert.equals(1, game.winner)
    end)

    it("should detect first player to reach target (multiple at target)", function()
      local game = GameState(4)
      setVP(game.players[2], 10)
      setVP(game.players[4], 10)

      local winner = game:checkVictory()

      -- First in array order wins
      assert.equals(2, winner)
    end)

    it("should use custom victoryTarget from config", function()
      local game = GameState(4)
      game.config.victoryTarget = 5
      setVP(game.players[3], 5)

      local winner = game:checkVictory()

      assert.equals(3, winner)
    end)

    it("should not change mode when no winner", function()
      local game = GameState(4)
      game.mode = "playing"
      setVP(game.players[1], 9)

      game:checkVictory()

      assert.equals("playing", game.mode)
      assert.is_nil(game.winner)
    end)
  end)

  -- Story 7-6: Setup Mode Tests
  describe("new() - setup mode initialization", function()
    it("should initialize mode as 'setup' by default", function()
      local game = GameState(4)

      assert.equals("setup", game.mode)
    end)

    it("should initialize setup structure with correct defaults", function()
      local game = GameState(4)

      assert.is_not_nil(game.setup)
      assert.equals(1, game.setup.round)
      assert.equals("forward", game.setup.direction)
      assert.equals("settlement", game.setup.phase)
      assert.equals(1, game.setup.currentPlayer)
    end)

    it("should initialize lastPlacedSettlement as nil", function()
      local game = GameState(4)

      assert.is_nil(game.setup.lastPlacedSettlement)
    end)
  end)

  describe("isSetup()", function()
    it("should return true when mode is 'setup'", function()
      local game = GameState(4)

      assert.is_true(game:isSetup())
    end)

    it("should return false when mode is 'playing'", function()
      local game = GameState(4)
      game.mode = "playing"

      assert.is_false(game:isSetup())
    end)

    it("should return false when mode is 'finished'", function()
      local game = GameState(4)
      game.mode = "finished"

      assert.is_false(game:isSetup())
    end)
  end)

  describe("getSetupPlayer()", function()
    it("should return currentPlayer from setup structure", function()
      local game = GameState(4)

      assert.equals(1, game:getSetupPlayer())
    end)

    it("should return updated value after setup advances", function()
      local game = GameState(4)
      game.setup.currentPlayer = 3

      assert.equals(3, game:getSetupPlayer())
    end)
  end)

  describe("getSetupPhase()", function()
    it("should return 'settlement' initially", function()
      local game = GameState(4)

      assert.equals("settlement", game:getSetupPhase())
    end)

    it("should return 'road' when setup.phase is road", function()
      local game = GameState(4)
      game.setup.phase = "road"

      assert.equals("road", game:getSetupPhase())
    end)
  end)

  describe("advanceSetup() - phase transitions", function()
    it("should transition from settlement to road phase", function()
      local game = GameState(4)
      assert.equals("settlement", game:getSetupPhase())

      game:advanceSetup()

      assert.equals("road", game:getSetupPhase())
      assert.equals(1, game:getSetupPlayer())  -- Same player
    end)

    it("should transition from road to next player in Round 1 (forward)", function()
      local game = GameState(4)
      game.setup.phase = "road"

      game:advanceSetup()

      assert.equals("settlement", game:getSetupPhase())
      assert.equals(2, game:getSetupPlayer())
      assert.equals(1, game.setup.round)
      assert.equals("forward", game.setup.direction)
    end)

    it("should cycle through all 4 players in Round 1", function()
      local game = GameState(4)

      -- Player 1: settlement -> road -> Player 2
      game:advanceSetup()  -- settlement -> road
      game:advanceSetup()  -- road -> next player (2)
      assert.equals(2, game:getSetupPlayer())

      -- Player 2: settlement -> road -> Player 3
      game:advanceSetup()  -- settlement -> road
      game:advanceSetup()  -- road -> next player (3)
      assert.equals(3, game:getSetupPlayer())

      -- Player 3: settlement -> road -> Player 4
      game:advanceSetup()  -- settlement -> road
      game:advanceSetup()  -- road -> next player (4)
      assert.equals(4, game:getSetupPlayer())
    end)

    it("should transition to Round 2 after player 4 completes in Round 1", function()
      local game = GameState(4)
      game.setup.currentPlayer = 4
      game.setup.phase = "road"

      game:advanceSetup()

      assert.equals(2, game.setup.round)
      assert.equals("reverse", game.setup.direction)
      assert.equals(4, game:getSetupPlayer())  -- Player 4 starts Round 2
      assert.equals("settlement", game:getSetupPhase())
    end)

    it("should go backwards in Round 2 (reverse direction)", function()
      local game = GameState(4)
      game.setup.round = 2
      game.setup.direction = "reverse"
      game.setup.currentPlayer = 4
      game.setup.phase = "road"

      game:advanceSetup()

      assert.equals(3, game:getSetupPlayer())  -- 4 -> 3
      assert.equals("settlement", game:getSetupPhase())
    end)

    it("should cycle backwards through all players in Round 2", function()
      local game = GameState(4)
      game.setup.round = 2
      game.setup.direction = "reverse"
      game.setup.currentPlayer = 4
      game.setup.phase = "settlement"

      -- Player 4: settlement -> road -> Player 3
      game:advanceSetup()  -- settlement -> road
      game:advanceSetup()  -- road -> prev player (3)
      assert.equals(3, game:getSetupPlayer())

      -- Player 3: settlement -> road -> Player 2
      game:advanceSetup()
      game:advanceSetup()
      assert.equals(2, game:getSetupPlayer())

      -- Player 2: settlement -> road -> Player 1
      game:advanceSetup()
      game:advanceSetup()
      assert.equals(1, game:getSetupPlayer())
    end)

    it("should transition to playing mode after player 1 completes Round 2", function()
      local game = GameState(4)
      game.setup.round = 2
      game.setup.direction = "reverse"
      game.setup.currentPlayer = 1
      game.setup.phase = "road"

      game:advanceSetup()

      assert.equals("playing", game.mode)
      assert.equals(1, game.turn.current)
      assert.equals("roll", game.turn.phase)
    end)

    it("should clear setup structure after transitioning to playing", function()
      local game = GameState(4)
      game.setup.round = 2
      game.setup.direction = "reverse"
      game.setup.currentPlayer = 1
      game.setup.phase = "road"

      game:advanceSetup()

      assert.is_nil(game.setup)
    end)
  end)

  describe("advanceSetup() - 3 player game", function()
    it("should transition to Round 2 after player 3 completes in Round 1", function()
      local game = GameState(3)
      game.setup.currentPlayer = 3
      game.setup.phase = "road"

      game:advanceSetup()

      assert.equals(2, game.setup.round)
      assert.equals("reverse", game.setup.direction)
      assert.equals(3, game:getSetupPlayer())
    end)

    it("should transition to playing after player 1 completes Round 2", function()
      local game = GameState(3)
      game.setup.round = 2
      game.setup.direction = "reverse"
      game.setup.currentPlayer = 1
      game.setup.phase = "road"

      game:advanceSetup()

      assert.equals("playing", game.mode)
    end)
  end)

  describe("advanceSetup() - 2 player game", function()
    it("should transition to Round 2 after player 2 completes in Round 1", function()
      local game = GameState(2)
      game.setup.currentPlayer = 2
      game.setup.phase = "road"

      game:advanceSetup()

      assert.equals(2, game.setup.round)
      assert.equals("reverse", game.setup.direction)
      assert.equals(2, game:getSetupPlayer())
    end)

    it("should transition to playing after player 1 completes Round 2", function()
      local game = GameState(2)
      game.setup.round = 2
      game.setup.direction = "reverse"
      game.setup.currentPlayer = 1
      game.setup.phase = "road"

      game:advanceSetup()

      assert.equals("playing", game.mode)
    end)
  end)

  describe("full setup flow - 4 player game (integration)", function()
    it("should complete entire snake draft sequence", function()
      local game = GameState(4)

      -- Round 1: 1 -> 2 -> 3 -> 4
      local expectedRound1 = {1, 2, 3, 4}
      for i, expectedPlayer in ipairs(expectedRound1) do
        assert.equals(expectedPlayer, game:getSetupPlayer(), "Round 1 player " .. i)
        assert.equals("settlement", game:getSetupPhase())
        game:advanceSetup()  -- settlement -> road
        assert.equals("road", game:getSetupPhase())
        game:advanceSetup()  -- road -> next
      end

      -- After Round 1, should be in Round 2
      assert.equals(2, game.setup.round)
      assert.equals("reverse", game.setup.direction)

      -- Round 2: 4 -> 3 -> 2 -> 1
      local expectedRound2 = {4, 3, 2, 1}
      for i, expectedPlayer in ipairs(expectedRound2) do
        if game:isSetup() then
          assert.equals(expectedPlayer, game:getSetupPlayer(), "Round 2 player " .. i)
          assert.equals("settlement", game:getSetupPhase())
          game:advanceSetup()  -- settlement -> road
          assert.equals("road", game:getSetupPhase())
          game:advanceSetup()  -- road -> next
        end
      end

      -- After Round 2, should be in playing mode
      assert.equals("playing", game.mode)
      assert.equals(1, game.turn.current)
      assert.equals("roll", game.turn.phase)
    end)
  end)

  describe("full setup flow - 3 player game (integration)", function()
    it("should complete snake draft with 3 players", function()
      local game = GameState(3)

      -- Round 1: 1 -> 2 -> 3
      for _, expected in ipairs({1, 2, 3}) do
        assert.equals(expected, game:getSetupPlayer())
        game:advanceSetup()  -- settlement
        game:advanceSetup()  -- road
      end

      assert.equals(2, game.setup.round)
      assert.equals("reverse", game.setup.direction)

      -- Round 2: 3 -> 2 -> 1
      for _, expected in ipairs({3, 2, 1}) do
        if game:isSetup() then
          assert.equals(expected, game:getSetupPlayer())
          game:advanceSetup()  -- settlement
          game:advanceSetup()  -- road
        end
      end

      assert.equals("playing", game.mode)
    end)
  end)

  describe("full setup flow - 2 player game (integration)", function()
    it("should complete snake draft with 2 players", function()
      local game = GameState(2)

      -- Round 1: 1 -> 2
      for _, expected in ipairs({1, 2}) do
        assert.equals(expected, game:getSetupPlayer())
        game:advanceSetup()  -- settlement
        game:advanceSetup()  -- road
      end

      assert.equals(2, game.setup.round)

      -- Round 2: 2 -> 1
      for _, expected in ipairs({2, 1}) do
        if game:isSetup() then
          assert.equals(expected, game:getSetupPlayer())
          game:advanceSetup()  -- settlement
          game:advanceSetup()  -- road
        end
      end

      assert.equals("playing", game.mode)
    end)
  end)

  describe("full turn cycle with phases", function()
    it("should complete a full turn cycle: roll -> main -> endTurn", function()
      local game = GameState(4)
      game.mode = "playing"  -- Skip setup phase for this test

      -- Initial state
      assert.equals("roll", game:getPhase())
      assert.is_true(game:canRoll())
      assert.is_false(game:canBuild())

      -- Roll dice
      local result = game:rollDice()
      assert.is_not_nil(result)
      assert.equals("main", game:getPhase())
      assert.is_false(game:canRoll())
      assert.is_true(game:canBuild())

      -- End turn
      game:endTurn()
      assert.equals("roll", game:getPhase())
      assert.equals(2, game:getCurrentPlayerId())
      assert.is_nil(game.diceResult)
    end)

    it("should maintain phase state across multiple turns", function()
      local game = GameState(2)
      game.mode = "playing"  -- Skip setup phase for this test

      for turn = 1, 4 do
        assert.equals("roll", game:getPhase())
        game:rollDice()
        assert.equals("main", game:getPhase())
        game:endTurn()
      end

      -- After 4 turns in 2-player game, back to player 1, round 3
      assert.equals(1, game:getCurrentPlayerId())
      assert.equals(3, game:getRound())
    end)
  end)
end)
