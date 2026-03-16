-- Forked from an implementation of Conway's Game of Life
-- https://github.com/Whitebrim/Game-of-life-love2d-playdate
import "CoreLibs/graphics"

local pd = playdate
local gfx = pd.graphics

local width = 400
local height = 240

-- Define splash screen
local splashImage = gfx.image.new("images/pd-MESS2-logo")
local splashShown = false
local rulesShown = false

local clearScreen = true
local autoPlay = false

local world = {}
local nextWorld = {}

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
    if not splashShown then
        clearScreen = false
        splashImage:draw(0, 0)
        if playdate.buttonJustPressed("a") or
            playdate.buttonJustPressed("b") then
            splashShown = true
        end
    else
        -- Main Game Loop
        if not rulesShown then
            gfx.clear()
            gfx.drawText("Put the rules here.", 150, 100)
            gfx.drawText("Push any button to continue...", 150, 150)
            if playdate.buttonJustPressed("a") or
                playdate.buttonJustPressed("b") then
                rulesShown = true
		        gfx.clear(gfx.kColorWhite)
            end
        end
    end

	local stepRequested = handleInput()

	if autoPlay or stepRequested then
		nextStep()
	end

	if clearScreen then
		gfx.clear(gfx.kColorWhite)
	end

    if splashShown and rulesShown then
    	gfx.setColor(gfx.kColorBlack)
	    drawWorld()
    end
end
