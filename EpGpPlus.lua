


local addonName, EpgpPlus = ...;

if not CharacterModelSceneMixin then
    CharacterModelSceneMixin = CreateFromMixins(PanningModelSceneMixin);
end

local SelectedExpansion, SelectedInstance, SelectedEncounter;


EpgpPlusMixin = {}


local EventsToRegister = {
    "PLAYER_ENTERING_WORLD",
    "ADDON_LOADED",
    "GROUP_ROSTER_UPDATE",
    "UNIT_INVENTORY_CHANGED",
    "LOOT_READY",
    "UPDATE_INSTANCE_INFO",
}

function EpgpPlusMixin:OnLoad()

    EpgpPlusUiPortrait:SetTexture("Interface/AddOns/EpgpPlus/Logo.jpg")

    for _, event in ipairs(EventsToRegister) do
        self:RegisterEvent(event)
    end

    self.Tab4.FullNuke:SetScript("OnClick", function()
        EpgpPlus.Database:Init(true)
    end)

    self:RegisterForDrag("LeftButton")

    self.Resize:Init(self, 600, 400, 1000, 620)

    SLASH_SOFTRESPLUS1 = '/epgpp'
    SlashCmdList['SOFTRESPLUS'] = function(msg)
        self:Show()
    end

    local function OnTabSelected(tabID)
        self:SelectTab(tabID)
    end

    --create nav bar home button
    local homeData = {
		name = HOME,
        id = 1,
		OnClick = function()
            OnTabSelected(0)
		end,
	}
    NavBar_Initialize(self.navBar, "NavButtonTemplate", homeData, self.navBar.home, self.navBar.overflow);

    self:SelectTab(1)

    self.Tab3:SetScript("OnShow", function()
        self:GuildTab_OnShow()
    end)

    --[[
        Initially the filter and search were intended  to be global
        with a redesign these were parented to the loot tab instead
    ]]
    local itemFilterIsSelectedFunc = function(data)
        return EpgpPlus.Database:GetItemFilters(data.classID, data.subClassID)
    end

    local itemFilterSetSelectedFunc = function(data)
        EpgpPlus.Database:SetItemFilters(data.classID, data.subClassID)
    end

    self.SearchItems:SetScript("OnEnterPressed", function(eb)
        self:SearchLoot(eb:GetText())
    end)

    self.ItemFilter:SetScript("OnClick", function()
        MenuUtil.CreateContextMenu(self.ItemFilter, function(_, rootDescription)
            for _, info in ipairs(EpgpPlus.ItemFilters) do
                local button = rootDescription:CreateCheckbox(C_Item.GetItemClassInfo(info.classID), itemFilterIsSelectedFunc, itemFilterSetSelectedFunc, {classID = info.classID, subClassID = "all"})
                if info.subClassIDs then
                    for _, subClassID in ipairs(info.subClassIDs) do
                        local label = C_Item.GetItemSubClassInfo(info.classID, subClassID)
                        button:CreateCheckbox(label, itemFilterIsSelectedFunc, itemFilterSetSelectedFunc, {classID = info.classID, subClassID = subClassID})
                    end
                end
            end
        end)
    end)

    EpgpPlus.Callbacks:RegisterCallback("Database_OnInitialized", self.Database_OnInitialized, self)
    EpgpPlus.Callbacks:RegisterCallback("Database_OnConfigChanged", self.LoadGuildMembers, self)
    EpgpPlus.Callbacks:RegisterCallback("Database_OnNewListCreated", self.Database_OnNewListCreated, self)
    EpgpPlus.Callbacks:RegisterCallback("Database_OnListDeleted", self.Database_OnListDeleted, self)
    EpgpPlus.Callbacks:RegisterCallback("Database_OnItemFiltersChanged", self.Database_OnItemFiltersChanged, self)

    EpgpPlus.Callbacks:RegisterCallback("List_OnItemsChanged", self.List_OnItemsChanged, self)

    EpgpPlus.Callbacks:RegisterCallback("Comms_OnPlayerEquipmentChanged", self.Comms_OnPlayerEquipmentChanged, self)

    table.insert(UISpecialFrames, self:GetName())

end

