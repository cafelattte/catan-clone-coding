-- tests/ui/colors_spec.lua
-- Story 6-1: Colors 모듈 테스트

describe("Colors", function()
  local Colors = require("src.ui.colors")

  -- AC6-1-2: 지형 색상 정의
  describe("TERRAIN", function()
    it("should define forest color as green", function()
      local c = Colors.TERRAIN.forest
      assert.is_not_nil(c)
      assert.equals(0.2, c[1])
      assert.equals(0.6, c[2])
      assert.equals(0.2, c[3])
    end)

    it("should define hills color as orange", function()
      local c = Colors.TERRAIN.hills
      assert.is_not_nil(c)
      assert.equals(0.8, c[1])
      assert.equals(0.5, c[2])
      assert.equals(0.2, c[3])
    end)

    it("should define pasture color as light green", function()
      local c = Colors.TERRAIN.pasture
      assert.is_not_nil(c)
      assert.equals(0.6, c[1])
      assert.equals(0.8, c[2])
      assert.equals(0.4, c[3])
    end)

    it("should define fields color as yellow", function()
      local c = Colors.TERRAIN.fields
      assert.is_not_nil(c)
      assert.equals(0.9, c[1])
      assert.equals(0.8, c[2])
      assert.equals(0.3, c[3])
    end)

    it("should define mountains color as gray", function()
      local c = Colors.TERRAIN.mountains
      assert.is_not_nil(c)
      assert.equals(0.5, c[1])
      assert.equals(0.5, c[2])
      assert.equals(0.5, c[3])
    end)

    it("should define desert color as beige", function()
      local c = Colors.TERRAIN.desert
      assert.is_not_nil(c)
      assert.equals(0.9, c[1])
      assert.equals(0.85, c[2])
      assert.equals(0.7, c[3])
    end)

    it("should have 6 terrain types", function()
      local count = 0
      for _ in pairs(Colors.TERRAIN) do
        count = count + 1
      end
      assert.equals(6, count)
    end)
  end)

  -- AC6-1-4: 숫자 색상 (6, 8 빨간색)
  describe("NUMBER", function()
    it("should define normal color as black", function()
      local c = Colors.NUMBER.normal
      assert.is_not_nil(c)
      assert.equals(0, c[1])
      assert.equals(0, c[2])
      assert.equals(0, c[3])
    end)

    it("should define hot color as red for 6 and 8", function()
      local c = Colors.NUMBER.hot
      assert.is_not_nil(c)
      assert.equals(0.8, c[1])
      assert.equals(0.1, c[2])
      assert.equals(0.1, c[3])
    end)

    it("should define background color for token", function()
      local c = Colors.NUMBER.background
      assert.is_not_nil(c)
      assert.equals(0.95, c[1])
      assert.equals(0.9, c[2])
      assert.equals(0.8, c[3])
    end)
  end)

  describe("PLAYER", function()
    it("should define 4 player colors", function()
      assert.is_not_nil(Colors.PLAYER[1])
      assert.is_not_nil(Colors.PLAYER[2])
      assert.is_not_nil(Colors.PLAYER[3])
      assert.is_not_nil(Colors.PLAYER[4])
    end)

    it("should have RGB values in 0-1 range", function()
      for i = 1, 4 do
        local c = Colors.PLAYER[i]
        assert.is_true(c[1] >= 0 and c[1] <= 1)
        assert.is_true(c[2] >= 0 and c[2] <= 1)
        assert.is_true(c[3] >= 0 and c[3] <= 1)
      end
    end)
  end)

  describe("UI", function()
    it("should define background color", function()
      assert.is_not_nil(Colors.UI.background)
    end)

    it("should define text color", function()
      assert.is_not_nil(Colors.UI.text)
    end)

    it("should define highlight color with alpha", function()
      local c = Colors.UI.highlight
      assert.is_not_nil(c)
      assert.equals(4, #c)  -- RGBA
    end)

    it("should define outline color", function()
      assert.is_not_nil(Colors.UI.outline)
    end)
  end)

  -- RGB 값 범위 검증
  describe("color value ranges", function()
    local function checkRGBRange(colorTable, name)
      for key, color in pairs(colorTable) do
        for i = 1, 3 do
          assert.is_true(
            color[i] >= 0 and color[i] <= 1,
            string.format("%s.%s[%d] should be in 0-1 range, got %s", name, key, i, color[i])
          )
        end
      end
    end

    it("should have TERRAIN colors in 0-1 range", function()
      checkRGBRange(Colors.TERRAIN, "TERRAIN")
    end)

    it("should have NUMBER colors in 0-1 range", function()
      checkRGBRange(Colors.NUMBER, "NUMBER")
    end)

    it("should have PLAYER colors in 0-1 range", function()
      local playerTable = {}
      for i, color in ipairs(Colors.PLAYER) do
        playerTable[tostring(i)] = color
      end
      checkRGBRange(playerTable, "PLAYER")
    end)
  end)
end)
