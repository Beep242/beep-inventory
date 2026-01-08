local PANEL = {}

AccessorFunc(PANEL, "panelWidth", "PanelWidth", FORCE_NUMBER)
AccessorFunc(PANEL, "panelHeight", "PanelHeight", FORCE_NUMBER)
AccessorFunc(PANEL, "modelPanelWidth", "ModelPanelWidth", FORCE_NUMBER)


local function GetRarityColor(rarity)
    local clr = BCORE.Inventory.config.Rarities[rarity].color
    if clr == "Rainbow" then
        return HSVToColor(CurTime() * 10 % 360, 1, 1)
    else
        return clr
    end
end


local function CalcStatDiff(base, current)
    local diff = current - (base or 0)
    local percent = base ~= 0 and (diff / base) * 100 or 0
    if math.abs(percent) > 1000 then
        percent = (percent / math.abs(percent)) * 200
    end
    local roundedPercent = math.Round(percent) 
    local text = (diff < 0 and roundedPercent .. "%") or ("+" .. roundedPercent .. "%")
    local colorval = string.StartsWith(text, "+") and Color(28, 208, 28) or Color(255, 0, 0)
    return text, colorval
end



local function DrawWrappedText(text, font, x, y, color, wrapWidth, align)
    local curY, curLine = y, ""
    surface.SetFont(font)
    for word in string.gmatch(text, "%S+") do
        local testLine = curLine == "" and word or (curLine .. " " .. word)
        local testW, _ = surface.GetTextSize(testLine)
        if testW > wrapWidth then
            draw.SimpleText(curLine, font, x, curY, color, align)
            curY = curY + 15
            curLine = word
        else
            curLine = testLine
        end
    end
    if curLine ~= "" then
        draw.SimpleText(curLine, font, x, curY, color, align)
    end
end

function PANEL:Init()
    self:SetPanelWidth(500)
    self:SetPanelHeight(300)
    self:SetModelPanelWidth(100)
    self:BUi():FadeIn(0.5)
    self.sockets = {}
end

