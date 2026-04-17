


local addonName, EpgpPlus = ...;


--[[

    In an effort to improve point sync across guild members a new approach was devised.

    GUILD_ROSTER_UPDATE seems to fire when officer notes change (amoung other things) which
    means we can listen for it and know to fetch updated points

    The addon api had so far done lots of roster looping and trying to get points or use sync data

    So now instead sync data will be used as the db and kept updated via the PointsListener

    When applying guild wide changes to points the PointsListener.ignoreEvent must be set to true

    Full guild scans should happen when
    -logging in
    -after guild wide changes

]]



local function OnSliderValueChanged(slider, delta, minValue)
    local newValue;
    if (delta ~= nil) then
        local currentValue = slider:GetValue()
        newValue = math.floor(currentValue+delta);
        if minValue and (newValue < minValue) then
            newValue = minValue
        end
        slider:SetValue(newValue)
    else
        newValue = math.floor(slider:GetValue())
        if minValue and (newValue < minValue) then
            newValue = minValue
        end
    end
    slider.value:SetText(newValue)
    return newValue;
end


local PointsListener;
local function CreatePointsListener()
    PointsListener = PointsListener or CreateFrame("Frame")
    PointsListener:RegisterEvent("GUILD_ROSTER_UPDATE")
    PointsListener.members = { ep = {}, gp = {}, }
    PointsListener.lastTrigger = 0;
    PointsListener.throttle = 5;
    PointsListener.changes = {}
    PointsListener.elapsed = 0;

    --[[
        OnUpdate has a 5 second limiter via the self.throttle value

        if any changes were detected then send them and reset the cache
    ]]

    PointsListener:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed;
        if self.elapsed > self.throttle then
            if (next(self.changes) ~= nil) then

                -- local dataLength = 0;
                -- for k, v in pairs(self.changes) do
                --     dataLength = dataLength + 1;
                -- end
                --print("Sending point change data: "..dataLength.." entries")

                EpgpPlus.Comms:SendGuildMessage("OnPlayerPointsChanged", self.changes)
                self.changes = {}
            end
            self.elapsed = 0;
        end
    end)

    PointsListener:SetScript("OnEvent", function(self)

        --lets not spam the crap out of comms where every guild member gets decay for example
        --using a throttle instead now
        -- if (self.ignoreEvent == true) then
        --     return;
        -- end

        if (C_GuildInfo.CanEditOfficerNote() ~= true) then
            return;
        end

        if IsInGuild() and GetGuildInfo("player") then
            C_GuildInfo.GuildRoster()
            local numMembers = GetNumGuildMembers()
            for i = 1, numMembers do
                local name, rankName, _, level, _, _, publicNote, officerNote, _, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(i)
                local ep, gp, pr;
                local hasChanged = false

                if (officerNote == "") then
                    SetGuildRosterSelection(i)
                    GuildRosterSetOfficerNote(i, "0,1")
                    ep = 0;
                    gp = 1;
                    hasChanged = true

                else
                    if (officerNote ~= nil) and (officerNote ~= " ") and (officerNote:find(",", nil, true)) then
                        ep, gp = strsplit(",", officerNote)
                        ep = tonumber(ep)
                        gp = tonumber(gp)


                        if (self.members.ep[name] == nil) then
                            self.members.ep[name] = ep;
                        else
                            if (self.members.ep[name] ~= ep) then
                                --oldEp = self.members.ep[name];
                                self.members.ep[name] = ep;
                                hasChanged = true;
                            end
                        end

                        if (self.members.gp[name] == nil) then
                            self.members.gp[name] = gp;
                        else
                            if (self.members.gp[name] ~= gp) then
                                --oldGp = self.members.gp[name];
                                self.members.gp[name] = gp;
                                hasChanged = true;
                            end
                        end


                        --we can compare the current syncData as well to know if this player should trigger the changed event
                        local syncData = EpgpPlus.Database:GetEpGpSyncData(name)
                        if (syncData == nil) then
                            hasChanged = true;
                        else
                            if (syncData.ep == nil) or (syncData.gp == nil) then
                                hasChanged = true;
                            end
                            if syncData.ep and (syncData.ep ~= ep) then
                                hasChanged = true;
                            end
                            if syncData.gp and (syncData.gp ~= gp) then
                                hasChanged = true;
                            end
                        end
                    end
                end


                if (hasChanged == true) then
                    self.changes[name] = officerNote;
                    EpgpPlus.Callbacks:TriggerEvent("OnPlayerPointsChanged_Internal", name, ep, gp)
                    --print(string.format("OnPlayerPointsChanged_Internal > [%s] Old: (%d,%d) New: (%d,%d)", name, oldEp, oldGp, ep, gp))
                end
            end
        end

    end)
end


--little helper func, maybe move to .Api 
local function SendMyEquipment()
    local myEquipment = EpgpPlus.Api.GetUnitEquipment("player")
    EpgpPlus.Comms:SendGroupMessage("OnPlayerEquipmentChanged", {
        equipment = myEquipment,
        player = EpgpPlus.Api.GetPlayerRealmName()
    })
end



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
    "UPDATE_INSTANCE_INFO",
    "GUILD_ROSTER_UPDATE",
}

function EpgpPlusMixin:OnLoad()

    self.initialSyncDataSent = false;

    GameTooltip:HookScript("OnTooltipSetItem", function(tt)
        local itemName, link = tt:GetItem()
        if link then
            local itemID = C_Item.GetItemInfoInstant(link)
            GameTooltip_AddColoredLine(tt, string.format("Item ID: %d", itemID), BLUE_FONT_COLOR)
        end
    end)

    EpgpPlusUiPortrait:SetTexture("Interface/AddOns/EpgpPlus/Logo.jpg")

    for _, event in ipairs(EventsToRegister) do
        self:RegisterEvent(event)
    end

    self:RegisterForDrag("LeftButton")

    --self.Resize:Init(self, 600, 400, 1000, 620)

    SLASH_EPGPPLUS1 = '/epgpp'
    SlashCmdList['EPGPPLUS'] = function(msg)
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
            OnTabSelected(1)
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
            for _, info in ipairs(EpgpPlus.Constants.ItemFilters) do
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
    EpgpPlus.Callbacks:RegisterCallback("Database_OnConfigChanged", self.Database_OnConfigChanged, self)
    EpgpPlus.Callbacks:RegisterCallback("Database_OnNewListCreated", self.Database_OnNewListCreated, self)
    EpgpPlus.Callbacks:RegisterCallback("Database_OnListDeleted", self.Database_OnListDeleted, self)
    EpgpPlus.Callbacks:RegisterCallback("Database_OnItemFiltersChanged", self.Database_OnItemFiltersChanged, self)
    EpgpPlus.Callbacks:RegisterCallback("Database_OnSyncDataReceived", self.Database_OnSyncDataReceived, self)
    EpgpPlus.Callbacks:RegisterCallback("OnPlayerPointsChanged_Event", self.OnPlayerPointsChanged_Event, self)
    EpgpPlus.Callbacks:RegisterCallback("List_OnItemsChanged", self.List_OnItemsChanged, self)
    EpgpPlus.Callbacks:RegisterCallback("Database_OnLogEvent", self.Database_OnLogEvent, self)

    table.insert(UISpecialFrames, self:GetName())

    C_Timer.After(2, function()
        self:Show()
    end)

    self.Tab1.SelectLoot:SetScript("OnClick", function()
        self:SelectTab(2)
    end)

    self.Tab1.GuildEPGP:SetScript("OnClick", function()
        self:SelectTab(3)
    end)

    self.Tab1.Options:SetScript("OnClick", function()
        self:SelectTab(4)
    end)

    self.Tab1.CharacterModel.ControlFrame:SetModelScene(self.Tab1.CharacterModel)

    local _, class = UnitClass("player");
    self.Tab1.Background:SetAtlas(string.format("legionmission-complete-background-%s", class:lower()))
    --Home.Background:SetAtlas(string.format("dressingroom-background-%s", class:lower()))

end

function EpgpPlusMixin:Database_OnConfigChanged(key, val)
    
    --guild roster changes
    if (key:find("guildControl", nil, true)) then
        self:FilterGuildMembers()
    end

    --listener
    if key == "pointsListenerThrottle" then
        if PointsListener then
            PointsListener.throttle = val;
        end
    end

end

function EpgpPlusMixin:Database_OnSyncDataReceived()
    self:FilterGuildMembers()
    self.EventText:SetText("Database_OnSyncDataReceived")
end

function EpgpPlusMixin:OnPlayerPointsChanged_Event()
    self:FilterGuildMembers()
    self.EventText:SetText("OnPlayerPointsChanged_Event")
end

function EpgpPlusMixin:Database_OnInitialized()
    self:InitializeInstanceUI()
    self:InitializeGuildUI()
    EpgpPlus.Comms:Init()

    self.Tab4.Content.General.SafetyMode:SetChecked(EpgpPlus.Database:GetConfig("safetyModeActive"))
    self.Tab4.Content.General.SafetyMode:SetScript("OnClick", function(cb)
        EpgpPlus.Database:SetConfig("safetyModeActive", cb:GetChecked())
        self:SetTitle(string.format("Safety Mode Enabled: %s", tostring(cb:GetChecked())))
    end)
    self:SetTitle(string.format("Safety Mode Enabled: %s", tostring(EpgpPlus.Database:GetConfig("safetyModeActive"))))

    self:InitializeOptionsUI()
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
            OnClick = function()
                self.Tab2.ExpansionMenu.scrollView:SetDataProvider(self.DataProviders.MenuNodes)
            end,
        })
        self.SearchItems:Show()
        self.ItemFilter:Show()
        self.Tab2.ExpansionMenu.scrollView:SetDataProvider(self.DataProviders.MenuNodes)
        self:ClearLoot()
    end

    if tabID == 3 then
        NavBar_AddButton(self.navBar, {
            id = 2,
            name = "Guild EPGP",
        })
    end

    if tabID == 4 then
        NavBar_AddButton(self.navBar, {
            id = 2,
            name = "Options",
        })
    end

