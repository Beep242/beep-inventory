local thread = BCORE.netstream

for i = 1, 200 do
    BUi:CreateFont("BCORE.Inventory." .. i, "Montserrat", i, 500)
    BUi:CreateFont("BCORE.Inventorys." .. i, "Montserrat", i, 600)
    BUi:CreateFont("BCORE.Inventoryb." .. i, "Montserrat", i, 1024)
end

local function SaveInventoryToFile()
    local inventoryData = {
        items = {},
        modifiers = {}
    }

    for _, item in pairs(LocalPlayer().BCORE_Inventory) do
        table.insert(inventoryData.items, { id = item.id, slot = item.slot, itemType = item.itemType })
    end

    for _, modifier in pairs(LocalPlayer().BCORE_Inventory_Modifiers) do
        table.insert(inventoryData.modifiers, { id = modifier.id, slot = modifier.slot, itemType = modifier.itemType })
    end

    local jsonData = util.TableToJSON(inventoryData, true)
    file.Write("inventory_save.png", jsonData)
end

local function LoadInventoryFromFile()
    if not file.Exists("inventory_save.png", "DATA") then
        return { items = {}, modifiers = {} }
    end

    local jsonData = file.Read("inventory_save.png", "DATA")
    local inventoryData = util.JSONToTable(jsonData)
    
    if not inventoryData then
        return { items = {}, modifiers = {} }
    end

    return inventoryData
end

thread.Hook("InventorySync", function(inventoryData)

    if not inventoryData then return end 
    
    local inventorySize = BCORE.Inventory.config.MaxSlots
    local modifierSize = BCORE.Inventory.config.MaxSlots
    local assignedSlots = {}
    local assignedModifierSlots = {}
    local inventoryById = {}
    local updatedInventory = {}
    local updatedModifiers = {}

    LocalPlayer().BCORE_Inventory = LocalPlayer().BCORE_Inventory or {}
    LocalPlayer().BCORE_Inventory_Modifiers = LocalPlayer().BCORE_Inventory_Modifiers or {}

    for _, existingItem in pairs(LocalPlayer().BCORE_Inventory) do
        if existingItem.id then
            inventoryById[existingItem.id] = existingItem
            if existingItem.slot then
                assignedSlots[existingItem.slot] = true
            end
        end
    end

    for _, existingModifier in pairs(LocalPlayer().BCORE_Inventory_Modifiers) do
        if existingModifier.id then
            inventoryById[existingModifier.id] = existingModifier
            if existingModifier.slot then
                assignedModifierSlots[existingModifier.slot] = true
            end
        end
    end

    for _, item in pairs(inventoryData) do
        if item.id and inventoryById[item.id] then
            item.slot = inventoryById[item.id].slot
        else
            if item.itemType == "Modifier" then
                local slot = 1
                while assignedModifierSlots[slot] and slot <= modifierSize do
                    slot = slot + 1
                end
                
                if slot <= modifierSize then
                    item.slot = slot
                    assignedModifierSlots[slot] = true
                else
                    print("WARNING: No available modifier slots for item ID:", item.id)
                end
            else
                local slot = 1
                while assignedSlots[slot] and slot <= inventorySize do
                    slot = slot + 1
                end
                
                if slot <= inventorySize then
                    item.slot = slot
                    assignedSlots[slot] = true
                else
                    print("WARNING: No available slots for item ID:", item.id)
                end
            end
        end

        if item.itemType == "Modifier" then
            updatedModifiers[item.id] = item
        else
            updatedInventory[item.id] = item
        end
    end

    LocalPlayer().BCORE_Inventory = {}
    for _, item in pairs(updatedInventory) do
        table.insert(LocalPlayer().BCORE_Inventory, item)
    end

    LocalPlayer().BCORE_Inventory_Modifiers = {}
    for _, modifier in pairs(updatedModifiers) do
        table.insert(LocalPlayer().BCORE_Inventory_Modifiers, modifier)
    end

    if IsValid(BCORE.Inventory.Context) then
        if BCORE.Inventory.upgradesbool then 
            BCORE.Inventory.Context.Inventory:Load(LocalPlayer().BCORE_Inventory)
        else
            BCORE.Inventory.Context.Inventory:Load(LocalPlayer().BCORE_Inventory_Modifiers)
        end
    end

end)

hook.Add("ShutDown", "BCORE_SaveAllInventories_CL", function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            SaveInventoryToFile()
        end
    end
end)

gameevent.Listen("client_disconnect")
hook.Add("client_disconnect", "BCORE_Save_CL", function(data)
    SaveInventoryToFile()
end)