function PANEL:SetItemInfo(data)
    self.Item = data
    if not self.Item then return end

    local basestats = {}
    local baseEnt = scripted_ents.Get(self.Item.className)
    if self.Item.itemType == "Modifier" then
        basestats = {}
    elseif baseEnt then
        basestats = self.Item.customData or {}
    else
        local wdata = weapons.Get(self.Item.className)
        if wdata and wdata.Primary then
            local p = wdata.Primary
            basestats = {
                Damage = p.Damage or 50,
                Accuracy = p.IronAccuracy or p.Accuracy or 85,
                Recoil = p.Recoil or p.KickUp or 1.2,
                ClipSize = p.ClipSize or 30,
                Spread = p.Spread or 0.05,
                RPM = p.RPM or 600,
                Shots = p.NumShots or p.Shots or 1
            }
        end
    end
    self.basestats = basestats

    if IsValid(self.infoholder) then self.infoholder:Remove() end
    if IsValid(self.modifireholderscroller) then self.modifireholderscroller:Remove() end

    self.infoholder = vgui.Create("DPanel", self)
    self.infoholder:Dock(TOP)
    self.infoholder:DockMargin(10, 10, 10, 10)
    self.infoholder:SetTall(100)
    self.infoholder:BUi():ClearPaint()

    local skinmaterial = self.Item.customData.Skin and CreateMaterial("BUi_Skin_" .. tostring(math.floor(SysTime() * 1000000 + math.random(1, 999999))), "UnlitGeneric", {
        ["$basetexture"] = self.Item.customData.Skin or "vgui/white",
        ["$translucent"] = "1",
        ["$vertexalpha"] = "1",
        ["$vertexcolor"] = "1"
    }) or BUi.Grad["Down"]


    self.mhold = vgui.Create("DPanel", self.infoholder)
    self.mhold:Dock(LEFT)
    self.mhold:SetWide(BUi:Scale(self:GetModelPanelWidth()))
    self.mhold:BUi():ClearPaint():FadeIn(0.2):Background(BCORE.Inventory.colors.light, 5):On("Paint", function(s, w, h)
        local rotation, siner = (CurTime() * 50) % 360, (math.sin(CurTime() * 2.5) + 2) * 0.3
        local rclr = GetRarityColor(self.Item.rarity)

        BUi.masks.Start()
        surface.SetAlphaMultiplier(siner)
        surface.SetDrawColor(color_white)
        if not self.Item.customData.Skin then
            surface.SetDrawColor(rclr)
        end
        surface.SetMaterial(skinmaterial)
        surface.DrawTexturedRectRotated(w/2, h/2, w, h*2, rotation)
        surface.SetAlphaMultiplier(1)
        BUi.masks.Source()
        draw.RoundedBox(6, 0, 0, w, h, rclr)
        BUi.masks.End()

        draw.RoundedBox(6, 2, 2, w - 4, h - 4, BCORE.Inventory.colors.sec)

        BUi.masks.Start()
        surface.SetAlphaMultiplier(siner)
        surface.SetDrawColor(color_white)
        if not self.Item.customData.Skin then
            surface.SetDrawColor(rclr)
        end
        surface.SetMaterial(skinmaterial)
        surface.DrawTexturedRect(0, 0, w, h)
        surface.SetDrawColor(rclr)
        surface.SetMaterial(BUi.Grad["Down"])
        surface.DrawTexturedRect(0, 0, w, h)
        surface.SetAlphaMultiplier(1)
        BUi.masks.Source()
        draw.RoundedBox(6, 0, 0, w, h, rclr)
        BUi.masks.End()
        draw.RoundedBox(6, 2, 2, w - 4, h - 4, Color(0, 0, 0, 130))
     

   
    end)

    self.ModelPanel = self.mhold:Add("DModelPanel")
    self.ModelPanel:Dock(FILL)
    self.ModelPanel:BUi():FadeIn(0.2)
    self.ModelPanel:SetModel(self.Item.model)
    function self.ModelPanel:LayoutEntity() return end
    local mn, mx = self.ModelPanel.Entity:GetRenderBounds()
    local size = math.max(math.abs(mn.x)+math.abs(mx.x), math.abs(mn.y)+math.abs(mx.y), math.abs(mn.z)+math.abs(mx.z))
    self.ModelPanel:SetFOV(40)
    self.ModelPanel:SetCamPos(Vector(size, size, size))
    self.ModelPanel:SetLookAt((mn + mx) * 0.5)



    self.navbar = vgui.Create("DPanel", self.infoholder)
    self.navbar:Dock(TOP)
    self.navbar:DockMargin(10, 0, 0, 0)
    self.navbar:SetTall(40)
    self.navbar:BUi():ClearPaint():Background(Color(56,56,56,200),5):FadeIn(0.5):On("Paint", function(s, w, h)
        local rclr = GetRarityColor(self.Item.rarity)
        local siner, rotation = (math.sin(CurTime()*2.5)+2)*0.3, (CurTime()*30)%360
        surface.SetAlphaMultiplier(siner)
        BUi.masks.Start()
        surface.SetMaterial(BUi.Grad["Right"])
        surface.SetDrawColor(rclr)
        surface.DrawTexturedRect(0,0,w,h)
        surface.SetMaterial(BUi.Grad["Left"])
        surface.DrawTexturedRect(0,0,w/2,h)
        surface.DrawTexturedRectRotated(w/2,h/2,w,h*2,rotation)
        BUi.masks.Source()
        draw.RoundedBox(5,0,0,w,h,BCORE.Inventory.colors.tert)
        BUi.masks.End()
        surface.SetAlphaMultiplier(1)
        draw.RoundedBox(5,1,1,w-2,h-2,BCORE.Inventory.colors.accent)
        draw.SimpleText(self.Item.name, "BCORE.Inventoryb.30", w/2, 20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)


    self.modifireholderscroller = vgui.Create("DScrollPanel", self)
    self.modifireholderscroller:Dock(LEFT)
    self.modifireholderscroller:DockMargin(10,15,10,10)
    self.modifireholderscroller:SetWide(self.mhold:GetWide())
    self.modifireholderscroller:BUi():ClearPaint():HideVBar()
    self.modifireholder = vgui.Create("DIconLayout", self.modifireholderscroller)
    self.modifireholder:Dock(FILL)
    self.modifireholder:SetSpaceX(10)
    self.modifireholder:SetSpaceY(10)
    self.modifireholder:BUi():ClearPaint()

    if self.Item.itemType == "UpgradableWeapon" then
        local socketCount = BCORE.Inventory.config.Rarities[self.Item.rarity].sockets or 0
        for i = 1, socketCount do
            local socket = BUi.Create("DPanel", self.modifireholder)
            socket:SetSize(45,45)
            socket:BUi():ClearPaint():On("Paint", function(s,w,h)
                draw.RoundedBox(6,0,0,w,h,BCORE.Inventory.colors.light)
                draw.RoundedBox(6,1,1,w-2,h-2,BCORE.Inventory.colors.sec)
            end)
            self.sockets[i] = {socket=socket, HasItem=false}
        end

        if self.Item.customData.Modifiers then
            for k,v in pairs(self.Item.customData.Modifiers) do
                local modifier = BUi.Create("[BCORE][UI][ITEM_PANEL]", self.sockets[k].socket)
                modifier:Dock(FILL)
                modifier:SetItem(v)
                modifier:Text("")
                self.sockets[k].HasItem = true
            end
        end
    end
end


function PANEL:Paint(w,h)
    if not self.Item then return end
    self:BUi():ClearPaint():Background(Color(56,56,56),5):On("Paint", function(s,w,h)
        local rclr = GetRarityColor(self.Item.rarity)
        local siner = (math.sin(CurTime()*2.5)+2)*0.3
        draw.RoundedBox(5,1,1,w-2,h-2,Color(28,28,28))
        surface.SetAlphaMultiplier(siner)
        BUi.masks.Start()
        BUi.DrawImgur(0,0,w,h,"https://invisibalfan-ui.github.io/bui_images/images/8clv24q.png",rclr)
        surface.SetMaterial(BUi.Grad["Down"])
        surface.SetDrawColor(rclr)
        surface.DrawTexturedRect(0,0,w,h)
        BUi.masks.Source()
        draw.RoundedBox(8,0,0,w,h,BCORE.Inventory.colors.tert)
        BUi.masks.End()
        surface.SetAlphaMultiplier(1)
        draw.RoundedBox(5,1,1,w,h,Color(0,0,0,130))

        local textX = self.navbar:GetWide()*0.83
        local rarity = BCORE.Inventory.config.Rarities[self.Item.rarity]
        local rtext = rarity.animate and rarity.animate(self.Item.rarity) or self.Item.rarity

        local function GetSkinName(str)
            local name = string.match(str, "([^/\\]+)$") or str
            return string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
        end

        draw.SimpleText(rtext .. (self.Item.customData.Skin and "-" .. GetSkinName(self.Item.customData.Skin) or ""), "BCORE.Inventoryb.30", textX, 50, rclr, TEXT_ALIGN_CENTER)

        if not table.IsEmpty(self.Item.customData) then
            local pos = 55
            for k,v in SortedPairs(self.Item.customData) do
                if k=="Modifiers" or k=="Type" or k=="Description" then continue end
                if isstring(v) or isbool(v) or istable(v) then continue end
                pos = pos + 30
                local val = v
                local offsetx,_ = surface.GetTextSize(k..": "..val.." ")
                if self.Item.itemType=="Modifier" then
                    draw.SimpleText(k..": ".. math.Round(val, 2) .." ","BCORE.Inventorys.25",self.navbar:GetWide()*0.33,pos,color_white,TEXT_ALIGN_LEFT)
                    draw.SimpleText("+" .. string.format("%.0f%%", val * 100), "BCORE.Inventorys.25", self.navbar:GetWide() * 0.33 + offsetx, pos, Color(28, 208, 28), TEXT_ALIGN_LEFT)
                else
                    local base = self.basestats[k] or 0
                    local sub, col = CalcStatDiff(base,val)
                    draw.SimpleText(k..": "..val.." ","BCORE.Inventorys.25",self.navbar:GetWide()*0.33,pos,color_white,TEXT_ALIGN_LEFT)
                    draw.SimpleText(sub,"BCORE.Inventorys.25",self.navbar:GetWide()*0.33+offsetx,pos,col,TEXT_ALIGN_LEFT)
                end
            end
        end

        if self.Item.itemType=="Modifier" or self.Item.itemType=="Suit" then
            draw.RoundedBox(6,10,120,100,h-130,BCORE.Inventory.colors.light)
            draw.RoundedBox(6,11,121,98,h-132,BCORE.Inventory.colors.sec)
            local desc = self.Item.customData.Description or self.Item.customData.description or "No description available."
            DrawWrappedText(desc,"BCORE.Inventorys.18",15,110,BCORE.Inventory.colors.cwhite,w-700,TEXT_ALIGN_LEFT)
        end
    end)
end

function PANEL:PerformLayout()
    self:BUi():FadeIn(0.5)
    self:SetSize(BUi:Scale(self:GetPanelWidth()),BUi:Scale(self:GetPanelHeight()))
    self:MakePopup()
end

vgui.Register("[BCORE][UI][ITEM_HOVER]", PANEL, "DPanel")
