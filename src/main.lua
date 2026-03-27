import "CoreLibs/graphics"
import "species"
import "community"
import "ui"

local pd = playdate
local gfx = pd.graphics

local GRID_W = 25
local GRID_H = 15
local AUTO_STEP_FRAMES = 10

local font = gfx.font.new("images/fonts/font-Cuberick-Bold")
gfx.setFont(font)
local splashImage = gfx.image.new("images/pd-MESS2-logo")

local critters = gfx.imagetable.new("images/sprites/species")
local map = gfx.tilemap.new()
map:setImageTable(critters)
map:setSize(GRID_W, GRID_H)

local function initializeGame()
    local secondsSinceEpoch = pd.getSecondsSinceEpoch()
    math.randomseed(secondsSinceEpoch)
end

local game = {
    autoPlay = false,
    autoFrameCounter = 0,
    splashShown = false,
}

local function rebuildCommunity()
    game.community = Community.new(map, critters, {
        width = GRID_W,
        height = GRID_H,
        mode = "filtering",
        colrate = 0.05,
        ecologicalStrength = 0.35,
        environmentOptimum = 0,
    })
end

local function handleInput()
    if pd.buttonJustPressed(pd.kButtonA) then
        game.community:step()
        game.autoFrameCounter = 0
    end

    if pd.buttonJustPressed(pd.kButtonB) then
        game.autoPlay = not game.autoPlay
        game.autoFrameCounter = 0
    end

    if pd.buttonJustPressed(pd.kButtonUp) then
        game.community:cycleMode(1)
    end

    if pd.buttonJustPressed(pd.kButtonDown) then
        game.community:cycleMode(-1)
    end

    if pd.buttonJustPressed(pd.kButtonRight) then
        game.community:adjustColonizationRate(0.01)
    end

    if pd.buttonJustPressed(pd.kButtonLeft) then
        game.community:adjustColonizationRate(-0.01)
    end
end

initializeGame()
rebuildCommunity()

pd.getSystemMenu():addMenuItem("reset", function()
    rebuildCommunity()
    game.splashShown = false
end)

function pd.update()
    if not game.splashShown then
        gfx.clear(gfx.kColorWhite)
        splashImage:draw(0, 0)

        if pd.buttonJustPressed(pd.kButtonA) or pd.buttonJustPressed(pd.kButtonB) then
            game.splashShown = true
        end

        return
    end

    handleInput()

    if game.autoPlay then
        game.autoFrameCounter += 1

        if game.autoFrameCounter >= AUTO_STEP_FRAMES then
            game.community:step()
            game.autoFrameCounter = 0
        end
    end

    gfx.clear(gfx.kColorWhite)
    map:draw(0, 0)
    UI.drawHUD(game.community, game.autoPlay)
end
