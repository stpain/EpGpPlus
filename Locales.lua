

local _, EpgpPlus = ...;

local locales = {
    enUS = {
        DecayPercentTooltip = "Uses the value as a percent when applying decay.",
        DecayNumberTooltip = "Uses the value as a plain number when applying decay.",
        DecayAndResetHelp = "|cffffffffYou can choose to apply decay or reset points to a new value.|r\n\nApply decay\n|cffffffffTo apply decay select the % value to use and which points to change then click Decay.|r\n\nReset\n|cffffffffTo reset points, select the new value and which points to change then click Reset.\n\n|cff66BBFFThe changes will only affect the players shown in the list below, make sure you remove any filtering before trying to apply to all guild members.",

        EffortPointsHeader = "|cffffffffEffort Points|r\nThese values are not automatically sent to the guild, any changes you make will need to be pushed before other guild members can use them.",
        GearPointsHeader = "|cffffffffGear Points|r\nThese values are not automatically sent to the guild, any changes you make will need to be pushed before other guild members can use them.",

        PointsListenerThrottle = "|cffffffffIf you have access to officer notes, the addon will create a 'listener' to detect changes to officer notes. To avoid spamming addon chat comms, the listener will cache changes and send the data every N seconds. A lower value will mean a smaller data packet but could also overwhelm the chat system.",
    },
}











local locale = GetLocale()
EpgpPlus.Locales = locales[locale];