end

function EpgpPlusMixin:OnEvent(event, ...)

    if (event == "ADDON_LOADED") and (... == addonName) then
        EpgpPlus.Database:Init()
    end

    if (event == "ADDON_LOADED") and (... == "ViragDevTool") then
        if ViragDevTool_AddData then
            ViragDevTool_AddData(EpgpPlusSavedVar, addonName)
        end
    end

    if (event == "GROUP_ROSTER_UPDATE") then
        SendMyEquipment()
        self:GuildTab_OnGroupRosterChanged()
    end

    if (event == "GUILD_ROSTER_UPDATE") then
        if self.initialSyncDataSent == false then
            local syncData = EpgpPlus.Api.BuildSyncData()
            if syncData then
                EpgpPlus.Database:StoreEpGPSyncData("", syncData, "Initial login sync")
            end
            self.initialSyncDataSent = true;
        end
        if PointsListener == nil then
            CreatePointsListener()
        end
    end

    if (event == "UPDATE_INSTANCE_INFO") then

    end

    if (event == "PLAYER_ENTERING_WORLD") then
        local isInitialLogin, isReload = ...;
        if isInitialLogin then
            SendMyEquipment()
        end
    end

    if (event == "UNIT_INVENTORY_CHANGED") and (... == "player") then
        if IsInRaid(LE_PARTY_CATEGORY_HOME) == true then

            --unregister the event as each change will trigger this and using addons to swap whole gear sets will make this go nuts
            self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
            C_Timer.After(1, function()
                SendMyEquipment()
                self:RegisterEvent("UNIT_INVENTORY_CHANGED")
            end)
        end
    end

end

