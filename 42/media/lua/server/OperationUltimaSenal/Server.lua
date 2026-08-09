local Mission = require("OperationUltimaSenal/Config")

local function addAndSync(container, entry)
    local item = container:AddItem(entry.item)
    if not item then
        return nil
    end

    if entry.ammo then
        item:setCurrentAmmoCount(entry.ammo)
    end

    sendAddItemToContainer(container, item)
    return item
end

local function equipAndSync(player, item)
    local location = item:canBeEquipped() or item:getBodyLocation()
    if not location then
        return
    end

    player:setWornItem(location, item)
    sendClothing(player, location, item)
end

local function removeCurrentClothing(player)
    local inventory = player:getInventory()
    local wornItems = player:getWornItems()
    while wornItems:size() > 0 do
        local item = wornItems:get(0):getItem()
        local location = item:canBeEquipped() or item:getBodyLocation()
        player:removeWornItem(item, false)
        inventory:Remove(item)
        sendRemoveItemFromContainer(inventory, item)
        if location then
            sendClothing(player, location, nil)
        end
    end
end

local function getBackpack(player)
    return player:getInventory():FindAndReturn("Bag_ALICEpack_Army")
end

local function addEntries(player, backpack, entries)
    local inventory = player:getInventory()
    local backpackInventory = backpack and backpack:getInventory()

    for _, entry in ipairs(entries) do
        local container = entry.destination == "backpack" and backpackInventory or inventory
        if not container then
            container = inventory
        end
        for _ = 1, entry.count do
            addAndSync(container, entry)
        end
    end
end

local function addKit(player)
    local inventory = player:getInventory()
    removeCurrentClothing(player)

    local backpack = addAndSync(inventory, { item = Mission.BACKPACK })
    equipAndSync(player, backpack)

    for _, itemType in ipairs(Mission.UNIFORM) do
        local uniformItem = addAndSync(inventory, { item = itemType })
        equipAndSync(player, uniformItem)
    end

    addEntries(player, backpack, Mission.COMMON_KIT)
end

local function addRoleKit(player, role)
    addEntries(player, getBackpack(player), role.kit)
end

local function getMissionState()
    return ModData.getOrCreate("OperationUltimaSenal.MissionState")
end

local function placeCases()
    local state = getMissionState()
    state.casesPlaced = state.casesPlaced or {}
    local cell = getWorld():getCell()

    for _, missionCase in ipairs(Mission.CASES) do
        if not state.casesPlaced[missionCase.id] then
            local square = cell:getGridSquare(missionCase.x, missionCase.y, missionCase.z)
            if square then
                local item = square:AddWorldInventoryItem(Mission.CASE_ITEM, 0.5, 0.5, 0)
                if item then
                    state.casesPlaced[missionCase.id] = true
                    print("[OperacionUltimaSenal] " .. missionCase.name .. " placed.")
                end
            end
        end
    end
end

local function getClaims()
    local state = getMissionState()
    state.roleClaims = state.roleClaims or {}
    return state.roleClaims
end

local function getUsername(player)
    return player:getUsername() or player:getDisplayName()
end

local function sendRoleStatus(player, message)
    local claims = getClaims()
    local roles = {}

    for _, role in ipairs(Mission.ROLES) do
        table.insert(roles, {
            id = role.id,
            name = role.name,
            title = role.title,
            description = role.description,
            claimedBy = claims[role.id],
        })
    end

    local data = player:getModData()
    sendServerCommand(player, Mission.MOD_ID, "roleStatus", {
        roles = roles,
        selectedRole = data.operationUltimaSenalRole,
        message = message,
    })
end

local function selectRole(player, roleId)
    local role = Mission.getRole(roleId)
    if not role then
        sendRoleStatus(player, "Rol no valido.")
        return
    end

    local data = player:getModData()
    local username = getUsername(player)
    local claims = getClaims()

    if data.operationUltimaSenalRole then
        sendRoleStatus(player, "Ya tienes un personaje asignado.")
        return
    end

    if claims[role.id] and claims[role.id] ~= username then
        sendRoleStatus(player, "Ese personaje ya fue elegido por otro operador.")
        return
    end

    claims[role.id] = username
    data.operationUltimaSenalRole = role.id
    data.operationUltimaSenalRoleOwner = username
    addRoleKit(player, role)
    sendRoleStatus(player, role.name .. " asignado. Kit de rol autorizado.")
end

local function handleCommand(module, command, player, args)
    if module ~= Mission.MOD_ID or not player then
        return
    end

    if command == "requestRoleStatus" then
        sendRoleStatus(player)
        return
    end

    if command == "requestCasePlacement" then
        placeCases()
        return
    end

    if command == "selectRole" then
        selectRole(player, args and args.roleId)
        return
    end

    if command == "requestBootstrap" then
        local data = player:getModData()
        if data.operationUltimaSenalBootstrap then
            return
        end

        if not player:getSquare() then
            return
        end

        addKit(player)
        data.operationUltimaSenalBootstrap = true
        sendServerCommand(player, Mission.MOD_ID, "bootstrapComplete", {})
    end
end

local function onServerStarted()
    print("[OperacionUltimaSenal] Server bootstrap loaded.")
end

Events.OnClientCommand.Add(handleCommand)
Events.OnServerStarted.Add(onServerStarted)
