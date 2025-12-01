-- src/game/rules.lua
-- Story 5-2: 자원 분배
-- Story 5-6: 승리 체크

local Constants = require("src.game.constants")

local Rules = {}

--- 주사위 결과에 따른 자원 분배
-- @param board Board 보드 객체
-- @param players table Player 객체 배열
-- @param rolledNumber number 주사위 합계 (2-12)
function Rules.distributeResources(board, players, rolledNumber)
    -- 해당 숫자의 타일들 조회
    local tiles = board:getTilesWithNumber(rolledNumber)

    for _, tile in ipairs(tiles) do
        local resource = Constants.TERRAIN_RESOURCE[tile.terrain]

        -- 사막은 자원 생산 없음
        if resource then
            -- 정착지: 1개 자원
            local settlements = board:getSettlementsOnTile(tile.q, tile.r)
            for _, settlement in ipairs(settlements) do
                local player = players[settlement.player]
                if player then
                    player:addResource(resource, 1)
                end
            end

            -- 도시: 2개 자원
            local cities = board:getCitiesOnTile(tile.q, tile.r)
            for _, city in ipairs(cities) do
                local player = players[city.player]
                if player then
                    player:addResource(resource, 2)
                end
            end
        end
    end
end

--- 승리 조건 체크
-- @param players table Player 객체 배열
-- @param victoryTarget number 승리 점수 (기본 10)
-- @return number|nil 승자 플레이어 ID, 없으면 nil
function Rules.checkVictory(players, victoryTarget)
    victoryTarget = victoryTarget or 10

    for i, player in ipairs(players) do
        local points = player:getVictoryPoints()
        if points >= victoryTarget then
            return i
        end
    end

    return nil
end

return Rules
