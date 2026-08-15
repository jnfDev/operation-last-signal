local Mission = require("OperationLastSignal/Config")
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "TimedActions/ISTimedActionQueue"

local RoleSelectPanel = ISPanel:derive("OperationLastSignalRoleSelect")
local DeploymentPanel = ISPanel:derive("OperationLastSignalDeployment")
local rolePanel
local deploymentPanel
local bootstrapComplete = false
local roleStatusReceived = false
local updateTicks = 0
local pendingRoleStatus
local pendingAttachedGear
local pendingRoleIdentities = {}
local pendingRoleProfile

local function requestMissionState()
    sendClientCommand(Mission.MOD_ID, "requestBootstrap", {})
    sendClientCommand(Mission.MOD_ID, "requestRoleStatus", {})
end

function RoleSelectPanel:initialise()
    ISPanel.initialise(self)
    self.backgroundColor = { r = 0.08, g = 0.11, b = 0.09, a = 0.95 }
    self.borderColor = { r = 0.72, g = 0.56, b = 0.25, a = 1 }
end

function RoleSelectPanel:render()
    ISPanel.render(self)
    self:drawTextCentre("OPERATION LAST SIGNAL", self.width / 2, 16, 0.90, 0.72, 0.34, 1, UIFont.Large)
    self:drawTextCentre("Choose a character for this operation", self.width / 2, 49, 0.85, 0.85, 0.85, 1, UIFont.Small)

    for index, role in ipairs(self.roles or {}) do
        local y = 82 + (index - 1) * 76
        self:drawText(role.name, 22, y, 0.94, 0.94, 0.94, 1, UIFont.Medium)
        self:drawText(role.title, 22, y + 23, 0.90, 0.72, 0.34, 1, UIFont.Small)
        self:drawText(role.description, 22, y + 41, 0.76, 0.76, 0.76, 1, UIFont.Small)
    end
end

function RoleSelectPanel:onChooseRole(button)
    self.statusMessage = "Assigning role and equipment..."
    for _, roleButton in ipairs(self.roleButtons) do
        roleButton:setEnable(false)
    end
    sendClientCommand(Mission.MOD_ID, "selectRole", { roleId = button.roleId })
end

function RoleSelectPanel:updateRoles(status)
    self.roles = status.roles or {}
    for index, role in ipairs(status.roles) do
        local claimedByOther = role.claimedBy and role.claimedBy ~= ""
        local button = self.roleButtons[index]

        if claimedByOther then
            button:setEnable(false)
            button:setTitle("CLAIMED")
        else
            button:setEnable(true)
            button:setTitle("SELECT")
        end
    end

    if status.message and status.message ~= "" then
        self.statusMessage = status.message
    end
end

function RoleSelectPanel:prerender()
    ISPanel.prerender(self)
    if self.statusMessage then
        self:drawTextCentre(self.statusMessage, self.width / 2, self.height - 34, 0.90, 0.72, 0.34, 1, UIFont.Small)
    end
end

function RoleSelectPanel:new(status)
    local width, height = 700, 430
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local panel = ISPanel.new(self, x, y, width, height)
    setmetatable(panel, self)
    self.__index = self
    panel.roleButtons = {}
    panel.statusMessage = ""
    panel.roles = {}

    for index, role in ipairs(status.roles) do
        local button = ISButton:new(548, 82 + (index - 1) * 76, 125, 32, "SELECT", panel, RoleSelectPanel.onChooseRole)
        button:initialise()
        button.roleId = role.id
        panel:addChild(button)
        panel.roleButtons[index] = button
    end

    panel:initialise()
    panel:addToUIManager()
    panel:setVisible(true)
    panel:updateRoles(status)
    return panel
end

function DeploymentPanel:initialise()
    ISPanel.initialise(self)
    self.backgroundColor = { r = 0.08, g = 0.11, b = 0.09, a = 0.95 }
    self.borderColor = { r = 0.72, g = 0.56, b = 0.25, a = 1 }
end

function DeploymentPanel:render()
    ISPanel.render(self)
    self:drawTextCentre("OPERATION LAST SIGNAL", self.width / 2, 22, 0.90, 0.72, 0.34, 1, UIFont.Medium)
    self:drawTextCentre("Preparing deployment...", self.width / 2, 57, 0.90, 0.90, 0.90, 1, UIFont.Small)
    self:drawTextCentre("Synchronizing equipment and uniform", self.width / 2, 80, 0.70, 0.70, 0.70, 1, UIFont.Small)
end

function DeploymentPanel:new()
    local width, height = 390, 125
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local panel = ISPanel.new(self, x, y, width, height)
    setmetatable(panel, self)
    self.__index = self
    panel:initialise()
    panel:addToUIManager()
    panel:setVisible(true)
    return panel
end

local function showDeploymentPanel()
    if not deploymentPanel then
        deploymentPanel = DeploymentPanel:new()
    end
end

