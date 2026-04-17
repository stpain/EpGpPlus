


local addonName, EpgpPlus = ...;

EpgpPlus.Constants = {};

--StaticPopup_Show("EpgpPlusConfirmDialog", "Dialog Text", nil, data)
StaticPopupDialogs['EpgpPlusConfirmDialog'] = {
    text = '%s',
    button1 = YES,
    button2 = NO,
    --button3 = "Default",
    OnAccept = function(self, data)
        if data.callback then
            data.callback()
        end
        --print("yes")
    end,
    OnCancel = function()
        --print("no")
    end,
    -- OnAlt = function(self, data)
        
    -- end,
    OnShow = function(self, data)
        if data.onLoad then
            data.onLoad(self)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
}



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



EpgpPlus.Constants.LogActionTakenComments = {

    --these first 3 match the roll values passed when players click need/greed/de
    [1] = "Awarded full GP for item",
    [2] = "Awarded for free as off spec",
    [3] = "Awarded for free to DE item",

    --these are api function names, using brackets to denote a function call
    [4] = "AdjustGuildMembersPoints()",
    [5] = "SetGuildMembersPoints()",
    [6] = "ApplyGuildDecay()",

    [7] = "Boss kill EP awarded",
}

EpgpPlus.MainNineSliceLayout =
{
    TopLeftCorner =	{ atlas = "optionsframe-nineslice-cornertopleft", x = -15, y = 15 },
    TopRightCorner =	{ atlas = "optionsframe-nineslice-cornertopright", x = 15, y = 15 },
    BottomLeftCorner =	{ atlas = "optionsframe-nineslice-cornerbottomleft", x = -15, y = -15 },
    BottomRightCorner =	{ atlas = "optionsframe-nineslice-cornerbottomright", x = 15, y = -15 },
    TopEdge = { atlas = "_optionsframe-nineslice-edgetop", },
    BottomEdge = { atlas = "_optionsframe-nineslice-edgebottom", },
    LeftEdge = { atlas = "!OptionsFrame-NineSlice-EdgeLeft", },
    RightEdge = { atlas = "!OptionsFrame-NineSlice-EdgeRight", },
    --Center = { layer = "BACKGROUND", atlas = "Tooltip-Glues-NineSlice-Center", x = -20, y = 20, x1 = 20, y1 = -20 },
}

EpgpPlus.Constants.ClassIdArmorType = {
    [1] = 4, --warrior
    [2] = 4, --paladin
    [3] = 3, --hunter
    [4] = 2, --rogue
    [5] = 1, --priest
    [6] = 4, --dk
    [7] = 3, --shaman
    [8] = 1, --mage
    [9] = 1, --warlocki
    [10] = 2, --monk 
    [11] = 2, --druid
    [12] = 2, --dh
}

EpgpPlus.Constants.ClassSkillSpellId = {
    DualWield = 674,
    Shields = 9116,
}

EpgpPlus.Constants.ItemSubClassIdToArmorSkillSpellId = {
    [Enum.ItemArmorSubclass.Cloth] = 9078,
    [Enum.ItemArmorSubclass.Leather] = 9077,
    [Enum.ItemArmorSubclass.Mail] = 8737,
    [Enum.ItemArmorSubclass.Plate] = 750,
}

EpgpPlus.Constants.ItemSubClassIdToWeaponSkillSpellId = {
    [Enum.ItemWeaponSubclass.Polearm] = 200,
    [Enum.ItemWeaponSubclass.Sword1H] = 201,
    [Enum.ItemWeaponSubclass.Sword2H] = 202,
    [Enum.ItemWeaponSubclass.Axe1H] = 196,
    [Enum.ItemWeaponSubclass.Axe2H] = 197,
    [Enum.ItemWeaponSubclass.Mace1H] = 198,
    [Enum.ItemWeaponSubclass.Mace2H] = 199,
    [Enum.ItemWeaponSubclass.Staff] = 227,
    [Enum.ItemWeaponSubclass.Dagger] = 1180,
    [Enum.ItemWeaponSubclass.Wand] = 5009,
    [Enum.ItemWeaponSubclass.Fishingpole] = 7738,
    [Enum.ItemWeaponSubclass.Guns] = 266,
    [Enum.ItemWeaponSubclass.Bows] = 264,
    [Enum.ItemWeaponSubclass.Crossbow] = 5011,
}

