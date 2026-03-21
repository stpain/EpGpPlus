

local addonName, EpgpPlus = ...;

local AceComm = LibStub:GetLibrary("AceComm-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub:GetLibrary("LibSerialize")

local Comms = {
    prefix = "srplus",
    channel = "WHISPER",
    priority = "NORMAL",
}

Comms.Events = {

    OnPlayerEquipmentChanged = function(payload, sender)
        EpgpPlus.Callbacks:TriggerEvent("Comms_OnPlayerEquipmentChanged", payload, sender)
    end,

    OnPlayerEquipmentRequested = function(_, sender)
        local myEquipment = EpgpPlus.Api.GetUnitEquipment("player")
        local ilvl = EpgpPlus.Api.GetPlayerItemLevel()
        Comms:SendGuildMessage("OnPlayerEquipmentChanged", {
            equipment = myEquipment,
            ilvl = ilvl,
        })
    end,

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


function Comms:SendGroupMessage(event, data)
    local msg = {
        event = event,
        payload = data,
    }
    self:SendCommMessage(self.prefix, self:SerializeAndCompressMessage(msg), "RAID", nil, self.priority)
end

function Comms:SendGuildMessage(event, data)
    local msg = {
        event = event,
        payload = data,
    }
    self:SendCommMessage(self.prefix, self:SerializeAndCompressMessage(msg), "GUILD", nil, self.priority)
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