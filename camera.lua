local Camera = {}

function Camera.new()
  return {
    x                = 0,
    y                = 0,
    smooth           = 5,
    currentLookAhead = 0,
    lookAheadMax     = 150,
    lookAheadGain    = 1.5
  }
end

function Camera.update(cam, dt, target, moveAmount)
  local screenWidth  = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()

  if moveAmount ~= 0 then
    cam.currentLookAhead = cam.currentLookAhead + moveAmount * cam.lookAheadGain
    cam.currentLookAhead = math.max(-cam.lookAheadMax, math.min(cam.lookAheadMax, cam.currentLookAhead))
  end

  local targetX = (target.x + target.w / 2 + cam.currentLookAhead) - screenWidth / 2
  local targetY = (target.y + target.h / 2) - screenHeight * 0.75

  cam.x = cam.x + (targetX - cam.x) * cam.smooth * dt
  cam.y = cam.y + (targetY - cam.y) * cam.smooth * dt
end

function Camera.attach(cam)
  love.graphics.push()
  love.graphics.translate(-cam.x, -cam.y)
end

function Camera.detach()
  love.graphics.pop()
end

return Camera
