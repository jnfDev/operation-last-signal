local Mission = require("OperationLastSignal/Config")
local BOOTSTRAP_VERSION = 1
local ROLE_PROFILE_VERSION = Mission.ROLE_PROFILE_VERSION
local pendingRoleProfiles = {}
local PRESERVED_ROLE_TRAITS = {
    CharacterTrait.WEAK,
    CharacterTrait.FEEBLE,
    CharacterTrait.STOUT,
    CharacterTrait.STRONG,
    CharacterTrait.UNFIT,
    CharacterTrait.OUT_OF_SHAPE,
    CharacterTrait.FIT,
    CharacterTrait.ATHLETIC,
}

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

local function placeCasesInChunk(loadedChunk)
    local state = getMissionState()
    state.casesPlaced = state.casesPlaced or {}
    local cell = getWorld():getCell()

    for _, missionCase in ipairs(Mission.CASES) do
        if not state.casesPlaced[missionCase.id] then
            local square = cell:getGridSquare(missionCase.x, missionCase.y, missionCase.z)
            if square and square:getChunk() == loadedChunk then
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

local function isRoleAuthorized(player, role)
    if not player or not role then
        return false
    end

    local username = getUsername(player)
    local data = player:getModData()
    local claims = getClaims()
    return data.operationLastSignalRole == role.id
        and data.operationLastSignalRoleOwner == username
        and claims[role.id] == username
end

local function reconcileUsernameClaim(player)
    local username = getUsername(player)
    local claims = getClaims()
    local claimedRole

    for _, role in ipairs(Mission.ROLES) do
        if claims[role.id] == username then
            if claimedRole then
                return nil, "multiple-role-claims"
            end
            claimedRole = role
        end
    end

    if not claimedRole then
        return nil
    end

    local data = player:getModData()
    if data.operationLastSignalRole ~= claimedRole.id
        or data.operationLastSignalRoleOwner ~= username then
        data.operationLastSignalRole = claimedRole.id
        data.operationLastSignalRoleOwner = username
        data.operationLastSignalRoleProfileVersion = nil
        player:transmitModData()
        logDiagnostic(
            "Role",
            "claim-restored user=" .. diagnosticValue(username)
                .. " playerRole=" .. diagnosticValue(claimedRole.id)
        )
    end

    return claimedRole
end

local function mergeSkillFloor(skills, skillName, targetLevel)
    if type(skillName) ~= "string"
        or type(targetLevel) ~= "number"
        or targetLevel < 0
        or targetLevel > 10
        or targetLevel ~= math.floor(targetLevel) then
        return false
    end

    skills[skillName] = math.max(skills[skillName] or 0, targetLevel)
    return true
end

local function buildRoleProfile(role)
    if not role or not role.identity
        or type(role.identity.forename) ~= "string"
        or type(role.identity.surname) ~= "string"
        or type(role.identity.displayName) ~= "string" then
        return nil, "invalid-identity"
    end

    local skills = {}
    for skillName, targetLevel in pairs(Mission.COMMON_SKILLS or {}) do
        if not mergeSkillFloor(skills, skillName, targetLevel) then
            return nil, "invalid-common-skill-" .. diagnosticValue(skillName)
        end
    end
    for skillName, targetLevel in pairs(role.skills or {}) do
        if not mergeSkillFloor(skills, skillName, targetLevel) then
            return nil, "invalid-role-skill-" .. diagnosticValue(skillName)
        end
    end

    local recipes = {}
    for _, recipe in ipairs(role.recipes or {}) do
        if type(recipe) ~= "string" or recipe == "" then
            return nil, "invalid-recipe"
        end
        table.insert(recipes, recipe)
    end

    return {
        roleId = role.id,
        version = ROLE_PROFILE_VERSION,
        identity = {
            forename = role.identity.forename,
            surname = role.identity.surname,
            displayName = role.identity.displayName,
        },
        skills = skills,
        recipes = recipes,
    }
end

local function applyRoleIdentity(player, identity)
    local descriptor = player:getDescriptor()
    if not descriptor then
        return false, "missing-descriptor"
    end

    if descriptor:getForename() ~= identity.forename then
        descriptor:setForename(identity.forename)
    end
    if descriptor:getSurname() ~= identity.surname then
        descriptor:setSurname(identity.surname)
    end
    if player:getDisplayName() ~= identity.displayName then
        player:setDisplayName(identity.displayName)
    end

    return true
