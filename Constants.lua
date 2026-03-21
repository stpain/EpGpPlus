


local addonName, EpgpPlus = ...;

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

EpgpPlus.InventorySlots = {
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

EpgpPlus.ExpansionInstances = {
    {
        "Molten Core",
        "Blackwing Lair",
        [[Onyxia's Lair]],
        [[Zul'Gurub]],
        [[Ruins of Ahn'Qiraj]],
        [[Temple of Ahn'Qiraj]],
        [[Naxxramas]],
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
    }
}

EpgpPlus.ExpansionArt = {
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

EpgpPlus.ItemFilters = {
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
            -- Enum.ItemMiscellaneousSubclass.Mount,
            -- Enum.ItemMiscellaneousSubclass.Other,
            -- Enum.ItemMiscellaneousSubclass.CompanionPet,
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
            --Enum.ItemRecipeSubclass.Jewelcrafting,
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