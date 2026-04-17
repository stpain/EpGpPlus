

local addonName, EpgpPlus = ...;



--[[
    Mixin for the loot treeview list

    This template is used for 2 situations
    * addItem - this is the main use and shows a + button on the right for the user to add the item to a list
    * deleteItem - this is used when viewing a list, shows a "bin" style button and enables the user to delete the item from the list

    The elements are passed a .rightButton config table which is used to determine which setup the template should prepare
]]
EpgpPlusEncounterItem = {}
function EpgpPlusEncounterItem:OnLoad()
    self:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        self.Highlight:Hide()
    end)

end


function EpgpPlusEncounterItem:SetDataBinding(binding, height)

    self:SetHeight(height)

    if binding.header then
        self.Label:SetText(binding.header)
        self.Label:SetFontObject("GameFontNormalLarge")
        self.Label:ClearAllPoints()
        self.Label:SetPoint("LEFT", 4, -4)
        self.Divider:Show()
        self.Icon:SetWidth(1)
        self:EnableMouse(false)
    
    elseif binding.itemID then

        self.itemID = binding.itemID;

        self:SetScript("OnEnter", function()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(binding.itemID)

            GameTooltip:Show()

            self.Highlight:Show()
        end)

        local item = EpgpPlus.Database.db.itemDb[binding.itemID];

        if item then

            self:SetScript("OnMouseDown", function()
                if IsControlKeyDown() then
                    DressUpItemLink(item.link)
                elseif IsShiftKeyDown() then
                    HandleModifiedItemClick(item.link)
                end
            end)

            self.Label:SetText(item.link)
            self.Label:SetFontObject("GameFontNormal")
            self.Label:ClearAllPoints()
            self.Label:SetPoint("TOPLEFT", self.Icon, "TOPRIGHT", 4, -1)

            self.Icon:SetTexture(item.icon)
            self.Icon:SetWidth(28)

            self.ItemSubType:SetText(binding.itemSubType)

            self.Divider:Hide()


            if (binding.rightButton) then
                if (binding.rightButton == "addItem") then
                    self.AddToList:Show()
                    self.AddToList:SetScript("OnClick", function()
                        EpgpPlus.Api.OpenAddItemContextMenu(self.AddToList, binding.itemID)
                    end)
                end
                if (binding.rightButton == "delete") then
                    self.DeleteItem:Show()
                    self.DeleteItem:SetScript("OnClick", function()
                        EpgpPlus.Callbacks:TriggerEvent("List_OnItemDeleted", binding.itemID, binding.listID)
                    end)
                end

            end

        end

    end

end
function EpgpPlusEncounterItem:ResetDataBinding()
    self.Label:SetText(nil)
    self.ItemSubType:SetText(nil)
    self.Icon:SetTexture(nil)
    self.AddToList:Hide()
    self.DeleteItem:Hide()
    self.Highlight:Hide()
    self.itemID = nil;
    self:SetScript("OnMouseDown", nil)
end

EpgpPlusBasicListMixin = {}
function EpgpPlusBasicListMixin:SetupButton(data)
    self:SetHeight(data.height)
    self.Label:SetText(data.label)
    self:SetScript("OnMouseDown", function()
        data.onClick(self)
    end)
    self.id = data.id;
end



--[[
    Basic mixin to show a label or itemLink, can be passed a script
]]
EpgpPlusBasicListItemMixin = {}
function EpgpPlusBasicListItemMixin:OnLoad()
    self:HookScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)
end
function EpgpPlusBasicListItemMixin:SetDataBinding(binding, height)
    self:SetHeight(height)
    if binding.label then
        self.Label:SetText(binding.label)
    end
    if binding.justifyH then
        self.Label:SetJustifyH(binding.justifyH)
    else
        self.Label:SetJustifyH("CENTER")
    end
    if binding.itemLink then
        self.Label:SetText(binding.itemLink)
        self:HookScript("OnEnter", function()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(binding.itemLink)
            GameTooltip:Show()
        end)
    end
    if binding.onMouseDown then
        self:SetScript("OnMouseDown", function()
            binding.onMouseDown(self, binding)
        end)
    end
end

function EpgpPlusBasicListItemMixin:ResetDataBinding()
    self.Label:SetText("")
end


local CommentInputLabel = "Add note (optional)";

