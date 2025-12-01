-- tests/game/rules_spec.lua
-- Story 5-2: 자원 분배 테스트
-- Story 5-6: 승리 체크 테스트
-- TDD: RED phase

describe("Rules", function()
    local Rules
    local Board
    local Player
    local Constants

    setup(function()
        Rules = require("src.game.rules")
        Board = require("src.game.board")
        Player = require("src.game.player")
        Constants = require("src.game.constants")
    end)

    describe("distributeResources", function()
        local board
        local players

        before_each(function()
            -- 표준 보드 생성
            board = Board.newStandard()
            -- 4명의 플레이어 생성
            players = {
                Player(1),
                Player(2),
                Player(3),
                Player(4)
            }
        end)

        it("should give 1 resource for settlement adjacent to matching tile", function()
            -- 숫자 8인 타일 찾기
            local tiles = board:getTilesWithNumber(8)
            assert.is_true(#tiles > 0, "Should have at least one tile with number 8")

            local tile = tiles[1]
            -- 타일의 N 정점에 정착지 배치
            board:placeSettlement(1, tile.q, tile.r, "N")

            -- 초기 자원 확인
            local resource = Constants.TERRAIN_RESOURCE[tile.terrain]
            if resource then
                local initialAmount = players[1]:getResource(resource)

                -- 자원 분배 실행
                Rules.distributeResources(board, players, 8)

                -- 정착지는 1개 자원 획득
                assert.are.equal(initialAmount + 1, players[1]:getResource(resource),
                    "Settlement should receive 1 " .. resource)
            end
        end)

        it("should give 2 resources for city adjacent to matching tile", function()
            -- 숫자 6인 타일 찾기
            local tiles = board:getTilesWithNumber(6)
            assert.is_true(#tiles > 0, "Should have at least one tile with number 6")

            local tile = tiles[1]
            -- 먼저 정착지 배치 후 도시로 업그레이드
            board:placeSettlement(1, tile.q, tile.r, "N")
            board:upgradeToCity(tile.q, tile.r, "N")

            local resource = Constants.TERRAIN_RESOURCE[tile.terrain]
            if resource then
                local initialAmount = players[1]:getResource(resource)

                Rules.distributeResources(board, players, 6)

                -- 도시는 2개 자원 획득
                assert.are.equal(initialAmount + 2, players[1]:getResource(resource),
                    "City should receive 2 " .. resource)
            end
        end)

        it("should not include desert in tiles with any number", function()
            -- 사막 타일은 숫자 토큰이 없으므로 어떤 숫자로도 조회되지 않음
            for num = 2, 12 do
                local tiles = board:getTilesWithNumber(num)
                for _, tile in ipairs(tiles) do
                    assert.is_not_equal("desert", tile.terrain,
                        "Desert should not have number token " .. num)
                end
            end
        end)

        it("should not produce resources from desert terrain", function()
            -- TERRAIN_RESOURCE에서 사막은 nil 반환 확인
            assert.is_nil(Constants.TERRAIN_RESOURCE["desert"],
                "Desert should not map to any resource")
        end)

        it("should distribute to multiple players independently", function()
            -- 같은 숫자의 타일 찾기
            local tiles = board:getTilesWithNumber(9)
            if #tiles > 0 then
                local tile = tiles[1]

                -- 두 플레이어가 같은 타일에 인접한 다른 정점에 정착지 배치
                board:placeSettlement(1, tile.q, tile.r, "N")
                board:placeSettlement(2, tile.q, tile.r, "S")

                local resource = Constants.TERRAIN_RESOURCE[tile.terrain]
                if resource then
                    local initial1 = players[1]:getResource(resource)
                    local initial2 = players[2]:getResource(resource)

                    Rules.distributeResources(board, players, 9)

                    -- 각 플레이어 독립적으로 자원 획득
                    assert.are.equal(initial1 + 1, players[1]:getResource(resource))
                    assert.are.equal(initial2 + 1, players[2]:getResource(resource))
                end
            end
        end)

        it("should not distribute for non-matching numbers", function()
            local tiles = board:getTilesWithNumber(5)
            if #tiles > 0 then
                local tile = tiles[1]
                board:placeSettlement(1, tile.q, tile.r, "N")

                local resource = Constants.TERRAIN_RESOURCE[tile.terrain]
                if resource then
                    local initialAmount = players[1]:getResource(resource)

                    -- 다른 숫자로 굴림
                    Rules.distributeResources(board, players, 10)

                    -- 자원 변화 없음
                    assert.are.equal(initialAmount, players[1]:getResource(resource))
                end
            end
        end)

        it("should handle multiple tiles with same number", function()
            -- 같은 숫자의 타일이 여러 개인 경우
            local tiles = board:getTilesWithNumber(4)
            if #tiles >= 2 then
                -- 두 타일에 각각 정착지 배치
                board:placeSettlement(1, tiles[1].q, tiles[1].r, "N")
                board:placeSettlement(1, tiles[2].q, tiles[2].r, "N")

                local resource1 = Constants.TERRAIN_RESOURCE[tiles[1].terrain]
                local resource2 = Constants.TERRAIN_RESOURCE[tiles[2].terrain]

                local initial1 = resource1 and players[1]:getResource(resource1) or 0
                local initial2 = resource2 and players[1]:getResource(resource2) or 0

                Rules.distributeResources(board, players, 4)

                -- 각 타일에서 자원 획득
                if resource1 then
                    assert.is_true(players[1]:getResource(resource1) > initial1)
                end
                if resource2 and resource2 ~= resource1 then
                    assert.is_true(players[1]:getResource(resource2) > initial2)
                end
            end
        end)
    end)

    describe("checkVictory", function()
        local players

        before_each(function()
            players = {
                Player(1),
                Player(2),
                Player(3),
                Player(4)
            }
        end)

        it("should return nil if no player has 10+ points", function()
            -- 기본 상태: 모든 플레이어 0점
            local winner = Rules.checkVictory(players, 10)
            assert.is_nil(winner)
        end)

        it("should return player id when player reaches exactly 10 points", function()
            -- 플레이어 1에게 10점 부여 (정착지 10개 = 10점)
            players[1].buildings.settlements = 10

            local winner = Rules.checkVictory(players, 10)
            assert.are.equal(1, winner)
        end)

        it("should return player id when player exceeds 10 points", function()
            -- 플레이어 2에게 12점 부여 (도시 6개 = 12점)
            players[2].buildings.cities = 6

            local winner = Rules.checkVictory(players, 10)
            assert.are.equal(2, winner)
        end)

        it("should use custom victory target", function()
            -- 5점으로 승리 조건 변경
            players[3].buildings.settlements = 5  -- 5점

            local winner = Rules.checkVictory(players, 5)
            assert.are.equal(3, winner)
        end)

        it("should return first player to reach victory in order", function()
            -- 여러 플레이어가 동시에 10점 이상
            players[2].buildings.settlements = 10
            players[3].buildings.cities = 5  -- 10점

            -- 순서대로 체크하므로 플레이어 2가 먼저
            local winner = Rules.checkVictory(players, 10)
            assert.are.equal(2, winner)
        end)
    end)
end)
