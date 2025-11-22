

local addonName, SoftResPlus = ...;


local DatabaseDefaults = {
    characterDirectory = {},
    instances = {},
    lists = {},
    logs = {},
    config = {},
    sessions = {},
}

local Database = {}
function Database:Init(reset)

    if (SoftResPlusSavedVar == nil) or (reset == true) then
        SoftResPlusSavedVar = {}
    end

    for k, v in pairs(DatabaseDefaults) do
        if SoftResPlusSavedVar[k] == nil then
            SoftResPlusSavedVar[k] = v
        end
    end

    for k, v in pairs(SoftResPlusSavedVar) do
        if DatabaseDefaults[k] == nil then
            SoftResPlusSavedVar[k] = nil;
        end
    end

    self.db = SoftResPlusSavedVar;

    if ViragDevTool_AddData then
        ViragDevTool_AddData(SoftResPlusSavedVar, addonName)
    end

    SoftResPlus.Callbacks:RegisterCallback("List_OnItemAdded", self.List_OnItemAdded, self)
    SoftResPlus.Callbacks:RegisterCallback("List_OnItemDeleted", self.List_OnItemDeleted, self)

    SoftResPlus.Callbacks:TriggerEvent("Database_OnInitialized")
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
                    SoftResPlus.Callbacks:TriggerEvent("List_OnItemsChanged", list, true)
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
                SoftResPlus.Callbacks:TriggerEvent("List_OnItemsChanged", list)
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

function Database:GetAllSessions()
    if self.db and self.db.sessions then
        return self.db.sessions;
    end
end

function Database:NewSession(instanceName)
    if self.db and self.db.sessions then
        local time = GetServerTime()
        local player = SoftResPlus.Api.GetPlayerRealmName()
        local newSession = {
            created = time,
            owner = player,
            instance = instanceName,
            players = {},
            log = {
                [1] = string.format("Session created by %s", player),
            },
            softReserves = {},
            hardReserves = {},
            defaultNumReserves = 2,
            multiReserve = false,
        }
        table.insert(self.db.sessions, 1, newSession)
        SoftResPlus.Callbacks:TriggerEvent("Database_OnSessionCreated", self.db.sessions[1])
    end
end

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
            SoftResPlus.Callbacks:TriggerEvent("Database_OnListDeleted")
        end
    end
end

function Database:NewList()
    
    local player = SoftResPlus.Api.GetPlayerRealmName()

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

    SoftResPlus.Callbacks:TriggerEvent("Database_OnNewListCreated", self.db.lists[1])
end

function Database:GetAllLists()
    if self.db and self.db.lists then
        return self.db.lists;
    end
end

function Database:NewLog()
    
end


SoftResPlus.Database = Database;