function EpgpPlusMixin:Database_OnInitialized()
    self:InitializeInstanceTab()
    self:InitializeSessionTab()
    self:InitializeGuildTab()
    EpgpPlus.Comms:Init()
end


function EpgpPlusMixin:SearchLoot()
    local searchText = self.SearchItems:GetText()

    local items;
    if SelectedInstance and SelectedEncounter then
       items = EpgpPlus.Api.GetEncounterLoot(SelectedInstance, SelectedEncounter)
    end

    if SelectedInstance then
        items = EpgpPlus.Api.GetAllInstanceLoot(SelectedInstance)
    end

    local results = EpgpPlus.Database:Search(searchText, items)

    --[[
        search loot should show the addItem button on item templates
    ]]
    self:LoadLoot(results, "addItem")
end



function EpgpPlusMixin:SelectTab(tabID)
    for _, f in ipairs(self.childTabs) do
        f:Hide()
    end
    if self["Tab"..tabID] then
        self["Tab"..tabID]:Show()
    end

    NavBar_Reset(self.navBar)

    self.SearchItems:Hide()
    self.ItemFilter:Hide()

    if tabID == 2 then
        NavBar_AddButton(self.navBar, {
            id = 2,
            name = "Loot",
        })
        self.SearchItems:Show()
        self.ItemFilter:Show()
    end

    if tabID == 3 then
        NavBar_AddButton(self.navBar, {
            id = 2,
            name = "Guild EPGP",
        })
    end

end

function EpgpPlusMixin:OnEvent(event, ...)

    if (event == "ADDON_LOADED") and (... == addonName) then
        EpgpPlus.Database:Init()
    end

    if (event == "GROUP_ROSTER_UPDATE") then
       self:GuildTab_OnGroupRosterChanged()
    end

    if (event == "UPDATE_INSTANCE_INFO") then
       self:CheckBossKill()
    end

    if (event == "PLAYER_ENTERING_WORLD") then
       self:LoadHomeTab()
    end

    -- if (event == "UNIT_INVENTORY_CHANGED") and (... == "player") then
    --     if IsInRaid(LE_PARTY_CATEGORY_HOME) then
    --         local myEquipment = EpgpPlus.Api.GetUnitEquipment("player")
    --         local ilvl = EpgpPlus.Api.GetPlayerItemLevel()
    --         EpgpPlus.Comms:SendGroupMessage("OnPlayerEquipmentChanged", {
    --             equipment = myEquipment,
    --             ilvl = ilvl,
    --         })
    --     end
    -- end

end

function EpgpPlusMixin:LoadHomeTab()

    local Home = self["Tab1"];

    Home.CharacterModel.ControlFrame:SetModelScene(Home.CharacterModel)

    local _, class = UnitClass("player");
    Home.Background:SetAtlas(string.format("legionmission-complete-background-%s", class:lower()))

    Home.SelectLoot:SetScript("OnClick", function()
        self:SelectTab(2)
    end)

    Home.GuildEPGP:SetScript("OnClick", function()
        self:SelectTab(3)
    end)

end


