

local _, EpgpPlus = ...;

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

--[[


decided against json for the SV, will use only on exporting

---Create and return a JSON object for the log data
---@param sourcePlayer string player taking action
---@param pointType string ep or gp
---@param pointChange number the points being given or taken
---@param targetPlayer string the player being actioned
---@param itemLink string item link if looting log or ""
---@param comment string comments on action
---@return string jsonLogComment the JSON object
function EpgpPlus.Api.CreateLogComment(sourcePlayer, pointType, pointChange, targetPlayer, itemLink, comment)
    local tbl = {
        time = GetServerTime(),
        sourcePlayer = sourcePlayer or "",
        pointType = pointType or "",
        pointChange = pointChange or "",
        targetPlayer = targetPlayer or "",
        itemLink = itemLink or "",
        comment = comment or "",
    }
    return C_EncodingUtil.SerializeJSON(tbl)
end

function EpgpPlus.Api.DecodeLogComment(logComment)
    return C_EncodingUtil.DeserializeJSON(logComment)
end

]]



--[[

    log commnts need to have

    -source player
    -action taken
    -target player
    -time
    -itemLink (or "")
    -pointsChanged
    -pointDelta
    -user comment

]]

---Create and return a table to use a log entry
---@param sourcePlayer string player name takign action
---@param actionTaken string action being taken (can also be a number ID to use with action comments in constants)
---@param targetPlayer string player being actioned
---@param pointsChanged string ep or gp or both or none
---@param pointsDelta string the before and after points [ep,gp] > [ep,gp] "this was at first just a number value but the logs looked odd"
---@param itemLink string item link or ""
---@param userComment string any user comment
---@param time number time of action returned by GetServerTime()
---@return table log Entry the entry to share to guild
---@return string sourcePlayer name of player taking action
---@return number serverTime the time of the action
function EpgpPlus.Api.CreateLogEntry(sourcePlayer, actionTaken, targetPlayer, pointsChanged, pointsDelta, itemLink, userComment, time)

    -- if type(actionTaken) == "number" then
    --     actionTaken = EpgpPlus.Constants.LogActionTakenComments[actionTaken]
    -- end

    sourcePlayer = sourcePlayer and sourcePlayer or "";
    actionTaken = actionTaken and actionTaken or "";
    targetPlayer = targetPlayer and targetPlayer or "";
    pointsChanged = pointsChanged and pointsChanged or "";
    pointsDelta = pointsDelta and pointsDelta or "";
    itemLink = itemLink and itemLink or "";
    userComment = userComment and userComment or "";
    time = time and time or GetServerTime();
    
    --as this will go through comms lets shorten it
    local entry = {
        src = sourcePlayer,
        actn = actionTaken,
        tar = targetPlayer,
        pchn = pointsChanged,
        pdel = pointsDelta,
        il = itemLink,
        ucmt = userComment,
        tme = time,
    }

    return entry, sourcePlayer, time;
end


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--[[
    Player functions
]]
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

---Return the players name in a name-realm format with optional colour hex
---@param useClassColor boolean? optional flag to colour the return string
---@return string name players name
function EpgpPlus.Api.GetPlayerRealmName(useClassColor)
    local name, realm = UnitName("player")
    if realm == nil then
        realm = GetNormalizedRealmName()
    end

    if useClassColor then
        local _, class = UnitClass("player");
        return RAID_CLASS_COLORS[class]:WrapTextInColorCode(string.format("%s-%s", name, realm))
    else
        return string.format("%s-%s", name, realm)
    end
end

function EpgpPlus.Api.GetUnitEquipment(unit)
    local equipment = {}
    for k, v in ipairs(EpgpPlus.Constants.InventorySlots) do
        local link = GetInventoryItemLink(unit, GetInventorySlotInfo(v.slot)) or false
        equipment[v.slot] = link
    end
    return equipment;
end

