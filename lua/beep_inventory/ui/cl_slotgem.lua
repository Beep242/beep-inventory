local PANEL = {}
AccessorFunc(PANEL, "slotIndex", "SlotIndex", FORCE_NUMBER)

function PANEL:Init()
    self:SetPanelWidth(550)
    self:SetPanelHeight(300)
    self:SetModelPanelWidth(100)
    self:BUi():FadeIn(0.5)
    self.sockets = {}
end

function PANEL:SetItemInfo(data)
    self.exit = BUi.Create("DButton", self)
    self.exit:Stick(RIGHT)
    self.exit:DockMargin(0, 10, 10, self:GetTall() -50)
    self.exit:SetWide(40)
    self.exit:SetText("")
    self.exit:BUi():ClearPaint():Background(Color(56,56,56,200),5)
        :FadeIn(0.5)
        :On("Paint", function(s,w,h)
        draw.RoundedBox(5,1,1,w-2,h-2,BCORE.Inventory.colors.accent)
            BUi.DrawImgur(0,0,w,h,"https://invisibalfan-ui.github.io/bui_images/images/0cjxwbc.png",color_white)
    end):FadeHover(Color(100,0,0,90),6,8)
    self.exit:On("DoClick", function() self:Remove() end)

    self.BaseClass.SetItemInfo(self, data)
    if not IsValid(self.infoholder) then return end

    for k,v in pairs(self.sockets) do
        if IsValid(v.socket) then v.socket:Remove() end
    end
    self.sockets = {}

    local socketCount = BCORE.Inventory.config.Rarities[self.Item.rarity].sockets or 1
    for i=1, socketCount do
        local socket = BUi.Create("DPanel", self.modifireholder)
        socket:SetSize(45,45)
        socket:BUi():ClearPaint():On("Paint", function(s,w,h)
            draw.RoundedBox(6,0,0,w,h,BCORE.Inventory.colors.light)
            draw.RoundedBox(6,1,1,w-2,h-2,BCORE.Inventory.colors.sec)
        end)
        self.sockets[i] = { socket = socket, HasItem = false }

  
        socket:Receiver("[BCORE][UI][ITEM]", function(receiver, droppedPanels, dropped)
            if not dropped or receiver:GetChildren()[1] then return end
            droppedPanels[1]:SetParent(receiver)
            droppedPanels[1]:Dock(FILL)
            self.sockets[i].HasItem = true

            if self.Item and droppedPanels[1]:GetItem() then
                BCORE.netstream.Start("BCORE.Inventory.Socket", self.Item.id, droppedPanels[1]:GetItem().id)
            end
        end)
    end
    if self.Item.customData.Modifiers then
        for k,v in pairs(self.Item.customData.Modifiers) do
            local modifier = BUi.Create("[BCORE][UI][ITEM_PANEL]", self.sockets[k].socket)
            modifier:Dock(FILL)
            modifier:SetItem(v)
            modifier:Text("")
            modifier.slotparent = self.Item
            modifier:Droppable("[BCORE][UI][ITEM]")
            self.sockets[k].HasItem = true
        end
    end
end

function PANEL:Paint(w,h)
    self.BaseClass.Paint(self, w, h)
    if self.Item then
        draw.SimpleText("Gem Slot", "BCORE.Inventorys.25", 10, 110, color_white, TEXT_ALIGN_LEFT)
    end
end

function PANEL:PerformLayout()
    self.BaseClass.PerformLayout(self)
    self:Center()
end

function PANEL:Think()
    if not IsValid(BCORE.Inventory.Context) or not BCORE.Inventory.Context:IsVisible() then
        self:Remove()
    end
end

vgui.Register("[BCORE][UI][SLOT_GEM]", PANEL, "[BCORE][UI][ITEM_HOVER]")
