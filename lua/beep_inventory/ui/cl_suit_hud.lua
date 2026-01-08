BCORE.netstream.Hook("SuitSync", function(suit)
    local ply = LocalPlayer()

    if suit == "none" then ply.currentsuit = "none" return end
    print(suit)
    ply.currentsuit = suit
    print(("[DEBUG] Received suit sync for player %s"):format(ply:Nick()))

    -- Initialize smoothed bars at max
    smoothHP = suit.customData.hp or 100
    smoothAP = suit.customData.ap or 0
end)

-- Safe Lerp function
local _Lerp = Lerp
local function SafeLerp(frac, from, to)
    if type(frac) ~= "number" then frac = 0 end
    if type(from) ~= "number" then from = 0 end
    if type(to) ~= "number" then to = from end
    return _Lerp(frac, from, to)
end

-- Smoothed values for animation
local smoothHP, smoothAP = nil, nil

local function GetRarityColor(rarity)
    local clr = BCORE.Inventory.config.Rarities[rarity].color
    if clr == "Rainbow" then
        return HSVToColor(CurTime() * 10 % 360, 1, 1)
    else
        return clr
    end
end

-- HUD
local function StartHud()
    local ply = LocalPlayer()
    if ply.currentsuit == "none" then return end  -- don't draw if no suit
    local suit = ply.currentsuit
    local color = Color(26,72,145)

    local width, height = BUi:Scale(1000), BUi:Scale(70)
    local baseX, baseY = width / 2, 20

    local rotation = (CurTime() * 40) % 360

    -- Main HUD background
    draw.RoundedBox(8, baseX, baseY, width, height, Color(46, 46, 46))

    
    BUi.masks.Start()
    surface.SetDrawColor(color)
    surface.SetMaterial(BUi.Grad["Down"])
    surface.DrawTexturedRectRotated(baseX + width/2, baseY + height/2, width, height*2, rotation)
    BUi.masks.Source()
    draw.RoundedBox(12, baseX, baseY, width, height, color_white)
    BUi.masks.End()

    draw.RoundedBox(8, baseX + 1, baseY + 1, width - 2, height - 2, Color(30, 30, 30))
    BUi.DrawImgur(baseX + 1, baseY + 1, width - 2, height - 2, "https://invisibalfan-ui.github.io/bui_images/images/gsaawd.png", color_white, 8)

    BUi.masks.Start()
    surface.SetDrawColor(color)
    surface.SetMaterial(BUi.Grad["Down"])
    surface.DrawTexturedRect(baseX + 1, baseY + 1, width - 2, height - 2)
    BUi.masks.Source()
    draw.RoundedBox(8, baseX + 1, baseY + 1, width - 2, height - 2, color_white)
    BUi.masks.End()

    

    draw.RoundedBox(6, baseX + 5, baseY + 35, width - 10, height - 40, Color(59, 59, 59))
    draw.RoundedBox(6, baseX + 6, baseY + 36, width - 12, height - 42, Color(35, 35, 35))

    local maxHp = suit.customData.maxhp or 1
    local maxAp = suit.customData.maxap or 1
    local hp = suit.customData.Health 
    local ap = suit.customData.Armor
    hp = ply:GetNW2Int("SuitHP", maxHp)
    ap = ply:GetNW2Int("SuitAP", maxAp)

    local textw, texth = surface.GetTextSize(suit.name)

    draw.SimpleText(suit.name, "BCORE.Inventoryb.25", baseX + width/2 , baseY + 5, Color(255, 255, 255, 255),TEXT_ALIGN_CENTER)
    draw.SimpleText("Armor: " .. ap .. "/" .. maxAp, "BCORE.Inventoryb.25", baseX + width - 20, baseY + 5, Color(255, 255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    draw.SimpleText("Health: " .. hp .. "/" .. maxHp, "BCORE.Inventoryb.25", baseX +20, baseY + 5, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    if smoothHP == nil then smoothHP = maxHp end
    if smoothAP == nil then smoothAP = maxAp end

    smoothHP = SafeLerp(0.1, smoothHP, hp)
    smoothAP = SafeLerp(0.1, smoothAP, ap)

    local hpFrac = math.Clamp(smoothHP / maxHp, 0, 1)
    local apFrac = math.Clamp(smoothAP / maxAp, 0, 1)

    local barX, barY = baseX + 6, baseY + 36
    local barW, barH = width - 12, height - 42

    local healthWidth = barW * 0.75 * hpFrac
    if hp <= 0 then healthWidth = 0 end
    
    draw.RoundedBox(6, barX, barY, healthWidth, barH,Color(255,0,0,62))
    BUi.masks.Start()
    surface.SetDrawColor(Color(255,0,0))
    surface.SetMaterial(BUi.Grad["Right"])
    surface.DrawTexturedRect(barX, barY , healthWidth, barH)
    BUi.masks.Source()
    draw.RoundedBoxEx(6, barX, barY, healthWidth, barH, Color(220, 50, 50), true, false, false, false)
    BUi.masks.End()

  
    if ap <= 0 then armorWidth = 0 end
    local armorWidth = barW * 0.25 * apFrac

    draw.RoundedBox(6, barX + barW * 0.75, barY, armorWidth, barH, Color(50, 101, 220, 20))
    BUi.masks.Start()
    surface.SetDrawColor( Color(50, 100, 220))
    surface.SetMaterial(BUi.Grad["Right"])
    surface.DrawTexturedRect(barX + barW * 0.75, barY, armorWidth, barH)

    surface.SetDrawColor(Color(255,0,0))
    surface.SetMaterial(BUi.Grad["Right"])
    surface.DrawTexturedRect(barX, barY , healthWidth, barH)


    BUi.masks.Source()
    draw.RoundedBoxEx(6, barX, barY, healthWidth, barH, Color(220, 50, 50), true, false, false, false)
    draw.RoundedBox(6, barX + barW * 0.75, barY, armorWidth, barH, Color(50, 100, 220))
    BUi.masks.End()
end

local AbilityCooldowns = AbilityCooldowns or {}

local function WrapText(text, font, maxWidth)
    surface.SetFont(font)
    local words = string.Explode(" ", text)
    local lines = {}
    local line = ""

    for _, word in ipairs(words) do
        local test = line == "" and word or (line .. " " .. word)
        local w = surface.GetTextSize(test)

        if w > maxWidth then
            table.insert(lines, line)
            line = word
        else
            line = test
        end
    end

    if line ~= "" then
        table.insert(lines, line)
    end

    return lines
end


net.Receive("BCORE_SuitAbilities", function()
    local abilityName = net.ReadString()

    local ply = LocalPlayer()
    if not ply.currentsuit then return end

    local abilities = ply.currentsuit.customData.abilities or {}
    local ability = abilities[abilityName]
    if not ability or not ability.Cooldown then return end

    AbilityCooldowns[abilityName] = {
        duration = ability.Cooldown,
        endTime = CurTime() + ability.Cooldown
    }
end)


local function DrawAbilities()
    local ply = LocalPlayer()
    if ply.currentsuit == "none" then return end

    local suit = ply.currentsuit
    local abilities = suit.customData.abilities or {}
    if table.Count(abilities) == 0 then return end

    local holdingDesc = input.IsKeyDown(KEY_C)

    local width = BUi:Scale(260)
    local padding = 12
    local baseRowHeight = 34
    local descLineHeight = 22

    local blocks = {}
    local totalHeight = 10

    for k, ability in pairs(abilities) do
        local blockHeight = baseRowHeight + 14

        local wrapped = {}
        if holdingDesc and ability.description then
            wrapped = WrapText(ability.description, "BCORE.Inventoryb.25", width - padding * 2)
            blockHeight = blockHeight + (#wrapped * descLineHeight)
        end

        blocks[#blocks + 1] = {
            name = k,
            ability = ability,
            lines = wrapped,
            height = blockHeight
        }

        totalHeight = totalHeight + blockHeight
    end

    local baseX = ScrW() - width - 20
    local baseY = ScrH() / 2 - totalHeight / 2

    local yOffset = baseY + 5

    for _, block in ipairs(blocks) do
        local abilityName = block.name
        local ability = block.ability

        local x = baseX + padding
        local y = yOffset

        local keyName = input.GetKeyName(ability.KeyBind or 0) or "?"
        local cd = AbilityCooldowns[abilityName]
        local cdText = ""
        if cd then
            local timeLeft = math.max(0, cd.endTime - CurTime())
            cdText = string.format("[%.1fs]", timeLeft)
        end

        local title = "[" .. string.upper(keyName) .. "] " .. abilityName .. " " .. (cdText ~= "[0.0s]" and cdText or "")
        draw.SimpleText(title, "BCORE.Inventoryb.25", x, y, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local textY = y + 22

        if holdingDesc then
            for _, line in ipairs(block.lines) do

                draw.SimpleText(line, "BCORE.Inventoryb.25", x, textY, Color(193, 191, 191), TEXT_ALIGN_LEFT)
                textY = textY + descLineHeight
            end
        end

        local barW = width - padding * 2
        local barH = 12
        local barY = y + block.height - 10

        draw.RoundedBox(4, x, barY - 12, barW, 2, Color(255, 255, 255))
        draw.RoundedBox(4, x, barY, barW, barH, Color(55, 55, 62))

        if cd then
            local timeLeft = math.max(0, cd.endTime - CurTime())
            local frac = math.Clamp(timeLeft / cd.duration, 0, 1)
            local col
            if frac < 0.33 then
                col = Color(220, 80, 80) -- red
            elseif frac < 0.66 then
                col = Color(220, 200, 60) -- yellow
            else
                col = Color(80, 220, 80) -- green
            end
            draw.RoundedBox(4, x, barY, barW * frac, barH, col)
        end

        yOffset = yOffset + block.height
    end
end



hook.Add("HUDPaint", "BCORE.SuitHUD", function()
    local ply = LocalPlayer()
    if ply.currentsuit then
        StartHud()
        DrawAbilities()
    end
end)
