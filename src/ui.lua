UI = UI or {}

local UI = UI

local MENU_IMAGE_W = 200
local MENU_IMAGE_H = 120
local min = math.min
local max = math.max

local function drawPanel(x, y, width, height)
    local gfx = playdate.graphics
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(x, y, width, height, 6)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(x, y, width, height, 6)
end

function UI.drawSplash(image)
    local gfx = playdate.graphics
    gfx.clear(gfx.kColorWhite)
    image:draw(0, 0)
end

function UI.drawControlsScreen()
    local gfx = playdate.graphics
    gfx.clear(gfx.kColorWhite)

    drawPanel(18, 14, 364, 212)
    gfx.drawTextAligned("Controls", 200, 28, kTextAlignment.center)
    gfx.drawText("A  Advance one step", 48, 62)
    gfx.drawText("B  Toggle autoplay", 48, 86)
    gfx.drawText("Up/Down  Change mode", 48, 110)
    gfx.drawText("Left/Right  Change migration", 48, 134)
    gfx.drawText("Menu  Open MESS", 48, 158)
    gfx.drawTextAligned("Press A or B to begin", 200, 194, kTextAlignment.center)
end

function UI.drawHUD(community, autoPlay)
    local gfx = playdate.graphics

    drawPanel(4, 4, 190, 66)
    gfx.drawText("What A MESS", 12, 10)
    gfx.drawText("Step " .. community.time .. "  " .. community:getModeLabel(), 12, 24)
    gfx.drawText("Species " .. community.lastRichness .. "  Dom " .. community.lastDominantAbundance, 12, 38)
    gfx.drawText(string.format("Mig %.2f  Eco %s", community.colrate, community:getEcologicalStrengthLabel()), 12, 52)

    drawPanel(250, 4, 146, 52)
    gfx.drawText(autoPlay and "Autoplay On" or "Autoplay Off", 258, 16)
    gfx.drawText("Menu > MESS", 258, 34)
end

function UI.buildMenuImage(community)
    local gfx = playdate.graphics
    local image = gfx.image.new(MENU_IMAGE_W, MENU_IMAGE_H, gfx.kColorWhite)
    local abundances = community:getRankAbundanceData()

    gfx.pushContext(image)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, MENU_IMAGE_W, MENU_IMAGE_H)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(0, 0, MENU_IMAGE_W, MENU_IMAGE_H, 6)
    gfx.drawText("MESS", 10, 8)
    gfx.drawText("Rank-Abundance", 10, 22)
    gfx.drawText("Eco " .. community:getEcologicalStrengthLabel(), 116, 8)

    local graphX = 10
    local graphY = 42
    local graphW = 180
    local graphH = 64

    gfx.drawRect(graphX, graphY, graphW, graphH)

    if #abundances == 0 then
        gfx.drawText("No species", 62, 66)
        gfx.popContext()
        return image
    end

    local maxBars = min(#abundances, 20)
    local maxAbundance = abundances[1]
    local slotWidth = graphW / maxBars

    for index = 1, maxBars do
        local abundance = abundances[index]
        local barHeight = 0

        if maxAbundance > 0 then
            barHeight = math.floor((abundance / maxAbundance) * (graphH - 4))
        end

        local barWidth = max(1, math.floor(slotWidth) - 1)
        local x = graphX + math.floor((index - 1) * slotWidth) + 1
        local y = graphY + graphH - 2 - barHeight

        gfx.fillRect(x, y, barWidth, barHeight)
    end

    gfx.drawText("r", graphX + graphW - 10, graphY + graphH + 2)
    gfx.drawText(tostring(maxAbundance), graphX + 4, graphY + 2)

    if #abundances > maxBars then
        gfx.drawText("top " .. maxBars, graphX + 118, graphY + 2)
    end

    gfx.popContext()

    return image
end

return UI
