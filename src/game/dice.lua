-- src/game/dice.lua
-- Story 5-1: 주사위 굴림 시스템
-- 2d6 주사위 굴림, 합계 2-12

local Dice = {}

--- 테스트용 시드 설정
-- @param seed number 난수 시드
function Dice.setSeed(seed)
    math.randomseed(seed)
end

--- 2d6 주사위 굴림
-- @return table {die1, die2, sum}
function Dice.roll()
    local die1 = math.random(1, 6)
    local die2 = math.random(1, 6)

    return {
        die1 = die1,
        die2 = die2,
        sum = die1 + die2
    }
end

return Dice
