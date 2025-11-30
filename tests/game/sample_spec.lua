-- tests/game/sample_spec.lua
-- Epic 1 Foundation 검증용 샘플 테스트

describe("Epic 1 Foundation", function()

  describe("Library Loading (Story 1-2)", function()

    it("should load classic", function()
      local classic = require("lib.classic")
      assert.is_not_nil(classic)
      assert.is_function(classic.extend)
    end)

    it("should load serpent", function()
      local serpent = require("lib.serpent")
      assert.is_not_nil(serpent)
      assert.is_function(serpent.dump)
      assert.is_function(serpent.line)
    end)

    -- hump.gamestate는 Love2D 전용 라이브러리
    -- Love2D 실행 시 검증 (busted 테스트 대상 아님)

  end)

  describe("Test Environment (Story 1-3)", function()

    it("should run busted tests", function()
      assert.is_true(true)
    end)

  end)

end)