function EpgpPlus.Api.GetUnitInventoryForEquipLocation(unit, equipLocation)
    local slotIndex = EpgpPlus.Constants.EquipLocationToSlotIndex[equipLocation]

    if type(slotIndex) == "number" then
        return GetInventoryItemLink(unit, slotIndex) or false

    elseif type(slotIndex) == "table" then

        --for now just return the first slot
        --TODO make UI handle 2 links
        return GetInventoryItemLink(unit, slotIndex[1]) or false
    end

    -- for k, v in ipairs(EpgpPlus.Constants.InventorySlots) do
    --     local link = GetInventoryItemLink(unit, GetInventorySlotInfo(v.slot)) or false
    --     if link then
    --         local itemID, _, _, equipLoc = C_Item.GetItemInfoInstant(link)
    --         if (equipLoc == equipLocation) then
    --             return link, itemID;
    --         end
    --     end
    -- end
end

function EpgpPlus.Api.GetUnitInventoryForSlot(unit, slotIndex)
    return GetInventoryItemLink(unit, GetInventorySlotInfo(slotIndex))
end

function EpgpPlus.Api.GetPlayerItemLevel()
    local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvp = GetAverageItemLevel()
    return avgItemLevelEquipped;
end

function EpgpPlus.Api.SplitOfficerNote(note)
    local ep, gp = strsplit(",", note);
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

function EpgpPlus.Api.GetItemGearPointValue(itemID)
    local id, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
    for _, invType in ipairs(EpgpPlus.Constants.GearPoints) do
        if (itemEquipLoc == invType.slot) then
            local ilvl = C_Item.GetDetailedItemLevelInfo(itemID)
            local itemQuality = C_Item.GetItemQualityByID(itemID)

            if ilvl and itemQuality then

                --formula taken from other epgp addon so we maintain item gp values
                --for now the slot modifiers are just hardcoded
                return math.floor(4.83 * (2 ^ ((ilvl / 26) + (itemQuality - 4)) * invType.modifier) * 1);
            end
        end
    end
end







--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--[[
    Loot function (master looter)
]]
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
function EpgpPlus.Api.GetTargetLoot()

    --https://warcraft.wiki.gg/wiki/API_GetLootSourceInfo

    local t = {}
    local link, itemName, equipLoc, itemID, classID, subClassID, texture, quantity, currencyID, itemQuality, isQuestItem, questID, locked, startsQuest

    local numLoot = GetNumLootItems()
    for i = 1, numLoot do
        if LootSlotHasItem(i) then

            texture, itemName, quantity, currencyID, itemQuality, locked, isQuestItem, questID, startsQuest = GetLootSlotInfo(i)
            
            if GetLootSlotType(i) == Enum.LootSlotType.Item then
                
                link = GetLootSlotLink(i)
                itemID, _, _, equipLoc, _, classID, subClassID = C_Item.GetItemInfoInstant(link)

                --this table will be sent via comms so it should be kept as minimal as possible
                table.insert(t, {
                    --icon = texture,
                    --itemID = itemID,
                    link = link,
                    --itemQuality = itemQuality,
                    slot = i,
                    --equipLoc = equipLoc,
                })

            end

        elseif GetLootSlotType(i) == Enum.LootSlotType.Money then
            LootSlot(i)
        end

    end


    --testing
    -- table.insert(t, {
    --     link = "|cffa335ee|Hitem:34176::::::::70::::::::::|h[Reign of Misery]|h|r",
    -- })
    -- table.insert(t, {
    --     link = "|cffa335ee|Hitem:29754::::::::70::::::::::|h[Chestguard of the Fallen Champion]|h|r",
    -- })
    -- table.insert(t, {
    --     link = "|cffa335ee|Hitem:28506::::::::70::::::::::|h[Gloves of Dexterous Manipulation]|h|r",
    -- })

    return t;
end


