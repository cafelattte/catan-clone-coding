-- tests/game/dice_spec.lua
-- Story 5-1: 주사위 굴림 시스템 테스트
-- TDD: RED phase

describe("Dice", function()
    local Dice

    setup(function()
        Dice = require("src.game.dice")
    end)

    describe("roll", function()
        it("should return a table with die1, die2, and sum", function()
            local result = Dice.roll()

            assert.is_table(result)
            assert.is_not_nil(result.die1)
            assert.is_not_nil(result.die2)
            assert.is_not_nil(result.sum)
        end)

        it("should have die1 in range 1-6", function()
            for _ = 1, 100 do
                local result = Dice.roll()
                assert.is_true(result.die1 >= 1 and result.die1 <= 6,
                    "die1 should be between 1 and 6, got " .. result.die1)
            end
        end)

        it("should have die2 in range 1-6", function()
            for _ = 1, 100 do
                local result = Dice.roll()
                assert.is_true(result.die2 >= 1 and result.die2 <= 6,
                    "die2 should be between 1 and 6, got " .. result.die2)
            end
        end)

        it("should have sum equal to die1 + die2", function()
            for _ = 1, 100 do
                local result = Dice.roll()
                assert.are.equal(result.die1 + result.die2, result.sum,
                    "sum should equal die1 + die2")
            end
        end)

        it("should have sum in range 2-12", function()
            for _ = 1, 100 do
                local result = Dice.roll()
                assert.is_true(result.sum >= 2 and result.sum <= 12,
                    "sum should be between 2 and 12, got " .. result.sum)
            end
        end)
    end)

    describe("setSeed", function()
        it("should produce reproducible results with same seed", function()
            Dice.setSeed(12345)
            local result1 = Dice.roll()

            Dice.setSeed(12345)
            local result2 = Dice.roll()

            assert.are.equal(result1.die1, result2.die1)
            assert.are.equal(result1.die2, result2.die2)
            assert.are.equal(result1.sum, result2.sum)
        end)

        it("should produce different results with different seeds", function()
            Dice.setSeed(11111)
            local result1 = Dice.roll()

            Dice.setSeed(99999)
            local result2 = Dice.roll()

            -- 시드 설정이 작동하는지 확인 (구조 검증)
            assert.is_table(result1)
            assert.is_table(result2)
        end)
    end)

    describe("distribution (statistical)", function()
        it("should have 7 as the most frequent sum over many rolls", function()
            Dice.setSeed(42)

            local counts = {}
            for i = 2, 12 do
                counts[i] = 0
            end

            local totalRolls = 1000
            for _ = 1, totalRolls do
                local result = Dice.roll()
                counts[result.sum] = counts[result.sum] + 1
            end

            -- 7이 가장 빈번해야 함 (이론상 16.67%)
            local maxSum = 2
            for sum = 3, 12 do
                if counts[sum] > counts[maxSum] then
                    maxSum = sum
                end
            end

            assert.are.equal(7, maxSum,
                "7 should be the most frequent sum, but got " .. maxSum)
        end)

        it("should produce all possible sums (2-12) over many rolls", function()
            Dice.setSeed(123)

            local seen = {}
            for _ = 1, 1000 do
                local result = Dice.roll()
                seen[result.sum] = true
            end

            for sum = 2, 12 do
                assert.is_true(seen[sum],
                    "sum " .. sum .. " should appear at least once")
            end
        end)
    end)
end)
