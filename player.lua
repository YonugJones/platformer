local Player = {}

function Player.new(x, y)
  return {
    x              = x,
    y              = y,
    w              = 40,
    h              = 40,
    speed          = 200,
    isFacingRight  = true,

    prevX          = x,
    prevY          = y,

    vy             = 0,
    gravity        = 1800,
    jumpForce      = -800,
    jumpCut        = 0.4,
    isGrounded     = false,
    coyoteTime     = 0.1,
    coyoteTimer    = 0,

    spawnX         = x,
    spawnY         = y,
    fallLimitY     = 700,

    dashSpeed      = 600,
    dashDuration   = 0.2,
    isDashing      = false,
    dashTimer      = 0,
    dashDirection  = 1,
    canDash        = true,

    isWallSliding  = false,
    wallDirection  = 0,  -- -1 wall on left, 1 wall on right
    wallSlideSpeed = 100 -- max fall speed while sliding down wall
  }
end

-- overlap test: does a box at x, y, w, h overlap platform? --
local function checkOverlap(x, y, w, h, plat)
  return x < plat.x + plat.w
      and x + w > plat.x
      and y < plat.y + plat.h
      and y + h > plat.y
end

local function isTouchingWallSlide(p, dir, platforms)
  local probeX = p.x + dir * 1 -- checks 1 pixel to the side of where the player currently is (the wall!)

  for _, plat in ipairs(platforms) do
    if checkOverlap(probeX, p.y, p.w, p.h, plat) then
      return true
    end
  end

  return false
end

local function resolveCollisions(p, goalX, goalY, platforms)
  p.isGrounded = false

  for _, platform in ipairs(platforms) do
    if checkOverlap(goalX, goalY, p.w, p.h, platform) then
      local wasAbove = p.prevY + p.h <= platform.y
      local wasBelow = p.prevY >= platform.y + platform.h
      local wasLeft  = p.prevX + p.w <= platform.x
      local wasRight = p.prevX >= platform.x + platform.w

      if wasAbove and p.vy >= 0 then
        goalY        = platform.y - p.h
        p.vy         = 0
        p.isGrounded = true
      elseif wasBelow and p.vy < 0 then
        goalY = platform.y + platform.h
        p.vy  = 0
      elseif wasLeft then
        goalX = platform.x - p.w
      elseif wasRight then
        goalX = platform.x + platform.w
      end
    end
  end

  return goalX, goalY
end

function Player.keypressed(p, key)
  if key == 'space' and p.coyoteTimer > 0 then
    p.vy          = p.jumpForce
    p.coyoteTimer = 0
  end

  if key == 'j' and p.canDash and not p.isDashing then
    p.isDashing     = true
    p.dashTimer     = p.dashDuration
    p.dashDirection = p.isFacingRight and 1 or -1
    p.canDash       = false
  end
end

function Player.keyreleased(p, key)
  if key == 'space' and p.vy < 0 then
    p.vy = p.vy * p.jumpCut
  end
end

function Player.update(p, dt, platforms)
  p.prevX = p.x
  p.prevY = p.y

  local goalX = p.x

  -- horizontal --
  if not p.isDashing then
    if love.keyboard.isDown('a') then
      goalX           = p.x - p.speed * dt
      p.isFacingRight = false
    end

    if love.keyboard.isDown('d') then
      goalX           = p.x + p.speed * dt
      p.isFacingRight = true
    end
  elseif p.isDashing then
    goalX       = p.x + p.dashSpeed * p.dashDirection * dt
    p.dashTimer = p.dashTimer - dt
    if p.dashTimer <= 0 then
      p.isDashing = false
    end
  end

  -- wall slide: only while airborn, not dashing, and holding toward a wall you're touching --
  p.isWallSliding = false

  if not p.isGrounded and not p.isDashing then
    if love.keyboard.isDown('a') and isTouchingWallSlide(p, -1, platforms) then
      p.isWallSliding = true
      p.wallDirection = -1
    elseif love.keyboard.isDown('d') and isTouchingWallSlide(p, 1, platforms) then
      p.isWallSliding = true
      p.wallDirection = 1
    end
  end

  -- gravity --
  if p.isDashing then
    p.vy = 0
  else
    p.vy = p.vy + p.gravity * dt
    -- cap fall speed while wall sliding --
    if p.isWallSliding and p.vy > p.wallSlideSpeed then
      p.vy = p.wallSlideSpeed
    end
  end
  local goalY = p.y + p.vy * dt

  -- tile collisions --
  p.x, p.y = resolveCollisions(p, goalX, goalY, platforms)

  local moveAmount = p.x - p.prevX

  -- dash resets once grounded --
  if p.isGrounded then
    p.canDash = true
  end

  -- coyote timer: reserts to full when grounded, ticks down when airborn --
  if p.isGrounded then
    p.coyoteTimer = p.coyoteTime
  else
    p.coyoteTimer = p.coyoteTimer - dt
  end

  -- fall off stage check --
  if p.y >= p.fallLimitY then
    p.x  = p.spawnX
    p.y  = p.spawnY
    p.vy = 0
  end

  return moveAmount
end

function Player.draw(p)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle('fill', p.x, p.y, p.w, p.h)
end

return Player