function EpgpPlusMixin:InitializeInstanceTab()

    local DataProvider = CreateTreeDataProvider()
    self.Tab1.ExpansionMenu.scrollView:SetDataProvider(DataProvider)

    self.ExpansionNodes = {}

    self.ListsNode = DataProvider:Insert({
        height = 96,
        template = "SoftResExpansionSelectTemplate",
        initializer = function(f)
            f.Label:SetText("Lists")
            f.BackgroundArt:SetAtlas("groupfinder-background-dungeons") --groupfinder-button-dungeons
            f.Highlight:SetAtlas("search-select")
            f.Label:SetFontObject("GameFontNormalHuge2")
            f.NewList:Show()
            f.NewList:SetScript("OnClick", function()
                EpgpPlus.Database:NewList()
            end)
            f:SetScript("OnMouseDown", function()
                self.ListsNode:ToggleCollapsed()
                if not self.ListsNode:IsCollapsed() then
                    self.Tab1.ExpansionHeaderImage:SetAtlas("groupfinder-button-dungeons")
                    self.Tab1.ListHeader:SetText("Lists")
                end

                SelectedExpansion = nil;
                SelectedInstance = nil;
                SelectedEncounter = nil;
            end)
        end,
    })

    local allLists = EpgpPlus.Database:GetAllLists()
    if allLists then
        for _, list in ipairs(allLists) do
            self:InsertItemList(list)
        end
    end

    self.ListsNode:ToggleCollapsed()

    --close all nodes, if provided args attempt to open and set selected nodes
    local function ToggleAllNodes(expansionName, instanceName, encounterName)
        for expNme, node in pairs(self.ExpansionNodes) do
            if not node:IsCollapsed() then
                node:ToggleCollapsed()
            end

            for instNme, node2 in pairs(self.ExpansionNodes[expNme]) do
                if not node2:IsCollapsed() then
                    node2:ToggleCollapsed()
                end

                for encNme, node3 in pairs(self.ExpansionNodes[expNme][instNme]) do
                    if not node3:IsCollapsed() then
                        node3:ToggleCollapsed()
                    end
                end
            end
        end

        SelectedInstance = nil;
        SelectedInstance = nil;
        SelectedEncounter = nil;

        if expansionName and self.ExpansionNodes[expansionName] then
            self.ExpansionNodes[expansionName]:ToggleCollapsed()

            SelectedExpansion = expansionName;

            if instanceName and self.ExpansionNodes[expansionName][instanceName] then
                self.ExpansionNodes[expansionName][instanceName]:ToggleCollapsed()

                SelectedInstance = instanceName;

                if encounterName and self.ExpansionNodes[expansionName][instanceName][encounterName] then
                    --self.ExpansionNodes[expansionName][instanceName][encounterName]:ToggleCollapsed()

                    SelectedEncounter = encounterName;
                end
            end
        end
    end

    for i = 1, 3 do
        local expansionName = _G["EXPANSION_NAME"..(i-1)]
        self.ExpansionNodes[expansionName] = DataProvider:Insert({
            template = "SoftResExpansionSelectTemplate",
            height = 96,
            initializer = function(f)
                f.Label:SetText(expansionName)
                f.BackgroundArt:SetAtlas(EpgpPlus.ExpansionArt.Large[i])
                f.Highlight:SetAtlas("search-select")
                f.Label:SetFontObject("GameFontNormalHuge2")
                f.NewList:Hide()
                f:SetScript("OnMouseDown", function()
                    
                    ToggleAllNodes(expansionName)
                    
                    self.Tab1.ExpansionHeaderImage:SetAtlas(EpgpPlus.ExpansionArt.Headers[i])
                    self.Tab1.ListHeader:SetText(expansionName)

                    self:ClearLoot()

                end)
            end,
        })

        if EpgpPlus.ExpansionInstances[i] then
            for _, instanceName in ipairs(EpgpPlus.ExpansionInstances[i]) do

                self.ExpansionNodes[expansionName][instanceName] = self.ExpansionNodes[expansionName]:Insert({
                    height = 46,
                    template = "SoftResExpansionSelectTemplate",
                    initializer = function(f)
                        f.BackgroundArt:SetAtlas("clickcastlist-buttonbackground")
                        f.Highlight:SetAtlas("search-select")
                        f.Label:SetText(instanceName)
                        f.NewList:Hide()
                        f.Label:SetFontObject("GameFontNormalLarge")
                        f:SetScript("OnMouseDown", function()

                            ToggleAllNodes(expansionName, instanceName)

                            self.Tab1.ListHeader:SetText(string.format("%s - %s", expansionName, instanceName))

                            self:LoadLoot(nil, "addItem")

                        end)
                    end,
                })


                local encounters = EpgpPlus.Api.GetInstanceEncounters(instanceName)
                for _, encounter in ipairs(encounters) do
                    self.ExpansionNodes[expansionName][instanceName][encounter] = self.ExpansionNodes[expansionName][instanceName]:Insert({
                        height = 32,
                        template = "SoftResExpansionSelectTemplate",
                        initializer = function(f)
                            f.BackgroundArt:SetAtlas("groupfinder-button-cover")
                            f.Highlight:SetAtlas("search-select")
                            f.Label:SetText(encounter)
                            f.NewList:Hide()
                            f.Label:SetFontObject("GameFontNormal")

                            f:SetScript("OnMouseDown", function()

                                --no need to toggle all nodes here as this is to load the loot list rather than to navigate
                                SelectedEncounter = encounter;

                                self:LoadLoot(nil,"addItem")

                            end)
                        end,
                    })
                end
            end
        end
    end