EpgpPlusGuildMemberListMixin = {}
function EpgpPlusGuildMemberListMixin:OnLoad()
    self.BottomDivider:SetTexelSnappingBias(0)
    self.BottomDivider:SetSnapToPixelGrid(false)

    self.InventoryButtons = {}
    
    local lastButton;
    for k, slot in ipairs(EpgpPlus.Constants.InventorySlots) do
        if (slot.slot ~= "TABARDSLOT") then
            local button = CreateFrame("Button", nil, self);
            button:SetNormalTexture(slot.icon)
            button:SetSize(16, 16)
            if lastButton == nil then
                button:SetPoint("LEFT", self.PR, "RIGHT", 10, 0)
            else
                button:SetPoint("LEFT", lastButton, "RIGHT", 2, 0)
            end
            lastButton = button;
            self.InventoryButtons[slot.slot] = button;
            button:Hide()

            button:SetScript("OnLeave", function()
                GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
            end)

            button:SetScript("OnEnter", function()
                if button.link then
                    GameTooltip:SetOwner(button, "ANCHOR_TOPRIGHT")
                    GameTooltip:SetHyperlink(button.link)
                    GameTooltip:Show()
                end
            end)
        end
    end

    -- self:RegisterEvent("GUILD_ROSTER_UPDATE")
    -- self:SetScript("OnEvent", function()
    --     if self:IsVisible() then
    --         self:UpdatePoints()
    --     end
    -- end)

    EpgpPlus.Callbacks:RegisterCallback("Database_OnPlayerInfoChanged", self.UpdateEquipment, self)
    EpgpPlus.Callbacks:RegisterCallback("OnPlayerPointsChanged_Event", self.OnPlayerPointsChanged_Event, self)

    self:SetScript("OnMouseDown", function(f, hw)
        if C_GuildInfo.CanEditOfficerNote() and (hw == "RightButton") then

            --probably a more specific method to this but for now just keep a ref to the input boxes on creation
            local pointsInput, commentInput, epCheckbox, gpCheckbox;

            MenuUtil.CreateContextMenu(f, function(_, rootDescription)

                rootDescription:CreateTitle(Ambiguate(self.character.name, "short"), RAID_CLASS_COLORS[self.character.class])
                rootDescription:CreateDivider()

                rootDescription:CreateTitle("Adjust Points")
                local numberInput = rootDescription:CreateTemplate("InputBoxTemplate")
                numberInput:AddInitializer(function(inputBox)
                    inputBox:SetSize(180, 22)
                    inputBox:SetText("Enter +/- number")
                    inputBox:SetAutoFocus(false)
                    pointsInput = inputBox;
                end)

                local noteInput = rootDescription:CreateTemplate("InputBoxTemplate")
                noteInput:AddInitializer(function(inputBox)
                    inputBox:SetSize(180, 22)
                    inputBox:SetText(CommentInputLabel)
                    inputBox:SetAutoFocus(false)
                    commentInput = inputBox;
                end)

                local epCheck = rootDescription:CreateTemplate("EpgpPlusMenuCheckbox")
                epCheck:AddInitializer(function(cb)
                    epCheckbox = cb.Checkbox;
                    cb.Checkbox:SetScript("OnClick", function()
                        if gpCheckbox then
                            gpCheckbox:SetChecked(not cb.Checkbox:GetChecked())
                        end
                    end)
                    cb:SetSize(180, 26)
                    cb.Checkbox.label:SetText("EP")
                    cb.Checkbox:SetChecked(false)
                end)

                local gpCheck = rootDescription:CreateTemplate("EpgpPlusMenuCheckbox")
                gpCheck:AddInitializer(function(cb)
                    gpCheckbox = cb.Checkbox;
                    cb.Checkbox:SetScript("OnClick", function()
                        if epCheckbox then
                            epCheckbox:SetChecked(not cb.Checkbox:GetChecked())
                        end
                    end)
                    cb:SetSize(180, 26)
                    cb.Checkbox.label:SetText("GP")
                    cb.Checkbox:SetChecked(false)
                end)

                local changeEP = rootDescription:CreateButton("Apply change", function()
                    --print(pointsInput:GetText(), commentInput:GetText(), epCheckbox:GetChecked(), gpCheckbox:GetChecked())

                    local pointType;
                    if (epCheckbox:GetChecked() == true) then
                        pointType = "ep";
                    elseif (gpCheckbox:GetChecked() == true) then
                        pointType = "gp";
                    end
                    local pointValue = tonumber(pointsInput:GetText())
                    if type(pointValue) == "number" then

                        local commentInputText = commentInput:GetText();
                        if (commentInputText == CommentInputLabel) then
                            commentInputText = "Manual adjustment";
                        end
                        
                        -- local comment = EpgpPlus.Api.CreateLogEntry(
                        --     EpgpPlus.Api.GetPlayerRealmName(), 
                        --     4, 
                        --     self.character.name, 
                        --     pointType, 
                        --     pointValue, 
                        --     "", 
                        --     commentInputText, 
                        --     GetServerTime()
                        -- )
                        
                        StaticPopup_Show("EpgpPlusConfirmDialog", "Confirm changes", nil, {
                            callback = function()
                                EpgpPlus.Api.AdjustGuildMembersPoints({[self.character.name] = true}, pointType, pointValue, commentInputText)
                            end,
                            onLoad = function(popup)
                                popup.ButtonContainer.Button1:Disable()
                                C_Timer.After(1, function()
                                    popup.ButtonContainer.Button1:Enable()
                                end)
                            end,
                        })
                    end

                end)

                rootDescription:CreateDivider()
                rootDescription:CreateButton("Reset points", function()
                    local commentInputText = commentInput:GetText();
                    if (commentInputText == CommentInputLabel) then
                        commentInputText = "Manual Reset";
                    end
                    StaticPopup_Show("EpgpPlusConfirmDialog", "Confirm changes", nil, {
                        callback = function()
                            EpgpPlus.Api.SetGuildMembersPoints({[self.character.name] = true}, 0, 1, commentInputText)
                        end,
                        onLoad = function(popup)
                            popup.ButtonContainer.Button1:Disable()
                            C_Timer.After(1, function()
                                popup.ButtonContainer.Button1:Enable()
                            end)
                        end,
                    })
                end)

                -- rootDescription:CreateButton("Request Equipment", function()
                
                -- end)

            end)
        end
    end)
