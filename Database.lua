

local addonName, EpgpPlus = ...;


local ColorHexCodes = {
    PlayerName = "|cffF7BA00",
}


local DatabaseDefaults = {
    characterDirectory = {},
    lists = {},
    pointsLog = {},
    config = {},
    itemDb = {},
    itemFilters = {},
    syncData = {},
    effortPoints = {},
    gearPoints = {},
}

local Database = {}
function Database:Init(reset)

    if SoftResPlusSavedVar then
        SoftResPlusSavedVar = nil;
    end

    if (reset == true) then
        EpgpPlusSavedVar = nil;
    end

    if (EpgpPlusSavedVar == nil) then
        EpgpPlusSavedVar = {}
    end

    for k, v in pairs(DatabaseDefaults) do
        if EpgpPlusSavedVar[k] == nil then
            EpgpPlusSavedVar[k] = v
        end
    end

    for k, v in pairs(EpgpPlusSavedVar) do
        if DatabaseDefaults[k] == nil then
            EpgpPlusSavedVar[k] = nil;
        end
    end

    self.db = EpgpPlusSavedVar;

    if self.db.config.safetyModeActive == nil then
        self.db.config.safetyModeActive = true;
    end
    if self.db.config.pointsListenerThrottle == nil then
        self.db.config.pointsListenerThrottle = 5;
    end

    self:LoadDefaultItemFilters()
    self:InitializeEncounters()
    self:InitializeGP()

    --smooth this out
    if (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC) then
        self:ProcessLootItems(0)
    end
    if (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC) then
        self:ProcessLootItems(0)
        self:ProcessLootItems(1)
    end

    EpgpPlus.Callbacks:RegisterCallback("List_OnItemAdded", self.List_OnItemAdded, self)
    EpgpPlus.Callbacks:RegisterCallback("List_OnItemDeleted", self.List_OnItemDeleted, self)
    EpgpPlus.Callbacks:RegisterCallback("OnPlayerPointsChanged_Internal", self.OnPlayerPointsChanged_Internal, self)

    EpgpPlus.Callbacks:TriggerEvent("Database_OnInitialized")
end

function Database:GetTable(tbl)
    if self.db and self.db[tbl] then
        return self.db[tbl]
    end
end

function Database:SetTable(tbl, data)
    if self.db and self.db[tbl] then
        self.db[tbl] = data
    end
end

function Database:SetEncounterEP(encounterID, ep)
    if self.db and self.db.effortPoints then
        self.db.effortPoints[encounterID] = ep
    end
end

function Database:GetEncounterEP(encounterID)
    if self.db and self.db.effortPoints and self.db.effortPoints[encounterID] then
        return self.db.effortPoints[encounterID]
    end
    return EpgpPlus.Constants.DefaultEncounterEP[EpgpPlus.Constants.EncounterIDs[encounterID]];
end

function Database:InitializeEncounters()

    local function GetEncounterID(encounterName)
        for id, name in pairs(EpgpPlus.Constants.EncounterIDs) do
            if (name == encounterName) then
                return id;
            end
        end
    end

    if self.db and self.db.effortPoints then
        for expansion, tbl in ipairs(EpgpPlus.Constants.DefaultEncounterEP) do
            for k, instance in ipairs(tbl) do
                for encounter, data in ipairs(instance) do
                    local encounterID = GetEncounterID(data.name);
                    if self.db.effortPoints[encounterID] == nil then
                        self.db.effortPoints[encounterID] = data.ep;
                    end
                end
            end
        end
    end
end



function Database:SetGP(slot, gp)
    if self.db and self.db.gearPoints then
        self.db.gearPoints[slot] = gp;
    end
end

function Database:GetGP(slot)
    if self.db and self.db.gearPoints then
        return self.db.gearPoints[slot];
    end
end

function Database:InitializeGP()
    if self.db and self.db.gearPoints then
        for _, info in ipairs(EpgpPlus.Constants.GearPoints) do
            if self.db.gearPoints[info.slot] == nil then
                self.db.gearPoints[info.slot] = info.modifier;
            end
            if type(self.db.gearPoints[info.slot]) ~= "number" then
                self.db.gearPoints[info.slot] = info.modifier;
            end
        end
    end
end



--[[
    Log
]]


function Database:AddPointsLogEntry(entry)
    if self.db and self.db.pointsLog then

        local exists = false;
        for k, v in ipairs(self.db.pointsLog) do

            --compare the source and time values as these should create a unique "id"
            if (v.src == entry.src) and (v.tme == entry.tme) then
                exists = true;
            end
        end
        if (exists == false) then
            table.insert(self.db.pointsLog, entry)
            EpgpPlus.Callbacks:TriggerEvent("Database_OnLogEvent")
        end
    end
