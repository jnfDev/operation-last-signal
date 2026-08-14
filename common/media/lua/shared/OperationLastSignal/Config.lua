OperationLastSignal = OperationLastSignal or {}

OperationLastSignal.MOD_ID = "operation-last-signal-dev"
OperationLastSignal.SPAWN = { x = 5579, y = 12485, z = 1 }
OperationLastSignal.ROLE_PROFILE_VERSION = 1

OperationLastSignal.CASES = {
    { id = "case-1", name = "Case One", x = 5579, y = 12485, z = 0 },
    { id = "case-2", name = "Case Two", x = 8085, y = 11524, z = 1 },
    { id = "case-3", name = "Case Three", x = 4117, y = 6522, z = 5 },
    { id = "case-4", name = "Case Four", x = 13613, y = 1695, z = 3 },
}

OperationLastSignal.CASE_ITEM = "Base.Bag_ProtectiveCaseMilitary"
OperationLastSignal.EXTRACTION = { name = "Clark Memorial Bridge", x = 12598, y = 973, z = 0 }

OperationLastSignal.BACKPACK = "Base.Bag_ALICEpack_Army"

OperationLastSignal.UNIFORM = {
    "Base.Hat_Army",
    "Base.Vest_BulletArmy",
    "Base.Shirt_CamoGreen",
    "Base.Trousers_CamoGreen",
    "Base.Shoes_ArmyBoots",
    "Base.Gloves_LeatherGloves",
    "Base.WristWatch_Left_ClassicMilitary",
    "Base.Bag_ALICE_BeltSus_Green",
    "Base.HolsterSimple_Green",
}

OperationLastSignal.COMMON_KIT = {
    { item = "Base.WalkieTalkie1", count = 1, destination = "backpack" },
    { item = "Base.Torch", count = 1, destination = "backpack" },
    { item = "Base.Battery", count = 2, destination = "backpack" },
    { item = "Base.Bandage", count = 4, destination = "backpack" },
    { item = "Base.HandAxe", count = 1, destination = "backpack" },
    { item = "Base.SleepingBag_Camo_Packed", count = 1, destination = "backpack" },
    { item = "Base.9mmClip", count = 3, ammo = 15, destination = "backpack" },
    { item = "Base.Bullets9mmBox", count = 4, destination = "backpack" },
}

OperationLastSignal.ATTACHED_GEAR = {
    {
        item = "Base.HuntingKnife",
        slotType = "SmallBeltLeft",
    },
    {
        item = "Base.CanteenMilitaryFull",
        slotType = "SmallBeltRight",
    },
    {
        item = "Base.FlashLight_AngleHead_Army",
        slotType = "WebbingRight",
    },
    {
        item = "Base.Pistol",
        ammo = 14,
        chambered = true,
        containsClip = true,
        slotType = "HolsterRight",
    },
}

OperationLastSignal.RIFLE_KIT = {
    { item = "Base.AssaultRifle", count = 1, slotType = "Back" },
    { item = "Base.556Clip", count = 4, ammo = 30, destination = "backpack" },
    { item = "Base.556Box", count = 4, destination = "backpack" },
}

OperationLastSignal.COMMON_SKILLS = {
    Fitness = 7,
    Strength = 7,
    Aiming = 5,
    Reloading = 5,
    Sprinting = 4,
    Nimble = 3,
    Lightfoot = 3,
    Maintenance = 3,
    SmallBlade = 3,
    Axe = 2,
}