EpgpPlus.Constants.EquipLocationToSlotIndex = {
    ["INVTYPE_HEAD"] = 1,
    ["INVTYPE_NECK"] = 2,
    ["INVTYPE_SHOULDER"] = 3,
    ["INVTYPE_BODY"] = 4,
    ["INVTYPE_CHEST"] = 5,
    ["INVTYPE_ROBE"] = 5,
    ["INVTYPE_WAIST"] = 6,
    ["INVTYPE_LEGS"] = 7,
    ["INVTYPE_FEET"] = 8,
    ["INVTYPE_WRIST"] = 9,
    ["INVTYPE_HAND"] = 10,
    ["INVTYPE_CLOAK"] = 15,
    ["INVTYPE_MAINHAND"] = 16,
    ["INVTYPE_OFFHAND"] = 17,
    ["INVTYPE_RANGED"] = 18,
    ["INVTYPE_RANGEDRIGHT"] = 18,
    ["INVTYPE_TABARD"] = 19,
    ["INVTYPE_WEAPON"] = {16, 17},
    ["INVTYPE_2HWEAPON"] = 16,
    ["INVTYPE_WEAPONMAINHAND"] = 16,
    ["INVTYPE_WEAPONOFFHAND"] = 17,
    ["INVTYPE_SHIELD"] = 17,
    ["INVTYPE_HOLDABLE"] = 17,
    ["INVTYPE_FINGER"] = {11, 12},
    ["INVTYPE_TRINKET"] = {13, 14},
}

EpgpPlus.Constants.InventorySlots = {
    {
        slot = "HEADSLOT",
        icon = 136516,
    },
    {
        slot = "NECKSLOT",
        icon = 136519,
    },
    {
        slot = "SHOULDERSLOT",
        icon = 136526,
    },
    {
        slot = "BACKSLOT",
        icon = 136521,
    },
    {
        slot = "SHIRTSLOT",
        icon = 136525,
    },
    {
        slot = "CHESTSLOT",
        icon = 136512,
    },
    {
        slot = "WAISTSLOT",
        icon = 136529,
    },
    {
        slot = "LEGSSLOT",
        icon = 136517,
    },
    {
        slot = "FEETSLOT",
        icon = 136513,
    },
    {
        slot = "WRISTSLOT",
        icon = 136530,
    },
    {
        slot = "HANDSSLOT",
        icon = 136515,
    },
    {
        slot = "FINGER0SLOT",
        icon = 136514,
    },
    {
        slot = "FINGER1SLOT",
        icon = 136523,
    },
    {
        slot = "TRINKET0SLOT",
        icon = 136528,
    },
    {
        slot = "TRINKET1SLOT",
        icon = 136528,
    },
    {
        slot = "MAINHANDSLOT",
        icon = 136518,
    },
    {
        slot = "SECONDARYHANDSLOT",
        icon = 136524,
    },
    {
        slot = "RANGEDSLOT",
        icon = 136520,
    },
    {
        slot = "TABARDSLOT",
        icon = 136527,
    },
    -- {
    --     slot = "RELICSLOT",
    --     icon = 136522,
    -- },
}

