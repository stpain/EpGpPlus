

local _, EpgpPlus = ...;

EpgpPlus.Callbacks = CreateFromMixins(CallbackRegistryMixin)
EpgpPlus.Callbacks:OnLoad()
EpgpPlus.Callbacks:GenerateCallbackEvents({
    "Database_OnInitialized",
    "Database_OnConfigChanged",
    "Database_OnNewListCreated",
    "Database_OnListDeleted",
    "Database_OnItemFiltersChanged",

    "Database_OnGuildMembersChanged",

    "Comms_OnPlayerEquipmentChanged",

    "List_OnItemAdded",
    "List_OnItemDeleted",
    "List_OnItemsChanged",


})