end

function Database:GetPointsLog()
    return self.db.pointsLog;
end

--[[
    Config
]]
function Database:SetConfig(key, val)
    if self.db and self.db.config then
        self.db.config[key] = val
        EpgpPlus.Callbacks:TriggerEvent("Database_OnConfigChanged", key, val)
    end
end

function Database:GetConfig(key)
    if self.db and self.db.config then
        return self.db.config[key];
    end
end




--[[
    Character Directory
]]
function Database:UpdateCharacterDirectory(name, key, val)
    if self.db and self.db.characterDirectory then
        if self.db.characterDirectory[name] then
            self.db.characterDirectory[name][key] = val;
        else
            self.db.characterDirectory[name] = {
                [key] = val,
            }
        end
        EpgpPlus.Callbacks:TriggerEvent("Database_OnPlayerInfoChanged", name, key)
    end
end

function Database:GetCharacterInfo(name, key)
    if self.db and self.db.characterDirectory and self.db.characterDirectory[name] then
        if key then
            return self.db.characterDirectory[name][key];
        else
            return self.db.characterDirectory[name];
        end
    end
end

--points stored in different table
function Database:StoreEpGPSyncData(sender, data, comment)
    --print("got sync data")
    --print(data.source)
    if self.db then
        self.db.syncData = data;
        EpgpPlus.Callbacks:TriggerEvent("Database_OnSyncDataReceived")


        -- local logEntry = EpgpPlus.Api.CreateLogEntry(
        --     data.source, 
        --     "(StoreEpGPSyncData)", 
        --     "", 
        --     "", 
        --     "", 
        --     "", 
        --     comment or "", 
        --     data.syncTime
        -- )
        -- self:AddPointsLogEntry(logEntry)

        --EpgpPlus.Comms:SendGuildMessage("OnPointsLogEntryReceived", logEntry)        
    end
end

function Database:OnPlayerPointsChanged_Internal(name, ep, gp)
    if self.db and self.db.syncData and self.db.syncData.data then
        self.db.syncData.data[name] = {
            ep = ep,
            gp = gp,
            pr = (ep/gp)
        }
    end
end

--now takes a table of t[name] = officerNote
function Database:UpdatePlayerSyncData(data)
    if self.db and self.db.syncData and self.db.syncData.data then
        for name, officerNote in pairs(data) do
            local ep, gp = strsplit(",", officerNote);
            ep = tonumber(ep);
            gp = tonumber(gp);
            self.db.syncData.data[name] = {
                ep = ep,
                gp = gp,
                pr = (ep/gp)
            }
            EpgpPlus.Callbacks:TriggerEvent("OnPlayerPointsChanged_Event", name, ep , gp)
        end
    end
    --DevTools_Dump(data)
    -- if self.db and self.db.syncData and self.db.syncData.data then
    --     for _, info in ipairs(self.db.syncData.data) do
    --         if (info.name == data.player) then
    --             local ep, gp = strsplit(",", data.officerNote);

    --             info.ep = tonumber(ep)
    --             info.gp = tonumber(gp)

    --             local newPR = (info.ep / info.gp);
    --             info.pr = newPR;

    --             EpgpPlus.Callbacks:TriggerEvent("OnPlayerPointsChanged_Event", info)
    --             return;
    --         end
    --     end
    -- end
end

function Database:GetLastSyncDataTime()
    if self.db and self.db.syncData and self.db.syncData.data then
        return self.db.syncData.syncTime;
    end
end

function Database:GetEpGpSyncData(name)
    if self.db and self.db.syncData and self.db.syncData.data then
        if name and self.db.syncData.data[name] then
            return self.db.syncData.data[name];
            -- for _, info in ipairs(self.db.syncData.data) do
            --     if name == info.name then
            --         return info, self.db.syncData.source, self.db.syncData.syncTime;
            --     end
            -- end
        else
            return self.db.syncData;
        end
    end
end


--[[
    Item filters
]]

local createSubClassTables = {
    [2] = true,
    [4] = true,
    [3] = true,
    [7] = true,
    [9] = true,
    [15] = true,
    [12] = true,
}
function Database:LoadDefaultItemFilters()
    if self.db and self.db.itemFilters then
        for _, info in ipairs(EpgpPlus.Constants.ItemFilters) do
            if self.db.itemFilters[info.classID] == nil then
                if createSubClassTables[info.classID] then
                    self.db.itemFilters[info.classID] = {}
                    if info.subClassIDs then
                        for _, subClassID in ipairs(info.subClassIDs) do
                            self.db.itemFilters[info.classID][subClassID] = true;
                        end
                    end
                else
                    self.db.itemFilters[info.classID] = true;
                end
            end
        end
    end
