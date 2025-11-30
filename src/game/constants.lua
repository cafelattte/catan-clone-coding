-- src/game/constants.lua
-- 카탄 게임 상수 정의

local Constants = {}

-- 자원 타입 (순서 유지)
Constants.RESOURCE_TYPES = {
  "wood",
  "brick",
  "sheep",
  "wheat",
  "ore"
}

-- 자원 타입 검증용 Set
Constants.RESOURCE_SET = {
  wood = true,
  brick = true,
  sheep = true,
  wheat = true,
  ore = true
}

-- 건물 비용
Constants.BUILD_COSTS = {
  road = {wood = 1, brick = 1},
  settlement = {wood = 1, brick = 1, sheep = 1, wheat = 1},
  city = {wheat = 2, ore = 3},
  devcard = {sheep = 1, wheat = 1, ore = 1}
}

-- 건물 점수
Constants.BUILDING_POINTS = {
  settlement = 1,
  city = 2
}

-- 지형 타입 (순회용)
Constants.TERRAIN_TYPES = {
  "forest",
  "hills",
  "pasture",
  "fields",
  "mountains",
  "desert"
}

-- 타일 분포 (GDD 명세)
Constants.TILE_DISTRIBUTION = {
  forest = 4,    -- 목재
  hills = 3,     -- 벽돌
  pasture = 4,   -- 양모
  fields = 4,    -- 밀
  mountains = 3, -- 광석
  desert = 1     -- 없음
}

-- 지형 → 자원 매핑
Constants.TERRAIN_RESOURCE = {
  forest = "wood",
  hills = "brick",
  pasture = "sheep",
  fields = "wheat",
  mountains = "ore",
  desert = nil
}

return Constants
