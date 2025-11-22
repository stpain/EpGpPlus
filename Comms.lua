

local addonName, SoftResPlus = ...;

local CommsKeys = {
    lfh = "LookingForHost",
}

local Comms = {
    prefix = "srplus"
}


local AceComm = LibStub:GetLibrary("AceComm-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub:GetLibrary("LibSerialize")


function Comms:Init()
    
    AceComm:Embed(self);
    self:RegisterComm(self.prefix);

    self.version = tonumber(C_AddOns.GetAddOnMetadata(addonName, "Version"));

    --self:SendCommMessage(self.prefix, encoded, channel, target, "NORMAL")
    -- local serialized = LibSerialize:Serialize(msg);
    -- local compressed = LibDeflate:CompressDeflate(serialized);
    -- local encoded    = LibDeflate:EncodeForWoWAddonChannel(compressed);


end

function Comms:SendHostRequest()
    self:SendCommMessage(self.prefix, "lfh", "RAID", nil, "NORMAL")
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

end




SoftResPlus.Comms = Comms;