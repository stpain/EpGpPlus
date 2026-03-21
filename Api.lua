

local _, EpgpPlus = ...;

local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub:GetLibrary("LibSerialize")

EpgpPlus.Api = {}

local rndClass = {
    "PALADIN",
    "WARRIOR",
    "HUNTER",
    "MAGE",
    "DRUID",
    "PRIEST",
    "WARLOCK",
    "ROGUE",
}
function EpgpPlus.Api.CreateTestGroup(maxSize)
    local ret = {
        {
            name = UnitName("player"),
            class = select(2, UnitClass("player"))
        },
    }
    for i = 1, (maxSize - 1) do
        local player = {
            name = string.format("Player-%d", i),
            class = rndClass[math.random(1, #rndClass)],
        }
        table.insert(ret, player)
    end
    return ret;
end

function EpgpPlus.Api.GetPlayerRealmName()
    local name, realm = UnitName("player")
    if realm == nil then
        realm = GetNormalizedRealmName()
    end
    return string.format("%s-%s", name, realm)
end

function EpgpPlus.Api.GetUnitEquipment(unit)
    local equipment = {}
    for k, v in ipairs(EpgpPlus.InventorySlots) do
        local link = GetInventoryItemLink(unit, GetInventorySlotInfo(v.slot)) or false
        equipment[v.slot] = link
    end
    return equipment;
end

function EpgpPlus.Api.GetPlayerItemLevel()
    local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvp = GetAverageItemLevel()
    return avgItemLevelEquipped;
end

--[[
    Loot functions
]]

function EpgpPlus.Api.OpenAddItemContextMenu(parent, itemID)
    MenuUtil.CreateContextMenu(parent, function(_, rootDescription)
        rootDescription:CreateTitle("Select List")
        rootDescription:CreateDivider()
        rootDescription:CreateButton(string.format("New List %s", CreateAtlasMarkup("bags-icon-addslots", 18, 18)), function() --add atlas markup for + symbol
            local newList = EpgpPlus.Database:NewList()
            EpgpPlus.Callbacks:TriggerEvent("List_OnItemAdded", itemID, newList.id)
        end)
        local _allLists = EpgpPlus.Database:GetAllLists()
        if _allLists then
            for _, list in ipairs(_allLists) do
                rootDescription:CreateButton(list.name, function()
                    EpgpPlus.Callbacks:TriggerEvent("List_OnItemAdded", itemID, list.id)
                end)
            end
        end
    end)
end

function EpgpPlus.Api.GetInstanceExpansionIndex(instanceName)
    for _, instance in ipairs(EpgpPlus.InstanceData) do
        if instance.name == instanceName then
            return instance.expansionIndex
        end
    end
end

function EpgpPlus.Api.GetInstanceNames(expansionIndex)
    local ret = {}
    local t = {}
    for _, instance in ipairs(EpgpPlus.InstanceData) do
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

function EpgpPlus.Api.GetInstanceEncounters(instanceName)
    local ret = {}
    local t = {}
    for _, instance in ipairs(EpgpPlus.InstanceData) do
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

function EpgpPlus.Api.GetEncounterLoot(instanceName, encounterName)
    local ret = {}
    for _, instance in ipairs(EpgpPlus.InstanceData) do
        if (instance.name == instanceName) and (instance.encounter == encounterName) then
            table.insert(ret, instance.itemID)
        end
    end
    return ret;
end

function EpgpPlus.Api.GetAllInstanceLoot(instanceName)
    local ret = {}
    for _, instance in ipairs(EpgpPlus.InstanceData) do
        if (instance.name == instanceName) then
            table.insert(ret, instance.itemID)
        end
    end
    return ret;
end


--[[
    Group functions
]]
function EpgpPlus.Api.GetGroupRoster(useNameKeys)
    local ret = {}
    for index = 1, 40 do
        local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(index)
        if useNameKeys and name then
            ret[name] = {
                name = name,
                rank = rank,
                level = level,
                class = fileName,
                index = index,
            }
        else
            table.insert(ret, {
                name = name,
                rank = rank,
                level = level,
                class = fileName,
                index = index,
            })
        end
    end
    return ret;
end

function EpgpPlus.Api.GetGroupMemberEquipment()
    
end


--[[
    Guild functions
]]
function EpgpPlus.Api.GetGuildRanks()
    local ret = {}
    if IsInGuild() and GetGuildInfo("player") then
        for i = 1, GuildControlGetNumRanks() do
            local name = GuildControlGetRankName(i)
            if name then
                table.insert(ret, name)
            end
        end
    end
    return ret;
end

function EpgpPlus.Api.GetGuildRosterIndex(nameOrGUID)
    if IsInGuild() and GetGuildInfo("player") then
        C_GuildInfo.GuildRoster()
        local totalMembers, onlineMember, _ = GetNumGuildMembers()
        for i = 1, totalMembers do
            local name, rankName, rankIndex, level, _, zone, publicNote, officerNote, isOnline, status, class, _, _, _, _, _, guid = GetGuildRosterInfo(i)
            if (nameOrGUID == name) or (nameOrGUID == guid) then
                return i
            end
        end
    end
end

function EpgpPlus.Api.GetGuildMembers()
    local ret = {}
    if IsInGuild() and GetGuildInfo("player") then
        C_GuildInfo.GuildRoster()
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local name, rankName, _, level, _, _, publicNote, officerNote, _, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(i)
            --if level == 60 then

                local ep, gp, pr;
                if (officerNote ~= nil) and (officerNote ~= " ") and (officerNote:find(",", nil, true)) then
                    ep, gp = strsplit(",", officerNote)
                    ep = tonumber(ep)
                    gp = tonumber(gp)
                    pr = (ep / gp)
                end

                table.insert(ret, {
                    name = name,
                    rank = rankName,
                    level = level,
                    publicNote = publicNote,
                    officerNote = officerNote,
                    class = class,
                    guid = guid,
                    ep = ep,
                    gp = gp,
                    pr = pr,
                })
            --end
        end
    end
    return ret;
end

function EpgpPlus.Api.DecodeOfficerNote(note)
    local officerNoteDecoded = LibDeflate:DecodeForPrint(note)
    if officerNoteDecoded then
        local decompressed = LibDeflate:DecompressDeflate(officerNoteDecoded);
        if decompressed then
            local success, data = LibSerialize:Deserialize(decompressed);
            if success and type(data) == "table" then
                return data;
            end
        end
    end
end

function EpgpPlus.Api.EncodeOfficerNote(note)
    local serialized = LibSerialize:Serialize(note);
    local compressed = LibDeflate:CompressDeflate(serialized);
    local encoded = LibDeflate:EncodeForPrint(compressed);
    return encoded;
end


--[[
    Session Table
    {
        host [string] - the player who created and opened the session
        created [number] - a timestamp of when the session was created
        instance [string] = instanceName,
        players [table] - list of players in the group

            players[name] = {
                reserves = {
                    itemID = payload.itemID,
                    itemLink = payload.itemLink,
                    bonusRoll = 0,    
                }
            }

        log [table] - list of events for the session
        softReserves [table] - list of itemIDs > list of players ---->>>>>>REMOVED
        hardReserves [table] - list of itemIDs that are hard reserved for the sesison
        defaultNumReserves [number] - default SR for each player
        multiReserve [boolean] - flag to allow multi reserves on items
    }
]]

--[[
    Session API - requires ActiveSession to be set
]]

local ActiveSession;

function EpgpPlus.Api.SetActiveSession(session)
    -- if EpgpPlus.Database and EpgpPlus.Database.db then
    --     for k, v in ipairs(EpgpPlus.Database.db.sessions) do
    --         if (v.host == session.host) and (v.created == session.created) then
    --             ActiveSession = v;
    --             if ViragDevTool_AddData then
    --                 ViragDevTool_AddData(ActiveSession, "ActiveSession")
    --             end
    --             return;
    --         end
    --     end
    -- end
    ActiveSession = session;
end

function EpgpPlus.Api.ClearActiveSession()
    ActiveSession = nil;
end

function EpgpPlus.Api.SendItemReserve(itemID, itemLink)
    if ActiveSession then
        EpgpPlus.Comms:Transmit_SetItemReserve(ActiveSession.host, ActiveSession.created, itemID, itemLink)
    end
end

function EpgpPlus.Api.GetReservesForPlayer(playerName)
    local ret = {}
    if ActiveSession and ActiveSession.players[playerName] then
        for k, v in ipairs(ActiveSession.players[playerName].reserves) do
            ret[v.itemID] = true;
        end
    end
    return ret;
end

function EpgpPlus.Api.GetReservesForItemID(itemID)
    --print("finding reserves for:", itemID)
    local ret = {}
    if ActiveSession then
        for name, info in pairs(ActiveSession.players) do
            --print(name)
            if info.reserves then
                for k, v in ipairs(info.reserves) do
                    --DevTools_Dump({v})
                    if v.itemID == itemID then
                        table.insert(ret, {
                            name = name,
                            class = info.class, --this allows the addon to use RAID_CLASS_COLORS[class]:WrapTextInColorCode(name)
                        })
                    end
                end
            end
        end
    end
    return ret;
end