end

function EpgpPlusGuildMemberListMixin:SetDataBinding(binding, height)
    self.character = binding;

    self.ClassIcon:SetAtlas(string.format("classicon-%s", self.character.class:lower()))
    self.Name:SetText(Ambiguate(self.character.name, "short"))
    self.Name:SetTextColor(RAID_CLASS_COLORS[self.character.class]:GetRGB())
    self.Level:SetText(self.character.level)
    self.Rank:SetText(self.character.rank)
    self.PublicNote:SetText(self.character.publicNote)

    self:UpdatePoints()
    self:UpdateEquipment()
end

function EpgpPlusGuildMemberListMixin:ResetDataBinding()
    self.character = nil;
    self:Clear()
end

function EpgpPlusGuildMemberListMixin:Clear()
    self.ItemLevel:SetText("")
    self.Name:SetText("")
    self.Level:SetText("")
    self.Rank:SetText("")
    self.PublicNote:SetText("")
    self.ClassIcon:SetTexture(nil)
    self.EP:SetText("")
    self.GP:SetText("")
    self.PR:SetText("")
end

function EpgpPlusGuildMemberListMixin:OnPlayerPointsChanged_Event()
    self:UpdatePoints()
end

function EpgpPlusGuildMemberListMixin:UpdatePoints()
    self.EP:SetText("")
    self.GP:SetText("")
    self.PR:SetText("")
    if self.character and self.character.name then

        local newPoints = EpgpPlus.Api.GetGuildMembersPoints(self.character.name)

        if newPoints then

            if type(newPoints.ep) == "number" then
                self.EP:SetText(newPoints.ep)
            end
            if type(newPoints.gp) == "number" then
                self.GP:SetText(newPoints.gp)
            end
            if type(newPoints.pr) == "number" then
                self.PR:SetText(string.format("%.3f", newPoints.pr))
            end

        end
    end
end

function EpgpPlusGuildMemberListMixin:UpdateEquipment()
    for _, button in pairs(self.InventoryButtons) do
        button.link = nil;
        button:Hide()
    end
    if self.character then
        local equipment = EpgpPlus.Database:GetCharacterInfo(self.character.name, "equipment")
        if equipment then
            for slot, link in pairs(equipment) do
                if self.InventoryButtons[slot] and link then
                    local icon = select(5, C_Item.GetItemInfoInstant(link))
                    self.InventoryButtons[slot]:SetNormalTexture(icon)
                    self.InventoryButtons[slot].link = link;
                    self.InventoryButtons[slot]:Show()
                end
            end
        end
    end
end





EpgpPlusLogEntryListviewItemMixin = {}
function EpgpPlusLogEntryListviewItemMixin:SetDataBinding(binding, height)
    self:SetHeight(height)
    self.Time:SetText(date("%Y-%m-%d %H:%M:%S", binding.tme))
    self.Source:SetText(Ambiguate(binding.src, "short"))
    self.Action:SetText(EpgpPlus.Constants.LogActionTakenComments[binding.actn] or "-")
    self.Target:SetText(Ambiguate(binding.tar, "short"))
    self.ItemLink:SetText(binding.il)
    self.PointChanged:SetText(binding.pchn)
    self.PointsDelta:SetText(binding.pdel)
end

function EpgpPlusLogEntryListviewItemMixin:ResetDataBindings()
    
end