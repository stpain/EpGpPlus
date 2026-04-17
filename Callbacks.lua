

local _, EpgpPlus = ...;

EpgpPlus.Callbacks = CreateFromMixins(CallbackRegistryMixin)
EpgpPlus.Callbacks:OnLoad()
EpgpPlus.Callbacks:GenerateCallbackEvents({
    "Database_OnInitialized",
    "Database_OnConfigChanged",
    "Database_OnNewListCreated",
    "Database_OnListDeleted",
    "Database_OnItemFiltersChanged",
    "Database_OnSyncDataReceived",
    "Database_OnGuildMembersChanged",

    "Database_OnPlayerInfoChanged",
    "Database_OnLogEvent",

    "List_OnItemAdded",
    "List_OnItemDeleted",
    "List_OnItemsChanged",

    "OnLootDataReceived",
    "OnLootItemRoll",

    "OnLootWindowClosed",

    "OnPlayerPointsChanged_Event",
    "OnPlayerPointsChanged_Internal",

})