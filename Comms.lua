

local addonName, EpgpPlus = ...;

local AceComm = LibStub:GetLibrary("AceComm-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub:GetLibrary("LibSerialize")

local Comms = {
    prefix = "epgpplus",
    channel = "WHISPER",
    priority = "NORMAL",
}

Comms.Events = {

    --we got a log entry so inform the database and get it stored
    OnPointsLogEntryReceived = function(payload, sender)
        EpgpPlus.Database:AddPointsLogEntry(payload)
    end,

    OnPlayerEquipmentChanged = function(payload, sender)
        EpgpPlus.Database:UpdateCharacterDirectory(payload.player, "equipment", payload.equipment)
    end,

    OnPlayerEquipmentRequested = function(_, sender)
        local myEquipment = EpgpPlus.Api.GetUnitEquipment("player")
        Comms:SendGuildMessage("OnPlayerEquipmentChanged", {
            player = EpgpPlus.Api.GetPlayerRealmName(),
            equipment = myEquipment,
        })
    end,

    OnGuildEpGpRequested = function(sender)
        local data = EpgpPlus.Api.BuildSyncData()
        EpgpPlus.Comms:SendGuildMessage("OnGuildEpGpReceieved", data)
    end,

    OnGuildEpGpReceieved = function(payload, sender)
        EpgpPlus.Database:StoreEpGPSyncData(sender, payload)
    end,

    OnPlayerPointsChanged = function(payload, sender)
        EpgpPlus.Database:UpdatePlayerSyncData(payload)
    end,

    OnLootDataReceived = function(payload, sender)
        EpgpPlus.Callbacks:TriggerEvent("OnLootDataReceived", payload)
    end,

    OnLootItemRoll = function(payload, sender)
        EpgpPlus.Callbacks:TriggerEvent("OnLootItemRoll", payload, sender)
    end,

    OnLootWindowClosed = function(payload, sender)
        EpgpPlus.Callbacks:TriggerEvent("OnLootWindowClosed", payload, sender)
    end,

    OnTableDataReceived = function(payload, sender)
        EpgpPlus.Database:SetTable(payload.tbl, payload.data)
        print(string.format("Received [%s] table data from %s", payload.tbl, sender))
    end

}


function Comms:Init()
    AceComm:Embed(self);
    self:RegisterComm(self.prefix);
    self.version = tonumber(C_AddOns.GetAddOnMetadata(addonName, "Version"));
end

function Comms:SerializeAndCompressMessage(msg)
    msg.version = self.version;
    local serialized = LibSerialize:Serialize(msg);
    local compressed = LibDeflate:CompressDeflate(serialized);
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed);
    return encoded;
end

function Comms:TellGuild(message)
    C_ChatInfo.SendChatMessage(message, "GUILD")
end

function Comms:SendGroupMessage(event, data)
    if (EpgpPlus.Database:GetConfig("safetyModeActive") == true) then
        print("+++++ Safety Mode Active +++++ [EpgpPlus.Comms.SendGroupMessage]", event)
        --DevTools_Dump({data})
    else
        local msg = {
            event = event,
            payload = data,
        }
        self:SendCommMessage(self.prefix, self:SerializeAndCompressMessage(msg), "RAID", nil, self.priority)
    end
end

local lastMessageSent;
function Comms:SendGuildMessage(event, data)
    if lastMessageSent == nil then
        print("SendGuildMessage()")
        lastMessageSent = time()
    else
        local delay = (time() - lastMessageSent)
        print("SendGuildMessage", SecondsToTime(delay))
        lastMessageSent = time()
    end
    if (EpgpPlus.Database:GetConfig("safetyModeActive") == true) then
        print("+++++ Safety Mode Active +++++ [EpgpPlus.Comms.SendGuildMessage]", event)
        --DevTools_Dump({data})
    else
        local msg = {
            event = event,
            payload = data,
        }
        self:SendCommMessage(self.prefix, self:SerializeAndCompressMessage(msg), "GUILD", nil, self.priority)
    end
end

function Comms:OnCommReceived(prefix, message, distribution, sender)

    if prefix ~= self.prefix then 
        return 
    end
    local decoded = LibDeflate:DecodeForWoWAddonChannel(message);
    if not decoded then
        return;
    end
    local decompressed = LibDeflate:DecompressDeflate(decoded);
    if not decompressed then
        return;
    end
    local success, data = LibSerialize:Deserialize(decompressed);
    if not success or type(data) ~= "table" then
        return;
    end

    if tonumber(data.version) < self.version then
        print("You are running an older version of EpgpPlus, please update.")
        return;
    end

    if self.Events[data.event] then
        self.Events[data.event](data.payload, sender)
    end

end




EpgpPlus.Comms = Comms;