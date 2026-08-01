function love.load()
  PLAYER_X     = 100
  PLAYER_Y     = 100
  PLAYER_W     = 40
  PLAYER_H     = 40
  PLAYER_SPEED = 200

  PLAYER_VY    = 0
  GRAVITY      = 1500
  JUMP_FORCE   = -600
  IS_GROUNDED  = false

  COYOTE_TIME  = 0.1
  COYOTE_TIMER = 0

  JUMP_CUT     = 0.4

  SPAWN_X      = PLAYER_X
  SPAWN_Y      = PLAYER_Y
  FALL_LIMIT_Y = 700

  PLATFORMS    = {
    { x = 0,   y = 400, width = 800, height = 100 },
    { x = 250, y = 280, width = 150, height = 20 }
  }
end

function love.update(dt)
  if love.keyboard.isDown('a') then
    PLAYER_X = PLAYER_X - PLAYER_SPEED * dt
  end

  if love.keyboard.isDown('d') then
    PLAYER_X = PLAYER_X + PLAYER_SPEED * dt
  end

  -- gravity --
  PLAYER_VY   = PLAYER_VY + GRAVITY * dt
  PLAYER_Y    = PLAYER_Y + PLAYER_VY * dt

  -- collision check --
  IS_GROUNDED = false
  for _, p in ipairs(PLATFORMS) do
    local isOverlappingX = PLAYER_X + PLAYER_W > p.x and PLAYER_X < p.x + p.width
    local isOverlappingY = PLAYER_Y + PLAYER_H > p.y and PLAYER_Y < p.y + p.height
    if isOverlappingX and isOverlappingY and PLAYER_VY >= 0 then
      PLAYER_Y = p.y - PLAYER_H
      PLAYER_VY = 0
      IS_GROUNDED = true
    end
  end

  if PLAYER_Y >= FALL_LIMIT_Y then
    PLAYER_X = SPAWN_X
    PLAYER_Y = SPAWN_Y
    PLAYER_VY = 0
  end

  -- coyote timer: resets to full when grounded, ticks down when airborn --
  if IS_GROUNDED then
    COYOTE_TIMER = COYOTE_TIME
  else
    COYOTE_TIMER = COYOTE_TIMER - dt
  end
end

function love.keypressed(key)
  if key == 'space' and COYOTE_TIMER > 0 then
    PLAYER_VY = JUMP_FORCE
    COYOTE_TIMER = 0
  end
end

function love.keyreleased(key)
  if key == 'space' and PLAYER_VY < 0 then
    PLAYER_VY = PLAYER_VY * JUMP_CUT
  end
end

function love.draw()
  love.graphics.setColor(0.3, 0.7, 0.3)
  for _, p in ipairs(PLATFORMS) do
    love.graphics.rectangle('fill', p.x, p.y, p.width, p.height)
  end


  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle('fill', PLAYER_X, PLAYER_Y, PLAYER_W, PLAYER_H)
end
