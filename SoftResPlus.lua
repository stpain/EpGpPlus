


local addonName, SoftResPlus = ...;



local MainNineSliceLayout =
{
    TopLeftCorner =	{ atlas = "optionsframe-nineslice-cornertopleft", x = -15, y = 15 },
    TopRightCorner =	{ atlas = "optionsframe-nineslice-cornertopright", x = 15, y = 15 },
    BottomLeftCorner =	{ atlas = "optionsframe-nineslice-cornerbottomleft", x = -15, y = -15 },
    BottomRightCorner =	{ atlas = "optionsframe-nineslice-cornerbottomright", x = 15, y = -15 },
    TopEdge = { atlas = "_optionsframe-nineslice-edgetop", },
    BottomEdge = { atlas = "_optionsframe-nineslice-edgebottom", },
    LeftEdge = { atlas = "!OptionsFrame-NineSlice-EdgeLeft", },
    RightEdge = { atlas = "!OptionsFrame-NineSlice-EdgeRight", },
    --Center = { layer = "BACKGROUND", atlas = "Tooltip-Glues-NineSlice-Center", x = -20, y = 20, x1 = 20, y1 = -20 },
}

local ExpansionArt = {
    Large = {
        "groupfinder-background-raids-classic",
        "groupfinder-background-raids-bc",
        "groupfinder-background-raids-wrath",
    },
    Headers = {
        "groupfinder-button-raids-classic",
        "groupfinder-button-raids-bc",
        "groupfinder-button-raids-wrath",
    }
}