end






--[[
    List functions
]]
function EpgpPlusMixin:Database_OnListDeleted()

    self.ListsNode:Flush()

    local allLists = EpgpPlus.Database:GetAllLists()
    if allLists then
        for _, list in ipairs(allLists) do
            self:InsertItemList(list)
        end
    end
end

function EpgpPlusMixin:Database_OnNewListCreated(list)
    self:InsertItemList(list)
end

function EpgpPlusMixin:InsertItemList(list)
    if self.ListsNode then
        self.ListsNode:InsertNodeAtIndex({
            height = 46,
            template = "EpgpPlusItemListMenuTemplate",
            initializer = function(f)
                f.BackgroundArt:SetAtlas("clickcastlist-buttonbackground")
                f.Highlight:SetAtlas("search-select")
                f.Label:SetText(list.name)
                f.Label:SetFontObject("GameFontNormalLarge")
                f:SetScript("OnMouseDown", function()
                    self:LoadLoot(list.items, "delete", list.id)
                    self.Tab1.ListHeader:SetText(list.name)
                end)
                f.Edit:Hide()
                f.Edit:SetScript("OnClick", function()
                    MenuUtil.CreateContextMenu(self, function(self, rootDescription)
                        rootDescription:CreateTitle("Edit")
                        rootDescription:CreateDivider()
                        rootDescription:CreateButton("Rename", function()
                            f.Label:Hide()
                            f.ListNameEditBox:SetText(list.name)
                            f.ListNameEditBox:Show()
                            f.ListNameEditBox:SetFocus()
                        end)
                        rootDescription:CreateButton("Delete", function()
                            EpgpPlus.Database:DeleteList(list)
                        end)
                    end)
                end)
                f.ListNameEditBox:SetScript("OnEnterPressed", function()
                    f.ListNameEditBox:Hide()
                    f.Label:SetText(list.name)
                    f.Label:Show()
                end)
                f.ListNameEditBox:SetScript("OnTextChanged", function(eb)
                    list.name = eb:GetText()
                end)
            end,
        }, 1)
    end
end













function EpgpPlusMixin:ClearLoot()
    self.Tab1.EncounterItemList.scrollView:SetDataProvider(CreateTreeDataProvider())
end


local function SortItems(a, b)
    if a.itemEquipLoc == b.itemEquipLoc then
        if a.itemType == b.itemType then
            return a.itemSubType < b.itemSubType
        else
            return a.itemType < b.itemType
        end
    else
        return a.itemEquipLoc < b.itemEquipLoc
    end
end

--check loot items and perform sorting and preparing template 
function EpgpPlusMixin:LoadLoot(loot, rightButton, listID, lootTableOverwrite)

    --DevTools_Dump({loot})
    if (loot == nil) then
        local items;
        if SelectedInstance and SelectedEncounter then
            items = EpgpPlus.Api.GetEncounterLoot(SelectedInstance, SelectedEncounter)
        end

        if SelectedInstance and (SelectedEncounter == nil) then
            items = EpgpPlus.Api.GetAllInstanceLoot(SelectedInstance)
        end

        loot = EpgpPlus.Database:Search("", items)
    end

    self.previousLoot = loot;
    self.previousRightButton = rightButton;

    if lootTableOverwrite then
        self.previousLoot = lootTableOverwrite;
    end

    local dataProvider = CreateTreeDataProvider()
    local temp = {}

    for _, itemID in ipairs(loot) do
        local id, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
        table.insert(temp, {
            itemID = itemID,
            itemType = itemType,
            itemSubType = itemSubType,
            itemEquipLoc = itemEquipLoc,
        })
    end


    table.sort(temp, SortItems)

    local nodes = {}

    for _, item in ipairs(temp) do

        --kinda nasty but as we're reusing the same template this just lets us control the visible buttons
        item.rightButton = rightButton;
        item.listID = listID;

        if item.itemEquipLoc and _G[item.itemEquipLoc] then
            local header = _G[item.itemEquipLoc]

            if nodes[header] == nil then
                nodes[header] = dataProvider:Insert({
                    header = header,
                })
            end

            nodes[header]:Insert(item)

        else
            if nodes.Unknown == nil then
                nodes.Unknown = dataProvider:Insert({
                    header = "-",
                })
            end
            nodes.Unknown:Insert(item)
        end

    end

    self.Tab1.EncounterItemList.scrollView:SetDataProvider(dataProvider)
