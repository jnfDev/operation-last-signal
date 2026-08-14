local Mission = require("OperationLastSignal/Config")
local BOOTSTRAP_VERSION = 1

local function logDiagnostic(scope, message)
    print("[OperationLastSignal][" .. scope .. "] " .. message)
end

local function diagnosticValue(value)
    if value == nil then
        return "nil"
    end
    return tostring(value)
end

local function diagnosticUsername(player)
    if not player then
        return "nil"
    end
    return diagnosticValue(player:getUsername() or player:getDisplayName())
end

local function addAndSync(container, entry)
    local item = container:AddItem(entry.item)
    if not item then
        logDiagnostic("Item", "add-failed item=" .. diagnosticValue(entry.item))
        return nil
    end

    if entry.ammo then
        item:setCurrentAmmoCount(entry.ammo)
    end
    if entry.containsClip then
        item:setContainsClip(true)
    end
    if entry.chambered then
        item:setRoundChambered(true)
    end
    if entry.uses then
        item:setUsedDelta(item:getUseDelta() * entry.uses)
    end
    if entry.emptyFluid then
        local fluidContainer = item:getFluidContainer()
        if fluidContainer then
            fluidContainer:Empty()
        end
    end

    sendAddItemToContainer(container, item)
    logDiagnostic(
        "Item",
        "added item=" .. diagnosticValue(entry.item)
            .. " destination=" .. diagnosticValue(entry.destination)
            .. " ammo=" .. diagnosticValue(entry.ammo)
            .. " uses=" .. diagnosticValue(entry.uses)
    )

    if entry.contents then
        local itemContainer = item:getInventory()
        if not itemContainer then
            logDiagnostic("Item", "container-missing item=" .. diagnosticValue(entry.item))
            return item
        end

        for _, childEntry in ipairs(entry.contents) do
            for _ = 1, childEntry.count or 1 do
                addAndSync(itemContainer, childEntry)
            end
        end
    end

    return item
end

local function equipAndSync(player, item)
    if not item then
        return
    end

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

local function addEntries(player, backpack, entries, attachedGear)
    local inventory = player:getInventory()
    local backpackInventory = backpack and backpack:getInventory()
    attachedGear = attachedGear or {}

    for _, entry in ipairs(entries) do
        local container = entry.destination == "backpack" and backpackInventory or inventory
        if not container then
            container = inventory
        end
        for _ = 1, entry.count or 1 do
            local item = addAndSync(container, entry)
            if item and entry.slotType then
                table.insert(attachedGear, {
                    itemId = item:getID(),
                    slotType = entry.slotType,
                })
            end
        end
    end

    return attachedGear
end

local function addKit(player)
    local username = diagnosticUsername(player)
    logDiagnostic("Bootstrap", "addKit-start user=" .. username)

    local inventory = player:getInventory()
    removeCurrentClothing(player)

    local backpack = addAndSync(inventory, { item = Mission.BACKPACK })
    equipAndSync(player, backpack)

    for _, itemType in ipairs(Mission.UNIFORM) do
        local uniformItem = addAndSync(inventory, { item = itemType })
        equipAndSync(player, uniformItem)
    end

    local attachedGear = {}
    addEntries(player, backpack, Mission.COMMON_KIT, attachedGear)
    addEntries(player, backpack, Mission.ATTACHED_GEAR, attachedGear)
    logDiagnostic("Bootstrap", "addKit-complete user=" .. username)
    return attachedGear
end

local function addRoleKit(player, role)
    local username = diagnosticUsername(player)
    logDiagnostic(
        "Role",
        "addRoleKit-start user=" .. username .. " role=" .. diagnosticValue(role and role.id)
    )
    local backpack = getBackpack(player)
    local attachedGear = {}
    if role.rifleKit then
        addEntries(player, backpack, Mission.RIFLE_KIT, attachedGear)
    end
    addEntries(player, backpack, role.kit, attachedGear)
    logDiagnostic(
        "Role",
        "addRoleKit-complete user=" .. username .. " role=" .. diagnosticValue(role and role.id)
    )
    return attachedGear
end

local function getMissionState()
    return ModData.getOrCreate("OperationLastSignal.MissionState")
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
                    print("[OperationLastSignal] " .. missionCase.name .. " placed.")
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
        selectedRole = data.operationLastSignalRole,
        message = message,
    })
end