local function hideDeploymentPanel()
    if deploymentPanel then
        deploymentPanel:removeFromUIManager()
        deploymentPanel = nil
    end
end

local function showRolePanel(status)
    if status.selectedRole then
        if rolePanel then
            rolePanel:removeFromUIManager()
            rolePanel = nil
        end
        return
    end

    if rolePanel then
        rolePanel:removeFromUIManager()
    end
    rolePanel = RoleSelectPanel:new(status)
end

local function requestBootstrap(playerIndex, player)
    if not player or player:isDead() then
        return
    end

    showDeploymentPanel()
    requestMissionState()
end

local function queueAttachedGear(attachedGear)
    if not attachedGear or #attachedGear == 0 then
        return
    end

    pendingAttachedGear = pendingAttachedGear or {}
    for _, attachment in ipairs(attachedGear) do
        local alreadyPending = false
        for _, pending in ipairs(pendingAttachedGear) do
            if pending.itemId == attachment.itemId then
                alreadyPending = true
                break
            end
        end

        if not alreadyPending then
            table.insert(pendingAttachedGear, {
                itemId = attachment.itemId,
                slotType = attachment.slotType,
            })
        end
    end
end

local function attachPendingGear(player)
    if not pendingAttachedGear or #pendingAttachedGear == 0 then
        pendingAttachedGear = nil
        return
    end
    if not player then
        return
    end

    local hotbar = getPlayerHotbar(player:getPlayerNum())
    if not hotbar then
        return
    end

    hotbar:refresh()
    local inventory = player:getInventory()
    local attachment = pendingAttachedGear[1]
    local item = inventory:getItemById(attachment.itemId)
    if not item then
        return
    end

    if item:getAttachedSlotType() == attachment.slotType then
        table.remove(pendingAttachedGear, 1)
        if #pendingAttachedGear > 0 then
            return
        end
        pendingAttachedGear = nil
        return
    end

    if ISTimedActionQueue.hasActionType(player, "ISAttachItemHotbar") then
        return
    end

    local slotIndex = hotbar:getThisSlotIndex(attachment.slotType)
    local slot = slotIndex and hotbar.availableSlot[slotIndex]
    local model = slot and slot.def.attachments[item:getAttachmentType()]
    if slot and model then
        hotbar:attachItem(item, model, slotIndex, slot.def, true)
    end
end

local function validateRoleProfile(player, profile)
    if type(profile) ~= "table" or profile.version ~= Mission.ROLE_PROFILE_VERSION then
        return nil, "version-mismatch"
    end

    local role = Mission.getRole(profile.roleId)
    if not role or not role.identity or type(profile.identity) ~= "table" then
        return nil, "invalid-role"
    end

    local selectedRole = pendingRoleStatus and pendingRoleStatus.selectedRole
    if not selectedRole then
        selectedRole = player:getModData().operationLastSignalRole
    end
    if selectedRole ~= profile.roleId then
        return nil, "role-mismatch"
    end

    if profile.identity.forename ~= role.identity.forename
        or profile.identity.surname ~= role.identity.surname
        or profile.identity.displayName ~= role.identity.displayName then
        return nil, "identity-mismatch"
    end

    if type(profile.applyProgression) ~= "boolean"
        or type(profile.skills) ~= "table"
        or type(profile.recipes) ~= "table" then
        return nil, "invalid-progression"
    end

    local expectedSkills = {}
    for skillName, targetLevel in pairs(Mission.COMMON_SKILLS or {}) do
        expectedSkills[skillName] = targetLevel
    end
    for skillName, targetLevel in pairs(role.skills or {}) do
        expectedSkills[skillName] = math.max(expectedSkills[skillName] or 0, targetLevel)
    end

    local expectedSkillCount = 0
    for skillName, targetLevel in pairs(expectedSkills) do
        expectedSkillCount = expectedSkillCount + 1
        if profile.skills[skillName] ~= targetLevel then
            return nil, "skill-profile-mismatch"
        end
    end
    local receivedSkillCount = 0
    for _ in pairs(profile.skills) do
        receivedSkillCount = receivedSkillCount + 1
    end
    if receivedSkillCount ~= expectedSkillCount then
        return nil, "skill-profile-mismatch"
    end

    local expectedRecipes = role.recipes or {}
    if #profile.recipes ~= #expectedRecipes then
        return nil, "recipe-profile-mismatch"
    end
    for index, recipe in ipairs(expectedRecipes) do
        if profile.recipes[index] ~= recipe then
            return nil, "recipe-profile-mismatch"
        end
    end

    return role
end

local function applyRoleIdentity(player, identity)
    local descriptor = player:getDescriptor()
    if not descriptor then
        error("missing-descriptor")
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
end

