OperationLastSignal = OperationLastSignal or {}

OperationLastSignal.MOD_ID = "operation-last-signal-dev"
OperationLastSignal.SPAWN = { x = 5579, y = 12485, z = 1 }

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
}

OperationLastSignal.COMMON_KIT = {
    { item = "Base.AssaultRifle", count = 1 },
    { item = "Base.HuntingKnife", count = 1 },
    { item = "Base.Bag_ProtectiveCaseMilitary", count = 1, destination = "backpack" },
    { item = "Base.556Clip", count = 4, ammo = 30, destination = "backpack" },
    { item = "Base.556Box", count = 4, destination = "backpack" },
    { item = "Base.WalkieTalkie1", count = 1, destination = "backpack" },
    { item = "Base.Torch", count = 1, destination = "backpack" },
    { item = "Base.Battery", count = 2, destination = "backpack" },
    { item = "Base.WaterBottle", count = 1, destination = "backpack" },
    { item = "Base.Bandage", count = 4, destination = "backpack" },
}

-- Role selection is intentionally limited to identity and equipment for this
-- first version. It does not alter vanilla professions, traits, or skills.
OperationLastSignal.ROLES = {
    {
        id = "commander",
        name = "Captain Marcus Hale",
        title = "Commander",
        description = "Coordinates routes, withdrawals, and mission decisions.",
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
        kit = {
            { item = "Base.AlcoholWipes", count = 4, destination = "backpack" },
            { item = "Base.Disinfectant", count = 1, destination = "backpack" },
            { item = "Base.SutureNeedle", count = 1, destination = "backpack" },
            { item = "Base.Tweezers", count = 1, destination = "backpack" },
        },
    },
    {
        id = "engineer",
        name = "Corporal Noah Bennett",
        title = "Engineer",
        description = "Keeps the vehicles operational and opens the extraction route.",
        kit = {
            { item = "Base.Wrench", count = 1, destination = "backpack" },
            { item = "Base.Screwdriver", count = 1, destination = "backpack" },
            { item = "Base.Jack", count = 1, destination = "backpack" },
            { item = "Base.TirePump", count = 1, destination = "backpack" },
            { item = "Base.PetrolCan", count = 1, destination = "backpack" },
        },
    },
    {
        id = "security",
        name = "Sergeant Daniel Price",
        title = "Security",
        description = "Protects Dr. Reyes and secures dangerous entrances.",
        kit = {
            { item = "Base.Shotgun", count = 1 },
            { item = "Base.ShotgunShells", count = 8, destination = "backpack" },
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
