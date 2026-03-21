

local addonName, EpgpPlus = ...;



--[[
    Mixin for the loot treeview list

    This template is used for 3 situations
    * addItem - this is the main use and shows a + button on the right for the user to add the item to a list
    * deleteItem - this is used when viewing a list, shows a "bin" style button and enables the user to delete the item from the list
    * reserveItem - this is used when showing loot for the active raid session, it shows a "dice" style button which allows
        the user to set/toggle the item as a reserve

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

            if (binding.rightButton == "reserveItem") then

                local playersReservingItem = EpgpPlus.Api.GetReservesForItemID(binding.itemID)
                if #playersReservingItem > 0 then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Players Reserving item:", 1,1,1)
                end
                for _, player in ipairs(playersReservingItem) do
                    if player.class and RAID_CLASS_COLORS[player.class] then
                        GameTooltip:AddLine(RAID_CLASS_COLORS[player.class]:WrapTextInColorCode(player.name))
                    else
                        GameTooltip:AddLine(player.name)
                    end

                end

            end

            GameTooltip:Show()

            self.Highlight:Show()
        end)

        local item = EpgpPlus.Database.db.itemDb[binding.itemID];

        if item then

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





--local editPublicNote = CanEditPublicNote()
--[[

EpgpPlus.Api.GetGuildRosterIndex(nameOrGUID)

                local rosterIndex = addon.api.getGuildRosterIndex(self.character.data.name)
                if type(rosterIndex) == "number" then
                    SetGuildRosterSelection(rosterIndex)
                    StaticPopup_Show("SET_GUILDOFFICERNOTE");
                end
]]

EpgpPlusGuildMemberListMixin = {}
function EpgpPlusGuildMemberListMixin:OnLoad()
    self.BottomDivider:SetTexelSnappingBias(0)
    self.BottomDivider:SetSnapToPixelGrid(false)

    EpgpPlus.Callbacks:RegisterCallback("Comms_OnPlayerEquipmentChanged", self.Comms_OnPlayerEquipmentChanged, self)

    -- self.AwardEP:SetScript("OnClick", function()
    --     if CanEditPublicNote() and self.character then
    --         local rosterIndex = EpgpPlus.Api.GetGuildRosterIndex(self.character.name)
    --         if rosterIndex then
    --             SetGuildRosterSelection(rosterIndex)
    --             --StaticPopup_Show("SET_GUILDOFFICERNOTE");


    --             --[[
                
    --                 Test data at the moment
    --             ]]

    --             --GuildRosterSetOfficerNote(GetGuildRosterSelection(), encoded)
    --         end
    --     end
    -- end)

    self:SetScript("OnMouseDown", function(f, hw)
        if (hw == "RightButton") then
            MenuUtil.CreateContextMenu(f, function(_, rootDescription)

                rootDescription:CreateTitle(Ambiguate(self.character.name, "short"))
                rootDescription:CreateDivider()

                --effort points
                local epButton = rootDescription:CreateButton("Effort Points", function() end)
                epButton:CreateButton("Add", function()
                
                end)
                epButton:CreateButton("Remove", function()
                
                end)

                --gear points
                local gpButton = rootDescription:CreateButton("Gear Points", function() end)
                gpButton:CreateButton("Add", function()
                
                end)
                gpButton:CreateButton("Remove", function()
                
                end)

            end)
        end
    end)
end

function EpgpPlusGuildMemberListMixin:SetEPGP(epgp)
    if CanEditPublicNote() and self.character then
        local rosterIndex = EpgpPlus.Api.GetGuildRosterIndex(self.character.name)
        if rosterIndex then
            SetGuildRosterSelection(rosterIndex)
            --StaticPopup_Show("SET_GUILDOFFICERNOTE");


            --GuildRosterSetOfficerNote(GetGuildRosterSelection(), encoded)
        end
    end
end

function EpgpPlusGuildMemberListMixin:Comms_OnPlayerEquipmentChanged(payload, sender)
    if self.character and (Ambiguate(self.character.name, "short") == sender) then
        self.ItemLevel:SetText(string.format("%.1f", payload.ilvl))
    end
end

function EpgpPlusGuildMemberListMixin:SetDataBinding(binding, height)
    self.character = binding;
    self:UpdateCharacter()
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
function EpgpPlusGuildMemberListMixin:UpdateCharacter()
    self:Clear()
    if self.character then
        self.ClassIcon:SetAtlas(string.format("classicon-%s", self.character.class:lower()))
        self.Name:SetText(Ambiguate(self.character.name, "short"))
        self.Name:SetTextColor(RAID_CLASS_COLORS[self.character.class]:GetRGB())
        self.Level:SetText(self.character.level)
        self.Rank:SetText(self.character.rank)
        self.PublicNote:SetText(self.character.publicNote)

        self.EP:SetText(self.character.ep)
        self.GP:SetText(self.character.gp)
        self.PR:SetText(string.format("%.2f", self.character.pr))

        -- for _, fs in ipairs(self.fontstrings) do
        --     fs:SetTextColor(RAID_CLASS_COLORS[self.character.class]:GetRGB())
        -- end

    end
end