end

function Database:SetItemFilters(classID, subClassID)
    if self.db and self.db.itemFilters then

        if subClassID == "all" then

            if type(self.db.itemFilters[classID]) == "table" then
                local allChecked = true;
                for k, v in pairs(self.db.itemFilters[classID]) do
                    if (v == false) then
                        allChecked = false;
                    end
                end

                for k, v in pairs(self.db.itemFilters[classID]) do
                    self.db.itemFilters[classID][k] = not allChecked;
                end

            else
                self.db.itemFilters[classID] = not self.db.itemFilters[classID];
            end

        else
            if not self.db.itemFilters[classID] then

                if createSubClassTables[classID] then
                    self.db.itemFilters[classID] = {}
                end
            end
            if self.db.itemFilters[classID][subClassID] == nil then
                self.db.itemFilters[classID][subClassID] = true
            else
                if type(subClassID) == "number" then
                    self.db.itemFilters[classID][subClassID] = not self.db.itemFilters[classID][subClassID];
                else
                    self.db.itemFilters[classID] = not self.db.itemFilters[classID];
                end
            end

        end

        EpgpPlus.Callbacks:TriggerEvent("Database_OnItemFiltersChanged")
    end
end

function Database:GetItemFilters(classID, subClassID)
    if self.db.itemFilters then

        if subClassID == "all" then
            if (type(self.db.itemFilters[classID]) == "table") then

                local allChecked = true;
                for k, v in pairs(self.db.itemFilters[classID]) do
                    if (v == false) then
                        allChecked = false;
                    end
                end
                return allChecked;
            else
                return self.db.itemFilters[classID];
            end
        end

        if type(classID == "number") and type(subClassID == "number") and (self.db.itemFilters[classID] ~= nil) and (self.db.itemFilters[classID][subClassID] ~= nil) then
            return self.db.itemFilters[classID][subClassID];
        end
        if type(classID == "number") and self.db.itemFilters[classID] and (subClassID == nil) then
            return self.db.itemFilters[classID];
        end
        if (classID == nil) and (subClassID == nil) then
            return self.db.itemFilters
        end
    end
end

function Database:Search(searchTerm, data)
    local ret = {}
    --local searchFuncs = {}
    local matchesClassAndOrSubClass;
    searchTerm = searchTerm:lower()
    --for k, v in pairs(searchTerm) do
        --table.insert(searchFuncs, function(itemID)

        local function validateItem(itemID)
            local item = self.db.itemDb[itemID];
            if item then

                --flag to know we have an item matching the filters from the drop down
                matchesClassAndOrSubClass = false;

                if type(self.db.itemFilters[item.classID]) == "boolean" then
                    matchesClassAndOrSubClass = self.db.itemFilters[item.classID]
                else
                    matchesClassAndOrSubClass = self.db.itemFilters[item.classID] and self.db.itemFilters[item.classID][item.subClassID];
                end

                for stat, val in pairs(item.stats) do
                    if matchesClassAndOrSubClass and stat:find(searchTerm, nil, true) then
                        return true;
                    end
                end

                for k, v in pairs(item) do
                    if type(v) == "string" then
                        if matchesClassAndOrSubClass and v:lower():find(searchTerm, nil, true) then
                            return true;
                        end
                    end
                end

                -- if item[k] then
                --     return matchesClassAndOrSubClass and self.db.itemDb[itemID][k]:lower():find(v, nil, true)
                -- end
            end
        end
        --end)
    --end

    --if #searchFuncs > 0 then
        if data then
            for _, itemID in ipairs(data) do
                --for _, func in ipairs(searchFuncs) do
                    if validateItem(itemID) then
                        table.insert(ret, itemID)
                    end
                --end
            end
        else
            for itemID, _ in pairs(self.db.itemDb) do
                --for _, func in ipairs(searchFuncs) do
                    if validateItem(itemID) then
                        table.insert(ret, itemID)
                    end
                --end
            end
        end
    --end
    return ret;
end

function Database:FilterItems(items)
    local ret = {}
    for _, itemID in ipairs(items) do
        local item = self.db.itemDb[itemID];
        if item then
            if type(self.db.itemFilters[item.classID]) == "boolean" then
                if self.db.itemFilters[item.classID] == true then
                    table.insert(ret, itemID)
                end
            else
                if (self.db.itemFilters[item.classID] == true) and (self.db.itemFilters[item.classID][item.subClassID] == true) then
                    table.insert(ret, itemID)
                end
            end

        end
    end
    return ret, items;