EpgpPlus.Constants.ExpansionInstances = {
    {
        "Molten Core",
        "Blackwing Lair",
        [[Onyxia's Lair]],
        [[Zul'Gurub]],
        [[Ruins of Ahn'Qiraj]],
        [[Temple of Ahn'Qiraj]],
        [[Naxxramas]],
        [[World Bosses]],
    },
    {
        [[Karazhan]],
        [[Gruul's Lair]],
        [[Magtheridon's Lair]],
        [[Serpentshrine Cavern]],
        [[Tempest Keep]],
        [[Hyjal Summit]],
        [[Black Temple]],
        [[Zul'Aman]],
        [[Sunwell Plateau]],
        [[World Bosses]],
    }
}

EpgpPlus.Constants.ExpansionArt = {
    Large = {
        "groupfinder-background-raids-classic",
        "groupfinder-background-raids-bc",
        "groupfinder-background-raids-wrath",
    },
    Headers = {
        "groupfinder-button-raids-classic",
        "groupfinder-button-raids-bc",
        "groupfinder-button-raids-wrath",
    }
}

EpgpPlus.Constants.ItemFilters = {
    {
        classID = Enum.ItemClass.Questitem,
        subClassIDs = {
            0,
        }
    },
    {
        classID = Enum.ItemClass.Tradegoods,
        subClassIDs = {
            0,
        }
    },
    {
        classID = Enum.ItemClass.Miscellaneous,
        subClassIDs = {
            Enum.ItemMiscellaneousSubclass.Junk,
            Enum.ItemMiscellaneousSubclass.Mount,
            Enum.ItemMiscellaneousSubclass.Other,
            Enum.ItemMiscellaneousSubclass.CompanionPet,
        }
    },
    {
        classID = Enum.ItemClass.Recipe,
        subClassIDs = {
            Enum.ItemRecipeSubclass.Alchemy,
            Enum.ItemRecipeSubclass.Blacksmithing,
            Enum.ItemRecipeSubclass.Enchanting,
            Enum.ItemRecipeSubclass.Engineering,
            --Enum.ItemRecipeSubclass.Inscription,
            Enum.ItemRecipeSubclass.Jewelcrafting,
            Enum.ItemRecipeSubclass.Leatherworking,
            Enum.ItemRecipeSubclass.Tailoring,
            Enum.ItemRecipeSubclass.Cooking,
            Enum.ItemRecipeSubclass.Book,
        }
    },
    {
        classID = Enum.ItemClass.Key,
    },
    {
        classID = Enum.ItemClass.Projectile,
    },
    {
        classID = Enum.ItemClass.Armor,
        subClassIDs = {
            Enum.ItemArmorSubclass.Cloth,
            Enum.ItemArmorSubclass.Leather,
            Enum.ItemArmorSubclass.Mail,
            Enum.ItemArmorSubclass.Plate,
            Enum.ItemArmorSubclass.Shield,
            Enum.ItemArmorSubclass.Generic,
            Enum.ItemArmorSubclass.Idol,
            Enum.ItemArmorSubclass.Libram,
            --Enum.ItemArmorSubclass.Relic,
            --Enum.ItemArmorSubclass.Sigil,
            Enum.ItemArmorSubclass.Totem,
        }
    },
    {
        classID = Enum.ItemClass.Weapon,
        subClassIDs = {
            Enum.ItemWeaponSubclass.Axe1H,
            Enum.ItemWeaponSubclass.Axe2H,
            Enum.ItemWeaponSubclass.Mace1H,
            Enum.ItemWeaponSubclass.Mace2H,
            Enum.ItemWeaponSubclass.Sword1H,
            Enum.ItemWeaponSubclass.Sword2H,
            Enum.ItemWeaponSubclass.Dagger,
            Enum.ItemWeaponSubclass.Polearm,
            Enum.ItemWeaponSubclass.Staff,
            Enum.ItemWeaponSubclass.Bows,
            Enum.ItemWeaponSubclass.Crossbow,
            Enum.ItemWeaponSubclass.Guns,
            Enum.ItemWeaponSubclass.Wand,
            Enum.ItemWeaponSubclass.Thrown,

            Enum.ItemWeaponSubclass.Fishingpole,
            
            -- Enum.ItemWeaponSubclass.Generic,
            -- Enum.ItemWeaponSubclass.Unarmed,
            -- Enum.ItemWeaponSubclass.Warglaive,
            -- Enum.ItemWeaponSubclass.Bearclaw,
            -- Enum.ItemWeaponSubclass.Catclaw,
        }
    }
}

EpgpPlus.Constants.GearPoints = {
    {
        slot = "INVTYPE_HEAD",
        modifier = 1,
    },
    {
        slot = "INVTYPE_NECK",
        modifier = 0.5,
    },
    {
        slot = "INVTYPE_SHOULDER",
        modifier = 0.75,
    },
    {
        slot = "INVTYPE_CHEST",
        modifier = 1,
    },
    {
        slot = "INVTYPE_WAIST",
        modifier = 0.75,
    },
    {
        slot = "INVTYPE_LEGS",
        modifier = 1,
    },
    {
        slot = "INVTYPE_FEET",
        modifier = 0.75,
    },
    {
        slot = "INVTYPE_WRIST",
        modifier = 0.5,
    },
    {
        slot = "INVTYPE_HAND",
        modifier = 0.75,
    },
    {
        slot = "INVTYPE_FINGER",
        modifier = 0.5,
    },
    {
        slot = "INVTYPE_TRINKET",
        modifier = 0.75,
    },
    {
        slot = "INVTYPE_WEAPON",
        modifier = 1.5,
    },
    {
        slot = "INVTYPE_SHIELD",
        modifier = 0.5,
    },
    {
        slot = "INVTYPE_RANGED",
        modifier = 2,
    },
    {
        slot = "INVTYPE_CLOAK",
        modifier = 0.5,
    },
    {
        slot = "INVTYPE_2HWEAPON",
        modifier = 2,
    },
    {
        slot = "INVTYPE_ROBE",
        modifier = 1,
    },
    {
        slot = "INVTYPE_WEAPONMAINHAND",
        modifier = 1.5,
    },
    {
        slot = "INVTYPE_WEAPONOFFHAND",
        modifier = 0.5,
    },
    {
        slot = "INVTYPE_HOLDABLE",
        modifier = 0.5,
    },
    {
        slot = "INVTYPE_THROWN",
        modifier = 0.5,
    },
    {
        slot = "INVTYPE_RANGEDRIGHT",
        modifier = 0.5,
    },
    {
        slot = "INVTYPE_RELIC",
        modifier = 0.5,
    },
}

EpgpPlus.Constants.EncounterIDs = {
      
    -- Onyxia's Lair
    [1084] = "Onyxia",

    -- Molten Core
    [663] = "Lucifron",
    [664] = "Magmadar",
    [665] = "Gehennas",
    [666] = "Garr",
    [667] = "Shazzrah",
    [668] = "Baron Geddon",
    [669] = "Sulfuron Harbinger",
    [670] = "Golemagg the Incinerator",
    [671] = "Majordomo Executus",
    [672] = "Ragnaros",

    -- Blackwing Lair
    [610] = "Razorgore the Untamed",
    [611] = "Vaelastrasz the Corrupt",
    [612] = "Broodlord Lashlayer",
    [613] = "Firemaw",
    [614] = "Ebonroc",
    [615] = "Flamegor",
    [616] = "Chromaggus",
    [617] = "Nefarian",

    -- Zul'Gurub
    [784] = "High Priest Venoxis",
    [785] = "High Priestess Jeklik",
    [786] = "High Priestess Mar'li",
    [787] = "Bloodlord Mandokir",
    [788] = "Edge of Madness",
    [789] = "High Priest Thekal",
    [790] = "Gahz'ranka",
    [791] = "High Priestess Arlokk",
    [792] = "Jin'do the Hexxer",
    [793] = "Hakkar",

    -- The Ruins of Ahn'Qiraj
    [718] = "Kurinnaxx",
    [719] = "General Rajaxx",
    [720] = "Moam",
    [721] = "Buru the Gorger",
    [722] = "Ayamiss the Hunter",
    [723] = "Ossirian the Unscarred",

    -- The Temple of Ahn'Qiraj
    [709] = "The Prophet Skeram",
    [711] = "Battleguard Sartura",
    [712] = "Fankriss the Unyielding",
    [714] = "Princess Huhuran",
    [710] = "The Silithid Royalty",
    [713] = "Viscidus",
    [716] = "Ouro",
    [715] = "The Twin Emperors",
    [717] = "C'Thun",

    -- Naxxramas
    [1107] = "Anub'Rekhan",
    [1110] = "Grand Widow Faerlina",
    [1116] = "Maexxna",

    [1117] = "Noth the Plaguebringer",
    [1112] = "Heigan the Unclean",
    [1115] = "Loatheb",

    [1113] = "Instructor Razuvious",
    [1109] = "Gothik the Harvester",
    [1121] = "The Four Horsemen",

    [1118] = "Patchwerk",
    [1111] = "Grobbulus",
    [1108] = "Gluth",
    [1120] = "Thaddius",

    [1119] = "Sapphiron",
    [1114] = "Kel'Thuzad",

    -- World Bosses: Lord Kazzak, Azuregos, Emeriss, Lethon, Ysondre, Taerar
    [3437] = "Lord Kazzak",
    [3440] = "Azuregos",
    [3438] = "Emeriss",
    [3442] = "Lethon",
    [3439] = "Ysondre",
    [3441] = "Taerar",

    -- # https://wago.tools/db2/DungeonEncounter?build=2.5.5.65534&page=1&sort%5BName_lang%5D=asc
    -- Karazhan
    [652] = "Attumen the Huntsman",
    [653] = "Moroes",
    [654] = "Maiden of Virtue",
    [655] = "Opera Hall",
    [656] = "The Curator",
    [657] = "Terestian Illhoof",
    [658] = "Shade of Aran",
    [659] = "Netherspite",
    [660] = "Chess Event",
    [661] = "Prince Malchezaar",
    [662] = "Nightbane",

    -- Gruul's Lair
    [649] = "High King Maulgar",
    [650] = "Gruul the Dragonkiller",

    -- Magtheridon's Lair
    [651] = "Magtheridon",

    -- Tempest Keep
    [730] = "Al'ar",
    [731] = "Void Reaver",
    [732] = "High Astromancer Solarian",
    [733] = "Kael'thas Sunstrider",

    -- Serpentshrine Cavern        
    [623] = "Hydross the Unstable",
    [624] = "The Lurker Below",
    [625] = "Leotheras the Blind",
    [626] = "Fathom-Lord Karathress",
    [627] = "Morogrim Tidewalker",
    [628] = "Lady Vashj",

    -- Hyjal Summit
    [618] = "Rage Winterchill",
    [619] = "Anetheron",
    [620] = "Kaz'rogal",
    [621] = "Azgalor",
    [622] = "Archimonde",

    -- Black Temple
    [601] = "High Warlord Naj'entus",
    [602] = "Supremus",
    [603] = "Shade of Akama",
    [604] = "Teron Gorefiend",
    [605] = "Gurtogg Bloodboil",
    [606] = "Reliquary of Souls",
    [607] = "Mother Shahraz",
    [608] = "The Illidari Council",
    [609] = "Illidan Stormrage",

    -- Zul'Aman
    [1189] = "Akil'zon",
    [1190] = "Nalorakk",
    [1191] = "Jan'alai",
    [1192] = "Halazzi",
    [1193] = "Hex Lord Malacrass",
    [1194] = "Zul'jin",

    -- Sunwell Plateau
    [724] = "Kalecgos",
    [725] = "Brutallus",
    [726] = "Felmyst",
    [727] = "Eredar Twins",
    [728] = "M'uru",
    [729] = "Kil'jaeden",

    -- World Bosses: 18728 Doom Lord Kazzak, 17711 Doomwalker
    [18728] = "Doom Lord Kazzak",
    [17711] = "Doomwalker",
}


EpgpPlus.Constants.DefaultEncounterEP = {

    --[1] classic (its actually 0 but we'll handle that in the ui loop)
    {
        {
            -- Molten Core
            { name = [[Lucifron]], ep = 5, },
            { name = [[Magmadar]], ep = 5, },
            { name = [[Gehennas]], ep = 5, },
            { name = [[Garr]], ep = 5, },
            { name = [[Baron Geddon]], ep = 5, },
            { name = [[Shazzrah]], ep = 5, },
            { name = [[Sulfuron Harbinger]], ep = 5, },
            { name = [[Golemagg the Incinerator]], ep = 5, },
            { name = [[Majordomo Executus]], ep = 5, },
            { name = [[Ragnaros]], ep = 7, },
        },
        {
            -- Blackwing Lair
            { name = [[Razorgore the Untamed]], ep = 7, },
            { name = [[Vaelastrasz the Corrupt]], ep = 7, },
            { name = [[Broodlord Lashlayer]], ep = 7, },
            { name = [[Firemaw]], ep = 7, },
            { name = [[Ebonroc]], ep = 7, },
            { name = [[Flamegor]], ep = 7, },
            { name = [[Chromaggus]], ep = 7, },
            { name = [[Nefarian]], ep = 10, },
        },
        {
            -- Onyxia's Lair
            { name = [[Onyxia]], ep = 5, },
        },
        {
            -- Zul'Gurub
            { name = [[High Priest Venoxis]], ep = 2, },
            { name = [[High Priestess Jeklik]], ep = 2, },
            { name = [[High Priestess Mar'li]], ep = 2, },
            { name = [[High Priest Thekal]], ep = 2, },
            { name = [[High Priestess Arlokk]], ep = 2, },
            { name = [[Edge of Madness]], ep = 2, },
            { name = [[Bloodlord Mandokir]], ep = 2, },
            { name = [[Jin'do the Hexxer]], ep = 2, },
            { name = [[Gahz'ranka]], ep = 2, },
            { name = [[Hakkar]], ep = 3, },
        },
        {
            -- The Ruins of Ahn'Qiraj
            { name = [[Kurinnaxx]], ep = 3, },
            { name = [[General Rajaxx]], ep = 3, },
            { name = [[Moam]], ep = 3, },
            { name = [[Buru the Gorger]], ep = 3, },
            { name = [[Ayamiss the Hunter]], ep = 3, },
            { name = [[Ossirian the Unscarred]], ep = 4, },
        },
        {
            -- The Temple of Ahn'Qiraj
            { name = [[The Prophet Skeram]], ep = 10, },
            { name = [[Battleguard Sartura]], ep = 10, },
            { name = [[Fankriss the Unyielding]], ep = 10, },
            { name = [[Princess Huhuran]], ep = 10, },
            { name = [[The Silithid Royalty]], ep = 10, },
            { name = [[Viscidus]], ep = 10, },
            { name = [[Ouro]], ep = 10, },
            { name = [[The Twin Emperors]], ep = 10, },
            { name = [[C'Thun]], ep = 12, },
        },
        {
            -- Naxxramas
            { name = [[Anub'Rekhan]], ep = 12, },
            { name = [[Grand Widow Faerlina]], ep = 12, },
            { name = [[Maexxna]], ep = 15, },

            { name = [[Noth the Plaguebringer]], ep = 12, },
            { name = [[Heigan the Unclean]], ep = 12, },
            { name = [[Loatheb]], ep = 15, },

            { name = [[Instructor Razuvious]], ep = 12, },
            { name = [[Gothik the Harvester]], ep = 12, },
            { name = [[The Four Horsemen]], ep = 15, },

            { name = [[Patchwerk]], ep = 12, },
            { name = [[Grobbulus]], ep = 12, },
            { name = [[Gluth]], ep = 12, },
            { name = [[Thaddius]], ep = 15, },

            { name = [[Sapphiron]], ep = 15, },
            { name = [[Kel'Thuzad]], ep = 15, },
        },
        {
            -- World Bosses
            { name = [[Lord Kazzak]], ep = 7, },
            { name = [[Azuregos]], ep = 7, },
            { name = [[Emeriss]], ep = 7, },
            { name = [[Lethon]], ep = 7, },
            { name = [[Ysondre]], ep = 7, },
            { name = [[Taerar]], ep = 7, },
        },
    },

    --[2] tbc (1)
    {
        {
            -- Karazhan
            { name = [[Attumen the Huntsman]], ep = 3, },
            { name = [[Moroes]], ep = 3, },
            { name = [[Maiden of Virtue]], ep = 3, },
            { name = [[Opera Hall]], ep = 3, },
            { name = [[The Curator]], ep = 3, },
            { name = [[Terestian Illhoof]], ep = 4, },
            { name = [[Shade of Aran]], ep = 4, },
            { name = [[Netherspite]], ep = 4, },
            { name = [[Chess Event]], ep = 4, },
            { name = [[Prince Malchezaar]], ep = 5, },
            { name = [[Nightbane]], ep = 5, },
        },
        {
            -- Gruul's Lair
            { name = [[High King Maulgar]], ep = 4, },
            { name = [[Gruul the Dragonkiller]], ep = 5, },
        },
        {
            -- Magtheridon's Lair
            { name = [[Magtheridon]], ep = 5, },
        },
        {
            -- Serpentshrine Cavern
            { name = [[Hydross the Unstable]], ep = 4, },
            { name = [[The Lurker Below]], ep = 4, },
            { name = [[Leotheras the Blind]], ep = 4, },
            { name = [[Fathom-Lord Karathress]], ep = 6, },
            { name = [[Morogrim Tidewalker]], ep = 6, },
            { name = [[Lady Vashj]], ep = 8, },
        },
        {
            -- Tempest Keep
            { name = [[Al'ar]], ep = 7, },
            { name = [[Void Reaver]], ep = 7, },
            { name = [[High Astromancer Solarian]], ep = 7, },
            { name = [[Kael'thas Sunstrider]], ep = 10, },
        },
        {
            -- Hyjal Summit
            { name = [[Rage Winterchill]], ep = 8, },
            { name = [[Anetheron]], ep = 8, },
            { name = [[Kaz'rogal]], ep = 9, },
            { name = [[Azgalor]], ep = 9, },
            { name = [[Archimonde]], ep = 11, },
        },
        {
            -- Black Temple
            { name = [[High Warlord Naj'entus]], ep = 10, },
            { name = [[Supremus]], ep = 10, },
            { name = [[Shade of Akama]], ep = 10, },
            { name = [[Teron Gorefiend]], ep = 10, },
            { name = [[Gurtogg Bloodboil]], ep = 11, },
            { name = [[Reliquary of Souls]], ep = 11, },
            { name = [[Mother Shahraz]], ep = 12, },
            { name = [[The Illidari Council]], ep = 12, },
            { name = [[Illidan Stormrage]], ep = 15, },
        },
        {
            -- Zul'Aman
            { name = [[Akil'zon]], ep = 3, },
            { name = [[Nalorakk]], ep = 3, },
            { name = [[Jan'alai]], ep = 3, },
            { name = [[Halazzi]], ep = 3, },
            { name = [[Hex Lord Malacrass]], ep = 3, },
            { name = [[Zul'jin]], ep = 4, },
        },
        {
            -- Sunwell Plateau
            { name = [[Kalecgos]], ep = 12, },
            { name = [[Brutallus]], ep = 13, },
            { name = [[Felmyst]], ep = 13, },
            { name = [[Eredar Twins]], ep = 14, },
            { name = [[M'uru]], ep = 14, },
            { name = [[Kil'jaeden]], ep = 18, },
        },
        {
            -- World Bosses
            { name = [[Doom Lord Kazzak]], ep = 7, },
            { name = [[Doomwalker]], ep = 7, },
        }
    },

    -- [3] wrath 
    {

    }


}