function love.load()
  PLAYER_X           = 100
  PLAYER_Y           = 100
  PLAYER_W           = 40
  PLAYER_H           = 40
  PLAYER_SPEED       = 200
  IS_FACING_RIGHT    = true

  PLAYER_VY          = 0
  GRAVITY            = 1500
  JUMP_FORCE         = -600
  IS_GROUNDED        = false

  COYOTE_TIME        = 0.1
  COYOTE_TIMER       = 0

  JUMP_CUT           = 0.4

  SPAWN_X            = PLAYER_X
  SPAWN_Y            = PLAYER_Y
  FALL_LIMIT_Y       = 700

  PLATFORMS          = {
    { x = 0,   y = 400, width = 800, height = 100 },
    { x = 250, y = 280, width = 150, height = 20 }
  }

  -- camera --
  CAMERA_X           = 0
  CAMERA_Y           = 0
  CAMERA_SMOOTH      = 5
  CURRENT_LOOK_AHEAD = 0
  LOOK_AHEAD_MAX     = 100 -- clamp so it can't look further than this in either direction
  LOOK_AHEAD_GAIN    = 1.5 -- how many pixels of look-ahead shift per pixel of player horizontal movement

  -- dash --
  DASH_SPEED         = 600
  DASH_DURATION      = 0.2
  IS_DASHING         = false
  DASH_TIMER         = 0
  DASH_DIRECTION     = 1
  CAN_DASH           = true
end

function love.update(dt)
  -- horizontal movement --
  local moveAmount = 0

  if not IS_DASHING then
    if love.keyboard.isDown('a') then
      PLAYER_X        = PLAYER_X - PLAYER_SPEED * dt
      IS_FACING_RIGHT = false
      moveAmount      = -PLAYER_SPEED * dt
    end

    if love.keyboard.isDown('d') then
      PLAYER_X        = PLAYER_X + PLAYER_SPEED * dt
      IS_FACING_RIGHT = true
      moveAmount      = PLAYER_SPEED * dt
    end
  end

  -- dash movement --
  if IS_DASHING then
    PLAYER_X   = PLAYER_X + DASH_SPEED * DASH_DIRECTION * dt
    moveAmount = DASH_SPEED * DASH_DIRECTION * dt

    DASH_TIMER = DASH_TIMER - dt
    if DASH_TIMER <= 0 then
      IS_DASHING = false
    end
  end

  -- gravity --
  if IS_DASHING then
    PLAYER_VY = 0
  else
    PLAYER_VY = PLAYER_VY + GRAVITY * dt
  end
  PLAYER_Y    = PLAYER_Y + PLAYER_VY * dt

  -- collision check --
  IS_GROUNDED = false
  for _, p in ipairs(PLATFORMS) do
    local isOverlappingX = PLAYER_X + PLAYER_W > p.x and PLAYER_X < p.x + p.width
    local isOverlappingY = PLAYER_Y + PLAYER_H > p.y and PLAYER_Y < p.y + p.height
    if isOverlappingX and isOverlappingY and PLAYER_VY >= 0 then
      PLAYER_Y    = p.y - PLAYER_H
      PLAYER_VY   = 0
      IS_GROUNDED = true
    end
  end

  -- dash resets once grounded --
  if IS_GROUNDED then
    CAN_DASH = true
  end

  -- coyote timer: resets to full when grounded, ticks down when airborn --
  if IS_GROUNDED then
    COYOTE_TIMER = COYOTE_TIME
  else
    COYOTE_TIMER = COYOTE_TIMER - dt
  end

  -- fall off stage check --
  if PLAYER_Y >= FALL_LIMIT_Y then
    PLAYER_X  = SPAWN_X
    PLAYER_Y  = SPAWN_Y
    PLAYER_VY = 0
  end

  -- camera follow --
  local screenWidth  = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()

  -- only shift look-ahead while actually moving, scaled by distance moved this frame --
  if moveAmount ~= 0 then
    CURRENT_LOOK_AHEAD = CURRENT_LOOK_AHEAD + moveAmount * LOOK_AHEAD_GAIN
    CURRENT_LOOK_AHEAD = math.max(-LOOK_AHEAD_MAX, math.min(LOOK_AHEAD_MAX, CURRENT_LOOK_AHEAD))
  end
  -- if moveAmount is 0 (no keys held), CURRENT_LOOK_AHEAD is left untouched - frozen --

  local targetX = (PLAYER_X + (PLAYER_W / 2) + CURRENT_LOOK_AHEAD) - screenWidth / 2
  local targetY = (PLAYER_Y + (PLAYER_H / 2)) - screenHeight * 0.75

  CAMERA_X = CAMERA_X + (targetX - CAMERA_X) * CAMERA_SMOOTH * dt
  CAMERA_Y = CAMERA_Y + (targetY - CAMERA_Y) * CAMERA_SMOOTH * dt
end

function love.keypressed(key)
  if key == 'space' and COYOTE_TIMER > 0 then
    PLAYER_VY    = JUMP_FORCE
    COYOTE_TIMER = 0
  end

  if key == 'j' and CAN_DASH and not IS_DASHING then
    IS_DASHING     = true
    DASH_TIMER     = DASH_DURATION
    DASH_DIRECTION = IS_FACING_RIGHT and 1 or -1
    CAN_DASH       = false
  end
end

function love.keyreleased(key)
  if key == 'space' and PLAYER_VY < 0 then
    PLAYER_VY = PLAYER_VY * JUMP_CUT
  end
end

function love.draw()
  love.graphics.push()
  love.graphics.translate(-CAMERA_X, -CAMERA_Y)

  love.graphics.setColor(0.3, 0.7, 0.3)
  for _, p in ipairs(PLATFORMS) do
    love.graphics.rectangle('fill', p.x, p.y, p.width, p.height)
  end

  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle('fill', PLAYER_X, PLAYER_Y, PLAYER_W, PLAYER_H)

  love.graphics.pop()
end