end

local function verifyRoleIdentity(player, identity)
    local descriptor = player:getDescriptor()
    return descriptor
        and descriptor:getForename() == identity.forename
        and descriptor:getSurname() == identity.surname
        and player:getDisplayName() == identity.displayName
end

local function broadcastRoleIdentity(player, profile)
    sendServerCommand(Mission.MOD_ID, "syncRoleIdentity", {
        roleId = profile.roleId,
        username = getUsername(player),
        onlineId = player:getOnlineID(),
        identity = profile.identity,
    })
end

local function resolvePerk(skillName)
    local perk = Perks.FromString(skillName)
    if not perk or not PerkFactory.getPerk(perk) then
        return nil
    end
    return perk
end

local function raiseSkillToFloor(player, perk, targetLevel)
    if player:getPerkLevel(perk) >= targetLevel then
        return true, false
    end

    local xp = player:getXp()
    local currentXp = xp:getXP(perk)
    local targetXp = perk:getTotalXpForLevel(targetLevel)
    if currentXp < targetXp then
        xp:setXPToLevel(perk, targetLevel)
    end

    while player:getPerkLevel(perk) < targetLevel do
        local previousLevel = player:getPerkLevel(perk)
        player:LevelPerk(perk, false)
        if player:getPerkLevel(perk) <= previousLevel then
            return false, false, "level-not-raised-" .. tostring(perk)
        end
    end

    if perk == Perks.Fitness then
        player:getStats():set(CharacterStat.FITNESS, player:getPerkLevel(perk) / 5 - 1)
    end

    -- Route a zero-value award through the multiplayer API so the server's XP
    -- checker adopts the exact values assigned above without changing XP or
    -- consuming an XP multiplier.
    addXpNoMultiplier(player, perk, 0)
    return true, true
end

local function snapshotRoleTraits(player)
    local traits = player:getCharacterTraits()
    local snapshot = {}
    for _, trait in ipairs(PRESERVED_ROLE_TRAITS) do
        snapshot[trait] = traits:get(trait)
    end
    return snapshot
end

local function restoreRoleTraits(player, snapshot)
    local traits = player:getCharacterTraits()
    for _, trait in ipairs(PRESERVED_ROLE_TRAITS) do
        if traits:get(trait) ~= snapshot[trait] then
            traits:set(trait, snapshot[trait])
        end
    end
end

local function applyRoleProgressionChanges(player, profile)
    local fitnessChanged = false
    for skillName, targetLevel in pairs(profile.skills) do
        local perk = resolvePerk(skillName)
        if not perk then
            return false, "unknown-perk-" .. skillName
        end

        local raisedOk, changed, raiseError = raiseSkillToFloor(player, perk, targetLevel)
        if not raisedOk then
            return false, raiseError
        end
        if changed and perk == Perks.Fitness then
            fitnessChanged = true
        end
    end

    for _, recipe in ipairs(profile.recipes) do
        if not player:isRecipeActuallyKnown(recipe) then
            player:learnRecipe(recipe)
        end
        if not player:isRecipeActuallyKnown(recipe) then
            return false, "unknown-recipe-" .. recipe
        end
    end

    return true, fitnessChanged
end

local function applyRoleProgression(player, profile)
    local traitSnapshot = snapshotRoleTraits(player)
    local callOk, changesOk, fitnessChangedOrError = pcall(applyRoleProgressionChanges, player, profile)
    local restoreOk, restoreError = pcall(restoreRoleTraits, player, traitSnapshot)
    if not restoreOk then
        return false, "trait-restore-failed-" .. tostring(restoreError)
    end
    if not callOk then
        return false, tostring(changesOk)
    end
    if not changesOk then
        return false, fitnessChangedOrError
    end

    if #profile.recipes > 0 then
        sendSyncPlayerFields(player, 0x00000001)
    end
    if fitnessChangedOrError then
        syncPlayerStats(player, 0x00000020)
    end

    return true
end

