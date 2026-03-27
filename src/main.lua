-- Forked from an implementation of Conway's Game of Life
-- https://github.com/Whitebrim/Game-of-life-love2d-playdate
import "CoreLibs/graphics"

local pd = playdate
local gfx = pd.graphics

local width = 400
local height = 240

local TILE_SIZE = 16
local GRID_W = 25
local GRID_H = 15
local EMPTY = 1

-- Load and set as the default for all future draw calls
local myFont = gfx.font.new('images/fonts/font-Cuberick-Bold')
gfx.setFont(myFont)


-- Load the species tiles and init the tilemap
local critters = gfx.imagetable.new("images/sprites/species")
local map = gfx.tilemap.new()
map:setImageTable(critters)
map:setSize(GRID_W, GRID_H)
for y = 1, GRID_H do
    for x = 1, GRID_W do
        map:setTileAtPosition(x, y, EMPTY)
    end
end


-- Define splash screen
local splashImage = gfx.image.new("images/pd-MESS2-logo")
local splashShown = false
local rulesShown = false

local clearScreen = true
local autoPlay = false

local world = {}
local nextWorld = {}


local function splash()
    if not splashShown then
        clearScreen = false
        splashImage:draw(0, 0)
        if playdate.buttonJustPressed("a") or
            playdate.buttonJustPressed("b") then
            splashShown = true
        end

    else
        if not rulesShown then
            gfx.clear()
            gfx.drawText("Put the rules here.", 150, 100)
            gfx.drawText("Push any button to continue...", 150, 150)
            if playdate.buttonJustPressed("a") or
                playdate.buttonJustPressed("b") then
                rulesShown = true
                gfx.clear(gfx.kColorWhite)
                clearScreen = true
            end
--          local v1 = gfx.image.new("images/sprites/v000")
--          local v2 = gfx.image.new("images/sprites/v000-8")
--          v1:draw(10, 10)
--          v2:draw(100, 10)
--          local critters = gfx.imagetable.new("images/sprites/flaticon/virus")
      
--          critters:drawImage(1, 100, 100)
--          critters:drawImage(2, 100, 120)
--          critters:drawImage(3, 100, 140)
            nspecies = critters:getSize()
            for y = 1, GRID_H do
                for x = 1, GRID_W do
                    map:setTileAtPosition(x, y, math.random(nspecies))
                end
            end
            map:draw(0,0)
        end
    end
end

local function cellIndex(x, y)
	return 1 + x + y * width
end

local function checkCellNeighbours(x, y)
	local left = (x - 1) % width
	local right = (x + 1) % width
	local up = (y - 1) % height
	local down = (y + 1) % height

	local aliveAmount = world[cellIndex(left, up)] +
		world[cellIndex(x, up)] +
		world[cellIndex(right, up)] +
		world[cellIndex(left, y)] +
		world[cellIndex(right, y)] +
		world[cellIndex(left, down)] +
		world[cellIndex(x, down)] +
		world[cellIndex(right, down)]

	if aliveAmount == 2 then
		return world[cellIndex(x, y)]
	end

	if aliveAmount == 3 then
		return 1
	end

	return 0
end

local function nextStep()
	for y = 0, height - 1 do
		for x = 0, width - 1 do
			nextWorld[cellIndex(x, y)] = checkCellNeighbours(x, y)
		end
	end

	world, nextWorld = nextWorld, world
end

local function drawWorld()
	for y = 0, height - 1 do
		for x = 0, width - 1 do
			if world[cellIndex(x, y)] == 1 then
				gfx.drawPixel(x, y)
			end
		end
	end
end

local function newWorld()
	for y = 0, height - 1 do
		for x = 0, width - 1 do
			local index = cellIndex(x, y)
			world[index] = math.random(2) - 1
			nextWorld[index] = 0
		end
	end
end


local cursorEnabled = true
local cursorX = 1
local cursorY = 1

local function clampCursor()
    if cursorX < 1 then cursorX = 1 end
    if cursorX > GRID_W then cursorX = GRID_W end
    if cursorY < 1 then cursorY = 1 end
    if cursorY > GRID_H then cursorY = GRID_H end
end

local function moveCursor(dx, dy)
    cursorX += dx
    cursorY += dy
    clampCursor()
end

local function drawCursor()
    if not cursorEnabled then
        return
    end

    local px = (cursorX - 1) * TILE_SIZE
    local py = (cursorY - 1) * TILE_SIZE

    -- outline around the selected tile
    gfx.drawRect(px, py, TILE_SIZE, TILE_SIZE)

    -- optional inner border for visibility
    gfx.drawRect(px + 1, py + 1, TILE_SIZE - 2, TILE_SIZE - 2)
end

local function initializeGame()
    local secondsSinceEpoch = pd.getSecondsSinceEpoch()
	math.randomseed(secondsSinceEpoch)
	newWorld()
end

local function handleInput()
	if pd.buttonJustPressed(pd.kButtonUp) then
		newWorld()
	end

	if pd.buttonJustPressed(pd.kButtonDown) then
		clearScreen = not clearScreen
	end

	if pd.buttonJustPressed(pd.kButtonB) then
		autoPlay = not autoPlay
	end

	return pd.buttonJustPressed(pd.kButtonA)
end

initializeGame()

function pd.update()

    if not rulesShown then
        splash()
    end

	local stepRequested = handleInput()

	if autoPlay or stepRequested then
		nextStep()
	end

	if clearScreen then
		gfx.clear(gfx.kColorWhite)
	end

    if rulesShown then
    	gfx.setColor(gfx.kColorBlack)
	    drawWorld()
    end

    map:draw(0, 0)
    drawCursor()
    
end