function EpgpPlusMixin:InitializeInstanceUI()

    --reset the nav bar and add in the loot button
    local function ResetNavBar()
        NavBar_Reset(self.navBar)
        NavBar_AddButton(self.navBar, {
            id = 2,
            name = "Loot",
            OnClick = function()
                self.Tab2.ExpansionMenu.scrollView:SetDataProvider(self.DataProviders.MenuNodes)
            end,
        })

        SelectedExpansion = nil;
        SelectedInstance = nil;
        SelectedEncounter = nil;

        -- self.SearchItems:Show()
        -- self.ItemFilter:Show()
        -- self.Tab2.ExpansionMenu.scrollView:SetDataProvider(self.DataProviders.MenuNodes)
        -- self:ClearLoot()
    end




    self.DataProviders = {
        MenuNodes = CreateTreeDataProvider(),
    }

    self.Tab2.ExpansionMenu.scrollView:SetDataProvider(self.DataProviders.MenuNodes)

    self.ExpansionNodes = {}

    --add list option to menu
    self.ListsNode = self.DataProviders.MenuNodes:Insert({
        height = 96,
        template = "EpgpExpansionSelectTemplate",
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
                    self.Tab2.ExpansionHeaderImage:SetAtlas("groupfinder-button-dungeons")
                    self.Tab2.ListHeader:SetText("Lists")
                end
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


    for i = 1, 3 do
        local expansionName = _G["EXPANSION_NAME"..(i-1)]

        local instances = EpgpPlus.Api.GetInstanceNames(i-1)

        self.DataProviders[expansionName] = CreateTreeDataProvider();

        self.DataProviders.MenuNodes:Insert({
            template = "EpgpExpansionSelectTemplate",
            height = 96,
            initializer = function(f)
                f.Label:SetText(expansionName)
                f.BackgroundArt:SetAtlas(EpgpPlus.Constants.ExpansionArt.Large[i])
                f.Highlight:SetAtlas("search-select")
                f.Label:SetFontObject("GameFontNormalHuge2")
                f.NewList:Hide()
                f:SetScript("OnMouseDown", function()

                    SelectedExpansion = i;
                    
                    ResetNavBar()
                    NavBar_AddButton(self.navBar, {
                        id = 3,
                        name = expansionName,
                    })

                    --load the dataProvider to show a list of instances
                    self.Tab2.ExpansionMenu.scrollView:SetDataProvider(self.DataProviders[expansionName])
                    
                    self.Tab2.ExpansionHeaderImage:SetAtlas(EpgpPlus.Constants.ExpansionArt.Headers[i])
                    self.Tab2.ListHeader:SetText(expansionName)

                    self:ClearLoot()

                end)
            end,
        })


        for i = #instances, 1, -1 do
            
            local instanceName = instances[i]

            self.DataProviders[expansionName..instanceName] = CreateTreeDataProvider();

            self.DataProviders[expansionName]:Insert({
                height = 46,
                template = "EpgpExpansionSelectTemplate",
                initializer = function(f)
                    f.BackgroundArt:SetAtlas("clickcastlist-buttonbackground")
                    f.Highlight:SetAtlas("search-select")
                    f.Label:SetText(instanceName)
                    f.NewList:Hide()
                    f.Label:SetFontObject("GameFontNormalLarge")
                    f:SetScript("OnMouseDown", function()

                        ResetNavBar()
                        NavBar_AddButton(self.navBar, {
                            id = 3,
                            name = expansionName,
                            OnClick = function()
                                self.Tab2.ExpansionMenu.scrollView:SetDataProvider(self.DataProviders[expansionName])
                                SelectedInstance = nil;
                                SelectedEncounter = nil;
                            end,
                        })
                        NavBar_AddButton(self.navBar, {
                            id = 4,
                            name = instanceName,
                        })

                        self.Tab2.ExpansionMenu.scrollView:SetDataProvider(self.DataProviders[expansionName..instanceName])

                        self.Tab2.ListHeader:SetText(string.format("%s - %s", expansionName, instanceName))

                        SelectedInstance = instanceName;

                        self:LoadLoot(nil, "addItem")

                    end)
                end,
            })

            local encounters = EpgpPlus.Api.GetInstanceEncounters(instanceName)
            for _, encounter in ipairs(encounters) do

                --self.DataProviders[expansionName..instanceName..encounter] = CreateTreeDataProvider();

                self.DataProviders[expansionName..instanceName]:Insert({
                    height = 32,
                    template = "EpgpExpansionSelectTemplate",
                    initializer = function(f)
                        f.BackgroundArt:SetAtlas("groupfinder-button-cover")
                        f.Highlight:SetAtlas("search-select")
                        f.Label:SetText(encounter)
                        f.NewList:Hide()
                        f.Label:SetFontObject("GameFontNormal")

                        f:SetScript("OnMouseDown", function()

                            ResetNavBar()
                            NavBar_AddButton(self.navBar, {
                                id = 3,
                                name = expansionName,
                                OnClick = function()
                                    self.Tab2.ExpansionMenu.scrollView:SetDataProvider(self.DataProviders[expansionName])
                                    SelectedInstance = nil;
                                    SelectedEncounter = nil;
                                end,
                            })
                            NavBar_AddButton(self.navBar, {
                                id = 4,
                                name = instanceName,
                                OnClick = function()
                                    self.Tab2.ExpansionMenu.scrollView:SetDataProvider(self.DataProviders[expansionName..instanceName])
                                    SelectedEncounter = nil;
                                end,
                            })
                            NavBar_AddButton(self.navBar, {
                                id = 4,
                                name = encounter,
                            })

                            --self.Tab2.ExpansionMenu.scrollView:SetDataProvider(self.DataProviders[expansionName..instanceName..encounter])

                            SelectedInstance = instanceName;
                            SelectedEncounter = encounter;

                            self:LoadLoot(nil,"addItem")

                        end)
                    end,
                })
            end

        end

    end

end

function EpgpPlusMixin:InitializeOptionsUI()

    local function SelectOptions(name)
        for _, f in ipairs(self.Tab4.Content.categories) do
            f:Hide()
        end
        if self.Tab4.Content[name] then
            self.Tab4.Content[name]:Show()
        end
    end

    local menuFrameIds = {
        General = 1,
        EffortPoints = 2,
        GearPoints = 3,
        Logs = 4,
        ImportExport = 5,
    }

    local MenuNodes = {};
    local GearPointNodes = {}
    local function CloseNodes()
        for _, node in pairs(MenuNodes) do
            if node:IsCollapsed() then

            else
                node:ToggleCollapsed()
            end
        end
        for _, node in pairs(GearPointNodes) do
            if node:IsCollapsed() then

            else
                node:ToggleCollapsed()
            end
        end
    end


    local normalR, normalG, normalB = NORMAL_FONT_COLOR:GetRGB()
    local function ResetFontLabels(frameId)
        for _, f in ipairs(self.Tab4.MenuList.scrollView.frames) do
            f.Label:SetTextColor(1,1,1)
        end

        local frame = self.Tab4.MenuList.scrollView:FindFrameByPredicate(function(f)
            return f.id == frameId
        end)
        frame.Label:SetTextColor(normalR, normalG, normalB)
    end
    
    MenuNodes.General = self.Tab4.MenuList.DataProvider:Insert({
        template = "EpgpPlusBasicListTemplate",
        height = 30,
        initializer = function(f)
            f:SetupButton({
                height = 30,
                label = "General",
                onClick = function(button)
                    SelectOptions("General")
                    CloseNodes()
                    ResetFontLabels(menuFrameIds.General)
                end,
                id = menuFrameIds.General;
            })
        end,
    })
    
    MenuNodes.EffortPoints = self.Tab4.MenuList.DataProvider:Insert({
        template = "EpgpPlusBasicListTemplate",
        height = 30,
        initializer = function(f)
            f:SetupButton({
                height = 30,
                label = "Effort Points",
                onClick = function(button)
                    SelectOptions("EffortPoints")
                    CloseNodes()
                    MenuNodes.EffortPoints:ToggleCollapsed()
                    ResetFontLabels(menuFrameIds.EffortPoints)
                end,
                id = menuFrameIds.EffortPoints;
            })
        end,
    })

    local function GetEncounterID(encounterName)
        for id, name in pairs(EpgpPlus.Constants.EncounterIDs) do
            if (name == encounterName) then
                return id;
            end
        end
    end

    for i, tbl in ipairs(EpgpPlus.Constants.DefaultEncounterEP) do
        local expansionFrameId = string.format("%d-%d", menuFrameIds.EffortPoints, i)
        local expansionName = _G["EXPANSION_NAME"..(i-1)]
        GearPointNodes[expansionName] = MenuNodes.EffortPoints:Insert({
            template = "EpgpPlusBasicListTemplate",
            height = 28,
            initializer = function(f)
                f:SetupButton({
                    height = 28,
                    label = _G["EXPANSION_NAME"..(i-1)],
                    onClick = function(button)
                        CloseNodes()
                        MenuNodes.EffortPoints:ToggleCollapsed()
                        GearPointNodes[expansionName]:ToggleCollapsed()
                        ResetFontLabels(expansionFrameId)
                    end,
                    id = expansionFrameId
                })
            end,
        })

        for k, instance in ipairs(tbl) do
            local instanceFrameId = (expansionFrameId.."-"..k)
            local instanceName = EpgpPlus.Constants.ExpansionInstances[i][k]
            GearPointNodes[expansionName.."_"..instanceName] = GearPointNodes[expansionName]:Insert({
                template = "EpgpPlusBasicListTemplate",
                height = 26,
                initializer = function(f)
                    f:SetupButton({
                        height = 26,
                        label = EpgpPlus.Constants.ExpansionInstances[i][k],
                        id = instanceFrameId,
                        onClick = function(button)
                            CloseNodes()
                            MenuNodes.EffortPoints:ToggleCollapsed()
                            GearPointNodes[expansionName]:ToggleCollapsed()
                            GearPointNodes[expansionName.."_"..instanceName]:ToggleCollapsed()
                            ResetFontLabels(instanceFrameId)

                            --load bosses into content
                            local DataProvider = CreateDataProvider()
                            self.Tab4.Content.EffortPoints.Listview.scrollView:SetDataProvider(DataProvider);
                            for encounter, data in ipairs(instance) do
                                local encounterID = GetEncounterID(data.name);

                                DataProvider:Insert({
                                    template = "EpgpPlusGearPointListviewItemTemplate",
                                    height = 28,
                                    initializer = function(bossFrame)
                                        bossFrame.Label:SetText(data.name)
                                        bossFrame.InputBox:SetText(EpgpPlus.Database:GetEncounterEP(encounterID))
                                        bossFrame.InputBox:SetScript("OnTextChanged", function(eb)
                                            local num = tonumber(eb:GetText());
                                            if num then
                                                EpgpPlus.Database:SetEncounterEP(encounterID, num)
                                            end
                                        end)
                                    end
                                })
                            end
                        end,
                    })
                end,
            })
        end
    end

    
    MenuNodes.GearPoints = self.Tab4.MenuList.DataProvider:Insert({
        template = "EpgpPlusBasicListTemplate",
        height = 30,
        initializer = function(f)
            f:SetupButton({
                height = 30,
                label = "Gear Points",
                onClick = function(button)
                    SelectOptions("GearPoints")
                    CloseNodes()
                    ResetFontLabels(menuFrameIds.GearPoints)

                    --EpgpPlus.Constants.GearPoints
                    local DataProvider = CreateDataProvider()
                    for _, info in ipairs(EpgpPlus.Constants.GearPoints) do
                        DataProvider:Insert({
                            template = "EpgpPlusGearPointListviewItemTemplate",
                            height = 32,
                            initializer = function(slotFrame)
                                slotFrame.Label:SetText(string.format("%s\n|cff848484[%s]|r", _G[info.slot], info.slot))
                                slotFrame.InputBox:SetText(EpgpPlus.Database:GetGP(info.slot))
                                slotFrame.InputBox:SetScript("OnTextChanged", function(eb)
                                    local num = tonumber(eb:GetText());
                                    if num then
                                        EpgpPlus.Database:SetGP(info.slot, num)
                                    end
                                end)
                            end
                        })
                    end
                    self.Tab4.Content.GearPoints.Listview.scrollView:SetDataProvider(DataProvider)
                end,
                id = menuFrameIds.GearPoints,
            })
        end,
    })
    
    MenuNodes.Logs = self.Tab4.MenuList.DataProvider:Insert({
        template = "EpgpPlusBasicListTemplate",
        height = 30,
        initializer = function(f)
            f:SetupButton({
                height = 30,
                label = "Logs",
                onClick = function(button)
                    SelectOptions("Logs")
                    CloseNodes()
                    ResetFontLabels(menuFrameIds.Logs)
                    self:Database_OnLogEvent()
                end,
                id = menuFrameIds.Logs,
            })
        end,
    })

    MenuNodes.ImportExport = self.Tab4.MenuList.DataProvider:Insert({
        template = "EpgpPlusBasicListTemplate",
        height = 30,
        initializer = function(f)
            f:SetupButton({
                height = 30,
                label = "Import/Export",
                onClick = function(button)
                    SelectOptions("ImportExport")
                    CloseNodes()
                    ResetFontLabels(menuFrameIds.ImportExport)
                    self.Tab4.Content.ImportExport.ImportData:Disable()
                end,
                id = menuFrameIds.ImportExport,
            })
        end,
    })


    CloseNodes()

    local content = self.Tab4.Content;

    content.General.FullNuke:SetScript("OnClick", function()
        EpgpPlus.Database:Init(true)
    end)

    content.General.PointsListenerThrottleHelp.tooltipText = EpgpPlus.Locales.PointsListenerThrottle;

    content.General.PointsListenerThrottle.label:SetText("Points Listener Throttle")
    content.General.PointsListenerThrottle:SetValue(EpgpPlus.Database:GetConfig("pointsListenerThrottle"))
    content.General.PointsListenerThrottle:SetScript("OnMouseWheel", function(sldr, delta)
        local newValue = OnSliderValueChanged(sldr, delta, 5)
        EpgpPlus.Database:SetConfig("pointsListenerThrottle", newValue);
    end)
    content.General.PointsListenerThrottle:SetScript("OnValueChanged", function(sldr)
        local newValue = OnSliderValueChanged(sldr, nil, 5)
        EpgpPlus.Database:SetConfig("pointsListenerThrottle", newValue);
    end)


    content.EffortPoints.Header:SetText(EpgpPlus.Locales.EffortPointsHeader)
    content.EffortPoints.Push:SetScript("OnClick", function()
        local data = EpgpPlus.Database:GetTable("effortPoints");
        EpgpPlus.Comms:SendGuildMessage("OnTableDataReceived", {
            tbl = "effortPoints",
            data = data,
        })
    end)

    content.GearPoints.Header:SetText(EpgpPlus.Locales.GearPointsHeader)
    content.GearPoints.Push:SetScript("OnClick", function()
        local data = EpgpPlus.Database:GetTable("gearPoints");
        EpgpPlus.Comms:SendGuildMessage("OnTableDataReceived", {
            tbl = "gearPoints",
            data = data,
        })
    end)

    content.Logs.SearchInput:SetScript("OnTextChanged", function(eb)
        self:FilterLogs()
    end)

    content.Logs.DeleteLogs:SetScript("OnClick", function()
        EpgpPlus.Database:SetTable("pointsLog", {})
        self:Database_OnLogEvent()
    end)

    content.ImportExport.EditboxScroller.EditBox:SetMaxLetters(1000000000)
    content.ImportExport.EditboxScroller.CharCount:SetShown(true);
    content.ImportExport.EditboxScroller.EditBox:ClearAllPoints()
    content.ImportExport.EditboxScroller.EditBox:SetPoint("TOPLEFT", content.ImportExport.EditboxScroller, "TOPLEFT", 0, 0)
    content.ImportExport.EditboxScroller.EditBox:SetPoint("BOTTOMRIGHT", content.ImportExport.EditboxScroller, "BOTTOMRIGHT", 0, 0)
    content.ImportExport.EditboxScroller.ScrollBar:ClearAllPoints()
    content.ImportExport.EditboxScroller.ScrollBar:SetPoint("TOPLEFT", content.ImportExport.EditboxScroller, "TOPRIGHT", 3, 4)
    content.ImportExport.EditboxScroller.ScrollBar:SetPoint("BOTTOMLEFT", content.ImportExport.EditboxScroller, "BOTTOMRIGHT", 3, -4)

    content.ImportExport.GenerateExport:SetScript("OnClick", function(btn)

        local syncData = EpgpPlus.Database:GetEpGpSyncData()

        MenuUtil.CreateContextMenu(self, function(self, rootDescription)
            rootDescription:CreateTitle("Export EPGP")
            rootDescription:CreateDivider()
            rootDescription:CreateButton("CSV", function()

                local outCSV;
                local rows = 0;
                for name, info in pairs(syncData.data) do
                    if outCSV == nil then
                        outCSV = string.format("%s,%d,%d,%d,", name, info.ep, info.gp, info.pr)

                    else
                        outCSV = string.format("%s\n%s,%d,%d,%d,", outCSV, name, info.ep, info.gp, info.pr)
                    end
                    rows = rows + 1;
                end
                content.ImportExport.EditboxScroller.EditBox:SetText(outCSV)
                content.ImportExport.EditboxInfo:SetText(string.format("CSV rows %d", rows))

            end)
            local json = rootDescription:CreateButton("JSON", function()
                local tidyData = {}
                for name, info in pairs(syncData.data) do
                    table.insert(tidyData, {
                        name = name,
                        ep = info.ep,
                        gp = info.gp,
                        pr = info.pr,
                    })
                end
                local outJSON = C_EncodingUtil.SerializeJSON(tidyData);
                content.ImportExport.EditboxScroller.EditBox:SetText(outJSON)
            end)

            json:SetTooltip(function()
                GameTooltip:AddLine("JSON")
                GameTooltip:AddLine("This format is not currently suported for importing.")
            end)
        end)
    end)

    content.ImportExport.ParseData:SetScript("OnClick", function(btn)

        self:ParseImport(content.ImportExport.EditboxScroller.EditBox:GetText())

    end)

        -- MenuUtil.CreateContextMenu(self, function(_, rootDescription)
        
        --     rootDescription:CreateTitle("Import Data")
        --     rootDescription:CreateDivider()

        --     local overwrite = rootDescription:CreateButton("Full Overwrite", function()
                
        --         self:ParseImport(content.ImportExport.EditboxScroller.EditBox:GetText())
        --     end)

        --     overwrite:SetTooltip(function()
        --         GameTooltip:AddLine("Full Overwrite")
        --         GameTooltip:AddLine("|cffffffffThis option will fully overwrite your guild EPGP data.")
        --     end)
        -- end)
    

end

local function FilterSearchTerm(term, entry)
    if (term == nil) or (term == "") then
        return true;
    end
    local src, tar, link, event = entry.src:lower(), entry.tar:lower(), entry.il:lower(), EpgpPlus.Constants.LogActionTakenComments[entry.actn]:lower();
    if (src:find(term, nil, true)) or (tar:find(term, nil, true)) or (link:find(term, nil, true)) or (event:find(term, nil, true)) then
        return true;
    end
end

function EpgpPlusMixin:FilterLogs(sort)
    local logs = EpgpPlus.Database:GetPointsLog()

    local temp = {}

    local term = self.Tab4.Content.Logs.SearchInput:GetText():lower();

    for _, entry in ipairs(logs) do
        if FilterSearchTerm(term, entry) then
            table.insert(temp, entry)
        end
    end

    if sort then
        table.sort(temp, sort)
    else
        table.sort(temp, function(a, b)
            if (a.tme == b.tme) then
                return a.src < b.src;
            else
                return a.tme > b.tme;
            end
        end)
    end

    local DataProvider = CreateDataProvider(temp)
    self.Tab4.Content.Logs.Listview.scrollView:SetDataProvider(DataProvider)
end

function EpgpPlusMixin:Database_OnLogEvent()
    self:FilterLogs()
end

function EpgpPlusMixin:ParseImport(text)

    if text and (text:find("[", nil, true)) then
        return;
    end

    if text and (text:find("{", nil, true)) then
        return;
    end

    if text and (text:find(",", nil, true)) then
        local results = EpgpPlus.Api.ParseCSV(text)

        self.Tab4.Content.ImportExport.EditboxScroller.EditBox:SetText(results.displayText)
        self.Tab4.Content.ImportExport.EditboxInfo:SetText(string.format("Results:\n|cffffffffRows In: %d\nRows Out: %d\nErrors: |cffCC1919%d|r\nPlease check the data shown below if errors exist. The data is in the format [name-realm] = 'ep,gp'.\nYou will need to correct your csv data and retry.", results.inRows, results.outRows, results.errors))

        if results.errors == 0 then
            self.Tab4.Content.ImportExport.ImportData:Enable()
            self.Tab4.Content.ImportExport.ImportData:SetScript("OnClick", function()
                EpgpPlus.Api.ImportData(results.outTbl)
            end)
        else
            self.Tab4.Content.ImportExport.ImportData:Disable()
            self.Tab4.Content.ImportExport.ImportData:SetScript("OnClick", nil)
        end

        -- local function parse(eb)
        --     eb:SetScript("OnTextChanged", nil)
        --     local guildRoster = EpgpPlus.Api.GetGuildMembersNames()
        --     local outStr = ""
        --     local lines = {strsplit("\n", eb:GetText())}
        --     for _, line in ipairs(lines) do
        --         local name = line:match("%[(.-)%]");
        --         local _, points = strsplit(" = ", line);
        --         local ep, gp = "?", "?";
        --         if guildRoster[name] then
        --             ep, gp = strsplit(",", points);
        --             if tonumber(ep) and tonumber(gp) then
        --                 if outStr == "" then
        --                     outStr = string.format("|cff40C040[%s]|r", line)
        --                 else
        --                     outStr = string.format("%s\n|cff40C040[%s]|r", outStr, line)
        --                 end

        --             else
        --                 if outStr == "" then
        --                     outStr = string.format("|cffCC1919[%s]|r", line)
        --                 else
        --                     outStr = string.format("%s\n|cffCC1919[%s]|r", outStr, line)
        --                 end
        --             end

        --         else
        --             if outStr == "" then
        --                 outStr = string.format("|cffCC1919[%s]|r", line)
        --             else
        --                 outStr = string.format("%s\n|cffCC1919[%s]|r", outStr, line)
        --             end
        --         end
        --     end

        --     eb:SetText(outStr)

        --     eb:SetScript("OnTextChanged", parse)
        -- end

        -- self.Tab4.Content.ImportExport.EditboxScroller.EditBox:SetScript("OnTextChanged", parse)

    end
end




















--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--[[
    Lists
]]
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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
                    self.Tab2.ListHeader:SetText(list.name)
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










--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--[[
    Loot dataProvider and sorting
]]
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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

function EpgpPlusMixin:ClearLoot()
    self.Tab2.EncounterItemList.scrollView:SetDataProvider(CreateTreeDataProvider())
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
                    header = "Misc",
                })
            end
            nodes.Unknown:Insert(item)
            --DevTools_Dump({item})
        end

    end

    self.Tab2.EncounterItemList.scrollView:SetDataProvider(dataProvider)