local function verifyRoleProgression(player, profile)
    for skillName, targetLevel in pairs(profile.skills) do
        local perk = resolvePerk(skillName)
        if not perk then
            return false, "unknown-perk-" .. skillName
        end
        if player:getPerkLevel(perk) < targetLevel then
            return false, "skill-below-floor-" .. skillName
        end
    end

    for _, recipe in ipairs(profile.recipes) do
        if not player:isRecipeActuallyKnown(recipe) then
            return false, "recipe-not-known-" .. recipe
        end
    end

    return true
end

local function ensureRoleProfile(player, role)
    if not isRoleAuthorized(player, role) then
        logDiagnostic(
            "Profile",
            "rejected user=" .. diagnosticUsername(player)
                .. " role=" .. diagnosticValue(role and role.id)
                .. " reason=role-not-authorized"
        )
        return
    end

    local profile, profileError = buildRoleProfile(role)
    if not profile then
        logDiagnostic(
            "Profile",
            "rejected user=" .. diagnosticUsername(player)
                .. " role=" .. diagnosticValue(role and role.id)
                .. " reason=" .. diagnosticValue(profileError)
        )
        return
    end

    local identityOk, identityApplied, identityError = pcall(applyRoleIdentity, player, profile.identity)
    if not identityOk then
        identityError = identityApplied
        identityApplied = false
    end
    if not identityApplied then
        logDiagnostic(
            "Profile",
            "identity-incomplete user=" .. diagnosticUsername(player)
                .. " role=" .. diagnosticValue(role.id)
                .. " reason=" .. diagnosticValue(identityError)
        )
        return
    end
    broadcastRoleIdentity(player, profile)

    local data = player:getModData()
    profile.applyProgression = data.operationLastSignalRoleProfileVersion ~= ROLE_PROFILE_VERSION

    if profile.applyProgression then
        local callOk, applyOk, applyError = pcall(applyRoleProgression, player, profile)
        if not callOk then
            applyError = applyOk
            applyOk = false
        end
        if not applyOk then
            logDiagnostic(
                "Profile",
                "progression-incomplete user=" .. diagnosticUsername(player)
                    .. " role=" .. diagnosticValue(role.id)
                    .. " version=" .. diagnosticValue(ROLE_PROFILE_VERSION)
                    .. " reason=" .. diagnosticValue(applyError)
            )
        end
    end

    local username = getUsername(player)
    pendingRoleProfiles[username] = {
        roleId = role.id,
        version = ROLE_PROFILE_VERSION,
        applyProgression = profile.applyProgression,
        profile = profile,
    }

    sendServerCommand(player, Mission.MOD_ID, "applyRoleProfile", profile)
    logDiagnostic(
        "Profile",
        "sent user=" .. diagnosticValue(username)
            .. " role=" .. diagnosticValue(role.id)
            .. " version=" .. diagnosticValue(ROLE_PROFILE_VERSION)
            .. " applyProgression=" .. diagnosticValue(profile.applyProgression)
    )
end

local function handleRoleProfileResult(player, args)
    local username = getUsername(player)
    local pending = pendingRoleProfiles[username]
    local data = player:getModData()
    local resultRoleId = type(args) == "table" and args.roleId or nil
    local resultVersion = type(args) == "table" and args.version or nil

    if not pending then
        logDiagnostic("Profile", "result-rejected user=" .. diagnosticValue(username) .. " reason=no-pending-profile")
        return
    end

    if type(args) ~= "table"
        or resultRoleId ~= pending.roleId
        or resultVersion ~= pending.version
        or not isRoleAuthorized(player, Mission.getRole(pending.roleId)) then
        logDiagnostic(
            "Profile",
            "result-rejected user=" .. diagnosticValue(username)
                .. " role=" .. diagnosticValue(resultRoleId)
                .. " version=" .. diagnosticValue(resultVersion)
                .. " reason=profile-mismatch"
        )
        return
    end

    pendingRoleProfiles[username] = nil
    if args.success ~= true then
        logDiagnostic(
            "Profile",
            "result-failed user=" .. diagnosticValue(username)
                .. " role=" .. diagnosticValue(args.roleId)
                .. " version=" .. diagnosticValue(args.version)
                .. " reason=" .. diagnosticValue(args.error)
        )
        return
    end

    if not verifyRoleIdentity(player, pending.profile.identity) then
        logDiagnostic(
            "Profile",
            "result-rejected user=" .. diagnosticValue(username)
                .. " role=" .. diagnosticValue(args.roleId)
                .. " version=" .. diagnosticValue(args.version)
                .. " reason=identity-mismatch"
        )
        return
    end

    if pending.applyProgression then
        local callOk, verified, verificationError = pcall(verifyRoleProgression, player, pending.profile)
        if not callOk then
            verificationError = verified
            verified = false
        end
        if not verified then
            logDiagnostic(
                "Profile",
                "result-rejected user=" .. diagnosticValue(username)
                    .. " role=" .. diagnosticValue(args.roleId)
                    .. " version=" .. diagnosticValue(args.version)
                    .. " reason=" .. diagnosticValue(verificationError)
            )
            return
        end

        data.operationLastSignalRoleProfileVersion = ROLE_PROFILE_VERSION
        player:transmitModData()
    end

    logDiagnostic(
        "Profile",
        "complete user=" .. diagnosticValue(username)
            .. " role=" .. diagnosticValue(args.roleId)
            .. " version=" .. diagnosticValue(args.version)
            .. " progressionApplied=" .. diagnosticValue(pending.applyProgression)
    )