end

--get loot for encounter and forward on to be loaded into a dataProvider
function EpgpPlusMixin:LoadEncounterLoot(instanceName, encounter, expansionIndex, rightButton)

    self.Tab1.ListHeader:SetText(string.format("%s - %s", instanceName, encounter))
    if expansionIndex then
        self.Tab1.ExpansionHeaderImage:SetAtlas(EpgpPlus.ExpansionArt.Headers[expansionIndex])
    end

    local loot = EpgpPlus.Api.GetEncounterLoot(instanceName, encounter)

    self:LoadLoot(loot, rightButton)

end

--re load the ui list to reflect list item changes
function EpgpPlusMixin:List_OnItemsChanged(list, reloadItems)
    if reloadItems then
        self:LoadLoot(list.items, "delete", list.id)
    end
end

function EpgpPlusMixin:Database_OnItemFiltersChanged()
    self:SearchLoot()
end










--[[

    Guild EPGP

    This system doesnt use the db to store player points, these are stored in the officers notes to preserve data security

    Logging will be stored in the db

]]
local rankFilterPrefixS = "guildControlRankFilter_%s"
local GuildMemberNodes = {};
local FilteredGuildMembers = {};
local GroupRosterMap = {};
function EpgpPlusMixin:InitializeGuildTab()


    local ranks = EpgpPlus.Api.GetGuildRanks()
    for _, rank in ipairs(ranks) do
        local hasConfig = EpgpPlus.Database:GetConfig(rankFilterPrefixS:format(rank))
        if hasConfig == nil then
            EpgpPlus.Database:SetConfig(rankFilterPrefixS:format(rank), true)
        end
    end

    local function SetRankFunc(rank)
        local rankFilter = EpgpPlus.Database:GetConfig(rankFilterPrefixS:format(rank))
        EpgpPlus.Database:SetConfig(rankFilterPrefixS:format(rank), (not rankFilter))
    end
    local function IsRankSetFunc(rank)
        return EpgpPlus.Database:GetConfig(rankFilterPrefixS:format(rank))
    end

    self.Tab3.GuildMemberControls.FilterRanks:SetScript("OnClick", function(btn)
        local ranks = EpgpPlus.Api.GetGuildRanks()
        MenuUtil.CreateContextMenu(btn, function(_, rootDescription)
            for _, rank in ipairs(ranks) do
                rootDescription:CreateCheckbox(rank, IsRankSetFunc, SetRankFunc, rank)
            end
        end)
    end)

    local minLevelFilter = EpgpPlus.Database:GetConfig("guildControlMinLevelFilter");
    if minLevelFilter == nil then
        EpgpPlus.Database:SetConfig("guildControlMinLevelFilter", 50);
    end
    minLevelFilter = EpgpPlus.Database:GetConfig("guildControlMinLevelFilter");

    local function OnSliderValueChanged(slider, delta)
        if delta then
            local currentValue = slider:GetValue()
            local newValue = math.floor(currentValue+delta);
            slider:SetValue(newValue)
            slider.value:SetText(newValue)
            EpgpPlus.Database:SetConfig("guildControlMinLevelFilter", newValue);
        else
            local newValue = math.floor(slider:GetValue())
            slider.value:SetText(newValue)
            EpgpPlus.Database:SetConfig("guildControlMinLevelFilter", newValue);
        end
    end

    self.Tab3.GuildMemberControls.FilterMinLevel.label:SetText("Min Level")
    self.Tab3.GuildMemberControls.FilterMinLevel.value:SetText(minLevelFilter)
    self.Tab3.GuildMemberControls.FilterMinLevel:SetMinMaxValues(1,80)
    self.Tab3.GuildMemberControls.FilterMinLevel:SetValue(minLevelFilter)
    self.Tab3.GuildMemberControls.FilterMinLevel:SetScript("OnMouseWheel", function(sldr, delta)
        OnSliderValueChanged(sldr, delta)
    end)
    self.Tab3.GuildMemberControls.FilterMinLevel:SetScript("OnValueChanged", function(sldr)
        OnSliderValueChanged(sldr)
    end)

    self.Tab3.GuildMemberControls.ToggleMembers:SetScript("OnClick", function()
        self:LoadGuildMembers()
    end)

