require "ISUI/ISPanel"
require "ISUI/ISModalDialog"
require "ISUI/ISToolTip"
require "ExtractionMode/Localization"
require "ExtractionMode/GaragePanel"
require "ExtractionMode/GarageControls"

ExtractionMode = ExtractionMode or {}

local PRIVATE_KEY_PREFIX = "IGUI_ExtractionMode_RussianLanguage_Garage_"

local function isRussianLanguage()
    local language = Translator and Translator.getLanguage and Translator.getLanguage()
    return language ~= nil and tostring(language:name()) == "RU"
end

local function state()
    return ExtractionMode.ClientState or {}
end

local function localized(suffix, fallback, ...)
    return ExtractionMode.Localization.get(PRIVATE_KEY_PREFIX .. tostring(suffix), fallback, ...)
end

local function modelLabel(record)
    if record == nil then return localized("UnknownVehicle", "Unknown vehicle") end
    local key = tostring(record.modelKey or "")
    local translated = key ~= "" and getTextOrNull
        and getTextOrNull("IGUI_VehicleName" .. key) or nil
    return translated or key ~= "" and key
        or tostring(record.scriptName or localized("UnknownVehicle", "Unknown vehicle"))
end

local function recordLabel(record)
    local label = nil
    if record and record.customName == true and tostring(record.name or "") ~= "" then
        label = tostring(record.name)
    else
        label = modelLabel(record)
    end
    local ordinal = math.max(1, math.floor(tonumber(record and record.nameOrdinal) or 1))
    if ordinal > 1 then label = label .. " " .. tostring(ordinal) end
    return label
end