-- Role selection assigns identity, skill floors, technical knowledge, and equipment.
OperationLastSignal.ROLES = {
    {
        id = "commander",
        name = "Captain Marcus Hale",
        title = "Commander",
        description = "Coordinates routes, withdrawals, and mission decisions.",
        identity = {
            forename = "Captain Marcus",
            surname = "Hale",
            displayName = "Captain Marcus Hale",
        },
        skills = {
            Aiming = 7,
            Reloading = 6,
            Nimble = 5,
            Sprinting = 5,
            Maintenance = 5,
        },
        rifleKit = true,
        kit = {
            { item = "Base.Map", count = 1, destination = "backpack" },
            { item = "Base.Pencil", count = 1, destination = "backpack" },
            { item = "Base.Pen", count = 1, destination = "backpack" },
        },
    },
    {
        id = "medic",
        name = "Dr. Elena Reyes",
        title = "Medic and specialist",
        description = "Authenticates the cases and keeps the team alive.",
        identity = {
            forename = "Dr. Elena",
            surname = "Reyes",
            displayName = "Dr. Elena Reyes",
        },
        skills = {
            Doctor = 10,
            Nimble = 4,
            Lightfoot = 5,
        },
        rifleKit = true,
        kit = {
            {
                item = "Base.FirstAidKit_Military",
                count = 1,
                destination = "backpack",
                contents = {
                    { item = "Base.Bandage", count = 4 },
                    { item = "Base.AlcoholWipes", count = 1, uses = 4 },
                    { item = "Base.Disinfectant", count = 1 },
                    { item = "Base.SutureNeedle", count = 1 },
                    { item = "Base.SutureNeedleHolder", count = 1 },
                    { item = "Base.Tweezers", count = 1 },
                    { item = "Base.Pills", count = 1 },
                    { item = "Base.Antibiotics", count = 1 },
                },
            },
            { item = "Base.Splint", count = 1, destination = "backpack" },
        },
    },
    {
        id = "engineer",
        name = "Corporal Noah Bennett",
        title = "Engineer",
        description = "Keeps the vehicles operational and opens the extraction route.",
        identity = {
            forename = "Corporal Noah",
            surname = "Bennett",
            displayName = "Corporal Noah Bennett",
        },
        skills = {
            Mechanics = 10,
            Electricity = 8,
            MetalWelding = 10,
            Maintenance = 6,
        },
        recipes = {
            "Basic Mechanics",
            "Intermediate Mechanics",
            "Advanced Mechanics",
            "Generator",
            "MetalWallLvl1",
            "MetalWallLvl2",
            "MetalFloorLvl1",
            "MetalWindowFrameLvl1",
            "MetalWindowFrameLvl2",
            "MetalWallFrame",
            "MetalDoorFrameLvl1",
            "MetalDoorFrameLvl2",
            "Metal_Stairs",
            "Metal_Counter_Lvl1",
            "Metal_Counter_Lvl2",
            "Metal_CounterCorner_Lvl1",
            "Metal_CounterCorner_Lvl2",
            "Metal_Crate_Lvl1",
            "Metal_Crate_Lvl2",
            "Metal_LockerBig_Lvl1",
            "Metal_LockerBig_Lvl2",
            "Metal_LockerSmall_Lvl1",
            "Metal_LockerSmall_Lvl2",
            "Metal_Shelves_Lvl1",
            "Metal_Shelves_Lvl2",
            "MetalPoleFenceGate",
            "MetalWireFenceGate",
            "MetalWireFenceGateSmall",
            "DoubleFenceGate",
            "DoubleWireGate",
            "MetalBigWireFence",
            "MetalBigMetalFence",
            "MetalPoleFenceGateSmall",
            "MetalSmallPoleFence",
            "MetalFenceLvl1",
            "MetalSmallWireFence",
            "MakeMetalSheet",
            "MakeSmallMetalSheet",
        },
        rifleKit = true,
        kit = {
            {
                item = "Base.Toolbox_Mechanic",
                count = 1,
                destination = "backpack",
                contents = {
                    { item = "Base.Wrench", count = 1 },
                    { item = "Base.Screwdriver", count = 1 },
                    { item = "Base.Jack", count = 1 },
                    { item = "Base.LugWrench", count = 1 },
                    { item = "Base.TirePump", count = 1 },
                    { item = "Base.DuctTape", count = 1 },
                    { item = "Base.EngineParts", count = 1 },
                },
            },
            { item = "Base.PetrolCan", count = 1, destination = "backpack", emptyFluid = true },
        },
    },
    {
        id = "security",
        name = "Sergeant Daniel Price",
        title = "Security",
        description = "Protects Dr. Reyes and secures dangerous entrances.",
        identity = {
            forename = "Sergeant Daniel",
            surname = "Price",
            displayName = "Sergeant Daniel Price",
        },
        skills = {
            Aiming = 9,
            Reloading = 8,
            Nimble = 6,
            Fitness = 8,
            Strength = 8,
            Maintenance = 6,
        },
        kit = {
            { item = "Base.Shotgun", count = 1, ammo = 4, chambered = true, slotType = "Back" },
            { item = "Base.ShotgunShellsBox", count = 4, destination = "backpack" },
        },
    },
}

function OperationLastSignal.getRole(roleId)
    for _, role in ipairs(OperationLastSignal.ROLES) do
        if role.id == roleId then
            return role
        end
    end
    return nil
end

return OperationLastSignal