end

function EpgpPlusMixin:GuildTab_OnShow()

    --send guild channel request
    EpgpPlus.Comms:SendGuildMessage("OnPlayerEquipmentRequested")

    self:LoadGuildMembers()
end

function EpgpPlusMixin:Comms_OnPlayerEquipmentChanged(payload, sender)
    if GuildMemberNodes[sender] then
        
    end

    --store the latest data in the directory
    EpgpPlus.Database:UpdateCharacterDirectory(sender, "equipment", payload.equipment)
    EpgpPlus.Database:UpdateCharacterDirectory(sender, "ilvl", payload.ilvl)
end

function EpgpPlusMixin:GuildTab_OnGroupRosterChanged()

    for i = 1, 40 do
        local unit = string.format("raid%s", i)
        local name = UnitName(unit)
        if name then
            GroupRosterMap[name] = unit
        end
    end

    --when the roster changes transmit player equipment data to all group members
    if IsInRaid(LE_PARTY_CATEGORY_HOME) then
        local myEquipment = EpgpPlus.Api.GetUnitEquipment("player")
        local ilvl = EpgpPlus.Api.GetPlayerItemLevel()
        EpgpPlus.Comms:SendGroupMessage("OnPlayerEquipmentChanged", {
            equipment = myEquipment,
            ilvl = ilvl,
        })
    end

    self:LoadGuildMembers()
end

function EpgpPlusMixin:LoadGuildMembers()

    if self.Tab3.GuildMemberList:IsVisible() then

        local ranks = EpgpPlus.Api.GetGuildRanks()
        local function GetRankIndex(rank)
            for index, rnk in ipairs(ranks) do
                if rnk == rank then
                    return index;
                end
            end
        end

        local showAllGuildMembers = self.Tab3.GuildMemberControls.ToggleMembers:GetChecked()
        local groupMembers = EpgpPlus.Api.GetGroupRoster(true)

        -- if ViragDevTool_AddData then
        --     ViragDevTool_AddData(groupMembers, addonName.."groupMembers")
        -- end

        local function FilterToggle(member)
            if showAllGuildMembers == true then
                return true;
            else
                --print(member.name)
                if groupMembers[Ambiguate(member.name, "short")] then
                    return true;
                end
            end
        end

        local minLevel = EpgpPlus.Database:GetConfig("guildControlMinLevelFilter")

        local function FilterRank(member)
            return EpgpPlus.Database:GetConfig(rankFilterPrefixS:format(member.rank));
        end

        local function FilterLevel(member)
            return member.level >= minLevel;
        end

        local guildMembers = EpgpPlus.Api.GetGuildMembers()
        GuildMemberNodes = {}
        FilteredGuildMembers = {};

        for k, member in ipairs(guildMembers) do
            if FilterLevel(member) and FilterRank(member) and FilterToggle(member) then
                table.insert(FilteredGuildMembers, member)
            end
        end

        table.sort(FilteredGuildMembers, function(a, b)
            if a.pr and b.pr then
                if a.pr == b.pr then
                    return a.ep > b.ep;
                else
                    return a.pr > b.pr;
                end
            else
                if GetRankIndex(a.rank) == GetRankIndex(b.rank) then
                    return a.level > b.level;
                else
                    return GetRankIndex(a.rank) < GetRankIndex(b.rank)
                end
            end
        end)

        local DataProvider = CreateTreeDataProvider()
        for _, member in ipairs(FilteredGuildMembers) do
            --GuildMemberNodes[member.name] = DataProvider:Insert(member)
            GuildMemberNodes[member.name] = DataProvider:Insert({
                height = 22,
                template = "EpgpPlusGuildMemberListTemplate",
                initializer = function(f)
                    f:SetDataBinding(member)
                end,
            })

        end
        self.Tab3.GuildMemberList.scrollView:SetDataProvider(DataProvider);

    end


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