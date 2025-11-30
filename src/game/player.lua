-- src/game/player.lua
-- 플레이어 데이터 및 자원 관리

local Class = require("lib.classic")
local Constants = require("src.game.constants")

local Player = Class:extend()

function Player:new(id)
  self.id = id
  self.resources = {
    wood = 0,
    brick = 0,
    sheep = 0,
    wheat = 0,
    ore = 0
  }
  self.buildings = {
    settlements = 0,
    cities = 0,
    roads = 0
  }
end

-- 특정 자원 보유량 조회
function Player:getResource(resourceType)
  if not Constants.RESOURCE_SET[resourceType] then
    return nil
  end
  return self.resources[resourceType]
end

-- 전체 자원 테이블 복사본 반환
function Player:getAllResources()
  local copy = {}
  for k, v in pairs(self.resources) do
    copy[k] = v
  end
  return copy
end

-- 자원 추가
function Player:addResource(resourceType, amount)
  if not Constants.RESOURCE_SET[resourceType] then
    return false
  end
  if amount < 0 then
    return false
  end
  self.resources[resourceType] = self.resources[resourceType] + amount
  return true
end

-- 자원 차감
function Player:removeResource(resourceType, amount)
  if not Constants.RESOURCE_SET[resourceType] then
    return nil, "Invalid resource type: " .. tostring(resourceType)
  end
  if self.resources[resourceType] < amount then
    return nil, "Not enough " .. resourceType
  end
  self.resources[resourceType] = self.resources[resourceType] - amount
  return true
end

-- 비용 충족 여부 확인
function Player:hasResources(costs)
  for resourceType, amount in pairs(costs) do
    if not self.resources[resourceType] or self.resources[resourceType] < amount then
      return false
    end
  end
  return true
end

-- 건설 가능 여부 확인
function Player:canBuild(buildingType)
  local cost = Constants.BUILD_COSTS[buildingType]
  if not cost then
    return false
  end
  return self:hasResources(cost)
end

-- 승리 점수 계산
function Player:getVictoryPoints()
  local points = 0
  points = points + self.buildings.settlements * Constants.BUILDING_POINTS.settlement
  points = points + self.buildings.cities * Constants.BUILDING_POINTS.city
  return points
end

-- 디버그용 문자열 출력
function Player:toString()
  local parts = {
    "Player " .. self.id,
    "  Resources: wood=" .. self.resources.wood ..
      ", brick=" .. self.resources.brick ..
      ", sheep=" .. self.resources.sheep ..
      ", wheat=" .. self.resources.wheat ..
      ", ore=" .. self.resources.ore,
    "  Buildings: settlements=" .. self.buildings.settlements ..
      ", cities=" .. self.buildings.cities ..
      ", roads=" .. self.buildings.roads,
    "  VP: " .. self:getVictoryPoints()
  }
  return table.concat(parts, "\n")
end

return Player