--[[
function MasterLooterPlayerFrame_OnClick(self)
	MasterLooterFrame.slot = LootFrame.selectedSlot;
	MasterLooterFrame.candidateId = self.id;
	if ( LootFrame.selectedQuality >= Constants.LootConsts.MasterLootQualityThreshold ) then
		local textArg1 = LootFrame.selectedItemName;
		local colorData = ColorManager.GetColorDataForItemQuality(LootFrame.selectedQuality);
		if colorData then
			textArg1 = colorData.hex..LootFrame.selectedItemName..FONT_COLOR_CODE_CLOSE;
		end

		StaticPopup_Show("CONFIRM_LOOT_DISTRIBUTION", textArg1, self.Name:GetText(), "LootWindow");
	else
		MasterLooterFrame_GiveMasterLoot();
	end
end
]]




--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--[[
    Group functions
]]
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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

function EpgpPlus.Api.GetGroupMemberIndex(name, realm)
    if realm == nil then
        realm = GetNormalizedRealmName()
    end

    --print(name, realm)

    for index = 1, 40 do
        local _name = GetRaidRosterInfo(index)
        --print(index, _name, name)
        if (_name == name) or (_name == string.format("%s-%s", name, realm)) then
            return index;
        end
    end
end

function EpgpPlus.Api.IsMasterLooter()
    local name, realm = UnitName("player")
    if realm == nil then
        realm = GetNormalizedRealmName()
    end
    for index = 1, 40 do
        local _name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(index)

        if (_name == name) or (_name == string.format("%s-%s", name, realm)) then
            return isML;
        end
    end
end











--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--[[
    Guild functions
]]
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

local function SetOfficerNoteForPlayer(nameOrGUID, newNote, comment)
    local rosterIndex = EpgpPlus.Api.GetGuildRosterIndex(nameOrGUID)
    if rosterIndex then
        SetGuildRosterSelection(rosterIndex)

        if (EpgpPlus.Database:GetConfig("safetyModeActive") == false) then
            GuildRosterSetOfficerNote(GetGuildRosterSelection(), newNote)
        end

        EpgpPlus.Comms:SendGuildMessage("OnPointsLogEntryReceived", comment)
    end
end

local function GetOfficerNoteForPlayer(nameOrGUID, returnTable)
    if IsInGuild() and GetGuildInfo("player") then
        C_GuildInfo.GuildRoster()
        local totalMembers, onlineMember, _ = GetNumGuildMembers()
        for i = 1, totalMembers do
            local name, _, _, _, _, _, _, officerNote, _, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(i)
            if (nameOrGUID == name) or (nameOrGUID == guid) then
                
                if returnTable == true then

                    --if the note isn't as expected just set it to default
                    local ep, gp = 0, 1;
                    if (officerNote ~= nil) and (officerNote ~= " ") and (officerNote:find(",", nil, true)) then
                        ep, gp = strsplit(",", officerNote)
                        ep = tonumber(ep);
                        gp = tonumber(gp);
                    end
                    return { ep = ep, gp = gp, }
                else
                    return officerNote;
                end
            end
        end
    end
end

function EpgpPlus.Api.GetGuildMembersNames()
    local guildRoster = {}
    C_GuildInfo.GuildRoster();
    local totalMembers, onlineMember, _ = GetNumGuildMembers()
    for i = 1, totalMembers do
        local _name = GetGuildRosterInfo(i);
        guildRoster[_name] = true;
    end
    return guildRoster;
end

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

function EpgpPlus.Api.ScanGuildRoster()

end

---Collect point data for all guild members
---@return table ret table of data
function EpgpPlus.Api.BuildSyncData()
    if C_GuildInfo.CanEditOfficerNote() then
        local ret = {};
        if IsInGuild() and GetGuildInfo("player") then
            C_GuildInfo.GuildRoster()
            local numMembers = GetNumGuildMembers()
            for i = 1, numMembers do
                local name, rankName, _, level, _, _, publicNote, officerNote, _, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(i)
                

                local ep, gp, pr;
                if (officerNote ~= nil) and (officerNote ~= " ") and (officerNote:find(",", nil, true)) then
                    ep, gp = strsplit(",", officerNote)
                    ep = tonumber(ep);
                    gp = tonumber(gp);
                    pr = (ep / gp)
                end

                -- table.insert(ret, {
                --     ep = ep,
                --     gp = gp,
                --     pr = pr,
                --     name = name,
                -- })

                ret[name] = {
                    ep = ep,
                    gp = gp,
                    pr = pr,
                }

                --print(name, ep, gp , pr)
            end
        end
        local source = EpgpPlus.Api.GetPlayerRealmName()
        return {
            source = source,
            data = ret,
            syncTime = GetServerTime()
        }
    end
