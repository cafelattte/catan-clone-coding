-- main.lua
-- Love2D 엔트리포인트
-- Story 7-3: hump.gamestate 기반 씬 관리

local Gamestate = require("lib.hump.gamestate")
local menu = require("src.scenes.menu")

function love.load()
  -- hump.gamestate 이벤트 등록
  Gamestate.registerEvents()

  -- 메인 메뉴 씬으로 시작
  Gamestate.switch(menu)
end