local ExpansionInstances = {
    {
        "Molten Core",
        "Blackwing Lair",
        [[Onyxia's Lair]],
        [[Zul'Gurub]],
        [[Ruins of Ahn'Qiraj]],
        [[Temple of Ahn'Qiraj]],
        [[Naxxramas]],
    },
    {
        [[Karazhan]],
        [[Gruul's Lair]],
        [[Magtheridon's Lair]],
        [[Serpentshrine Cavern]],
        [[Tempest Keep]],
        [[Hyjal Summit]],
        [[Black Temple]],
        [[Zul'Aman]],
        [[Sunwell Plateau]],
    }
}













SoftResPlus.Callbacks = CreateFromMixins(CallbackRegistryMixin)
SoftResPlus.Callbacks:OnLoad()
SoftResPlus.Callbacks:GenerateCallbackEvents({
    "Database_OnInitialized",
    "Database_OnNewListCreated",
    "Database_OnListDeleted",

    "Database_OnSessionCreated",
    "Database_OnSessionDeleted",

    "Session_OnSelected",
    "Session_OnHardReservesChanged",

    "List_OnItemAdded",
    "List_OnItemDeleted",
    "List_OnItemsChanged",

    "Character_On",
})





















SoftResPlus.Api = {}

function SoftResPlus.Api.GetPlayerRealmName()
    local name, realm = UnitName("player")
    if realm == nil then
        realm = GetNormalizedRealmName()
    end
    return string.format("%s-%s", name, realm)
end

--[[
    Loot functions
]]

function SoftResPlus.Api.GetInstanceNames(expansionIndex)
    local ret = {}
    local t = {}
    for _, instance in ipairs(SoftResPlus.InstanceData) do
        if ((expansionIndex and (expansionIndex == instance.expansionIndex)) or expansionIndex == nil) then
            if (t[instance.name] == nil) then
                t[instance.name] = true;
                table.insert(ret, instance.name)
            end
        end
    end
    t = nil;
    return ret;
end

function SoftResPlus.Api.GetInstanceEncounters(instanceName)
    local ret = {}
    local t = {}
    for _, instance in ipairs(SoftResPlus.InstanceData) do
        if (instance.name == instanceName) then
            if not t[instance.encounter] then
                t[instance.encounter] = true;
                table.insert(ret, instance.encounter)
            end
        end
    end
    t = nil;
    return ret;
end

function SoftResPlus.Api.GetEncounterLoot(instanceName, encounterName)
    local ret = {}
    for _, instance in ipairs(SoftResPlus.InstanceData) do
        if (instance.name == instanceName) and (instance.encounter == encounterName) then
            table.insert(ret, instance.itemID)
        end
    end
    return ret;
end


--[[
    Guild functions
]]

function SoftResPlus.Api.GetGuildMembers()
    local ret = {}
    C_GuildInfo.GuildRoster()
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local name, rankName, _, level, _, _, publicNote, _, _, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(i)
        if level == 60 then
            table.insert(ret, {
                name = name,
                rank = rankName,
                level = level,
                note = publicNote,
                class = class,
                guid = guid,
            })
        end
    end
    return ret;
end

















SoftResPlusMixin = {}



local EventsToRegister = {
    "PLAYER_ENTERING_WORLD",
    "ADDON_LOADED",
}

function SoftResPlusMixin:OnLoad()

    --NineSliceUtil.ApplyLayout(self, MainNineSliceLayout) "Interface/AddOns/SoftResPlus/Logo.jpg"

    SoftResPlusUiPortrait:SetTexture("Interface/AddOns/SoftResPlus/Logo.jpg")

    for _, event in ipairs(EventsToRegister) do
        self:RegisterEvent(event)
    end

    self:RegisterForDrag("LeftButton")

    self.Resize:Init(self, 600, 400, 1000, 620)

    SLASH_SOFTRESPLUS1 = '/srp'
    SlashCmdList['SOFTRESPLUS'] = function(msg)
        self:Show()
    end

    local function OnTabSelected(tabID)
        self:SelectTab(tabID)
    end
    self.TabSystem:SetTabSelectedCallback(OnTabSelected)
    self.TabSystem:AddTab("Items")
    self.TabSystem:AddTab("Sessions")
    self.TabSystem:SetTab(1)

    local function NewSession(instance)
        self.TabSystem:SetTab(2)
        SoftResPlus.Database:NewSession(instance)
    end

    self.NewSession:SetScript("OnClick", function()
        MenuUtil.CreateContextMenu(self, function(self, rootDescription)
            
            -- CLASSIC MULTI LEVEL DROPDOWN STYLE
            -- rootDescription:CreateTitle("Select Instance")
            -- rootDescription:CreateDivider()
            -- for i = 0, 2 do
            --     local button = rootDescription:CreateButton(_G["EXPANSION_NAME"..i], function() end)
            --     local instances = SoftResPlus.Api.GetInstanceNames(i)
            --     for _, instanceName in ipairs(instances) do
            --         button:CreateButton(instanceName, function()
            --             NewSession(instanceName)
            --         end)
            --     end
            -- end

            -- GRIDVIEW STYLE LAYOUT
            rootDescription:SetGridMode(MenuConstants.HorizontalGridDirection, 3, 5)
            for i = 0, 2 do
                rootDescription:CreateTitle(_G["EXPANSION_NAME"..i])
            end

            local classicInstances = SoftResPlus.Api.GetInstanceNames(0)
            local tbcInstances = SoftResPlus.Api.GetInstanceNames(1)
            local wrathInstances = SoftResPlus.Api.GetInstanceNames(2)

            local counts = {
                {
                    expansion = "classic",
                    count = #classicInstances,
                },
                {
                    expansion = "tbc",
                    count = #tbcInstances,
                },
                {
                    expansion = "wrath",
                    count = #wrathInstances,
                },
            }
            table.sort(counts, function(a, b)
                return a.count > b.count
            end)
            
            for i = 1, counts[1].count do
                if classicInstances[i] then
                    rootDescription:CreateButton(classicInstances[i], function() NewSession(classicInstances[i]) end)
                else
                    rootDescription:CreateSpacer()
                end
                if tbcInstances[i] then
                    rootDescription:CreateButton(tbcInstances[i], function() NewSession(tbcInstances[i]) end)
                else
                    rootDescription:CreateSpacer()
                end
                if wrathInstances[i] then
                    rootDescription:CreateButton(wrathInstances[i], function() NewSession(wrathInstances[i]) end)
                else
                    rootDescription:CreateSpacer()
                end
            end


        end)
    end)

    SoftResPlus.Callbacks:RegisterCallback("Database_OnInitialized", self.Database_OnInitialized, self)
    SoftResPlus.Callbacks:RegisterCallback("Database_OnNewListCreated", self.Database_OnNewListCreated, self)
    SoftResPlus.Callbacks:RegisterCallback("Database_OnListDeleted", self.Database_OnListDeleted, self)
    SoftResPlus.Callbacks:RegisterCallback("List_OnItemsChanged", self.List_OnItemsChanged, self)
    SoftResPlus.Callbacks:RegisterCallback("Database_OnSessionCreated", self.Database_OnSessionCreated, self)
    SoftResPlus.Callbacks:RegisterCallback("Session_OnSelected", self.Session_OnSelected, self)
    SoftResPlus.Callbacks:RegisterCallback("Session_OnHardReservesChanged", self.Session_OnHardReservesChanged, self)

    self.DataProviders = {}

    table.insert(UISpecialFrames, self:GetName())

end

function SoftResPlusMixin:Database_OnInitialized()
    self:InitializeInstanceTab()
    self:SetUpSessionTab()
    SoftResPlus.Comms:Init()
end

function SoftResPlusMixin:SelectTab(tabID)
    for _, f in ipairs(self.childTabs) do
        f:Hide()
    end
    if self["Tab"..tabID] then
        self["Tab"..tabID]:Show()
    end
end

function SoftResPlusMixin:OnEvent(event, ...)

    if (event == "ADDON_LOADED") and (... == addonName) then
        SoftResPlus.Database:Init()
    end


end

function SoftResPlusMixin:SetUpSessionTab()
    self.Tab2.SessionPanel.AllowMultiReserves.label:SetText("Allow multi-reserves")
    local sessions = SoftResPlus.Database:GetAllSessions()
    self.SessionsDataProvider = CreateDataProvider(sessions)
    self.Tab2.SessionContainer.SessionList.scrollView:SetDataProvider(self.SessionsDataProvider)

    NineSliceUtil.ApplyLayout(self.Tab2.SessionPanel.HardReserveList, MainNineSliceLayout)

    local function SetReserveCount(num)
        self.Tab2.SessionPanel.NumAllowedReservesCount:SetText(num)
    end

    self.Tab2.SessionPanel.IncreaseReserves:SetScript("OnClick", function ()
        if self.Tab2.SessionPanel.activeSession then
            self.Tab2.SessionPanel.activeSession.defaultNumReserves = self.Tab2.SessionPanel.activeSession.defaultNumReserves + 1;
            SetReserveCount(self.Tab2.SessionPanel.activeSession.defaultNumReserves)
        end
    end)

    self.Tab2.SessionPanel.DecreaseReserves:SetScript("OnClick", function ()
        if self.Tab2.SessionPanel.activeSession then
            self.Tab2.SessionPanel.activeSession.defaultNumReserves = self.Tab2.SessionPanel.activeSession.defaultNumReserves - 1;
            if self.Tab2.SessionPanel.activeSession.defaultNumReserves < 0 then
                self.Tab2.SessionPanel.activeSession.defaultNumReserves = 0
            end
            SetReserveCount(self.Tab2.SessionPanel.activeSession.defaultNumReserves)
        end
    end)

    self.Tab2.SessionPanel.AllowMultiReserves:SetScript("OnClick", function(cb)
        if self.Tab2.SessionPanel.activeSession then
            self.Tab2.SessionPanel.activeSession.multiReserve = cb:GetChecked()
        end
    end)


    self.Tab2.SessionPanel.AddHardReserveItem:SetScript("OnClick", function()
        if self.Tab2.SessionPanel.activeSession then
            local encounters = SoftResPlus.Api.GetInstanceEncounters(self.Tab2.SessionPanel.activeSession.instance)

            MenuUtil.CreateContextMenu(self, function(_, rootDescription)

                for _, encounter in ipairs(encounters) do
                    
                    local button = rootDescription:CreateButton(encounter, function() end)
                    local loot = SoftResPlus.Api.GetEncounterLoot(self.Tab2.SessionPanel.activeSession.instance, encounter)
                    
                    button:CreateTitle(encounter)
                    
                    for _, itemID in ipairs(loot) do
                        
                        --local itemButton = button:CreateButton("", function() end)

                        local item = Item:CreateFromItemID(itemID)
                        if item and (not item:IsItemEmpty()) then
                            
                            item:ContinueOnItemLoad(function ()

                                local link = item:GetItemLink()

                                local itemButton = button:CreateButton(link, function()
                                    table.insert(self.Tab2.SessionPanel.activeSession.hardReserves, {
                                        itemID = itemID,
                                        itemLink = link,
                                    })
                                    SoftResPlus.Callbacks:TriggerEvent("Session_OnHardReservesChanged")
                                end)

                                -- itemButton:AddInitializer(function(b, desc, menu)
                                --     b.fontString:SetText(item:GetItemLink())
                                --     itemButton:SetTooltip(function(tooltip, data)
                                --         GameTooltip:SetItemByID(itemID)
                                --     end)
                                --     return (b.fontString:GetUnboundedStringWidth() + 20), 20;
                                -- end)
                            end)
                        end
                    end
                end
            end)
        end
    end)
end

local function ResetMenuListElement(f)
    f.Label:SetText(nil)
    f.BackgroundArt:SetTexture(nil)
    f.Highlight:SetAtlas("search-select")
    f.Label:SetFontObject("GameFontNormal")
    f.NewList:Hide()
end

function SoftResPlusMixin:InitializeInstanceTab()

    local DataProvider = CreateTreeDataProvider()
    self.Tab1.ExpansionMenu.scrollView:SetDataProvider(DataProvider)

    local nodes = {}

    for i = 1, 3 do
        local expansionName = _G["EXPANSION_NAME"..(i-1)]
        nodes[expansionName] = DataProvider:Insert({
            template = "SoftResExpansionSelectTemplate",
            height = 96,
            initializer = function(f)
                f.Label:SetText(expansionName)
                f.BackgroundArt:SetAtlas(ExpansionArt.Large[i])
                f.Highlight:SetAtlas("search-select")
                f.Label:SetFontObject("GameFontNormalHuge2")
                f.NewList:Hide()
                f:SetScript("OnMouseDown", function()
                    nodes[expansionName]:ToggleCollapsed()
                    if not nodes[expansionName]:IsCollapsed() then
                        self.Tab1.ExpansionHeaderImage:SetAtlas(ExpansionArt.Headers[i])
                        self.Tab1.ListHeader:SetText(expansionName)
                    end
                end)
            end,
        })

        if ExpansionInstances[i] then
            for _, instanceName in ipairs(ExpansionInstances[i]) do
                nodes[expansionName][instanceName] = nodes[expansionName]:Insert({
                    height = 46,
                    template = "SoftResExpansionSelectTemplate",
                    initializer = function(f)
                        f.BackgroundArt:SetAtlas("clickcastlist-buttonbackground")
                        f.Highlight:SetAtlas("search-select")
                        f.Label:SetText(instanceName)
                        f.NewList:Hide()
                        f.Label:SetFontObject("GameFontNormalLarge")
                        f:SetScript("OnMouseDown", function()

                            nodes[expansionName][instanceName]:ToggleCollapsed()

                            for _, insName in ipairs(ExpansionInstances[i]) do
                                if (insName ~= instanceName) and (not nodes[expansionName][insName]:IsCollapsed()) then
                                    nodes[expansionName][insName]:ToggleCollapsed()
                                end
                            end

                        end)
                    end,
                })


                local encounters = SoftResPlus.Api.GetInstanceEncounters(instanceName)
                for _, encounter in ipairs(encounters) do
                    nodes[expansionName][instanceName][encounter] = nodes[expansionName][instanceName]:Insert({
                        height = 32,
                        template = "SoftResExpansionSelectTemplate",
                        initializer = function(f)
                            f.BackgroundArt:SetAtlas("groupfinder-button-cover")
                            f.Highlight:SetAtlas("search-select")
                            f.Label:SetText(encounter)
                            f.NewList:Hide()
                            f.Label:SetFontObject("GameFontNormal")

                            f:SetScript("OnMouseDown", function()
                                self:LoadEncounterLoot(instanceName, encounter, i)
                            end)
                        end,
                    })
                end

                nodes[expansionName][instanceName]:ToggleCollapsed()
            end

            nodes[expansionName]:ToggleCollapsed()
        end
    end

    self.ListsNode = DataProvider:Insert({
        height = "96",
        template = "SoftResExpansionSelectTemplate",
        initializer = function(f)
            f.Label:SetText("Lists")
            f.BackgroundArt:SetAtlas("groupfinder-background-dungeons") --groupfinder-button-dungeons
            f.Highlight:SetAtlas("search-select")
            f.Label:SetFontObject("GameFontNormalHuge2")
            f.NewList:Show()
            f.NewList:SetScript("OnClick", function()
                SoftResPlus.Database:NewList()
            end)
            f:SetScript("OnMouseDown", function()
                self.ListsNode:ToggleCollapsed()
                if not self.ListsNode:IsCollapsed() then
                    self.Tab1.ExpansionHeaderImage:SetAtlas("groupfinder-button-dungeons")
                    self.Tab1.ListHeader:SetText("Lists")
                end
            end)
        end,
    })

    self.ListsNode:IsCollapsed()

    local allLists = SoftResPlus.Database:GetAllLists()
    if allLists then
        for _, list in ipairs(allLists) do
            self:InsertItemList(list)
        end
    end

end

function SoftResPlusMixin:Database_OnListDeleted()

    self.ListsNode:Flush()

    local allLists = SoftResPlus.Database:GetAllLists()
    if allLists then
        for _, list in ipairs(allLists) do
            self:InsertItemList(list)
        end
    end
end

function SoftResPlusMixin:Database_OnNewListCreated(list)
    self:InsertItemList(list)
end

function SoftResPlusMixin:InsertItemList(list)
    if self.ListsNode then
        self.ListsNode:InsertNodeAtIndex({
            height = 46,
            template = "SoftResPlusItemListMenuTemplate",
            initializer = function(f)
                f.BackgroundArt:SetAtlas("clickcastlist-buttonbackground")
                f.Highlight:SetAtlas("search-select")
                f.Label:SetText(list.name)
                f.Label:SetFontObject("GameFontNormalLarge")
                f:SetScript("OnMouseDown", function()
                    self:LoadLoot(list.items, nil, "delete", list.id)
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
                            SoftResPlus.Database:DeleteList(list)
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

--check loot items and perform sorting and preparing template flags
function SoftResPlusMixin:LoadLoot(loot, dataProvider, rightButton, listID)

    if not dataProvider then
        dataProvider = CreateTreeDataProvider()
    end

    local temp = {}

    for _, itemID in ipairs(loot) do
        local id, itemType, itemSubType, itemEquipLoc = C_Item.GetItemInfoInstant(itemID)
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
function SoftResPlusMixin:LoadEncounterLoot(instanceName, encounter, expansionIndex)

    self.Tab1.ListHeader:SetText(string.format("%s - %s", instanceName, encounter))
    self.Tab1.ExpansionHeaderImage:SetAtlas(ExpansionArt.Headers[expansionIndex])
    self.Tab1.EncounterItemList:Show()
    
    if self.DataProviders[instanceName] and self.DataProviders[instanceName][encounter] then
        
        self.Tab1.EncounterItemList.scrollView:SetDataProvider(self.DataProviders[instanceName][encounter])

    else

        if not self.DataProviders[instanceName] then
            self.DataProviders[instanceName] = {}
        end

        if not self.DataProviders[instanceName][encounter] then
            self.DataProviders[instanceName][encounter] = CreateTreeDataProvider()

            local loot = SoftResPlus.Api.GetEncounterLoot(instanceName, encounter)

            self:LoadLoot(loot, self.DataProviders[instanceName][encounter], "addItem")

        end

    end

end

--re load the ui to reflect list item changes
function SoftResPlusMixin:List_OnItemsChanged(list, reloadItems)
    if reloadItems then
        self:LoadLoot(list.items, nil, "delete", list.id)
    end
end

--load new session into the ui
function SoftResPlusMixin:Database_OnSessionCreated(session)
    self.SessionsDataProvider:InsertAtIndex(session, 1)
end

function SoftResPlusMixin:Session_OnSelected(session)
    self.Tab2.SessionPanel.activeSession = session;

    self.Tab2.SessionPanel.NumAllowedReservesCount:SetText(session.defaultNumReserves)
    self.Tab2.SessionPanel.AllowMultiReserves:SetChecked(session.multiReserve)

    self.Tab2.SessionContainer.SessionList.scrollView:ForEachFrame(function(f)
        if f.id == string.format("%s-%d", session.instance, session.created) then
            f.Selected:Show()
        else
            f.Selected:Hide()
        end
    end)

    self:Session_OnHardReservesChanged()
end

function SoftResPlusMixin:Session_OnHardReservesChanged()
    if self.Tab2.SessionPanel.activeSession then
        local DataProvider = CreateDataProvider(self.Tab2.SessionPanel.activeSession.hardReserves)
        self.Tab2.SessionPanel.HardReserveList.scrollView:SetDataProvider(DataProvider)
    end
end