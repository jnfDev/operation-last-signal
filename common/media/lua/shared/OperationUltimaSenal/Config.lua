OperationUltimaSenal = OperationUltimaSenal or {}

OperationUltimaSenal.MOD_ID = "operation-ultima-senal"
OperationUltimaSenal.SPAWN = { x = 5579, y = 12485, z = 1 }

OperationUltimaSenal.CASES = {
    { id = "case-1", name = "Caso Uno", x = 5579, y = 12485, z = 0 },
    { id = "case-2", name = "Caso Dos", x = 8085, y = 11524, z = 1 },
    { id = "case-3", name = "Caso Tres", x = 4117, y = 6522, z = 5 },
    { id = "case-4", name = "Caso Cuatro", x = 13613, y = 1695, z = 3 },
}

OperationUltimaSenal.CASE_ITEM = "Base.Bag_ProtectiveCaseMilitary"
OperationUltimaSenal.EXTRACTION = { name = "Clark Memorial Bridge", x = 12598, y = 973, z = 0 }

OperationUltimaSenal.BACKPACK = "Base.Bag_ALICEpack_Army"

OperationUltimaSenal.UNIFORM = {
    "Base.Hat_Army",
    "Base.Vest_BulletArmy",
    "Base.Shirt_CamoGreen",
    "Base.Trousers_CamoGreen",
    "Base.Shoes_ArmyBoots",
    "Base.Gloves_LeatherGloves",
    "Base.WristWatch_Left_ClassicMilitary",
}

OperationUltimaSenal.COMMON_KIT = {
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
OperationUltimaSenal.ROLES = {
    {
        id = "commander",
        name = "Capitan Marcus Hale",
        title = "Comandante",
        description = "Coordina rutas, retiradas y decisiones de mision.",
        kit = {
            { item = "Base.Map", count = 1, destination = "backpack" },
            { item = "Base.Pencil", count = 1, destination = "backpack" },
            { item = "Base.Pen", count = 1, destination = "backpack" },
        },
    },
    {
        id = "medic",
        name = "Dra. Elena Reyes",
        title = "Medica y especialista",
        description = "Autentica los maletines y mantiene al equipo con vida.",
        kit = {
            { item = "Base.AlcoholWipes", count = 4, destination = "backpack" },
            { item = "Base.Disinfectant", count = 1, destination = "backpack" },
            { item = "Base.SutureNeedle", count = 1, destination = "backpack" },
            { item = "Base.Tweezers", count = 1, destination = "backpack" },
        },
    },
    {
        id = "engineer",
        name = "Cabo Noah Bennett",
        title = "Ingeniero",
        description = "Mantiene los vehiculos operativos y abre la ruta de extraccion.",
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
        name = "Sargento Daniel Price",
        title = "Seguridad",
        description = "Protege a la Dra. Reyes y controla las entradas peligrosas.",
        kit = {
            { item = "Base.Shotgun", count = 1 },
            { item = "Base.ShotgunShells", count = 8, destination = "backpack" },
        },
    },
}

function OperationUltimaSenal.getRole(roleId)
    for _, role in ipairs(OperationUltimaSenal.ROLES) do
        if role.id == roleId then
            return role
        end
    end
    return nil
end

return OperationUltimaSenal
