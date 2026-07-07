local PANEL = {}

local currentMenu = nil
BCORE.Inventory = BCORE.Inventory or {}
BCORE.Inventory.SelectedItems = BCORE.Inventory.SelectedItems or {}

function PANEL:SetItem(data)
    self._skinmat     = nil
    self.ItemSelected = false
    self.Item         = data

    if not self.Item then
        if IsValid(self.ModelPanel) then
            self.ModelPanel:Remove()
        end
        return
    end

    if IsValid(self.ModelPanel) then
        self.ModelPanel:Remove()
    end

    self.ModelPanel = self:Add("DModelPanel")
    self.ModelPanel:Dock(FILL)
    self.ModelPanel.LayoutEntity = function() return end
    self.ModelPanel:SetModel(self.Item.model)

    local mn, mx = self.ModelPanel.Entity:GetRenderBounds()
    local size = math.max(
        math.abs(mn.x) + math.abs(mx.x),
        math.abs(mn.y) + math.abs(mx.y),
        math.abs(mn.z) + math.abs(mx.z)
    )

    self.ModelPanel:SetFOV(40)
    self.ModelPanel:SetCamPos(Vector(size, size, size))
    self.ModelPanel:SetLookAt((mn + mx) * 0.5)

    if not self.ModelPanel.NoDrag then
        self.ModelPanel:SetDragParent(self)
    end

    self.ModelPanel.DoClick = function()
        local item = self.Item
        if not item or not item.id then return end

        local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)

        if not shift then
            BCORE.Inventory.SelectedItems = {}
        end

        local selected = BCORE.Inventory.SelectedItems[item.id]

        if selected then
            BCORE.Inventory.SelectedItems[item.id] = nil
            self.ItemSelected = false
        else
            BCORE.Inventory.SelectedItems[item.id] = item
            self.ItemSelected = true
        end

        if IsValid(currentMenu) then
            currentMenu:Close()
        end
    end

    self.ModelPanel.DoRightClick = function(s)
        self:RemoveTooltip()

        if IsValid(currentMenu) then
            currentMenu:Close()
        end

        local menu = BUi.Create("BUi.DMenu", self)
        currentMenu = menu
        menu:SetSize(110)

        for k, v in pairs(self.Item.onAction or {}) do
            menu:AddOption(v, function()
                BCORE.Inventory:RequestAction(self.Item.id, v)

                if v == "Socket" then
                    BCORE.Inventory.Context.slotgem = BUi.Create("[BCORE][UI][SLOT_GEM]")
                    BCORE.Inventory.Context.slotgem:SetItemInfo(self.Item)
                end
            end)
        end

        menu:Open()
    end
end

function PANEL:Paint(w, h)

    if not self.Item then return end

    local rotation = (CurTime() * 50) % 360
    local siner    = (math.sin(CurTime() * 2.5) + 2) * 0.3
    local rclr

    if BCORE.Inventory.config.Rarities[self.Item.rarity].color == "Rainbow" then
        rclr = HSVToColor(CurTime() * 10 % 360, 1, 1)
    else
        rclr = BCORE.Inventory.config.Rarities[self.Item.rarity].color
    end

    if self.Item.customData.Skin and not self._skinmat then
        self._skinmat = CreateMaterial("BUi_Skin_" .. self.Item.id, "UnlitGeneric", {
            ["$basetexture"] = self.Item.customData.Skin,
            ["$translucent"] = "1",
            ["$vertexalpha"]  = "1",
            ["$vertexcolor"]  = "1"
        })
    end

    local skinmaterial = self._skinmat or BUi.Grad["Down"]

    draw.RoundedBox(6, 0, 0, w, h, BCORE.Inventory.colors.light)

    BUi.masks.Start()
    surface.SetDrawColor(self.Item.customData.Skin and color_white or rclr)
    surface.SetMaterial(skinmaterial)
    surface.DrawTexturedRectRotated(w/2, h/2, w, h*2, rotation)
    BUi.masks.Source()
    draw.RoundedBox(6, 0, 0, w, h, rclr)
    BUi.masks.End()

    draw.RoundedBox(6, 1, 1, w-2, h-2, BCORE.Inventory.colors.sec)

    BUi.masks.Start()
    surface.SetAlphaMultiplier(siner)

    if not self.Item.customData.Skin then
        BUi.DrawImgur(0, 0, w, h, "https://invisibalfan-ui.github.io/bui_images/images/hx2vcku.png", rclr)
        surface.SetDrawColor(rclr)
        surface.SetMaterial(skinmaterial)
        surface.DrawTexturedRect(1, h/4 - 1, w-2, h/1.3)
    else
        surface.SetDrawColor(color_white)
        surface.SetMaterial(skinmaterial)
        surface.DrawTexturedRect(1, 1, w-2, h-2)
    end

    BUi.masks.Source()
    draw.RoundedBox(6, 1, 1, w-2, h-2, BCORE.Inventory.colors.sec)
    BUi.masks.End()
    surface.SetAlphaMultiplier(1)

    if self.ItemSelected then
        draw.RoundedBox(6, 0, 0, w, h, Color(255, 80, 80, 80))
    end

end

function PANEL:GetItem()
    return self.Item
end

function PANEL:Think()

    if not self.Item or not self:IsVisible() then
        self:RemoveTooltip()
        return
    end

    local isHovered = self.ModelPanel and self.ModelPanel:IsHovered()
    if isHovered then
        local mouseX, mouseY = input.GetCursorPos()
        self:UpdateTooltip(mouseX + 20, mouseY - 240)
    else
        self:RemoveTooltip()
    end
end

function PANEL:UpdateTooltip(x, y)
    if not self.tip then
        self.tip = vgui.Create("[BCORE][UI][ITEM_HOVER]")
        self.tip:SetItemInfo(self.Item)
    end
    self.tip:SetPos(x, y)
end

function PANEL:RemoveTooltip()
    if IsValid(self.tip) then
        self.tip:Remove()
        self.tip = nil
    end
end

function PANEL:OnRemove()
    if IsValid(self.tip) then
        self.tip:Remove()
    end
end

vgui.Register("[BCORE][UI][ITEM_PANEL]", PANEL, "DButton")