end

--this is used to populate the epgp guild listview
function EpgpPlus.Api.GetGuildMembers()
    local ret = {}
    local playerPoints;
    local syncData = EpgpPlus.Database:GetEpGpSyncData();
    if syncData then
        local findData = function(name)
            if syncData.data[name] then
                return syncData.data[name]
            end
            return { ep = 0, gp = 1, pr = (0/1), }
        end
        if IsInGuild() and GetGuildInfo("player") then
            C_GuildInfo.GuildRoster()
            local numMembers = GetNumGuildMembers()
            for i = 1, numMembers do
                local name, rankName, _, level, _, _, publicNote, officerNote, _, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(i)
                
                playerPoints = findData(name)

                table.insert(ret, {
                    name = name,
                    rank = rankName,
                    level = level,
                    publicNote = publicNote,
                    class = class,
                    guid = guid,
                    ep = playerPoints.ep,
                    gp = playerPoints.gp,
                    pr = playerPoints.pr,
                })
            end
        end
        return ret, syncData.syncTime, syncData.source;
    end
end


--return the sync data instead with the updated sync method
function EpgpPlus.Api.GetGuildMembersPoints(nameOrGUID)

    return EpgpPlus.Database:GetEpGpSyncData(nameOrGUID);

    -- local ret = {}
    -- local canEditOfficerNote = C_GuildInfo.CanEditOfficerNote();
    -- local syncData, findData, playerPoints;
    -- if (canEditOfficerNote == false) then
    --     syncData = EpgpPlus.Database:GetEpGpSyncData();
    --     findData = function(name)
    --         for _, info in ipairs(syncData.data) do
    --             if (info.name == nameOrGUID) then
    --                 --DevTools_Dump({info})
    --                 return info;
    --             end
    --         end
    --         return { ep = 0, gp = 1, pr = (0/1), }
    --     end
    -- end
    -- if IsInGuild() and GetGuildInfo("player") then
    --     C_GuildInfo.GuildRoster()
    --     local numMembers = GetNumGuildMembers()
    --     for i = 1, numMembers do
    --         local name, rankName, _, level, _, _, publicNote, officerNote, _, _, class, _, _, _, _, _, guid = GetGuildRosterInfo(i)


    --         if canEditOfficerNote == true then

    --             local ep, gp, pr;
    --             if (officerNote ~= nil) and (officerNote ~= " ") and (officerNote:find(",", nil, true)) then
    --                 ep, gp = strsplit(",", officerNote)
    --                 ep = tonumber(ep) or 1;
    --                 gp = tonumber(gp) or 1;
    --                 pr = (ep / gp)
    --             end

    --             if nameOrGUID and ((nameOrGUID == name) or (nameOrGUID == guid)) then
    --                 return {
    --                     ep = ep,
    --                     gp = gp,
    --                     pr = pr,
    --                 }
    --             end

    --             table.insert(ret, {
    --                 name = name,
    --                 ep = ep,
    --                 gp = gp,
    --                 pr = pr,
    --             })

    --         else
    --             playerPoints = findData(name)

    --             if nameOrGUID and ((nameOrGUID == name) or (nameOrGUID == guid)) then
    --                 return playerPoints;

    --             else
    --                 table.insert(ret, {
    --                     name = name,
    --                     ep = playerPoints.ep,
    --                     gp = playerPoints.gp,
    --                     pr = playerPoints.pr,
    --                 })
    --             end

    --         end
    --     end
    -- end
    -- return ret;
end