local garageMessageKeys = {
    ["Your missing vehicle key was replaced and added to your inventory."] = "Message_MissingKeyReplaced",
    ["Vehicle storage was cancelled because the active vehicle could not be identified safely. Wait for it to finish loading and try again."] = "Error_StorageVehicleUnidentified",
    ["That RV cannot be returned while a player is inside its interior."] = "Error_RvInteriorOccupied",
    ["The RV was left in the raid because someone entered its interior during extraction."] = "Error_RvLeftInRaid",
    ["Your vehicle was kept safely in the garage because the previous vehicle has not finished despawning."] = "Message_VehicleKeptInGarage",
    ["The inactive vehicle was returned to its owner's garage and your vehicle was deployed."] = "Message_InactiveReturnedAndDeployed",
    ["The hideout vehicle bay is not loaded."] = "Error_BayNotLoaded",
    ["The hideout vehicle bay is blocked by another vehicle."] = "Error_BayBlocked",
    ["Project Zomboid could not create that vehicle in the indoor hideout bay."] = "Error_VehicleCreationFailed",
    ["The previous active vehicle is still despawning. Wait for the current garage transition to finish."] = "Error_PreviousVehicleDespawning",
    ["That garage vehicle no longer exists."] = "Error_VehicleMissing",
    ["There is no active hideout vehicle."] = "Error_NoActiveVehicle",
    ["The active hideout vehicle is reserved for a raid deployment."] = "Error_ActiveVehicleRaidReserved",
    ["The active hideout vehicle is occupied."] = "Error_ActiveVehicleOccupied",
    ["The active hideout vehicle has not been inactive long enough to swap."] = "Error_InactivityTimer",
    ["Vehicles can only be deployed while their owner is inside the hideout."] = "Error_OwnerOutsideHideout",
    ["The vehicle owner is unavailable."] = "Error_OwnerUnavailable",
    ["A living owner is required."] = "Error_LivingOwnerRequired",
    ["Only the active vehicle's owner can transfer it."] = "Error_TransferOwnerOnly",
    ["Wait for the active vehicle to finish returning before transferring it."] = "Error_TransferWhileReturning",
    ["The vehicle cannot be transferred while it is reserved for raid deployment."] = "Error_TransferRaidReserved",
    ["The active vehicle is not currently loaded."] = "Error_ActiveVehicleNotLoaded",
    ["A living player must be sitting in the driver's seat."] = "Error_LivingDriverRequired",
    ["The player in the driver's seat changed. Review the current driver and try again."] = "Error_DriverChanged",
    ["The current driver already shares ownership of this garage."] = "Error_DriverAlreadyOwner",
    ["Garage controls are only available while alive in the hideout."] = "Error_ControlsUnavailable",
    ["Vehicle swap started. The active vehicle is being returned before yours is deployed."] = "Message_SwapStarted",
    ["Your vehicle was deployed in the hideout garage."] = "Message_VehicleDeployed",
    ["Only the active vehicle's owner can return it."] = "Error_ReturnOwnerOnly",
    ["Returning your active vehicle to the garage."] = "Message_ReturningActiveVehicle",
    ["Wait for the current vehicle return or swap to finish before deleting a vehicle."] = "Error_DeleteDuringTransition",
    ["Return the active vehicle to the garage before deleting it."] = "Error_ReturnBeforeDelete",
    ["Vehicle names cannot be blank."] = "Error_BlankName",
    ["That vehicle is still completing its extraction transaction."] = "Error_ExtractionPending",
    ["Choose a different player."] = "Error_ChooseDifferentPlayer",
    ["That vehicle is already in the destination garage."] = "Error_AlreadyInDestinationGarage",
    ["The hideout vehicle bay could not be registered."] = "Error_BayRegistrationFailed",
    ["Project Zomboid could not register the indoor hideout vehicle bay."] = "Error_IndoorBayRegistrationFailed",
    ["Vehicle restoration failed."] = "Error_RestorationFailed",
    ["Vehicle restoration verification found missing or changed cargo."] = "Error_RestorationCargoChanged",
    ["The vehicle owner is unavailable for key delivery."] = "Error_KeyOwnerUnavailable",
    ["The vehicle owner has no available inventory."] = "Error_OwnerInventoryUnavailable",
    ["Project Zomboid could not create the replacement vehicle key."] = "Error_KeyCreationFailed",
    ["The replacement vehicle key could not be added to the owner's inventory."] = "Error_KeyDeliveryFailed",
    ["Vehicle reconstruction data is unavailable."] = "Error_ReconstructionDataUnavailable",
    ["The vehicle destination is not loaded."] = "Error_DestinationNotLoaded",
    ["Project Zomboid could not reconstruct the raid vehicle."] = "Error_ReconstructionFailed",
    ["The garage's player clearance tile is unavailable."] = "Error_ClearanceTileUnavailable",
    ["The garage player clearance tile is occupied."] = "Error_ClearanceTileOccupied",
    ["The vehicle is already being returned to its owner's garage."] = "Error_AlreadyReturning",
    ["The active vehicle is still loading and could not be identified safely. Wait a moment and try again."] = "Error_ActiveVehicleLoading",
    ["The active vehicle has no recoverable snapshot."] = "Error_NoRecoverableSnapshot",
    ["The current driver's garage identity is unavailable."] = "Error_DriverGarageUnavailable",
    ["That is not the active hideout vehicle."] = "Error_NotActiveVehicle",
    ["The raid source is no longer the active hideout vehicle."] = "Error_RaidSourceChanged",
    ["The raid source removal could not be queued."] = "Error_RaidSourceRemovalFailed",
}

