UI = UI or {}

local UI = UI

local MENU_IMAGE_W = 400
local MENU_IMAGE_H = 240
local MENU_CONTENT_W = 200
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
end

function UI.buildMenuImage(community)
    local gfx = playdate.graphics
    local image = gfx.image.new(MENU_IMAGE_W, MENU_IMAGE_H, gfx.kColorWhite)
    local abundances = community:getRankAbundanceData()

    gfx.pushContext(image)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 0, MENU_IMAGE_W, MENU_IMAGE_H)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(0, 0, MENU_CONTENT_W, MENU_IMAGE_H, 6)
    gfx.drawText("MESS", 12, 10)
    gfx.drawText("Rank-Abundance", 12, 28)
    gfx.drawText("Eco " .. community:getEcologicalStrengthLabel(), 12, 46)

    local graphX = 12
    local graphY = 72
    local graphW = 176
    local graphH = 144

    gfx.drawRect(graphX, graphY, graphW, graphH)

    if #abundances == 0 then
        gfx.drawText("No species", 66, 136)
        gfx.popContext()
        return image
    end

    local maxBars = min(#abundances, 24)
    local maxAbundance = abundances[1]
    local slotWidth = graphW / maxBars

    for index = 1, maxBars do
        local abundance = abundances[index]
        local barHeight = 0

        if maxAbundance > 0 then
            barHeight = math.floor((abundance / maxAbundance) * (graphH - 6))
        end

        local barWidth = max(1, math.floor(slotWidth) - 1)
        local x = graphX + math.floor((index - 1) * slotWidth) + 1
        local y = graphY + graphH - 3 - barHeight

        gfx.fillRect(x, y, barWidth, barHeight)
    end

    gfx.drawText("Rank", graphX + graphW - 26, graphY + graphH + 4)
    gfx.drawText("Max " .. tostring(maxAbundance), graphX + 4, graphY + 4)

    if #abundances > maxBars then
        gfx.drawText("top " .. maxBars, graphX + 108, graphY + 4)
    end

    gfx.popContext()

    return image
end

return UI
