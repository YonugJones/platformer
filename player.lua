local Player = {}

function Player.new(x, y, keys)
  return {
    x                    = x,
    y                    = y,
    w                    = 40,
    h                    = 40,
    speed                = 350,
    isFacingRight        = true,

    prevX                = x,
    prevY                = y,

    vy                   = 0,
    gravity              = 1800,
    jumpForce            = -800,
    jumpCut              = 0.4,
    isGrounded           = false,
    coyoteTime           = 0.1,
    coyoteTimer          = 0,

    spawnX               = x,
    spawnY               = y,
    fallLimitY           = 700,

    dashSpeed            = 600,
    dashDuration         = 0.2,
    isDashing            = false,
    dashTimer            = 0,
    dashDirection        = 1,
    canDash              = true,

    isWallSliding        = false,
    wallDirection        = 0,    -- -1 wall on left, 1 wall on right
    wallSlideSpeed       = 100,  -- max fall speed while sliding down wall

    wallJumpSpeedX       = 300,  -- horizontal push speed away from wall
    wallJumpForceY       = -700, -- vertical jump force for a wall jump
    wallJumpLockDuration = 0.15, -- how long normal a/d input is ignored after a wall jump
    wallJumpLockTimer    = 0,
    wallJumpDirection    = 0,    -- which way the wall jump is pushing (opposit of wallDirection)

    jumpBuffer           = .1,   -- seconds a jump press is remembered before landing
    jumpBufferTimer      = 0,
    isJumpHeld           = false,

    keys                 = {
      left  = keys and keys.left or 'a',
      right = keys and keys.right or 'd',
      jump  = keys and keys.jump or 'space',
      dash  = keys and keys.dash or 'j'
    }
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

local function isTouchingHazard(p, hazards)
  for _, hz in ipairs(hazards) do
    if checkOverlap(p.x, p.y, p.w, p.h, hz) then
      return true
    end
  end

  return false
end

local function resetToSpawn(p)
  p.x  = p.spawnX
  p.y  = p.spawnY
  p.vy = 0
end

local function tryJump(p)
  if p.coyoteTimer > 0 then
    p.vy = p.jumpForce

    if not p.isJumpHeld then
      p.vy = p.vy * p.jumpCut
    end

    p.coyoteTimer     = 0
    p.jumpBufferTimer = 0
  end
end

function Player.keypressed(p, key)
  if key == p.keys.jump then
    if p.isWallSliding then
      p.vy                = p.wallJumpForceY
      p.wallJumpDirection = -p.wallDirection
      p.wallJumpLockTimer = p.wallJumpLockDuration
      p.isFacingRight     = p.wallJumpDirection > 0
      p.isWallSliding     = false
      p.wallDirection     = 0
    else
      p.jumpBufferTimer = p.jumpBuffer
      p.isJumpHeld = true
      tryJump(p)
    end
  end

  if key == p.keys.dash and p.canDash and not p.isDashing then
    p.isDashing     = true
    p.dashTimer     = p.dashDuration
    p.dashDirection = p.isFacingRight and 1 or -1
    p.canDash       = false
  end
end

function Player.keyreleased(p, key)
  if key == p.keys.jump then
    p.isJumpHeld = false
    if p.vy < 0 then
      p.vy = p.vy * p.jumpCut
    end
  end
end

function Player.update(p, dt, platforms, hazards)
  p.prevX = p.x
  p.prevY = p.y
  local goalX = p.x

  -- horizontal --
  if p.isDashing then
    goalX = p.x + p.dashSpeed * p.dashDirection * dt
    p.dashTimer = p.dashTimer - dt
    if p.dashTimer <= 0 then
      p.isDashing = false
    end
  elseif p.wallJumpLockTimer > 0 then
    goalX               = p.x + p.wallJumpSpeedX * p.wallJumpDirection * dt
    p.wallJumpLockTimer = p.wallJumpLockTimer - dt
  else -- normal a/d movement --
    if love.keyboard.isDown(p.keys.left) then
      goalX           = p.x - p.speed * dt
      p.isFacingRight = false
    end

    if love.keyboard.isDown(p.keys.right) then
      goalX           = p.x + p.speed * dt
      p.isFacingRight = true
    end
  end

  -- wall slide: only while airborn, not dashing, and holding toward a wall you're touching --
  p.isWallSliding = false

  if not p.isGrounded and not p.isDashing and p.wallJumpLockTimer <= 0 then
    if love.keyboard.isDown(p.keys.left) and isTouchingWallSlide(p, -1, platforms) then
      p.isWallSliding = true
      p.wallDirection = -1
    elseif love.keyboard.isDown(p.keys.right) and isTouchingWallSlide(p, 1, platforms) then
      p.isWallSliding = true
      p.wallDirection = 1
    end
  end

  if not p.isWallSliding then
    p.wallDirection = 0
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

  -- jump buffer --
  if p.jumpBufferTimer > 0 then
    p.jumpBufferTimer = p.jumpBufferTimer - dt
  end

  if p.isGrounded and p.jumpBufferTimer > 0 then
    tryJump(p)
  end

  -- tile collisions --
  p.x, p.y = resolveCollisions(p, goalX, goalY, platforms)

  local moveAmount = p.x - p.prevX

  -- dash resets once grounded --
  if p.isGrounded or p.isWallSliding then
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
    resetToSpawn(p)
  end

  -- hazards check --
  if hazards and isTouchingHazard(p, hazards) then
    resetToSpawn(p)
  end

  return moveAmount
end

function Player.draw(p)
  love.graphics.setColor(1, 1, 1)
  love.graphics.rectangle('fill', p.x, p.y, p.w, p.h)
end

return Player
