require "ExtractionMode/HUD"
require "ExtractionMode/TownPicker"

ExtractionMode = ExtractionMode or {}

local HUD_WIDTH = 680
local TOWN_PICKER_WIDTH = 760
local TOWN_PICKER_PADDING = 14
local TOWN_PICKER_COLUMN_GAP = 12

local function isRussianLanguage()
    local language = Translator and Translator.getLanguage and Translator.getLanguage()
    return language ~= nil and tostring(language:name()) == "RU"
end

local function preserveRightEdge(panel, width)
    local right = panel:getRight()
    local screenWidth = getCore():getScreenWidth()
    local resolvedWidth = math.min(width, screenWidth)
    panel:setWidth(resolvedWidth)
    panel:setX(math.max(0, math.min(screenWidth - resolvedWidth, right - resolvedWidth)))
    if panel.initialFallbackX ~= nil then panel.initialFallbackX = panel:getX() end
end

local function preservePlayerCenter(panel, width)
    local playerNum = panel.playerNum or 0
    local screenLeft = getPlayerScreenLeft(playerNum)
    local screenWidth = getPlayerScreenWidth(playerNum)
    local center = panel:getX() + panel:getWidth() / 2
    local resolvedWidth = math.min(width, math.max(1, screenWidth - 20))
    local rightLimit = screenLeft + screenWidth - resolvedWidth
    panel:setWidth(resolvedWidth)
    panel:setX(math.max(screenLeft, math.min(rightLimit, math.floor(center - resolvedWidth / 2))))
end

local function layoutHUDChildren(hud)
    if hud.minimized then return end

    local width = hud:getWidth()
    local secondaryButtonWidth = math.floor((width - 30) / 2)

    if hud.toggle then hud.toggle:setX(width - 30) end
    if hud.action then hud.action:setWidth(width - 24) end
    if hud.townButton then hud.townButton:setWidth(width - 24) end
    if hud.upgradeButton then hud.upgradeButton:setWidth(secondaryButtonWidth) end
    if hud.questButton then
        hud.questButton:setX(18 + secondaryButtonWidth)
        hud.questButton:setWidth(secondaryButtonWidth)
    end
end

local function patchHUD()
    local HUD = ExtractionMode.HUD
    if HUD == nil or HUD.ExtractionModeRussianLanguageLayoutPatched then return end

    local previousNew = HUD.new
    HUD.new = function(self, ...)
        local hud = previousNew(self, ...)
        if isRussianLanguage() and not hud.minimized then
            preserveRightEdge(hud, HUD_WIDTH)
        end
        return hud
    end

    local previousCreateChildren = HUD.createChildren
    HUD.createChildren = function(self, ...)
        previousCreateChildren(self, ...)
        if isRussianLanguage() then layoutHUDChildren(self) end
    end

    local previousToggleMinimized = HUD.onToggleMinimized
    HUD.onToggleMinimized = function(self, ...)
        local right = self:getRight()
        previousToggleMinimized(self, ...)
        if isRussianLanguage() then
            local width = self.minimized and self:getWidth() or HUD_WIDTH
            self:setX(right - self:getWidth())
            preserveRightEdge(self, width)
            layoutHUDChildren(self)
        end
    end

    HUD.ExtractionModeRussianLanguageLayoutPatched = true
end

local function layoutTownButtons(picker)
    local buttonWidth = math.floor((picker:getWidth()
        - TOWN_PICKER_PADDING * 2 - TOWN_PICKER_COLUMN_GAP) / 2)
    local townIndex = 0

    for _, child in ipairs(picker.children or {}) do
        if child.townKey ~= nil then
            local column = townIndex % 2
            child:setX(TOWN_PICKER_PADDING + column * (buttonWidth + TOWN_PICKER_COLUMN_GAP))
            child:setWidth(buttonWidth)
            townIndex = townIndex + 1
        end
    end

    if picker.closeButton then
        picker.closeButton:setWidth(picker:getWidth() - TOWN_PICKER_PADDING * 2)
    end
    picker:autoGenerateJoypadButtonsLists()
end

local function patchTownPicker()
    local Picker = ExtractionMode.TownPicker
    if Picker == nil or Picker.ExtractionModeRussianLanguageLayoutPatched then return end

    local previousNew = Picker.new
    Picker.new = function(self, ...)
        local picker = previousNew(self, ...)
        if isRussianLanguage() then preservePlayerCenter(picker, TOWN_PICKER_WIDTH) end
        return picker
    end

    local previousCreateChildren = Picker.createChildren
    Picker.createChildren = function(self, ...)
        previousCreateChildren(self, ...)
        if isRussianLanguage() then layoutTownButtons(self) end
    end

    Picker.ExtractionModeRussianLanguageLayoutPatched = true
end

patchHUD()
patchTownPicker()