local garageMessagePrefixes = {
    {
        english = "Vehicle storage was cancelled because its vehicle or cargo data could not be saved safely: ",
        key = "Error_StorageDataUnsafe",
    },
    {
        english = "Vehicle extraction was cancelled because its vehicle or cargo data could not be saved safely: ",
        key = "Error_ExtractionDataUnsafe",
    },
    {
        english = "Vehicle storage was cancelled to protect its ignition key: ",
        key = "Error_StorageKeyUnsafe",
    },
    {
        english = "The inactive vehicle was returned, but your vehicle could not be deployed: ",
        key = "Error_DeploymentAfterReturnFailed",
    },
    {
        english = "Vehicle swap was cancelled because the active vehicle could not be saved safely: ",
        key = "Error_SwapDataUnsafe",
    },
    {
        english = "Vehicle restoration verification failed: ",
        key = "Error_RestorationVerificationFailed",
    },
    {
        english = "vehicle cargo could not be captured safely: ",
        key = "Error_CargoCaptureFailed",
    },
}

local function translateGarageMessage(message)
    message = tostring(message or "")
    local key = garageMessageKeys[message]
    if key then return localized(key, message) end

    local savedVehicle = string.match(message, "^(.-) was saved to your personal garage%.$")
    if savedVehicle then
        return localized("Message_VehicleSavedAfterRaid", "%1 was saved to your personal garage.", savedVehicle)
    end
    local previousOwner, vehicleName = string.match(message,
        "^(.-) transferred ownership of (.-) to you%.$")
    if previousOwner and vehicleName then
        return localized("Message_TransferredToYou", "%1 transferred ownership of %2 to you.",
            previousOwner, vehicleName)
    end
    local transferredVehicle, driverName = string.match(message,
        "^Transferred (.-) to (.-)%.$")
    if transferredVehicle and driverName then
        return localized("Message_TransferredToDriver", "Transferred %1 to %2.",
            transferredVehicle, driverName)
    end
    local deletedVehicle = string.match(message,
        "^Deleted (.-) and all of its stored cargo%.$")
    if deletedVehicle then
        return localized("Message_VehicleDeleted", "Deleted %1 and all of its stored cargo.",
            deletedVehicle)
    end
    for _, prefix in ipairs(garageMessagePrefixes) do
        if string.sub(message, 1, #prefix.english) == prefix.english then
            local details = string.sub(message, #prefix.english + 1)
            return localized(prefix.key, prefix.english .. "%1", details)
        end
    end
    return message
end

local function localizeSelection(panel)
    local data = state()
    local record = panel:selectedRecord()
    local active = data.activeHideoutVehicle
    local transition = data.garageTransition
    local ownsActive = active ~= nil
        and tostring(active.owner or "") == tostring(data.garageOwner or "")
    local driverOwner = active and tostring(active.driverGarageOwner or "") or ""
    local driverName = active and tostring(active.driverUsername or "") or ""
    local driverIsDifferent = driverOwner ~= ""
        and driverOwner ~= tostring(data.garageOwner or "")

    panel.saveNameButton:setTitle(localized("Button_SaveName", "SAVE NAME"))
    panel.deleteButton:setTitle(localized("Button_Delete", "DELETE STORED VEHICLE"))
    panel.transferButton:setTitle(localized("Button_Transfer", "TRANSFER OWNERSHIP TO CURRENT DRIVER"))
    panel.storeButton:setTitle(localized("Button_Return", "RETURN ACTIVE VEHICLE"))

    panel.deleteButton:setTooltip((transition ~= nil or active ~= nil and active.storing == true)
        and localized("Tooltip_DeleteDuringTransition", "Wait for the current vehicle return or swap to finish before deleting a vehicle.")
        or record ~= nil and record.transactionPending == true
        and localized("Tooltip_ExtractionPending", "This vehicle is still completing its extraction transaction.")
        or record ~= nil
        and localized("Tooltip_DeleteSelected", "Permanently delete the selected stored vehicle and all cargo inside it. Active vehicles must be returned first.")
        or localized("Tooltip_DeleteSelect", "Select a stored vehicle to delete. Return an active vehicle before deleting that vehicle."))

    if active == nil then
        panel.transferButton:setTooltip(localized("Tooltip_TransferNoActive", "There is no active hideout vehicle to transfer."))
    elseif not ownsActive then
        panel.transferButton:setTooltip(localized("Tooltip_TransferOwnerOnly", "Only the active vehicle's owner can transfer it."))
    elseif active.storing == true then
        panel.transferButton:setTooltip(localized("Tooltip_TransferReturning", "The active vehicle is already being returned."))
    elseif active.raidReserved == true then
        panel.transferButton:setTooltip(localized("Tooltip_TransferReserved", "The active vehicle is reserved for raid deployment."))
    elseif driverOwner == "" then
        panel.transferButton:setTooltip(localized("Tooltip_TransferDriverRequired", "Another player must sit in the driver's seat before ownership can be transferred."))
    elseif not driverIsDifferent then
        panel.transferButton:setTooltip(localized("Tooltip_TransferSameOwner", "The current driver already shares your garage ownership."))
    else
        panel.transferButton:setTooltip(localized("Tooltip_TransferToDriver", "Transfer this active vehicle to current driver %1.",
            driverName ~= "" and driverName or driverOwner))
    end

    if active == nil then
        panel.deployButton:setTitle(transition ~= nil
            and localized("Button_Wait", "PLEASE WAIT")
            or localized("Button_Deploy", "SPAWN VEHICLE"))
        panel.deployButton:setTooltip(transition ~= nil
            and localized("Tooltip_DeployDuringTransition", "The previous active vehicle is still despawning. No vehicle can be deployed until the garage transition finishes.")
            or record ~= nil and record.transactionPending == true
            and localized("Tooltip_ExtractionPending", "This vehicle is still completing its extraction transaction.")
            or record ~= nil
            and localized("Tooltip_DeploySelected", "Deploy the selected vehicle into the hideout garage bay.")
            or localized("Tooltip_DeploySelect", "Select a stored vehicle to deploy."))
        panel.storeButton:setTooltip(localized("Tooltip_ReturnNoActive", "There is no active hideout vehicle to return."))
    else
        panel.deployButton:setTitle(localized("Button_Swap", "SWAP VEHICLE"))
        if record ~= nil and record.transactionPending == true then
            panel.deployButton:setTooltip(localized("Tooltip_ExtractionPending", "This vehicle is still completing its extraction transaction."))
        elseif record == nil then
            panel.deployButton:setTooltip(localized("Tooltip_SwapSelect", "Select one of your stored vehicles to swap in."))
        elseif active.storing == true then
            panel.deployButton:setTooltip(localized("Tooltip_SwapReturning", "The active vehicle is already being returned to its owner's garage."))
        elseif active.raidReserved == true then
            panel.deployButton:setTooltip(localized("Tooltip_SwapReserved", "The active vehicle is reserved for a raid deployment and cannot be swapped."))
        elseif not ownsActive and active.occupied == true then
            panel.deployButton:setTooltip(localized("Tooltip_SwapOccupied", "Another player's active vehicle is occupied and cannot be swapped."))
        elseif not ownsActive and active.inactive ~= true then
            panel.deployButton:setTooltip(localized("Tooltip_SwapInactivity", "Another player's vehicle can only be swapped after its inactivity timer expires."))
        else
            panel.deployButton:setTooltip(ownsActive
                and localized("Tooltip_SwapOwn", "Return your active vehicle and deploy the selected vehicle.")
                or localized("Tooltip_SwapOther", "Return the inactive vehicle to its owner and deploy your selected vehicle."))
        end

        if not ownsActive then
            panel.storeButton:setTooltip(localized("Tooltip_ReturnOwnerOnly", "Only the active vehicle's owner can return it manually."))
        elseif active.storing == true then
            panel.storeButton:setTooltip(localized("Tooltip_ReturnAlready", "Your active vehicle is already being returned."))
        elseif active.raidReserved == true then
            panel.storeButton:setTooltip(localized("Tooltip_ReturnReserved", "Your vehicle is reserved for raid deployment and cannot be returned."))
        else
            panel.storeButton:setTooltip(localized("Tooltip_Return", "Save the active vehicle and all current cargo back into your garage."))
        end
    end
end

local function renderGarage(panel)
    ISPanel.render(panel)
    panel:drawTextCentre(localized("Title", "PERSONAL GARAGE"), panel.width / 2, 10,
        0.96, 0.72, 0.18, 1, UIFont.Medium)
    panel:drawTextCentre(localized("Subtitle", "Stored vehicles are personal. Only one vehicle may be active in the hideout."),
        panel.width / 2, 34, 0.80, 0.80, 0.80, 1, UIFont.Small)

    local record = panel:selectedRecord()
    local active = state().activeHideoutVehicle
    local transition = state().garageTransition
    if active ~= nil then
        local status = active.raidReserved == true and localized("Status_Reserved", "Reserved for raid")
            or active.storing == true and localized("Status_Returning", "Returning to garage")
            or active.occupied == true and localized("Status_Occupied", "Occupied")
            or active.inactive == true and localized("Status_Inactive", "Inactive")
            or localized("Status_Active", "Active")
        panel:drawText(localized("ActiveSummary", "ACTIVE: %1 | Owner: %2 | %3",
            recordLabel(active), tostring(active.owner or localized("UnknownOwner", "Unknown")), status),
            16, 52, 0.72, 0.86, 1, 1, UIFont.Small)
    elseif transition ~= nil then
        panel:drawText(localized("Transition", "GARAGE: Completing vehicle return..."),
            16, 52, 0.96, 0.72, 0.18, 1, UIFont.Small)
    else
        panel:drawText(localized("NoActiveVehicle", "ACTIVE: None"),
            16, 52, 0.58, 0.58, 0.58, 1, UIFont.Small)
    end

    panel:drawText(localized("SavedVehicles", "SAVED VEHICLES"), 16, 73,
        0.96, 0.72, 0.18, 1, UIFont.Small)
    if record == nil then
        panel:drawTextCentre(localized("NoSavedVehicles", "No vehicles saved"), 541, 214,
            0.85, 0.85, 0.85, 1, UIFont.Medium)
        return
    end

    panel:drawText(localized("VehicleName", "VEHICLE NAME"), 318, 386,
        0.96, 0.72, 0.18, 1, UIFont.Small)
    panel:drawText(localized("Model", "Model: %1", modelLabel(record)),
        318, 448, 0.88, 0.88, 0.88, 1, UIFont.Small)
    local capacity = math.max(0, tonumber(record.fuelCapacity) or 0)
    local fuel = math.max(0, tonumber(record.fuel) or 0)
    local fuelText = capacity > 0
        and localized("FuelCapacity", "Fuel: %1 / %2 L", string.format("%.1f", fuel), string.format("%.1f", capacity))
        or localized("Fuel", "Fuel: %1 L", string.format("%.1f", fuel))
    panel:drawText(fuelText, 318, 469, 0.88, 0.88, 0.88, 1, UIFont.Small)
    local batteryText = record.batteryPresent == true
        and localized("Battery", "Battery: %1%%", string.format("%.1f", math.max(0, tonumber(record.batteryCharge) or 0)))
        or localized("NoBattery", "Battery: No Battery")
    panel:drawText(batteryText, 530, 448, 0.88, 0.88, 0.88, 1, UIFont.Small)
    panel:drawText(localized("EngineCondition", "Engine condition: %1%%",
        tostring(math.floor(tonumber(record.engineCondition) or 0))),
        530, 469, 0.88, 0.88, 0.88, 1, UIFont.Small)
end

local function patchGaragePanel()
    local Panel = ExtractionMode.GaragePanel
    if Panel == nil or Panel.ExtractionModeRussianLanguagePatched then return end

    local previousCreateChildren = Panel.createChildren
    Panel.createChildren = function(self, ...)
        previousCreateChildren(self, ...)
        if not isRussianLanguage() then return end
        self.deployButton:setWidth(446)
        self.storeButton:setX(318)
        self.storeButton:setY(534)
        self.storeButton:setWidth(446)
        self.deleteButton:setY(574)
        self.transferButton:setY(614)
        self.closeButton:setTitle(localized("Button_Close", "CLOSE"))
        localizeSelection(self)
    end

    local previousRefreshSelection = Panel.refreshSelection
    Panel.refreshSelection = function(self, ...)
        previousRefreshSelection(self, ...)
        if isRussianLanguage() then localizeSelection(self) end
    end

    local previousRender = Panel.render
    Panel.render = function(self, ...)
        if isRussianLanguage() then
            renderGarage(self)
        else
            previousRender(self, ...)
        end
    end

    local previousTransfer = Panel.onTransferToDriver
    Panel.onTransferToDriver = function(self, ...)
        if not isRussianLanguage() then return previousTransfer(self, ...) end
        local active = state().activeHideoutVehicle
        if active == nil or tostring(active.driverUsername or "") == "" then return end
        local message = localized("ConfirmTransfer",
            "Transfer ownership of '%1' to current driver %2?\nThey will become the active owner, and the vehicle will return to their personal garage when stored.",
            tostring(active.name or active.scriptName or localized("Vehicle", "Vehicle")),
            tostring(active.driverUsername))
        local modal = ISModalDialog:new(0, 0, 600, 180, message, true,
            self, Panel.onTransferConfirmed, nil, active.driverUsername)
        modal:initialise()
        modal:setCapture(true)
        modal:setAlwaysOnTop(true)
        modal:addToUIManager()
    end

    local previousDelete = Panel.onDelete
    Panel.onDelete = function(self, ...)
        if not isRussianLanguage() then return previousDelete(self, ...) end
        local record = self:selectedRecord()
        if record == nil then return end
        local message = localized("ConfirmDelete",
            "Delete '%1' from your garage?\nThis is irreversible. The vehicle and every item stored inside it will be permanently deleted.",
            recordLabel(record))
        local modal = ISModalDialog:new(0, 0, 570, 170, message, true,
            self, Panel.onDeleteConfirmed, nil, record.id)
        modal:initialise()
        modal:setCapture(true)
        modal:setAlwaysOnTop(true)
        modal:addToUIManager()
    end

    Panel.ExtractionModeRussianLanguagePatched = true
end

local function patchRawGarageMessages()
    local Localization = ExtractionMode.Localization
    if Localization == nil or Localization.ExtractionModeRussianLanguageGaragePatched then return end

    local previousResolveMessage = Localization.resolveMessage
    Localization.resolveMessage = function(payload)
        local message = previousResolveMessage(payload)
        if isRussianLanguage() then return translateGarageMessage(message) end
        return message
    end

    Localization.ExtractionModeRussianLanguageGaragePatched = true
end

local function localizeGarageContextTooltip(playerNum, context)
    if not isRussianLanguage() or context == nil then return end
    local expectedName = ExtractionMode.Localization.get(
        "ContextMenu_ExtractionMode_GarageControls", "Garage Controls...")
    for _, option in ipairs(context.options or {}) do
        if tostring(option.name or "") == expectedName then
            option.toolTip = option.toolTip or ISToolTip:new()
            local player = getSpecificPlayer and getSpecificPlayer(playerNum) or nil
            local onControlTile = player ~= nil and option.notAvailable ~= true
                and option.toolTip.description == "Open the garage controls."
            option.toolTip.description = onControlTile
                and localized("Tooltip_OpenControls", "Open the garage controls.")
                or localized("Tooltip_ApproachControls", "Approach the highlighted tile and use the garage controls.")
        end
    end
end

patchGaragePanel()
patchRawGarageMessages()
Events.OnFillWorldObjectContextMenu.Add(localizeGarageContextTooltip)