end

--get loot for encounter and forward on to be loaded into a dataProvider
function EpgpPlusMixin:LoadEncounterLoot(instanceName, encounter, expansionIndex, rightButton)

    self.Tab2.ListHeader:SetText(string.format("%s - %s", instanceName, encounter))
    if expansionIndex then
        self.Tab2.ExpansionHeaderImage:SetAtlas(EpgpPlus.Constants.ExpansionArt.Headers[expansionIndex])
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








--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--[[

    Guild EPGP

    This system doesnt use the db to store player points, these are stored in the officers notes to preserve data security

    Logging will be stored in the db

]]
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local rankFilterPrefixS = "guildControlRankFilter_%s"
local classFilterPrefixS = "guildControlClassFilter_%s"

function EpgpPlusMixin:InitializeGuildUI()

    self.GuildMemberNodes = {}
    self.FilteredGuildMembers = {}

    self:SetScript("OnShow", function()
        if C_GuildInfo.CanEditOfficerNote() == false then
            self.Tab3.GuildMemberControls.DecayOptions.ApplyDecay:Disable()
            self.Tab3.GuildMemberControls.DecayOptions.ResetPoints:Disable()
        else
            self.Tab3.GuildMemberControls.DecayOptions.ApplyDecay:Enable()
            self.Tab3.GuildMemberControls.DecayOptions.ResetPoints:Enable()
        end
    end)


    self.Tab3.GuildMemberControls.SyncOptions.Sync:SetScript("OnEnter", function(b)
        GameTooltip:SetOwner(b, "ANCHOR_TOPRIGHT")
        GameTooltip:AddLine("Sync EPGP")
        GameTooltip:AddLine("|cffffffffOfficer note access?|r sends data to guild members. Otherwise sends a\nrequest for data (requires someone with officer note access to be online!)\n\nData is updated as changes are detected, full sync isn't required everytime.")
        GameTooltip:Show()
    end)
    self.Tab3.GuildMemberControls.SyncOptions.Sync:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)
    self.Tab3.GuildMemberControls.SyncOptions.Sync:SetScript("OnClick", function(btn)
    
        --if the player is able to read officer notes then send the data across guild comms
        if C_GuildInfo.CanEditOfficerNote() then
            local syncData = EpgpPlus.Api.BuildSyncData()
            if syncData then
                --DevTools_Dump({syncData})
                EpgpPlus.Comms:SendGuildMessage("OnGuildEpGpReceieved", syncData)
            end

        --if the player cannot see officer notes request the data
        else
            EpgpPlus.Comms:SendGuildMessage("OnGuildEpGpRequested")
        end

        btn:Disable()
        btn.Cooldown:SetCooldown(GetTime(), 60)
        C_Timer.After(60, function()
            btn:Enable()
        end)
    end)


    local ranks = EpgpPlus.Api.GetGuildRanks()
    for _, rank in ipairs(ranks) do
        local hasConfig = EpgpPlus.Database:GetConfig(rankFilterPrefixS:format(rank))
        if hasConfig == nil then
            EpgpPlus.Database:SetConfig(rankFilterPrefixS:format(rank), true)
        end
    end

    for i = 1, 12 do
        local _, class = GetClassInfo(i);
        if class then
            local hasConfig = EpgpPlus.Database:GetConfig(classFilterPrefixS:format(class));
            if hasConfig == nil then
                EpgpPlus.Database:SetConfig(classFilterPrefixS:format(class), true);
            end
        end
    end

    local function SetClassFunc(class)
        local classFilter = EpgpPlus.Database:GetConfig(classFilterPrefixS:format(class))
        EpgpPlus.Database:SetConfig(classFilterPrefixS:format(class), (not classFilter))
    end
    local function IsClassSetFunc(class)
        return EpgpPlus.Database:GetConfig(classFilterPrefixS:format(class))
    end

    local function SetRankFunc(rank)
        local rankFilter = EpgpPlus.Database:GetConfig(rankFilterPrefixS:format(rank))
        EpgpPlus.Database:SetConfig(rankFilterPrefixS:format(rank), (not rankFilter))
    end
    local function IsRankSetFunc(rank)
        return EpgpPlus.Database:GetConfig(rankFilterPrefixS:format(rank))
    end

    local function IsAnyFilterActive()
        local search = self.Tab3.GuildMemberControls.RosterOptions.SearchInput:GetText()
        if #search > 0 then
            return true
        end
        if (self.Tab3.GuildMemberControls.RosterOptions.ToggleMembers:GetChecked() == false) then
            return true;
        end
        for i = 1, 12 do
            local class, engClass = GetClassInfo(i);
            if class then
                if (EpgpPlus.Database:GetConfig(classFilterPrefixS:format(engClass)) == false) then
                    return true;
                end
            end
        end
        local ranks = EpgpPlus.Api.GetGuildRanks()
        for _, rank in ipairs(ranks) do
            if (EpgpPlus.Database:GetConfig(rankFilterPrefixS:format(rank)) == false) then
                return true
            end
        end
        return false;
    end

    local sortOrders = {
        gp = true,
        ep = true,
        pr = true,
    }
    self.Tab3.GuildMemberControls.RosterOptions.Filters:SetScript("OnClick", function(btn, hw)
        --if (hw == "RightButton") then
            local ranks = EpgpPlus.Api.GetGuildRanks()
            MenuUtil.CreateContextMenu(btn, function(_, rootDescription)

                rootDescription:CreateTitle("Filters")

                local filterClassButton = rootDescription:CreateButton("Class", function() end)
                local added = {}
                for i = 1, 12 do
                    local class, engClass = GetClassInfo(i);
                    if class and (not added[class]) then
                        filterClassButton:CreateCheckbox(class, IsClassSetFunc, SetClassFunc, engClass)
                        added[class] = true;
                    end
                end

                local filterRankButton = rootDescription:CreateButton("Ranks", function() end)
                for _, rank in ipairs(ranks) do
                    filterRankButton:CreateCheckbox(rank, IsRankSetFunc, SetRankFunc, rank)
                end

                rootDescription:CreateDivider()
                rootDescription:CreateTitle("Sort Points")

                local sortEP = rootDescription:CreateButton("EP", function()
            
                    local sortFunc = function(a, b)
                        if (a.ep ~= nil) and (b.ep ~= nil) then
                            if a.ep == b.ep then
                                return a.level > b.level;
                            else
                                return a.ep > b.ep;
                            end
                        else
                            return a.level > b.level;
                        end
                    end

                    self:FilterGuildMembers(sortFunc)
                end)

                local sortGP = rootDescription:CreateButton("GP", function()
            
                    local sortFunc = function(a, b)

                        if (a.gp ~= nil) and (b.gp ~= nil) then
                            if a.gp == b.gp then
                                return a.level > b.level;
                            else
                                return a.gp > b.gp;
                            end
                        else
                            return a.level > b.level;
                        end
                    end

                    self:FilterGuildMembers(sortFunc)
                end)

                local sortPR = rootDescription:CreateButton("PR", function()
                    self:FilterGuildMembers()
                end)


            end)
        --end
    end)

    self.Tab3.GuildMemberControls.RosterOptions.SearchInput.Hint:SetText("|cffB9B9B9Search for...")
    self.Tab3.GuildMemberControls.RosterOptions.SearchInput:SetScript("OnTextChanged", function(eb)
        eb.Hint:Hide()
        local text = eb:GetText()
        if (#text > 2) then
            self.Tab3.GuildMemberControls.RosterOptions.searchInputValue = text;
        else
            self.Tab3.GuildMemberControls.RosterOptions.searchInputValue = nil;
        end
        if (#text == 0) then
            eb.Hint:Show()
            self.Tab3.GuildMemberControls.RosterOptions.searchInputValue = nil;
            C_Timer.After(5, function()
                eb:ClearFocus()
            end)
        end
        self:FilterGuildMembers()
    end)

    local minLevelFilter = EpgpPlus.Database:GetConfig("guildControlMinLevelFilter");
    if minLevelFilter == nil then
        EpgpPlus.Database:SetConfig("guildControlMinLevelFilter", 50);
    end
    minLevelFilter = EpgpPlus.Database:GetConfig("guildControlMinLevelFilter");

    self.Tab3.GuildMemberControls.RosterOptions.FilterMinLevel.label:SetText("Min Level")
    self.Tab3.GuildMemberControls.RosterOptions.FilterMinLevel.value:SetText(minLevelFilter)
    self.Tab3.GuildMemberControls.RosterOptions.FilterMinLevel:SetMinMaxValues(1,80)
    self.Tab3.GuildMemberControls.RosterOptions.FilterMinLevel:SetValue(minLevelFilter)
    self.Tab3.GuildMemberControls.RosterOptions.FilterMinLevel:SetScript("OnMouseWheel", function(sldr, delta)
        local newValue = OnSliderValueChanged(sldr, delta)
        EpgpPlus.Database:SetConfig("guildControlMinLevelFilter", newValue);
    end)
    self.Tab3.GuildMemberControls.RosterOptions.FilterMinLevel:SetScript("OnValueChanged", function(sldr)
        local newValue = OnSliderValueChanged(sldr)
        EpgpPlus.Database:SetConfig("guildControlMinLevelFilter", newValue);
    end)

    self.Tab3.GuildMemberControls.RosterOptions.ToggleMembers:SetScript("OnClick", function()
        self:FilterGuildMembers()
    end)

    self.Tab3.GuildMemberControls.RosterOptions.ToggleMembers:SetChecked(true)

    local r, g, b = LINK_FONT_COLOR:GetRGB()
    --self.Tab3.GuildMemberControls.SyncOptions.Source:SetTextColor(r, g, b)
    self.Tab3.GuildMemberControls.SyncOptions.Info:SetTextColor(r, g, b)

    local decayPercent = EpgpPlus.Database:GetConfig("epgpControlDecayPercent");
    if decayPercent == nil then
        EpgpPlus.Database:SetConfig("epgpControlDecayPercent", 10);
    end
    decayPercent = EpgpPlus.Database:GetConfig("epgpControlDecayPercent");

    self.Tab3.GuildMemberControls.DecayOptions.DecayValueSlider.label:SetText("Value")
    self.Tab3.GuildMemberControls.DecayOptions.DecayValueSlider.value:SetText(decayPercent)
    self.Tab3.GuildMemberControls.DecayOptions.DecayValueSlider:SetMinMaxValues(0,100)
    self.Tab3.GuildMemberControls.DecayOptions.DecayValueSlider:SetValue(decayPercent)
    self.Tab3.GuildMemberControls.DecayOptions.DecayValueSlider:SetScript("OnMouseWheel", function(sldr, delta)
        local newValue = OnSliderValueChanged(sldr, delta)
        EpgpPlus.Database:SetConfig("epgpControlDecayPercent", newValue);
    end)
    self.Tab3.GuildMemberControls.DecayOptions.DecayValueSlider:SetScript("OnValueChanged", function(sldr)
        local newValue = OnSliderValueChanged(sldr)
        EpgpPlus.Database:SetConfig("epgpControlDecayPercent", newValue);
    end)


    self.Tab3.GuildMemberControls.DecayOptions.Help.tooltipText = EpgpPlus.Locales.DecayAndResetHelp;

    self.Tab3.GuildMemberControls.DecayOptions.ApplyDecay:SetScript("OnClick", function()

        --PointsListener.ignoreEvent = true

        local decayGP = self.Tab3.GuildMemberControls.DecayOptions.GearPointCheckBox:GetChecked()
        local decayEP = self.Tab3.GuildMemberControls.DecayOptions.EffortPointCheckBox:GetChecked()
        local decayPercentValue = tonumber(self.Tab3.GuildMemberControls.DecayOptions.DecayValueSlider.value:GetText())

        local members = {}
        for k, v in ipairs(self.FilteredGuildMembers) do
            members[v.name] = true;
        end

        local dialogText;
        if (IsAnyFilterActive() == true) then
            dialogText = "\n\nYou have filters active\n\nApply decay at %d%% ?\n ";
        else
            dialogText = "\n\nApply Decay at %d%%\n "
        end

        StaticPopup_Show("EpgpPlusConfirmDialog", string.format(dialogText, decayPercentValue), nil, {
            callback = function()
                if decayPercentValue > 0 then
                    decayPercentValue = decayPercentValue / 100;
                else
                    decayPercentValue = 0;
                end
                EpgpPlus.Api.ApplyGuildDecay(decayPercentValue, decayEP, decayGP, members)
                --PointsListener.ignoreEvent = nil;
            end,
            onLoad = function(popup)
                popup.AlertIcon:SetAtlas("services-icon-warning")
                popup.AlertIcon:Show()
                popup.ButtonContainer.Button1:Disable()
                C_Timer.After(1, function()
                    popup.ButtonContainer.Button1:Enable()
                end)
            end,
        })

    end)

    self.Tab3.GuildMemberControls.DecayOptions.ResetPoints:SetScript("OnClick", function()
    
        local newGP = self.Tab3.GuildMemberControls.DecayOptions.GearPointCheckBox:GetChecked()
        local newEp = self.Tab3.GuildMemberControls.DecayOptions.EffortPointCheckBox:GetChecked()
        local newValue = tonumber(self.Tab3.GuildMemberControls.DecayOptions.DecayValueSlider.value:GetText())

        --PointsListener.ignoreEvent = true

        local members = {}
        for k, v in ipairs(self.FilteredGuildMembers) do
            members[v.name] = true;
        end

        local newEpValue, newGpValue;

        local dialogText = "";

        if (IsAnyFilterActive() == true) then
            dialogText = "\n\nYou have filters active\n ";
        end

        if (newGP == true) and (newEp == true) then
            dialogText = dialogText..string.format("\n\nReset EP and GP to %d\n ", newValue);
            newEpValue = newValue;
            newGpValue = newValue;
        else
            if (newEp == true) then
                dialogText = dialogText..string.format("\n\nReset EP to %d\n ", newValue);
                newEpValue = newValue;
            elseif (newGP == true) then
                dialogText = dialogText..string.format("\n\nReset GP to %d\n ", newValue)
                newGpValue = newValue;
            end
        end

        StaticPopup_Show("EpgpPlusConfirmDialog", dialogText, nil, {
            callback = function()
                EpgpPlus.Api.SetGuildMembersPoints(members, newEpValue, newGpValue, "Reset Points")
                --PointsListener.ignoreEvent = nil;
            end,
            onLoad = function(popup)
                popup.AlertIcon:SetAtlas("services-icon-warning")
                popup.AlertIcon:Show()
                popup.ButtonContainer.Button1:Disable()
                C_Timer.After(1, function()
                    popup.ButtonContainer.Button1:Enable()
                end)
            end,
        })

    
    end)

end

function EpgpPlusMixin:GuildTab_OnShow()
    self:FilterGuildMembers()
end


function EpgpPlusMixin:GuildTab_OnGroupRosterChanged()
    self:FilterGuildMembers()
end


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Sort functions
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
local function FilterToggle(member, showAllGuildMembers, groupMembers)
    if showAllGuildMembers == true then
        return true;
    else
        --print(member.name)
        if groupMembers[Ambiguate(member.name, "short")] then
            return true;
        end
    end
end

local function FilterRank(member)
    return EpgpPlus.Database:GetConfig(rankFilterPrefixS:format(member.rank));
end

local function FilterClass(member)
    return EpgpPlus.Database:GetConfig(classFilterPrefixS:format(member.class));
end

local function FilterLevel(member, minLevel)
    return member.level >= minLevel;
end

local function FilterSearchTerm(member, term)
    term = (term and term:lower());
    if term == nil then
        return true;
    end
    if member.name:lower():find(term, nil, true) then
        return true;
    end
    if member.publicNote:lower():find(term, nil, true) then
        return true;
    end
end


function EpgpPlusMixin:FilterGuildMembers(sortFunc)

    if self.Tab3.GuildMemberList:IsVisible() then

        self.GuildMemberNodes = {}
        self.FilteredGuildMembers = {};

        local function GetRankIndex(rank)
            local ranks = EpgpPlus.Api.GetGuildRanks()
            for index, rnk in ipairs(ranks) do
                if rnk == rank then
                    return index;
                end
            end
        end

        local minLevel = EpgpPlus.Database:GetConfig("guildControlMinLevelFilter")

        --this api will get player data from thje guild roster and then use sync data for points data
        local guildMembers, syncTime, syncSource = EpgpPlus.Api.GetGuildMembers()
        if type(guildMembers) ~= "table" then
            self:LoadGuildMembers()
            return
        end
        local groupMembers = EpgpPlus.Api.GetGroupRoster(true)
        local showAllGuildMembers = self.Tab3.GuildMemberControls.RosterOptions.ToggleMembers:GetChecked()


        --local r, g, b = GREEN_FONT_COLOR:GetRGB()
        local r, g, b = LINK_FONT_COLOR:GetRGB()
        self.Tab3.GuildMemberControls.SyncOptions.Info:SetTextColor(r, g, b)
        local timeFormatted = tostring(date("%c", syncTime))
        timeFormatted = timeFormatted:sub(1, (#timeFormatted - 5))
        self.Tab3.GuildMemberControls.SyncOptions.Info:SetText(string.format("Full sync last recieved:\nSource: %s\nTime: %s", syncSource, timeFormatted))

        local searchText = self.Tab3.GuildMemberControls.RosterOptions.searchInputValue

        for k, member in ipairs(guildMembers) do
            if FilterSearchTerm(member, searchText) and FilterLevel(member, minLevel) and FilterRank(member) and FilterToggle(member, showAllGuildMembers, groupMembers) and FilterClass(member) then
                table.insert(self.FilteredGuildMembers, member)
            end
        end

        if sortFunc then
            table.sort(self.FilteredGuildMembers, sortFunc)
        else
            table.sort(self.FilteredGuildMembers, function(a, b)
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
        end

        self:LoadGuildMembers()
    end


end

function EpgpPlusMixin:LoadGuildMembers()
    local DataProvider = CreateTreeDataProvider()
    for _, member in ipairs(self.FilteredGuildMembers) do
        self.GuildMemberNodes[member.name] = DataProvider:Insert({
            height = 22,
            template = "EpgpPlusGuildMemberListTemplate",
            initializer = function(f)
                f:SetDataBinding(member)
            end,
        })

    end
    self.Tab3.GuildMemberList.scrollView:SetDataProvider(DataProvider);
end

























--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--[[
    Looting UI
]]
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



local events = {
    "LOOT_READY",
    "LOOT_OPENED",
    "LOOT_CLOSED",
    "LOOT_SLOT_CLEARED",
    "ENCOUNTER_END",
}

EpgpPlusMasterLootMixin = {}

function EpgpPlusMasterLootMixin:OnLoad()

    EpgpPlusMasterLootUiPortrait:SetTexture("Interface/AddOns/EpgpPlus/Logo.jpg")

    self:RegisterForDrag("LeftButton")

    self.Resize:Init(self, 400, 250, 500, 800)

    for _, event in ipairs(events) do
        self:RegisterEvent(event)
    end

    EpgpPlus.Callbacks:RegisterCallback("OnLootDataReceived", self.OnLootDataReceived, self)
    EpgpPlus.Callbacks:RegisterCallback("OnLootItemRoll", self.OnLootItemRoll, self)
    EpgpPlus.Callbacks:RegisterCallback("OnLootWindowClosed", self.OnLootWindowClosed, self)
    EpgpPlus.Callbacks:RegisterCallback("OnPlayerPointsChanged_Event", self.OnPlayerPointsChanged_Event, self)
    EpgpPlus.Callbacks:RegisterCallback("OnPlayerPointsChanged_Internal", self.OnPlayerPointsChanged_Internal, self)

    table.insert(UISpecialFrames, self:GetName())

    C_Timer.After(2, function()
        self:Show()
    end)
end

function EpgpPlusMasterLootMixin:OnEvent(event, ...)

    if (event == "LOOT_OPENED") and (EpgpPlus.Api.IsMasterLooter() == true) then
        self:OnLootOpened()
        -- LootFrame:ClearAllPoints()
        -- LootFrame:SetClampedToScreen(false)
        -- LootFrame:SetPoint("RIGHT", UIParent, "LEFT", -10, 0)
    end

    --if the ML isn't looting then nobody can do anything as slot indexing might change
    if (event == "LOOT_CLOSED") and (EpgpPlus.Api.IsMasterLooter() == true) then
        EpgpPlus.Comms:SendGroupMessage("OnLootWindowClosed")
    end

    if (event == "ENCOUNTER_END") then

        SendMyEquipment()

        if (EpgpPlus.Api.IsMasterLooter() == true) then

            local encounterID, encounterName, difficultyID, groupSize, success = ...;

            if EpgpPlus.Constants.EncounterIDs[encounterID] and (success == 1) then

                local ep = EpgpPlus.Database:GetEncounterEP(encounterID);
                
                local isSafetyModeActive = EpgpPlus.Database:GetConfig("safetyModeActive");

                if isSafetyModeActive == true then
                    print("+++++ Safety Mode Active +++++ [ENCOUNTER_END]")
                    print(string.format("[EPGPP] %s defeated, awarding %d EP", encounterName, ep))
                else
                    self:AwardEP(ep)
                    print(string.format("[EPGPP] %s defeated, awarding %d EP", encounterName, ep))
                end
                
            end

        end
    end
end


function EpgpPlusMasterLootMixin:AwardEP(epValue)
    local groupRoster = EpgpPlus.Api.GetGroupRoster(true);
    EpgpPlus.Api.AdjustGuildMembersPoints(groupRoster, "ep", epValue, "", nil, 7)
end


---ML has opened the corpse loot, transmit the data to group members
function EpgpPlusMasterLootMixin:OnLootOpened()
    local targetLoot = EpgpPlus.Api.GetTargetLoot()
    EpgpPlus.Comms:SendGroupMessage("OnLootDataReceived", targetLoot)
end

---ML has closed the loot window, close UI to groiup members
function EpgpPlusMasterLootMixin:OnLootWindowClosed()
    self.LootListview.scrollView:SetDataProvider(CreateTreeDataProvider())
    self:Hide()
end



--[[
    loot item template helper functions
]]

local function ResetLootNode(f)
    f.id = nil;
    f.ItemLink:SetText("")
    f.GearPointLabel:SetText("")
    f.RollCount:SetText("Rolls: 0")
    f.EquipLocation:SetText("")
    f:SetScript("OnMouseDown", nil)
    f:SetScript("OnEnter", nil)
end

local function InitLootFrame(f, itemLink, gp, equipLocText)
    ResetLootNode(f)
    f.ItemLink:SetText(itemLink)
    f.RollCount:SetText("Rolls: 0")
    f.GearPointLabel:SetText(gp)
    f.EquipLocation:SetText(equipLocText or LINK_FONT_COLOR:WrapTextInColorCode("[Right click for items]"))
end

local function UpdateLootNodeButtons(f, id, playerName, currentItem)
    f.MainSpec:SetScript("OnClick", function()
        EpgpPlus.Comms:SendGuildMessage("OnLootItemRoll", { id = id, roll = 1, player = playerName, currentItem = currentItem, })
    end)
    f.OffSpec:SetScript("OnClick", function()
        EpgpPlus.Comms:SendGuildMessage("OnLootItemRoll", { id = id, roll = 2, player = playerName, currentItem = currentItem, })
    end)
    f.DE:SetScript("OnClick", function()
        EpgpPlus.Comms:SendGuildMessage("OnLootItemRoll", {id = id, roll = 3, player = playerName, })
    end)
    f.Pass:SetScript("OnClick", function()
        EpgpPlus.Comms:SendGuildMessage("OnLootItemRoll", { id = id, roll = 4, player = playerName, })
    end)
end



local LootTemplateFrameName = "EpgpPlusMasterLootItemListTemplate";
local LootTemplateHeight = 36;

function EpgpPlusMasterLootMixin:OnLootDataReceived(data)


    --[[
        had to rewrite this to make use of Item:ContinueOnLoad() because of ilvl calls etc   
    ]]

    self.LootNodes = {};

    self.PlayerRolls = {}

    self.DataProvider = CreateTreeDataProvider();

    local numLootItems = #data;
    
    for i = 1, numLootItems do
        
        local link = data[i].link;
        local itemID, _, _, equipLoc, icon, classID, subClassID = C_Item.GetItemInfoInstant(link)
        local id = string.format("%d:%d", itemID, data[i].slot)

        local itemIsListed = EpgpPlus.Database:IsItemInList(itemID)

        if EpgpPlus.TierTokens[itemID] then
            local _, class = UnitClass("player")

            --only bother if its for the player class
            if EpgpPlus.TierTokens[itemID][class] then
                
                local tokenItems = {};

                for _, itemId in ipairs(EpgpPlus.TierTokens[itemID][class]) do
                    local item = Item:CreateFromItemID(itemId);
                    item:ContinueOnItemLoad(function()
                        table.insert(tokenItems, item:GetItemLink())

                        --token items will always be for the same slot so ok to overwrite
                        equipLoc = select(4, C_Item.GetItemInfoInstant(item:GetItemLink()))
                        local playerName = EpgpPlus.Api.GetPlayerRealmName()
                        local currentItem = EpgpPlus.Api.GetUnitInventoryForEquipLocation("player", equipLoc)

                        --with the item data loaded we can safely get the gp value
                        local gp = EpgpPlus.Api.GetItemGearPointValue(EpgpPlus.TierTokens[itemID][class][1])

                        --all items should now be handled so add the parent item to the UI
                        if (#tokenItems == #EpgpPlus.TierTokens[itemID][class]) then
                            self.LootNodes[id] = self.DataProvider:Insert({
                                template = LootTemplateFrameName,
                                height = LootTemplateHeight,

                                --used when clicking a child node
                                itemLink = link,
                                gp = gp,

                                initializer = function(f)
                                    InitLootFrame(f, link, gp)
                                    UpdateLootNodeButtons(f, id, playerName, currentItem)

                                    --because this is a token item we want to show the players the items they get from it
                                    f:SetScript("OnMouseDown", function(_, hw)
                                        if (hw == "RightButton") then
                                            MenuUtil.CreateContextMenu(f, function(_, rootDescription)
                                                rootDescription:CreateTitle(link)
                                                rootDescription:CreateDivider()
                                                for _, _link in ipairs(tokenItems) do
                                                    local button = rootDescription:CreateButton(_link, function() end)
                                                    button:SetTooltip(function()
                                                        GameTooltip:SetHyperlink(_link)
                                                    end)
                                                end
                                            end)
                                        end
                                    end)
                                end,
                            })
                        end

                    end)
                end

            end

        else

            local item = Item:CreateFromItemLink(link);
            item:ContinueOnItemLoad(function()

                equipLoc = select(4, C_Item.GetItemInfoInstant(item:GetItemLink()))
                local playerName = EpgpPlus.Api.GetPlayerRealmName()
                local currentItem = EpgpPlus.Api.GetUnitInventoryForEquipLocation("player", equipLoc)

                local gp = EpgpPlus.Api.GetItemGearPointValue(itemID);



                self.LootNodes[id] = self.DataProvider:Insert({
                    template = LootTemplateFrameName,
                    height = LootTemplateHeight,

                    --used when clicking a child node
                    itemLink = link,
                    gp = gp,

                    initializer = function(f)
                        InitLootFrame(f, link, gp, _G[equipLoc])
                        UpdateLootNodeButtons(f, id, playerName, currentItem)

                        --normal item so show the tooltip
                        f:SetScript("OnEnter", function()
                            GameTooltip:SetOwner(self, "ANCHOR_NONE")
                            GameTooltip:ClearAllPoints()
                            GameTooltip:SetPoint("LEFT", self, "RIGHT", 5, 0)
                            GameTooltip:SetHyperlink(link)
                            GameTooltip:Show()
                        end)
                    end,
                })
            end)
        end

    end


    --[[
    
    for k, loot in ipairs(data) do
        local itemID, _, _, equipLoc, icon, classID, subClassID = C_Item.GetItemInfoInstant(loot.itemLink)

        --create a unique id key for the item using its itemID and index in the loot data
        --this prevents multiple same item drops gettign muddled
        local id = string.format("%d:%d", itemID, loot.lootSlotIndex)

        local gp;

        --lets check for tier tokens
        local tokenItems = {}
        if EpgpPlus.TierTokens[itemID] then

            local class = select(2, UnitClass("player"))
            if EpgpPlus.TierTokens[itemID][class] then

                for _, itemId in ipairs(EpgpPlus.TierTokens[itemID][class]) do

                    local item = Item:CreateFromItemID(itemId)
                    item:ContinueOnItemLoad(function()
                        table.insert(tokenItems, item:GetItemLink())

                        --update the equipLoc data
                        equipLoc = select(4, C_Item.GetItemInfoInstant(item:GetItemLink()))
                        
                        --token items are always the same slot so just get the first item and update the gp
                        gp = EpgpPlus.Api.GetItemGearPointValue(EpgpPlus.TierTokens[itemID][class][1])

                    end)
                end
            end

        else

            --we dont want to use the token for gp calculations so handle normal items here
            gp = EpgpPlus.Api.GetItemGearPointValue(itemID);
        end

        self.LootNodes[id] = self.DataProvider:Insert({
            template = "EpgpPlusMasterLootItemListTemplate",
            height = 36,

            --to access later from child nodes
            itemLink = loot.itemLink,
            gp = gp,

            initializer = function(f)

                ResetLootNode(f)

                f.id = id;

                --tier tokens
                if EpgpPlus.TierTokens[itemID] then

                    f.EquipLocation:SetText(LINK_FONT_COLOR:WrapTextInColorCode("[Right click for items]"))

                    f:SetScript("OnMouseDown", function(_, hw)
                        if (hw == "RightButton") then
                            MenuUtil.CreateContextMenu(f, function(_, rootDescription)
                                rootDescription:CreateTitle(loot.itemLink)
                                rootDescription:CreateDivider()
                                for _, link in ipairs(tokenItems) do
                                    local button = rootDescription:CreateButton(link, function() end)
                                    button:SetTooltip(function()
                                        GameTooltip:SetHyperlink(link)
                                    end)
                                end
                            end)
                        end
                    end)
                else
                    f.EquipLocation:SetText(_G[equipLoc])
                    f:SetScript("OnMouseDown", nil)
                    f:SetScript("OnEnter", function()
                        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
                        GameTooltip:SetHyperlink(loot.itemLink)
                        GameTooltip:Show()
                    end)
                end

                f.ItemLink:SetText(loot.itemLink)
                f.RollCount:SetText("Rolls: 0")
                f.GearPointLabel:SetText(gp)

                local playerName = EpgpPlus.Api.GetPlayerRealmName()

                local currentSlotItem = EpgpPlus.Api.GetUnitInventoryForEquipLocation("player", equipLoc)

                f.MainSpec:SetScript("OnClick", function()
                    EpgpPlus.Comms:SendGuildMessage("OnLootItemRoll", { id = id, roll = 1, player = playerName, currentItem = currentSlotItem, })
                end)
                f.OffSpec:SetScript("OnClick", function()
                    EpgpPlus.Comms:SendGuildMessage("OnLootItemRoll", { id = id, roll = 2, player = playerName, currentItem = currentSlotItem, })
                end)
                f.DE:SetScript("OnClick", function()
                    EpgpPlus.Comms:SendGuildMessage("OnLootItemRoll", {id = id, roll = 3, player = playerName, })
                end)
                f.Pass:SetScript("OnClick", function()
                    EpgpPlus.Comms:SendGuildMessage("OnLootItemRoll", { id = id, roll = 4, player = playerName, })
                end)
            end,
        })
    end

    ]]

    self.LootListview.scrollView:SetDataProvider(self.DataProvider)

    self:Show()
end


local function GetRollAtlas(roll)
    if (roll == 1) then
        return "lootroll-icon-need";
    end
    if (roll == 2) then
        return "lootroll-icon-greed";
    end
    if (roll == 3) then
        return "lootroll-icon-disenchant";
    end
    if (roll == 4) then
        return "lootroll-icon-pass";
    end
end

local function ResetPlayerRollNode(f)
    f.LeftLabel:SetText("")
    f.LeftLabel2:SetText("")
    f.RightLabel:SetText("")
    f:SetScript("OnEnter", nil)
    f:SetScript("OnMouseDown", nil)
end


local function SortPlayers(data)
    local temp = {}
    for player, info in pairs(data) do
        table.insert(temp, info)
    end

    table.sort(temp, function(a, b)
        if a.roll == b.roll then
            return a.pr > b.pr;
        else
            return a.roll < b.roll;
        end
    end)
    return temp
end


-- to try to ensure the ML is getting up to date data, the _Internal callback fires for this client on every change detected
-- go in and look for a player and update the pr
function EpgpPlusMasterLootMixin:OnPlayerPointsChanged_Internal(name, ep, gp)
    --print("OnPlayerPointsChanged_Internal > ", name, ep , gp, (ep/gp))
    if self.PlayerRolls then
        for nodeID, tbl in pairs(self.PlayerRolls) do
            for playerName, rollData in pairs(tbl) do
                --is playerName and rollData.player the same?
                --print(playerName, rollData.player)
                if rollData.player == name then
                    rollData.pr = (ep / gp);
                    local temp = SortPlayers(tbl)
                    self:LoadPlayersForLootItemNode(nodeID, temp)
                end
            end
        end
    end
end

--player without officer note access will not get the _Internal callback as they cant see changes
--this will update a little slower
function EpgpPlusMasterLootMixin:OnPlayerPointsChanged_Event()
    --print("OnPlayerPointsChanged_Event")
    if self.PlayerRolls then
        for nodeID, tbl in pairs(self.PlayerRolls) do
            for playerName, rollData in pairs(tbl) do
                local playerPoints = EpgpPlus.Api.GetGuildMembersPoints(rollData.player)
                rollData.pr = playerPoints.pr
            end
            local temp = SortPlayers(tbl)
            self:LoadPlayersForLootItemNode(nodeID, temp)
        end
    end
end


--local testingIndex = 0;
function EpgpPlusMasterLootMixin:OnLootItemRoll(data, sender)

    --testingIndex = testingIndex + 1;

    local playerPoints = EpgpPlus.Api.GetGuildMembersPoints(data.player) --math.random() -- 

    data.pr = playerPoints.pr;

    --DevTools_Dump({data})

    --because Sort doesnt work, or I cant make it work we'll do it the ugly way
    if self.LootNodes[data.id] then
        self.LootNodes[data.id]:Flush()
    end

    --self.PlayerRolls is reset to {} when the loot data first comes in
    --here we need to create the child table
    if self.PlayerRolls[data.id] == nil then
        self.PlayerRolls[data.id] = {}
    end

    --straight up overwrite with new data
    --self.PlayerRolls[data.id][data.player..testingIndex] = data;
    self.PlayerRolls[data.id][data.player] = data;

    local temp = SortPlayers(self.PlayerRolls[data.id])

    self:LoadPlayersForLootItemNode(data.id, temp)
    
    -- for _, player in ipairs(temp) do
    --     self.LootNodes[data.id]:Insert({
    --         template = "EpgpPlusBasicListItemTemplateNoMixin",
    --         height = 22,
    --         initializer = function(f)

    --             ResetPlayerRollNode(f)

    --             f.LeftLabel:SetText(Ambiguate(data.player, "short"))

    --             if data.currentItem then
    --                 f:SetScript("OnEnter", function()
    --                     GameTooltip:SetOwner(self, "ANCHOR_NONE")
    --                     GameTooltip:ClearAllPoints()
    --                     GameTooltip:SetPoint("LEFT", self, "RIGHT", 5, 0)
    --                     GameTooltip:SetHyperlink(data.currentItem)
    --                     GameTooltip:Show()
    --                 end)
    --                 f.LeftLabel2:SetText(data.currentItem)
    --             else
    --                 f.LeftLabel2:SetText("")
    --             end

    --             f.RightLabel:SetText(string.format("%s - %.2f", CreateAtlasMarkup(GetRollAtlas(player.roll), 18, 18), player.pr))

    --             --if (EpgpPlus.Api.IsMasterLooter() == true) then
                    
    --                 --setup a script for the ML to be able to award the loot
    --                 f:SetScript("OnMouseDown", function(_, hw)
    --                     if (hw == "RightButton") then

    --                         local parentNodeData = self.LootNodes[data.id]:GetData();

    --                         -- because we're not doing off spec or de costs just zero the gp if thats the player roll
    --                         local gp = parentNodeData.gp;
    --                         if (player.roll > 1) then
    --                             gp = 0;
    --                         end

    --                         local itemID, lootSlotIndex = strsplit(":", data.id)
    --                         lootSlotIndex = tonumber(lootSlotIndex);

    --                         local raidRosterIndex = EpgpPlus.Api.GetGroupMemberIndex(Ambiguate(data.player, "short"))

    --                         --if (type(lootSlotIndex) == "number") and (type(raidRosterIndex) == "number") then
                            
    --                             MenuUtil.CreateContextMenu(f, function(f, rootDescription)

    --                                 rootDescription:CreateTitle(CONFIRM_LOOT_DISTRIBUTION:format(parentNodeData.itemLink, Ambiguate(data.player, "short")))
    --                                 rootDescription:CreateDivider()
    --                                 rootDescription:CreateTitle("Player Roll:")
    --                                 rootDescription:CreateButton(string.format("%s [GP: %s]", CreateAtlasMarkup(GetRollAtlas(player.roll), 24, 24), gp), function()
                                    
    --                                 end)

    --                                 rootDescription:CreateDivider()
    --                                 rootDescription:CreateTitle("Other options:")

    --                                 for i = 1, 3 do
    --                                     if (i ~= player.roll) then
    --                                         if (i == 1) then
    --                                             rootDescription:CreateButton(string.format("%s [GP: %s]", CreateAtlasMarkup(GetRollAtlas(i), 24, 24), parentNodeData.gp), function()
                                                
    --                                             end)
    --                                         else
    --                                             rootDescription:CreateButton(string.format("%s [GP: %s]", CreateAtlasMarkup(GetRollAtlas(i), 24, 24), 0), function()
                                                
    --                                             end)
    --                                         end
    --                                     end
    --                                 end

    --                             end)
    --                         --end
    --                     end
    --                 end)
    --             --end
    --         end,
    --     })
    -- end

    self.LootListview.scrollView:ForEachFrame(function(f)
        if f.id == data.id then
            f.RollCount:SetText(string.format("[Rolls: %d/%d]", #temp , GetNumGroupMembers()))
        end
    end)

end

local function GiveLoot(lootSlotIndex, raidRosterIndex, playerName, gp, comment, itemLink, actionID)
    print("GiveLoot", lootSlotIndex, raidRosterIndex, playerName, gp, comment, itemLink, actionID)
    GiveMasterLoot(lootSlotIndex, raidRosterIndex)
    EpgpPlus.Api.AdjustGuildMembersPoints({[playerName] = true}, "gp", gp, comment, itemLink, actionID)
end

function EpgpPlusMasterLootMixin:LoadPlayersForLootItemNode(nodeID, players)
    if self.LootNodes[nodeID] then
        self.LootNodes[nodeID]:Flush()
    end
    for _, player in ipairs(players) do
        self.LootNodes[nodeID]:Insert({
            template = "EpgpPlusBasicListItemTemplateNoMixin",
            height = 22,
            initializer = function(f)

                ResetPlayerRollNode(f)

                f.LeftLabel:SetText(Ambiguate(player.player, "short"))

                if player.currentItem then
                    f:SetScript("OnEnter", function()
                        GameTooltip:SetOwner(self, "ANCHOR_NONE")
                        GameTooltip:ClearAllPoints()
                        GameTooltip:SetPoint("LEFT", self, "RIGHT", 5, 0)
                        GameTooltip:SetHyperlink(player.currentItem)
                        GameTooltip:Show()
                    end)
                    f.LeftLabel2:SetText(player.currentItem)
                else
                    f.LeftLabel2:SetText("")
                end

                --monitor the formatting on the pr value, more DP will show better clarity on what pr folks have
                f.RightLabel:SetText(string.format("%s - %.4f", CreateAtlasMarkup(GetRollAtlas(player.roll), 18, 18), player.pr))

                --if (EpgpPlus.Api.IsMasterLooter() == true) then
                    
                    --setup a script for the ML to be able to award the loot
                    f:SetScript("OnMouseDown", function(_, hw)
                        if (hw == "RightButton") then

                            local parentNodeData = self.LootNodes[nodeID]:GetData();

                            -- because we're not doing off spec or de costs just zero the gp if thats the player roll
                            local gp = parentNodeData.gp;
                            if (player.roll > 1) then
                                gp = 0;
                            end

                            local itemID, lootSlotIndex = strsplit(":", nodeID)
                            lootSlotIndex = tonumber(lootSlotIndex);

                            local raidRosterIndex = EpgpPlus.Api.GetGroupMemberIndex(Ambiguate(player.player, "short"))

                            if (type(lootSlotIndex) == "number") and (type(raidRosterIndex) == "number") then
                            
                                MenuUtil.CreateContextMenu(f, function(f, rootDescription)

                                    rootDescription:CreateTitle(CONFIRM_LOOT_DISTRIBUTION:format(parentNodeData.itemLink, Ambiguate(player.player, "short")))
                                    rootDescription:CreateDivider()
                                    rootDescription:CreateTitle("Player Roll:")
                                    rootDescription:CreateButton(string.format("%s [GP: %s]", CreateAtlasMarkup(GetRollAtlas(player.roll), 24, 24), gp or 0), function()

                                        --local logComment = EpgpPlus.Api.CreateLogComment(UnitName("player"), "gp", -gp, player.player, parentNodeData.itemLink, EpgpPlus.Constants.LogActionTakenComments[player.roll])
                                        GiveLoot(lootSlotIndex, raidRosterIndex, player.player, gp or 0, "", parentNodeData.itemLink, 1)
                                    end)

                                    rootDescription:CreateDivider()
                                    rootDescription:CreateTitle("Other options:")

                                    --https://warcraft.wiki.gg/wiki/API_RollOnLoot

                                    for i = 1, 3 do
                                        if (i ~= player.roll) then
                                            if (i == 1) then
                                                rootDescription:CreateButton(string.format("%s [GP: %s]", CreateAtlasMarkup(GetRollAtlas(i), 24, 24), parentNodeData.gp or 0), function()
                                                    GiveLoot(lootSlotIndex, raidRosterIndex, player.player, parentNodeData.gp or 0, "", parentNodeData.itemLink, 1)
                                                    -- local logEntry = EpgpPlus.Api.CreateLogEntry(
                                                    --     UnitName("player"), 
                                                    --     1, 
                                                    --     player.player, 
                                                    --     "gp", 
                                                    --     parentNodeData.gp, 
                                                    --     parentNodeData.itemLink, 
                                                    --     "", 
                                                    --     GetServerTime()
                                                    -- )
                                                    -- EpgpPlus.Comms:SendGuildMessage("OnPointsLogEntryReceived", logEntry)
                                                end)
                                            else
                                                rootDescription:CreateButton(string.format("%s [GP: %s]", CreateAtlasMarkup(GetRollAtlas(i), 24, 24), 0), function()
                                                    GiveLoot(lootSlotIndex, raidRosterIndex, player.player, 0, "", parentNodeData.itemLink, player.roll)
                                                    -- local logEntry = EpgpPlus.Api.CreateLogEntry(
                                                    --     UnitName("player"), 
                                                    --     player.roll,
                                                    --     player.player, 
                                                    --     "gp", 
                                                    --     0, 
                                                    --     parentNodeData.itemLink, 
                                                    --     "", 
                                                    --     GetServerTime()
                                                    -- )
                                                    -- EpgpPlus.Comms:SendGuildMessage("OnPointsLogEntryReceived", logEntry)
                                                end)
                                            end
                                        end
                                    end

                                end)
                            end
                        end
                    end)
                --end
            end,
        })
    end
end