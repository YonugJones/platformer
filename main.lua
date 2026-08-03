_G.love      = require 'love'
local Player = require 'player'

function love.load()
  player             = Player.new(100, 100)

  platforms          = {
    { x = 0,   y = 400, w = 800, h = 100 },
    { x = 250, y = 280, w = 150, h = 20 }
  }

  -- camera --
  CAMERA_X           = 0
  CAMERA_Y           = 0
  CAMERA_SMOOTH      = 5
  CURRENT_LOOK_AHEAD = 0
  LOOK_AHEAD_MAX     = 150 -- clamp so it can't look further than this in either direction
  LOOK_AHEAD_GAIN    = 1.5 -- how many pixels of look-ahead shift per pixel of player horizontal movement
end

function love.update(dt)
  local moveAmount   = Player.update(player, dt, platforms)

  -- camera follow --
  local screenWidth  = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()

  -- only shift look-ahead while actually moving, scaled by distance moved this frame --
  if moveAmount ~= 0 then
    CURRENT_LOOK_AHEAD = CURRENT_LOOK_AHEAD + moveAmount * LOOK_AHEAD_GAIN
    CURRENT_LOOK_AHEAD = math.max(-LOOK_AHEAD_MAX, math.min(LOOK_AHEAD_MAX, CURRENT_LOOK_AHEAD))
  end
  -- if moveAmount is 0 (no keys held), CURRENT_LOOK_AHEAD is left untouched - frozen --

  local targetX = (player.x + (player.w / 2) + CURRENT_LOOK_AHEAD) - screenWidth / 2
  local targetY = (player.y + (player.h / 2)) - screenHeight * 0.75

  CAMERA_X = CAMERA_X + (targetX - CAMERA_X) * CAMERA_SMOOTH * dt
  CAMERA_Y = CAMERA_Y + (targetY - CAMERA_Y) * CAMERA_SMOOTH * dt
end

function love.keypressed(key)
  Player.keypressed(player, key)
end

function love.keyreleased(key)
  Player.keyreleased(player, key)
end

function love.draw()
  love.graphics.push()
  love.graphics.translate(-CAMERA_X, -CAMERA_Y)

  love.graphics.setColor(0.3, 0.7, 0.3)
  for _, plat in ipairs(platforms) do
    love.graphics.rectangle('fill', plat.x, plat.y, plat.w, plat.h)
  end

  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle('fill', player.x, player.y, player.w, player.h)

  love.graphics.pop()
end