local function selectRole(player, roleId)
    local role = Mission.getRole(roleId)
    if not role then
        logDiagnostic(
            "Role",
            "rejected user=" .. diagnosticUsername(player)
                .. " requestedRole=" .. diagnosticValue(roleId)
                .. " reason=invalid-role"
        )
        sendRoleStatus(player, "Invalid role.")
        return
    end

    local data = player:getModData()
    local username = getUsername(player)
    local claims = getClaims()

    logDiagnostic(
        "Role",
        "request user=" .. diagnosticValue(username)
            .. " requestedRole=" .. diagnosticValue(roleId)
            .. " playerRole=" .. diagnosticValue(data.operationLastSignalRole)
            .. " claimedBy=" .. diagnosticValue(claims[role.id])
    )

    if data.operationLastSignalRole then
        logDiagnostic(
            "Role",
            "rejected user=" .. diagnosticValue(username)
                .. " requestedRole=" .. diagnosticValue(roleId)
                .. " reason=player-already-has-role"
        )
        sendRoleStatus(player, "You already have an assigned character.")
        return
    end

    if claims[role.id] and claims[role.id] ~= username then
        logDiagnostic(
            "Role",
            "rejected user=" .. diagnosticValue(username)
                .. " requestedRole=" .. diagnosticValue(roleId)
                .. " claimedBy=" .. diagnosticValue(claims[role.id])
                .. " reason=role-claimed"
        )
        sendRoleStatus(player, "That character has already been selected by another operator.")
        return
    end

    claims[role.id] = username
    data.operationLastSignalRole = role.id
    data.operationLastSignalRoleOwner = username
    player:transmitModData()
    logDiagnostic(
        "Role",
        "state-stored user=" .. diagnosticValue(username)
            .. " playerRole=" .. diagnosticValue(data.operationLastSignalRole)
            .. " roleOwner=" .. diagnosticValue(data.operationLastSignalRoleOwner)
            .. " claimedBy=" .. diagnosticValue(claims[role.id])
    )
    local attachedGear = addRoleKit(player, role)
    if #attachedGear > 0 then
        sendServerCommand(player, Mission.MOD_ID, "attachGear", {
            attachedGear = attachedGear,
        })
    end
    logDiagnostic(
        "Role",
        "assigned user=" .. diagnosticValue(username) .. " role=" .. diagnosticValue(role.id)
    )
    sendRoleStatus(player, role.name .. " assigned. Role kit authorized.")
end

local function handleCommand(module, command, player, args)
    if module ~= Mission.MOD_ID or not player then
        return
    end

    if command == "requestRoleStatus" then
        local data = player:getModData()
        logDiagnostic(
            "Role",
            "status-request user=" .. diagnosticUsername(player)
                .. " playerRole=" .. diagnosticValue(data.operationLastSignalRole)
        )
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
        local username = diagnosticUsername(player)
        logDiagnostic(
            "Bootstrap",
            "request user=" .. username
                .. " storedVersion=" .. diagnosticValue(data.operationLastSignalBootstrapVersion)
                .. " expectedVersion=" .. diagnosticValue(BOOTSTRAP_VERSION)
                .. " hasSquare=" .. diagnosticValue(player:getSquare() ~= nil)
        )

        if data.operationLastSignalBootstrapVersion == BOOTSTRAP_VERSION then
            logDiagnostic(
                "Bootstrap",
                "skipped user=" .. username
                    .. " version=" .. diagnosticValue(data.operationLastSignalBootstrapVersion)
                    .. " reason=already-complete"
            )
            sendServerCommand(player, Mission.MOD_ID, "bootstrapComplete", {})
            logDiagnostic("Bootstrap", "complete-sent user=" .. username)
            return
        end

        if not player:getSquare() then
            logDiagnostic("Bootstrap", "deferred user=" .. username .. " reason=no-square")
            return
        end

        local attachedGear = addKit(player)
        logDiagnostic(
            "Bootstrap",
            "before-state-store user=" .. username
                .. " storedVersion=" .. diagnosticValue(data.operationLastSignalBootstrapVersion)
        )
        data.operationLastSignalBootstrapVersion = BOOTSTRAP_VERSION
        player:transmitModData()
        logDiagnostic(
            "Bootstrap",
            "state-stored user=" .. username
                .. " storedVersion=" .. diagnosticValue(data.operationLastSignalBootstrapVersion)
        )
        sendServerCommand(player, Mission.MOD_ID, "bootstrapComplete", {
            attachedGear = attachedGear,
        })
        logDiagnostic("Bootstrap", "complete-sent user=" .. username)
    end
end

local function onServerStarted()
    print("[OperationLastSignal] Server bootstrap loaded.")
end

Events.OnClientCommand.Add(handleCommand)
Events.OnServerStarted.Add(onServerStarted)
