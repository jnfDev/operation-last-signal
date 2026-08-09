local Mission = require("OperationUltimaSenal/Config")
require "ISUI/ISPanel"
require "ISUI/ISButton"

local RoleSelectPanel = ISPanel:derive("OperationUltimaSenalRoleSelect")
local DeploymentPanel = ISPanel:derive("OperationUltimaSenalDeployment")
local rolePanel
local deploymentPanel
local bootstrapComplete = false
local roleStatusReceived = false
local updateTicks = 0
local casePlacementTicks = 0
local pendingRoleStatus

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
    self:drawTextCentre("OPERACION ULTIMA SENAL", self.width / 2, 16, 0.90, 0.72, 0.34, 1, UIFont.Large)
    self:drawTextCentre("Elige un personaje para esta operacion", self.width / 2, 49, 0.85, 0.85, 0.85, 1, UIFont.Small)

    for index, role in ipairs(self.roles or {}) do
        local y = 82 + (index - 1) * 76
        self:drawText(role.name, 22, y, 0.94, 0.94, 0.94, 1, UIFont.Medium)
        self:drawText(role.title, 22, y + 23, 0.90, 0.72, 0.34, 1, UIFont.Small)
        self:drawText(role.description, 22, y + 41, 0.76, 0.76, 0.76, 1, UIFont.Small)
    end
end

function RoleSelectPanel:onChooseRole(button)
    self.statusMessage = "Asignando rol y equipo..."
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
            button:setTitle("OCUPADO")
        else
            button:setEnable(true)
            button:setTitle("ELEGIR")
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
        local button = ISButton:new(548, 82 + (index - 1) * 76, 125, 32, "ELEGIR", panel, RoleSelectPanel.onChooseRole)
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
    self:drawTextCentre("OPERACION ULTIMA SENAL", self.width / 2, 22, 0.90, 0.72, 0.34, 1, UIFont.Medium)
    self:drawTextCentre("Preparando despliegue...", self.width / 2, 57, 0.90, 0.90, 0.90, 1, UIFont.Small)
    self:drawTextCentre("Sincronizando equipo y uniforme", self.width / 2, 80, 0.70, 0.70, 0.70, 1, UIFont.Small)
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

local function retryMissionState(player)
    if not player or player:isDead() then
        return
    end

    casePlacementTicks = casePlacementTicks + 1
    if casePlacementTicks % 120 == 0 then
        sendClientCommand(Mission.MOD_ID, "requestCasePlacement", {})
    end

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

    if command == "bootstrapComplete" then
        bootstrapComplete = true
        hideDeploymentPanel()
        if pendingRoleStatus then
            showRolePanel(pendingRoleStatus)
        end
        return
    end

    if command ~= "roleStatus" or not args then
        return
    end

    roleStatusReceived = true
    pendingRoleStatus = args
    if not bootstrapComplete then
        return
    end

    showRolePanel(args)
end

Events.OnCreatePlayer.Add(requestBootstrap)
Events.OnPlayerUpdate.Add(retryMissionState)
Events.OnServerCommand.Add(onServerCommand)