function EpgpPlus.Api.ParseCSV(csv)
    local name, ep, gp, pr;
    local inRows = 0;
    local outTbl = {}
    csv = csv:gsub("\n", "")
    local inStr = {strsplit(",", csv)}
    for i = 1, (#inStr - 3), 4 do
        name = inStr[i]
        ep = inStr[i+1]
        gp = inStr[i+2]
        pr = inStr[i+3]

        outTbl[name] = string.format("%d,%d", ep, gp);
        inRows = inRows + 1;
    end

    --DevTools_Dump({outTbl})

    local guildRoster = EpgpPlus.Api.GetGuildMembersNames()

    local displayText = "";
    local outRows = 0;
    local errors = 0;
    for name, note in pairs(outTbl) do
        if (guildRoster[name] == true) then
            if displayText == "" then
                displayText = string.format("|cff40C040[%s] = %s|r", name, note)
            else
                displayText = string.format("%s\n|cff40C040[%s] = %s|r", displayText, name, note)
            end
            outRows = outRows + 1;

        else
            if displayText == "" then
                displayText = string.format("|cffCC1919[%s] = %s|r", name, note)
            else
                displayText = string.format("%s\n|cffCC1919[%s] = %s|r", displayText, name, note)
            end
            errors = errors + 1;
        end
    end

    return {
        errors = errors,
        inRows = inRows,
        outRows = outRows,
        displayText = displayText,
        outTbl = outTbl,
    }
end


function EpgpPlus.Api.ImportData(data)

    local realm = GetNormalizedRealmName()
    local isSafetyModeActive = EpgpPlus.Database:GetConfig("safetyModeActive");

    if isSafetyModeActive == true then
        return;
    end

    if IsInGuild() and GetGuildInfo("player") and C_GuildInfo.CanEditOfficerNote() then
        C_GuildInfo.GuildRoster()
        local totalMembers, onlineMember, _ = GetNumGuildMembers()
        for i = 1, totalMembers do
            local name, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)

            if data and data[name] then
                SetGuildRosterSelection(i)
                GuildRosterSetOfficerNote(i, data[name])

            elseif data and data[name.."-"..realm] then
                SetGuildRosterSelection(i)
                GuildRosterSetOfficerNote(i, data[name.."-"..realm])
            end

        end
    end
end


---Set the guild members points, hard set no math applied
---@param members table table of players {t[name] = true}
---@param newEP number new ep value
---@param newGP number new gp value
---@param comment string comment for change
function EpgpPlus.Api.SetGuildMembersPoints(members, newEP, newGP, comment)

    local realm = GetNormalizedRealmName()
    local isSafetyModeActive = EpgpPlus.Database:GetConfig("safetyModeActive");

    local numMembers = 0;
    for k, v in pairs(members) do
        numMembers = numMembers + 1;
    end
    local newNote;
    local oldEP, oldGP
    local pointChanged = "";
    if newEP and newGP then
        pointChanged = "ep:gp";
    else
        if newEP then
            pointChanged = "ep";
        elseif newGP then
            pointChanged = "gp";
        end
    end

    if IsInGuild() and GetGuildInfo("player") and C_GuildInfo.CanEditOfficerNote() then
        C_GuildInfo.GuildRoster()
        local totalMembers, onlineMember, _ = GetNumGuildMembers()
        for i = 1, totalMembers do
            local name, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)

            if members and (members[name] or members[name.."-"..realm]) then

                local ep, gp = 0, 1;
                if (officerNote ~= nil) and (officerNote ~= " ") and (officerNote:find(",", nil, true)) then
                    ep, gp = strsplit(",", officerNote)
                    ep = tonumber(ep);
                    gp = tonumber(gp);
                end

                oldEP, oldGP = ep, gp;

                if type(newEP) == "number" then
                    ep = newEP;
                end

                if type(newGP) == "number" then
                    gp = newGP;
                end

                newNote = string.format("%d,%d", ep, gp)

                if (isSafetyModeActive == false) then
                    SetGuildRosterSelection(i)
                    GuildRosterSetOfficerNote(i, newNote)
                else
                    print("+++++ Safety Mode Active +++++ [EpgpPlus.Api.SetGuildMembersPoints]")
                    --DevTools_Dump({ member = name, newOfficerNote = newNote, })
                end

                if (numMembers == 1) then

                    local logEntry = EpgpPlus.Api.CreateLogEntry(
                        UnitName("player"), 
                        5, 
                        name, 
                        pointChanged, 
                        string.format("[%d,%d] > [%d,%d]", oldEP, oldGP, newEP, newGP), 
                        "", 
                        comment, 
                        GetServerTime()
                    )

                    EpgpPlus.Comms:SendGuildMessage("OnPointsLogEntryReceived", logEntry)
                end

            end

        end

        if (numMembers > 1) then
            
            local logEntry = EpgpPlus.Api.CreateLogEntry(
                UnitName("player"), 
                5, 
                "Multiple Players", 
                pointChanged, 
                string.format("[%d,%d]", newEP, newGP), 
                "", 
                comment, 
                GetServerTime()
            )

            EpgpPlus.Comms:SendGuildMessage("OnPointsLogEntryReceived", logEntry)
        end
    end