end

local function sendRoleStatus(player, message, suppressSelectedRole)
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
        selectedRole = not suppressSelectedRole and data.operationLastSignalRole or nil,
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

    local claimedRole, claimError = reconcileUsernameClaim(player)
    if claimError then
        logDiagnostic(
            "Role",
            "rejected user=" .. diagnosticValue(username)
                .. " requestedRole=" .. diagnosticValue(roleId)
                .. " reason=" .. diagnosticValue(claimError)
        )
        sendRoleStatus(
            player,
            "Role ownership is inconsistent. Reconnect after the host reviews the claims.",
            true
        )
        return
    end

    if claimedRole then
        logDiagnostic(
            "Role",
            "restored user=" .. diagnosticValue(username)
                .. " requestedRole=" .. diagnosticValue(roleId)
                .. " playerRole=" .. diagnosticValue(claimedRole.id)
                .. " reason=username-already-owns-role"
        )
        sendRoleStatus(player, "Your assigned character has been restored.")
        ensureRoleProfile(player, claimedRole)
        return
    end

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
    sendRoleStatus(player, role.name .. " assigned. Role kit and profile authorized.")
    ensureRoleProfile(player, role)
end

local function handleCommand(module, command, player, args)
    if module ~= Mission.MOD_ID or not player then
        return
    end

    if command == "requestRoleStatus" then
        local data = player:getModData()
        local claimedRole, claimError = reconcileUsernameClaim(player)
        logDiagnostic(
            "Role",
            "status-request user=" .. diagnosticUsername(player)
                .. " playerRole=" .. diagnosticValue(data.operationLastSignalRole)
        )
        if claimError then
            logDiagnostic(
                "Role",
                "status-rejected user=" .. diagnosticUsername(player)
                    .. " reason=" .. diagnosticValue(claimError)
            )
            sendRoleStatus(
                player,
                "Role ownership is inconsistent. Reconnect after the host reviews the claims.",
                true
            )
            return
        end
        sendRoleStatus(player)
        local role = claimedRole or Mission.getRole(data.operationLastSignalRole)
        if role then
            ensureRoleProfile(player, role)
        end
        return
    end

    if command == "selectRole" then
        selectRole(player, args and args.roleId)
        return
    end

    if command == "roleProfileResult" then
        handleRoleProfileResult(player, args)
        return
    end

    if command == "requestBootstrap" then
        local data = player:getModData()
        local username = diagnosticUsername(player)
        local playerSquare = player:getSquare()
        logDiagnostic(
            "Bootstrap",
            "request user=" .. username
                .. " storedVersion=" .. diagnosticValue(data.operationLastSignalBootstrapVersion)
                .. " expectedVersion=" .. diagnosticValue(BOOTSTRAP_VERSION)
                .. " hasSquare=" .. diagnosticValue(playerSquare ~= nil)
        )

        local playerChunk = playerSquare and playerSquare:getChunk()
        if playerChunk then
            placeCasesInChunk(playerChunk)
        end

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

        if not playerSquare then
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
Events.LoadChunk.Add(placeCasesInChunk)
Events.OnServerStarted.Add(onServerStarted)
