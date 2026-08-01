function love.load()
  PLAYER_X     = 100
  PLAYER_Y     = 100
  PLAYER_SPEED = 200

  PLAYER_VY    = 0
  GRAVITY      = 1500
  JUMP_FORCE   = -600
  IS_GROUNDED  = false

  GROUND_X     = 0
  GROUND_Y     = 400
  GROUND_W     = 800
  GROUND_H     = 100
end

function love.update(dt)
  if love.keyboard.isDown('a') then
    PLAYER_X = PLAYER_X - PLAYER_SPEED * dt
  end

  if love.keyboard.isDown('d') then
    PLAYER_X = PLAYER_X + PLAYER_SPEED * dt
  end

  -- gravity --
  PLAYER_VY = PLAYER_VY + GRAVITY * dt
  PLAYER_Y  = PLAYER_Y + PLAYER_VY * dt

  -- ground check --
  if PLAYER_Y + 40 >= GROUND_Y then
    PLAYER_Y    = GROUND_Y - 40
    PLAYER_VY   = 0
    IS_GROUNDED = true
  else
    IS_GROUNDED = false
  end
end

function love.keypressed(key)
  if key == 'space' then
    PLAYER_VY = JUMP_FORCE
  end
end

function love.draw()
  love.graphics.setColor(0.3, 0.7, 0.3)
  love.graphics.rectangle('fill', GROUND_X, GROUND_Y, GROUND_W, GROUND_H)


  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle('fill', PLAYER_X, PLAYER_Y, 40, 40)
end