end

---Apply new points to guild member
---@param members table t[name] table of players
---@param pointType string "ep"/"gp" denotes the point type to apply
---@param points number point value
---@param userComment string log comment
---@param itemLink string item link if awarded
---@param actionID number index used for EpgpPlus.Constants.LogActionTakenComments
function EpgpPlus.Api.AdjustGuildMembersPoints(members, pointType, points, userComment, itemLink, actionID)

    local realm = GetNormalizedRealmName()

    local isSafetyModeActive = EpgpPlus.Database:GetConfig("safetyModeActive");

    local numMembers = 0;
    for k, v in pairs(members) do
        numMembers = numMembers + 1;
    end

    if IsInGuild() and GetGuildInfo("player") and C_GuildInfo.CanEditOfficerNote() then
        C_GuildInfo.GuildRoster()
        local totalMembers, onlineMember, _ = GetNumGuildMembers()
        for i = 1, totalMembers do
            local name, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)

            if members and (members[name] or members[name.."-"..realm]) then

                local ep, gp = 0, 1;
                if (officerNote ~= nil) and (officerNote ~= " ") and (officerNote:find(",", nil, true)) then
                    ep, gp = strsplit(",", officerNote)
                    ep = tonumber(ep);
                    gp = tonumber(gp);
                end

                local t = {
                    ep = ep,
                    gp = gp,
                }

                t[pointType] = t[pointType] + points;

                local newNote = string.format("%d,%d", t.ep, t.gp)

                if (isSafetyModeActive == false) then
                    SetGuildRosterSelection(i)
                    GuildRosterSetOfficerNote(i, newNote)
                else
                    print("+++++ Safety Mode Active +++++ [EpgpPlus.Api.SetGuildMembersPoints]")
                    print(string.format("[%d] new points: %d,%d", name, t.ep, t.gp))
                    --DevTools_Dump({ member = name, newOfficerNote = newNote, })
                end

                if (numMembers == 1) then
                    local comment = EpgpPlus.Api.CreateLogEntry(
                        EpgpPlus.Api.GetPlayerRealmName(), 
                        actionID or 4, 
                        name, 
                        pointType, 
                        string.format("[%d,%d] > [%d,%d]", ep, gp, t.ep, t.gp), 
                        itemLink or "", 
                        userComment, 
                        GetServerTime()
                    )
                    EpgpPlus.Comms:SendGuildMessage("OnPointsLogEntryReceived", comment)
                end

            end

        end

    end

    if (numMembers > 1) then
        local comment = EpgpPlus.Api.CreateLogEntry(
            EpgpPlus.Api.GetPlayerRealmName(), 
            actionID or 4, 
            "Multiple Players", 
            pointType, 
            string.format("%s %d", pointType, points), 
            itemLink or "", 
            userComment, 
            GetServerTime()
        )
        EpgpPlus.Comms:SendGuildMessage("OnPointsLogEntryReceived", comment)
    end


    --local currentValues = GetOfficerNoteForPlayer(nameOrGUID, true)

    --DevTools_Dump({currentValues})
    -- if currentValues and currentValues[pointType] then

    --     local oldEP, oldGP = currentValues.ep, currentValues.gp;

    --     currentValues[pointType] = (currentValues[pointType] + points)
    --     local newNote = string.format("%d,%d", currentValues.ep, currentValues.gp)


    --     local comment = EpgpPlus.Api.CreateLogEntry(
    --         EpgpPlus.Api.GetPlayerRealmName(), 
    --         actionID or 4, 
    --         nameOrGUID, 
    --         pointType, 
    --         string.format("[%d,%d] > [%d,%d]", oldEP, oldGP, currentValues.ep, currentValues.gp), 
    --         itemLink or "", 
    --         userComment, 
    --         GetServerTime()
    --     )


    --     SetOfficerNoteForPlayer(nameOrGUID, newNote, comment)
    -- end

