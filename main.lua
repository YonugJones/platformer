_G.love      = require 'love'
local Player = require 'player'
local Camera = require 'camera'

local player
local camera
local platforms
local hazards

function love.load()
  player    = Player.new(100, 100)
  camera    = Camera.new()
  platforms = {
    { x = 0,   y = 400,  w = 800, h = 100 }, -- base level platform
    { x = 250, y = 200,  w = 150, h = 160 },
    { x = 500, y = 0,    w = 150, h = 200 },
    { x = 500, y = -350, w = 150, h = 200 }
  }
  hazards   = {
    { x = 800, y = 400, w = 200, h = 100 }
  }
end

function love.update(dt)
  local moveAmount = Player.update(player, dt, platforms, hazards)
  Camera.update(camera, dt, player, moveAmount)
end

function love.keypressed(key)
  Player.keypressed(player, key)
end

function love.keyreleased(key)
  Player.keyreleased(player, key)
end

function love.draw()
  Camera.attach(camera)

  -- draw platforms --
  love.graphics.setColor(0.3, 0.7, 0.3)
  for _, plat in ipairs(platforms) do
    love.graphics.rectangle('fill', plat.x, plat.y, plat.w, plat.h)
  end

  -- draw hazards --
  love.graphics.setColor(0.9, 0.2, 0.2)
  for _, hz in ipairs(hazards) do
    love.graphics.rectangle('fill', hz.x, hz.y, hz.w, hz.h)
  end

  Player.draw(player)
  Camera.detach()
end