end

function Database:ProcessLootItems(expansionIndex)
    if self.db and self.db.itemDb then
        for _, loot in ipairs(EpgpPlus.InstanceData) do
            if (loot.expansionIndex == expansionIndex) then
                if (self.db.itemDb[loot.itemID] == nil) then
                    self.db.itemDb[loot.itemID] = {}
                    local item = Item:CreateFromItemID(loot.itemID)
                    if item and (not item:IsItemEmpty()) then
                        item:ContinueOnItemLoad(function()
                            local itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID = C_Item.GetItemInfoInstant(loot.itemID)
                            self.db.itemDb[loot.itemID].name = item:GetItemName()
                            self.db.itemDb[loot.itemID].link = item:GetItemLink()
                            self.db.itemDb[loot.itemID].icon = icon
                            self.db.itemDb[loot.itemID].equipLoc = itemEquipLoc
                            self.db.itemDb[loot.itemID].classID = classID
                            self.db.itemDb[loot.itemID].subClassID = subClassID
                            self.db.itemDb[loot.itemID].itemType = itemType
                            self.db.itemDb[loot.itemID].itemSubType = itemSubType
                            self.db.itemDb[loot.itemID].expansionIndex = expansionIndex
                            self.db.itemDb[loot.itemID].instance = loot.name
                            self.db.itemDb[loot.itemID].encounter = loot.encounter
                            self.db.itemDb[loot.itemID].stats = {}
                            local stats = GetItemStats(item:GetItemLink())
                            for k, v in pairs(stats) do
                                self.db.itemDb[loot.itemID].stats[_G[k]:lower()] = v;
                            end
                        end)
                    end
                end
            end
        end
    end
end


--[[
    List functions
]]

function Database:DeleteList(list)
    if self.db and self.db.lists then
        local keyToRemove;
        for k, _list in ipairs(self.db.lists) do
            if (list.id == _list.id) then
                keyToRemove = k;
            end
        end
        if keyToRemove then
            table.remove(self.db.lists, keyToRemove)
            EpgpPlus.Callbacks:TriggerEvent("Database_OnListDeleted")
        end
    end
end

function Database:NewList()
    
    local player = EpgpPlus.Api.GetPlayerRealmName()

    local newList = {
        character = player,
        items = {},
        id = time(),
        icon = false,
        name = "New List",
    }

    if self.db and self.db.lists then
        table.insert(self.db.lists, 1, newList)
    end

    EpgpPlus.Callbacks:TriggerEvent("Database_OnNewListCreated", self.db.lists[1])

    return self.db.lists[1];
end

function Database:GetAllLists()
    if self.db and self.db.lists then
        return self.db.lists;
    end
end

function Database:IsItemInList(itemID, returnTable)
    local ret = {};
    if self.db and self.db.lists then
        for _, list in ipairs(self.db.lists) do
            for _, id in ipairs(list.items) do
                if (id == itemID) then
                    if returnTable then
                        table.insert(ret, list.id)
                    else
                        return true;
                    end
                end
            end
        end
    end
    return ret;
end

function Database:GetListByID(listID)

end

function Database:List_OnItemDeleted(itemID, listID)
    if self.db and self.db.lists then
        for _, list in ipairs(self.db.lists) do
            if list.id == listID then
                local keyToRemove;
                for k, id in ipairs(list.items) do
                    if id == itemID then
                        keyToRemove = k;
                    end
                end
                if keyToRemove then
                    table.remove(list.items, keyToRemove)
                    EpgpPlus.Callbacks:TriggerEvent("List_OnItemsChanged", list, true)
                end
            end
        end
    end
end

function Database:List_OnItemAdded(itemID, listID)
    if self.db and self.db.lists then
        for _, list in ipairs(self.db.lists) do
            if list.id == listID then
                table.insert(list.items, itemID)
                EpgpPlus.Callbacks:TriggerEvent("List_OnItemsChanged", list)
                return;
            end
        end
    end
end






function Database:NewPlayer(player)
    if self.db and self.db.characterDirectory then
        if self.db.characterDirectory[player.name] then
            
        else
            self.db.characterDirectory[player.name] = {
                level = player.level,
                class = player.class,
                guid = player.guid,
            }
        end
    end
end











--[[
    GUILD CONTROL
]]



EpgpPlus.Database = Database;