gameevent.Listen("player_activate")
hook.Add("player_activate", "BCORE_LOAD_CL", function(ply)
    timer.Simple(7, function()
        LocalPlayer().BCORE_Inventory = LocalPlayer().BCORE_Inventory or {}
        LocalPlayer().BCORE_Inventory_Modifiers = LocalPlayer().BCORE_Inventory_Modifiers or {}

        local savedInventory = LoadInventoryFromFile()
        local inventoryById = {}

        for _, item in pairs(savedInventory.items) do
            inventoryById[item.id] = item.slot
        end

        for _, modifier in pairs(savedInventory.modifiers) do
            inventoryById[modifier.id] = modifier.slot
        end

        for _, item in pairs(LocalPlayer().BCORE_Inventory or {}) do
            if inventoryById[item.id] then
                item.slot = inventoryById[item.id]
            end
        end
        

        for _, modifier in pairs(LocalPlayer().BCORE_Inventory_Modifiers or {}) do
            if inventoryById[modifier.id] then
                modifier.slot = inventoryById[modifier.id]
            end
        end
    end)
end)



hook.Add("PostDrawTranslucentRenderables", "BCORE.Inventory.ItemOverhead", function()
    local lp = LocalPlayer()
    local lpPos = lp:GetPos()

    for _, ent in ipairs(ents.GetAll()) do
        if not ent:GetNWBool("IsItem") then continue end

        local distSqr = ent:GetPos():DistToSqr(lpPos)
        if distSqr > 1000 * 1000 then continue end -- early out

        local vertOffset = distSqr < 4500 and 25 or 10
        local tick = distSqr < 4500

        local min, max = ent:GetCollisionBounds()
        local height = max.z - min.z
        local targetOffset = Vector(0, 0, height + vertOffset)
        ent.smoothedOffset = ent.smoothedOffset or targetOffset
        ent.smoothedOffset = LerpVector(FrameTime() * 10, ent.smoothedOffset, targetOffset)

        local pos = ent:GetPos() + ent.smoothedOffset
        local ang = Angle(0, EyeAngles().y - 90, 90)
        local siner = (math.sin(CurTime() * 2.5) + 2) * 0.3


        local rarityColor = BCORE.Inventory.config.Rarities[ent:GetNWString("ItemRarity")].color
        local rclr = rarityColor == "Rainbow" and HSVToColor(CurTime() * 10 % 360, 1, 1) or rarityColor


        local customDataCount = 0
        for i = 1, 100 do
            if ent:GetNWString("Custom_" .. i, "Unknown") ~= "Unknown" then
                customDataCount = customDataCount + 1
            end
        end


        local targetBoxHeight = 120 + (customDataCount * 85)
        ent.boxHeight = ent.boxHeight or 120
        ent.boxHeight = Lerp(FrameTime() * 10, ent.boxHeight, tick and targetBoxHeight or 120)

        ent.textOffset = ent.textOffset or 150
        ent.textOffset = Lerp(FrameTime() * 6, ent.textOffset, tick and 150 or 75)

        cam.Start3D2D(pos, ang, 0.03)
            local nameText = ent:GetNWString("ItemName", "Unknown Item")
            local tw, _ = surface.GetTextSize(nameText)
            local namex, namey, namew, nameh = (-400 + 800 * 0.5 - tw * 0.5) - 100, -160, tw + 200, 150

     
            surface.SetAlphaMultiplier(siner)
            draw.RoundedBox(32, namex, namey, namew, nameh, rclr)
            surface.SetAlphaMultiplier(1)
            draw.RoundedBox(32, namex + 5, namey + 5, namew - 12, nameh - 12, BCORE.Inventory.colors.bg)


            surface.SetAlphaMultiplier(siner)
            draw.RoundedBox(32, -400, 0, 800, ent.boxHeight, rclr)
            surface.SetAlphaMultiplier(1)
            draw.RoundedBox(32, -395, 5, 788, ent.boxHeight - 12, BCORE.Inventory.colors.bg)
            draw.RoundedBoxEx(32, -395, 5, 788, 110, tick and BCORE.Inventory.colors.accent or Color(0,0,0,0), true, true, false, false)

        
            if tick then
                ent.alpha = Lerp(FrameTime() / 4, ent.alpha or 0, 255)
                ent.alpha = math.Clamp(ent.alpha, 0, 255)
            else
                ent.alpha = 0
            end

   
            local lineoffset = 390
            for i = 1, customDataCount - 1 do
                draw.RoundedBox(0, -395, lineoffset * 0.5, 788, 5, Color(rclr.r,rclr.g,rclr.b,ent.alpha))
                lineoffset = lineoffset + 170
            end

            local function GetSkinName(str)
                local name = string.match(str, "([^/\\]+)$") or str
                return string.upper(string.sub(name,1,1)) .. string.sub(name,2)
            end

            local textoffset = ent.textOffset
            for i = 1, customDataCount do
                local customDataValue = ent:GetNWString("Custom_" .. i, "Unknown")
                if customDataValue == "Unknown" then continue end
                local key, val = string.match(customDataValue, "([^:]+):%s*(.+)")
                key = key or "Unknown"
                val = val or ""

                if key:lower():find("skin") then
                    val = GetSkinName(val)
                end

                draw.SimpleText(key .. ": " .. tostring(val), "BCORE.Inventorys.75", -380, textoffset, Color(255,255,255,ent.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                textoffset = textoffset + 85
            end

            
            local modIndex = 1
            local nextRowY = 0
            while true do
                local firstKey = "Modifier_" .. modIndex .. "_1"
                if ent:GetNWString(firstKey, "Unknown") == "Unknown" then break end

                local leftLines = {}
                local subIndex = 1
                while true do
                    local subKey = "Modifier_" .. modIndex .. "_" .. subIndex
                    local val = ent:GetNWString(subKey, "Unknown")
                    if val == "Unknown" then break end
                    table.insert(leftLines, val)
                    subIndex = subIndex + 1
                end

                local boxW, boxH = 780, (#leftLines * 75) + 100
                local leftX, leftY = -1220, nextRowY
                local modrclr = BCORE.Inventory:GetRarityColor(ent:GetNWString("Modifier_" .. modIndex .. "_Rarity", "Unknown"))
                draw.RoundedBox(32, leftX, leftY, boxW, tick and boxH  or ent.boxHeight-20, modrclr)
                draw.RoundedBox(32, leftX + 5, leftY + 5, boxW - 12, tick and boxH - 12 or ent.boxHeight-30, BCORE.Inventory.colors.bg)
                draw.SimpleText(ent:GetNWString("Modifier_" .. modIndex .. "_Name", "Unknown"), "BCORE.Inventoryb.85", leftX + boxW*0.5, leftY + 40, modrclr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                local y = leftY + 110
                for idx, text in ipairs(leftLines) do
                    draw.SimpleText(text, "BCORE.Inventorys.75", leftX + 20, y, Color(255,255,255,ent.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    if idx < #leftLines then
                        draw.RoundedBox(0, leftX + 10, y + 45, boxW - 20, 4, Color(modrclr.r,modrclr.g,modrclr.b,ent.alpha))
                    end
                    y = y + 80
                end

    
                local rightLines = {}
                local subIndex2 = 1
                while true do
                    local subKey2 = "Modifier_" .. (modIndex + 1) .. "_" .. subIndex2
                    local val2 = ent:GetNWString(subKey2, "Unknown")
                    if val2 == "Unknown" then break end
                    table.insert(rightLines, val2)
                    subIndex2 = subIndex2 + 1
                end

                local rightX, rightY = 440, nextRowY 
                if #rightLines > 0 then
                    local boxH2 = (#rightLines * 75) + 100
                    draw.RoundedBox(32, rightX, rightY, boxW, tick and boxH2  or ent.boxHeight-20, modrclr)
                    draw.RoundedBox(32, rightX + 5, rightY + 5, boxW - 12, tick and boxH2 - 12 or ent.boxHeight-30, BCORE.Inventory.colors.bg)
                    draw.SimpleText(ent:GetNWString("Modifier_" .. (modIndex + 1) .. "_Name", "Unknown"), "BCORE.Inventoryb.85", rightX + boxW*0.5, rightY + 40, modrclr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                    y = rightY + 110
                    for idx, text in ipairs(rightLines) do
                        draw.SimpleText(text, "BCORE.Inventorys.70", rightX + 20, y, Color(255,255,255,ent.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        if idx < #rightLines then
                            draw.RoundedBox(0, rightX + 10, y + 45, boxW - 20, 4, Color(modrclr.r,modrclr.g,modrclr.b,ent.alpha))
                        end
                        y = y + 80
                    end
                end

                local rowHeight = math.max(boxH, (#rightLines * 45) + 100)
                nextRowY = nextRowY + rowHeight + 40
                modIndex = modIndex + 2
            end

            -- Draw rarity and item name
            local rarity = BCORE.Inventory.config.Rarities[ent:GetNWString("ItemRarity", "Unknown Item")]
            local rtext = rarity.animate and rarity.animate(ent:GetNWString("ItemRarity", "Unknown Item")) or ent:GetNWString("ItemRarity", "Unknown Item") or "Unknown Item"
            draw.SimpleText(rtext, "BCORE.Inventoryb.110", -400 + 800 * 0.5, 100 * 0.5, rclr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(nameText, "BCORE.Inventoryb.110", -400 + 800 * 0.5, -170 * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end)






net.Receive("BCORE.Inventory.Chat", function()
    chat.AddText(Color(73, 122, 214), "[INVENTORY]" .. " ", color_white, net.ReadString() or "")
end)

function BCORE.Inventory:RequestAction(itemID, action)
    thread.Start("BCORE.Inventory.RequestAction", itemID, action)
end

net.Receive("RepairSuit", function()
        local price = net.ReadFloat()
        local popup = BUi.Create("BUi.Popup")
        popup:SetName("Repair Suit?") 
        popup:SetMode("yesno", {
        text = "Are you sure you would like to repair your suit for $ " .. price,

        yes = function()
            net.Start("RepairSuit")
            net.SendToServer()
        end,

        no = function()
            popup:Remove()
        end,
        })
end)

net.Receive("ApplyWeaponSkin", function()
    local weapon = net.ReadEntity()
    local skin = net.ReadString()
    if not IsValid(weapon) or not skin or skin == "" then return end

    weapon:SetNWString("WeaponSkin", skin)
    weapon.skinMat = skin

    weapon.drawnMaterials = {}
    local mats = weapon:GetMaterials()
    for i = 1, #mats do
        if not weapon.Blacklisted or not weapon.Blacklisted[mats[i]] then
            weapon.drawnMaterials[#weapon.drawnMaterials + 1] = i
        end
    end


    weapon.oDrawWorldModel = weapon.oDrawWorldModel or weapon.DrawWorldModel
    function weapon:DrawWorldModel(flags)
        if self.oDrawWorldModel then self:oDrawWorldModel(flags) end
        if self.skinMat then self:SetMaterial(self.skinMat) end
    end


    if weapon.VElements or weapon.WElements then
        local function HandleElements(tbl, isViewModel)
            local renderOrder = {}
            for k, v in pairs(tbl) do
                if v.type == "Model" then
                    table.insert(renderOrder, 1, k)
                else
                    table.insert(renderOrder, k)
                end
            end
            for _, name in ipairs(renderOrder) do
                local v = tbl[name]
                if not v or v.hide then continue end
                local model = v.modelEnt
                if not IsValid(model) then continue end

                local bone_ent = isViewModel and weapon.Owner:GetViewModel() or (IsValid(weapon.Owner) and weapon.Owner or weapon)
                local pos, ang
                if v.bone then
                    pos, ang = weapon:GetBoneOrientation(tbl, v, bone_ent)
                else
                    pos, ang = weapon:GetBoneOrientation(tbl, v, bone_ent, "ValveBiped.Bip01_R_Hand")
                end
                if not pos then continue end

                model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
                ang:RotateAroundAxis(ang:Up(), v.angle.y)
                ang:RotateAroundAxis(ang:Right(), v.angle.p)
                ang:RotateAroundAxis(ang:Forward(), v.angle.r)
                model:SetAngles(ang)

                local matrix = Matrix()
                matrix:Scale(v.size)
                model:EnableMatrix("RenderMultiply", matrix)

                model:SetMaterial(weapon.skinMat or (v.OriginalMaterial or ""))
                if v.skin and v.skin ~= model:GetSkin() then model:SetSkin(v.skin) end
                if v.bodygroup then
                    for k2, v2 in pairs(v.bodygroup) do
                        if model:GetBodygroup(k2) ~= v2 then model:SetBodygroup(k2, v2) end
                    end
                end

                if v.surpresslightning then render.SuppressEngineLighting(true) end
                render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
                render.SetBlend(v.color.a / 255)
                model:DrawModel()
                render.SetBlend(1)
                render.SetColorModulation(1, 1, 1)
                if v.surpresslightning then render.SuppressEngineLighting(false) end
            end
        end

        function weapon:ViewModelDrawn()
            if not IsValid(self.Owner) then return end
            HandleElements(self.VElements, true)
        end

        function weapon:DrawWorldModel()
            if self.ShowWorldModel == nil or self.ShowWorldModel then self:DrawModel() end
            if not self.WElements then return end
            HandleElements(self.WElements, false)
        end
    end

    hook.Add("PreDrawViewModel", "ApplyWeaponSkinToViewModel_" .. weapon:EntIndex(), function(vm, ply, wep)
        if wep ~= weapon or not weapon.skinMat or not weapon.drawnMaterials then return end
        for _, mat in ipairs(weapon.drawnMaterials) do
            vm:SetSubMaterial(mat - 1, weapon.skinMat)
        end
    end)
end)