end

local function ApplyDecay(value, decay)
    if value == 0 then
        return 0;
    end
    return value - math.ceil(value * decay);
end

function EpgpPlus.Api.ApplyGuildDecay(decayPercent, decayEP, decayGP, members)
    
    local realm = GetNormalizedRealmName()
    local isSafetyModeActive = EpgpPlus.Database:GetConfig("safetyModeActive");

    --print(decayPercent, tostring(decayEP), tostring(decayGP))

    if IsInGuild() and GetGuildInfo("player") and C_GuildInfo.CanEditOfficerNote() then
        C_GuildInfo.GuildRoster()
        local totalMembers, onlineMember, _ = GetNumGuildMembers()
        for i = 1, totalMembers do
            local name, _, _, _, _, _, _, officerNote = GetGuildRosterInfo(i)

            local ep, gp, newEP, newGP;
            if (officerNote ~= nil) and (officerNote ~= " ") and (officerNote:find(",", nil, true)) then
                ep, gp = strsplit(",", officerNote)
                ep = tonumber(ep);
                gp = tonumber(gp);
            end

            if ep and gp and (members and (members[name] or members[name.."-"..realm])) then

                --print(name, ep, gp)
                
                if (decayEP == true) then
                    newEP = ApplyDecay(ep, decayPercent)
                    -- print(ep, newEP)

                    -- local decay = (ep / 100) * decayPercent;
                    -- local newEpVal = ep - decay;
                    -- print(decay, newEpVal)
                else
                    newEP = ep;
                end
                if (decayGP == true) then
                    newGP = ApplyDecay(gp, decayPercent)
                else
                    newGP = gp;
                end

                --print(newEP, newGP)

                local newNote = string.format("%d,%d", newEP, newGP)

                if (isSafetyModeActive == false) then
                    SetGuildRosterSelection(i)
                    GuildRosterSetOfficerNote(i, newNote)
                else
                    print("+++++ Safety Mode Active +++++ [EpgpPlus.Api.ApplyGuildDecay]")
                    --ools_Dump({ member = name, newOfficerNote = newNote, })
                end
            end

        end

        local player = UnitName("player")

        local pointChanged = "";
        if decayEP and decayGP then
            pointChanged = "ep:gp";
        else
            if decayEP then
                pointChanged = "ep";
            elseif decayGP then
                pointChanged = "gp";
            end
        end

        local decayLogValue = string.format("%d%%", (decayPercent * 100))
        local logEntry = EpgpPlus.Api.CreateLogEntry(
            player,
            6,
            "Multiple Players",
            pointChanged,
            decayLogValue,
            "",
            "Apply decay",
            GetServerTime()
        )
        EpgpPlus.Comms:SendGuildMessage("OnPointsLogEntryReceived", logEntry)


        --[[
            I'd like to find a way to log the players who had decay affect them but its going to hurt the comms.....
        ]]
        
        --print(string.format("[%s] (Old EP: %d New EP: %d) (Old GP: %d New GP: %d)", name, ep, newEP, gp, newGP))
    end
end









--[[
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
]]