local function queueRoleIdentity(args)
    if type(args) ~= "table"
        or type(args.username) ~= "string"
        or args.username == "" then
        return false
    end

    local role = Mission.getRole(args.roleId)
    if not role or not role.identity then
        return false
    end
    if args.identity and type(args.identity) ~= "table" then
        return false
    end
    if args.identity
        and (args.identity.forename ~= role.identity.forename
            or args.identity.surname ~= role.identity.surname
            or args.identity.displayName ~= role.identity.displayName) then
        return false
    end

    pendingRoleIdentities[args.username] = {
        username = args.username,
        onlineId = args.onlineId,
        identity = role.identity,
    }
    return true
end

local function applyPendingRoleIdentities()
    for username, pending in pairs(pendingRoleIdentities) do
        local player
        if type(pending.onlineId) == "number" then
            player = getPlayerByOnlineID(pending.onlineId)
        end
        if not player then
            player = getPlayerFromUsername(username)
        end

        if player and player:getUsername() == username then
            local callOk = pcall(applyRoleIdentity, player, pending.identity)
            if callOk then
                pendingRoleIdentities[username] = nil
            end
        end
    end
end

local function sendRoleProfileResult(profile, success, resultError)
    sendClientCommand(Mission.MOD_ID, "roleProfileResult", {
        roleId = type(profile) == "table" and profile.roleId or nil,
        version = type(profile) == "table" and profile.version or nil,
        success = success,
        error = resultError and string.sub(tostring(resultError), 1, 200) or nil,
    })
end

local function verifyLocalRoleProgression(player, profile)
    for skillName, targetLevel in pairs(profile.skills) do
        local perk = Perks.FromString(skillName)
        if not perk or not PerkFactory.getPerk(perk) then
            return false
        end
        if player:getPerkLevel(perk) < targetLevel then
            return false
        end
    end

    for _, recipe in ipairs(profile.recipes) do
        if not player:isRecipeActuallyKnown(recipe) then
            return false
        end
    end

    return true
end


local function completePendingRoleProfile(player)
    if not pendingRoleProfile or not player or player:isDead() then
        return
    end

    local role, validationError = validateRoleProfile(player, pendingRoleProfile)
    if not role then
        local rejectedProfile = pendingRoleProfile
        pendingRoleProfile = nil
        sendRoleProfileResult(rejectedProfile, false, validationError)
        return
    end

    local callOk, progressionReady = pcall(verifyLocalRoleProgression, player, pendingRoleProfile)
    if not callOk or not progressionReady then
        return
    end

    local completedProfile = pendingRoleProfile
    pendingRoleProfile = nil
    sendRoleProfileResult(completedProfile, true)
end

local function handleRoleProfile(profile)
    local player = getPlayer()

    if not player or player:isDead() then
        sendRoleProfileResult(profile, false, "player-unavailable")
        return
    end

    local role, validationError = validateRoleProfile(player, profile)
    if not role then
        sendRoleProfileResult(profile, false, validationError)
        return
    end

    local callOk, applyError = pcall(applyRoleIdentity, player, profile.identity)
    if not callOk then
        sendRoleProfileResult(profile, false, applyError)
        return
    end

    if not profile.applyProgression then
        sendRoleProfileResult(profile, true)
        return
    end

    pendingRoleProfile = profile
    completePendingRoleProfile(player)
end

local function retryMissionState(player)
    if not player or player:isDead() then
        return
    end

    attachPendingGear(player)
    applyPendingRoleIdentities()
    completePendingRoleProfile(player)

    if bootstrapComplete and roleStatusReceived then
        return
    end

    updateTicks = updateTicks + 1
    if updateTicks % 120 == 0 then
        requestMissionState()
    end
end

local function onServerCommand(module, command, args)
    if module ~= Mission.MOD_ID then
        return
    end

    if command == "applyRoleProfile" then
        handleRoleProfile(args)
        return
    end

    if command == "syncRoleIdentity" then
        if queueRoleIdentity(args) then
            applyPendingRoleIdentities()
        end
        return
    end

    if command == "bootstrapComplete" then
        bootstrapComplete = true
        queueAttachedGear(args and args.attachedGear)
        hideDeploymentPanel()
        if pendingRoleStatus then
            showRolePanel(pendingRoleStatus)
        end
        return
    end

    if command == "attachGear" then
        queueAttachedGear(args and args.attachedGear)
        return
    end

    if command ~= "roleStatus" or not args then
        return
    end

    roleStatusReceived = true
    pendingRoleStatus = args
    for _, roleStatus in ipairs(args.roles or {}) do
        if roleStatus.claimedBy and roleStatus.claimedBy ~= "" then
            queueRoleIdentity({
                roleId = roleStatus.id,
                username = roleStatus.claimedBy,
            })
        end
    end
    applyPendingRoleIdentities()
    if not bootstrapComplete then
        return
    end

    showRolePanel(args)
end

Events.OnCreatePlayer.Add(requestBootstrap)
Events.OnPlayerUpdate.Add(retryMissionState)
Events.OnServerCommand.Add(onServerCommand)
