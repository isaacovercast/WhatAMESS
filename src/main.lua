import "CoreLibs/graphics"
import "species"
import "community"
import "ui"

local pd = playdate
local gfx = pd.graphics

local GRID_W = 25
local GRID_H = 15
local AUTO_STEP_FRAMES = 10

local ECOLOGICAL_STRENGTH_OPTIONS = {
    {label = "Very Low", value = 0.15},
    {label = "Low", value = 0.22},
    {label = "Medium", value = 0.35},
    {label = "High", value = 0.55},
    {label = "Very High", value = 0.85},
}

local font = gfx.font.new("images/fonts/font-Cuberick-Bold")
gfx.setFont(font)

local splashImage = gfx.image.new("images/pd-MESS2-logo")
local critters = gfx.imagetable.new("images/sprites/species")
local map = gfx.tilemap.new()
map:setImageTable(critters)
map:setSize(GRID_W, GRID_H)

local game = {
    autoPlay = false,
    autoFrameCounter = 0,
    screen = "splash",
    ecologicalStrengthIndex = 3,
    menuImage = nil,
}

local function getEcologicalStrengthOption()
    return ECOLOGICAL_STRENGTH_OPTIONS[game.ecologicalStrengthIndex]
end

local function initializeGame()
    local secondsSinceEpoch = pd.getSecondsSinceEpoch()
    math.randomseed(secondsSinceEpoch)
end

local function rebuildCommunity()
    local ecologicalOption = getEcologicalStrengthOption()

    game.community = Community.new(map, critters, {
        width = GRID_W,
        height = GRID_H,
        mode = "filtering",
        colrate = 0.05,
        ecologicalStrength = ecologicalOption.value,
        ecologicalStrengthLabel = ecologicalOption.label,
        environmentOptimum = 0,
    })
end

local function refreshMenuImage()
    if game.community then
        game.menuImage = UI.buildMenuImage(game.community)
        pd.setMenuImage(game.menuImage, 0)
    end
end

local function setEcologicalStrengthByLabel(label)
    for index, option in ipairs(ECOLOGICAL_STRENGTH_OPTIONS) do
        if option.label == label then
            game.ecologicalStrengthIndex = index

            if game.community then
                game.community:setEcologicalStrength(option.value, option.label)
                refreshMenuImage()
            end

            return
        end
    end
end

local function resetGame()
    game.autoPlay = false
    game.autoFrameCounter = 0
    game.screen = "splash"
    rebuildCommunity()
    refreshMenuImage()
end

local function handleSimulationInput()
    if pd.buttonJustPressed(pd.kButtonA) then
        game.community:step()
        refreshMenuImage()
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

local function handleIntroAdvance(nextScreen)
    if pd.buttonJustPressed(pd.kButtonA) or pd.buttonJustPressed(pd.kButtonB) then
        game.screen = nextScreen
    end
end

local function configureMenu()
    local menu = pd.getSystemMenu()
    local labels = {}

    menu:removeAllMenuItems()

    for _, option in ipairs(ECOLOGICAL_STRENGTH_OPTIONS) do
        labels[#labels + 1] = option.label
    end

    menu:addOptionsMenuItem("MESS", labels, getEcologicalStrengthOption().label, function(value)
        setEcologicalStrengthByLabel(value)
    end)

    menu:addMenuItem("restart game", function()
        resetGame()
    end)
end

initializeGame()
rebuildCommunity()
refreshMenuImage()
configureMenu()

function pd.gameWillPause()
    if game.menuImage then
        pd.setMenuImage(game.menuImage, 0)
    end
end

function pd.update()
    if game.screen == "splash" then
        UI.drawSplash(splashImage)
        handleIntroAdvance("controls")
        return
    end

    if game.screen == "controls" then
        UI.drawControlsScreen()
        handleIntroAdvance("simulation")
        return
    end

    handleSimulationInput()

    if game.autoPlay then
        game.autoFrameCounter += 1

        if game.autoFrameCounter >= AUTO_STEP_FRAMES then
            game.community:step()
            refreshMenuImage()
            game.autoFrameCounter = 0
        end
    end

    gfx.clear(gfx.kColorWhite)
    map:draw(0, 0)
    UI.drawHUD(game.community, game.autoPlay)
end
