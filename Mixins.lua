

local addonName, SoftResPlus = ...;

SoftResPlusLoadItemMixin = {}
function SoftResPlusLoadItemMixin:SetItemByID(itemID)
    local item = Item:CreateFromItemID(itemID)
    if item and (not item:IsItemEmpty()) then
        item:ContinueOnItemLoad(function()
        
            self:HookScript("OnEnter", function()
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(itemID)
                GameTooltip:Show()
            end)

            self:HookScript("OnLeave", function()
                GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
            end)

            if self.Label then
                self.Label:SetText(item:GetItemLink())
            end

            if self.Icon then
                self.Icon:SetTexture(item:GetItemIcon())
            end

        end)
    end
end


SoftResPlusEncounterItem = {}
function SoftResPlusEncounterItem:SetDataBinding(binding, height)

    if binding.itemID and binding.itemSubType then
        local item = Item:CreateFromItemID(binding.itemID)
        if item and (not item:IsItemEmpty()) then
            item:ContinueOnItemLoad(function()
            
                self:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetItemByID(binding.itemID)
                    GameTooltip:Show()

                    self.Highlight:Show()
                end)

                self:SetScript("OnLeave", function()
                    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)

                    -- if self.AddToList:IsMouseOver() then
                    --     self.Highlight:Show()
                    -- else
                    --     self.Highlight:Hide()
                    -- end

                    self.Highlight:Hide()
                end)

                self.Label:SetText(item:GetItemLink())
                self.Label:SetFontObject("GameFontNormal")
                self.Label:ClearAllPoints()
                self.Label:SetPoint("TOPLEFT", self.Icon, "TOPRIGHT", 4, -1)

                self.Icon:SetTexture(item:GetItemIcon())
                self.Icon:SetWidth(28)

                self.ItemSubType:SetText(binding.itemSubType)

                self.Divider:Hide()

                if binding.rightButton == "addItem" then
                    self.AddToList:Show()
                    self.AddToList:SetScript("OnClick", function()
                        MenuUtil.CreateContextMenu(self, function(self, rootDescription)
                            rootDescription:CreateTitle("Select List")
                            rootDescription:CreateDivider()
                            local allLists = SoftResPlus.Database:GetAllLists()
                            if allLists then
                                for _, list in ipairs(allLists) do
                                    rootDescription:CreateButton(list.name, function()
                                        SoftResPlus.Callbacks:TriggerEvent("List_OnItemAdded", binding.itemID, list.id)
                                    end)
                                end
                            end
                        end)
                    end)
                end

                if (binding.rightButton == "delete") and binding.listID then
                    self.DeleteItem:Show()
                    self.DeleteItem:SetScript("OnClick", function()
                        SoftResPlus.Callbacks:TriggerEvent("List_OnItemDeleted", binding.itemID, binding.listID)
                    end)
                end

            end)
        end

        self:EnableMouse(true)

    elseif binding.header then
        self.Label:SetText(binding.header)
        self.Label:SetFontObject("GameFontNormalLarge")
        self.Label:ClearAllPoints()
        self.Label:SetPoint("LEFT", 4, -4)
        self.Divider:Show()
        self.Icon:SetWidth(1)
        self.AddToList:Hide()
        self.DeleteItem:Hide()
        self.Highlight:Hide()
        self:EnableMouse(false)
    end
end
function SoftResPlusEncounterItem:ResetDataBinding()
    self.Label:SetText(nil)
    self.ItemSubType:SetText(nil)
    self.Icon:SetTexture(nil)
    self.AddToList:Hide()
    self.DeleteItem:Hide()
    self.Highlight:Hide()
end







SoftResPlusSessionSelectMixin = {}
function SoftResPlusSessionSelectMixin:SetDataBinding(binding, height)
    self:SetHeight(height)
    self.Label:SetText(binding.instance)
    self.TimeStamp:SetText(date("%A %Y-%m-%d %H:%M", binding.created))

    self.id = string.format("%s-%d", binding.instance, binding.created)

    self:SetScript("OnMouseDown", function()
        SoftResPlus.Callbacks:TriggerEvent("Session_OnSelected", binding)
    end)
end

function SoftResPlusSessionSelectMixin:ResetDataBinding()
    self.id = nil;
end





SoftResPlusBasicListItemMixin = {}
function SoftResPlusBasicListItemMixin:SetDataBinding(binding, height)
    self:SetHeight(height)
    if binding.label then
        self.Label:SetText(binding.label)
    elseif binding.itemLink then
        self.Label:SetText(binding.itemLink)
    end
end

function SoftResPlusBasicListItemMixin:ResetDataBinding()
    self.Label:SetText("")
end