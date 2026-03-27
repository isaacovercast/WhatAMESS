UI = UI or {}

local UI = UI

local function drawPanel(x, y, width, height)
    local gfx = playdate.graphics
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(x, y, width, height, 6)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(x, y, width, height, 6)
end

function UI.drawHUD(community, autoPlay)
    local gfx = playdate.graphics

    drawPanel(4, 4, 170, 66)
    gfx.drawText("What A MESS", 12, 10)
    gfx.drawText("Step " .. community.time .. "  " .. community:getModeLabel(), 12, 24)
    gfx.drawText("Species " .. community.lastRichness .. "  Dom " .. community.lastDominantAbundance, 12, 38)
    gfx.drawText(string.format("Mig %.2f  In %d", community.colrate, community.lastMigrantCount), 12, 52)

    drawPanel(225, 4, 171, 66)
    gfx.drawText("A Step  B Auto", 233, 10)
    gfx.drawText("Up/Down Mode", 233, 24)
    gfx.drawText("Left/Right Migration", 233, 38)
    gfx.drawText(autoPlay and "Autoplay On" or "Autoplay Off", 233, 52)
end

return UI
