MapEditor = {
    active = false,
    radius = 500.0,
    center = nil,
    currentPreview = nil,
    currentModelName = "",
    currentIsObjective = false,
    placedObjects = {},
    objectives = {},
    spawns = {},
    placedModels = {},
    objectiveMarkers = {},
    objectiveIndex = 0,
    currentBasePos = vector3(0, 0, 0),
    isVerticalMode = false,
    currentVerticalOffset = 0.0,
    lastMouseY = 0,
    pickedUpIndex = nil,
    _isPickedUp = false,
    _pendingObjType = nil,
    _editingObjIdx = nil,
    _isEditingSpawn = false,
    _editingSpawnSide = nil,
}

CinematicMode = {
    active = false,
    cam = nil,
    speed = 0.5,
    rotSpeed = 2.5,
    fov = 50.0,
    oldPos = nil,
    oldPitch = nil,
    oldHeading = nil,
    oldHeight = nil,
}

RegisterCommand('buildmap', function(source, args)
    if MapEditor.active then
        print("^1[RTS MapBuilder] Editor is already active.^7")
        return
    end

    local centerX = tonumber(args[1]) or 0
    local centerY = tonumber(args[2]) or 0
    local centerZ = tonumber(args[3]) or 0
    local radius = tonumber(args[4]) or 500.0

    MapEditor.center = vector3(centerX, centerY, centerZ)
    MapEditor.radius = radius
    MapEditor.placedObjects = {}
    MapEditor.placedModels = {}
    MapEditor.currentPreview = nil
    MapEditor.currentModelName = ""

    InitBuilderCam(MapEditor.center)
    Wait(100)
    MapEditor.active = true

    SetNuiFocusKeepInput(false)
    SetNuiFocus(true, true)
    DisplayHud(false)
    DisplayRadar(false)

    SendNUIMessage({ action = 'builderShow' })
    SendBuilderInfo()
    SendNUIMessage({ action = 'builderCatalog', catalog = BuilderCatalog })

    print(string.format("^2[RTS MapBuilder] Editor started at %.1f, %.1f, %.1f (radius: %.0f)^7",
        centerX, centerY, centerZ, radius))
end, false)

function SendBuilderInfo()
    SendNUIMessage({
        action = 'builderInfo',
        modelName = MapEditor.currentModelName or '',
        count = #MapEditor.placedObjects
    })
end

RegisterCommand('editmap', function()
    if MapEditor.active then
        print("^1[RTS MapBuilder] Editor tools are already active.^7")
        return
    end
    MapEditor.active = true
    print("^2[RTS MapBuilder] Editor tools re-enabled.^7")
end, false)

RegisterCommand('spawn', function(source, args)
    if not MapEditor.active then
        print("^1[RTS MapBuilder] Start the editor with /buildmap first.^7")
        return
    end
    local modelName = args[1]
    if not modelName then
        print("^1[RTS MapBuilder] Usage: /spawn [modelName]^7")
        return
    end

    if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
        DeleteEntity(MapEditor.currentPreview)
    end

    local modelHash = GetHashKey(modelName)
    RequestModel(modelHash)
    local t = 0
    while not HasModelLoaded(modelHash) and t < 500 do Wait(10); t = t + 1 end

    if not HasModelLoaded(modelHash) then
        print("^1[RTS MapBuilder] Failed to load model: " .. modelName .. "^7")
        return
    end

    local camPos = GetCamCoord(1337)
    local entity
    if IsModelAVehicle(modelHash) then
        entity = CreateVehicle(modelHash, camPos.x, camPos.y, camPos.z, 0.0, true, true)
    else
        entity = CreateObject(modelHash, camPos.x, camPos.y, camPos.z, true, true, false)
    end

    SetEntityAsMissionEntity(entity, true, true)
    SetEntityInvincible(entity, true)
    FreezeEntityPosition(entity, true)

    MapEditor.currentPreview = entity
    MapEditor.currentModelName = modelName
    SendBuilderInfo()
    print("^2[RTS MapBuilder] Spawned: " .. modelName .. "^7")
end, false)

RegisterCommand('removelast', function()
    if not MapEditor.active then return end
    if #MapEditor.placedObjects > 0 then
        local obj = table.remove(MapEditor.placedObjects)
        if DoesEntityExist(obj) then DeleteEntity(obj) end
        SendBuilderInfo()
        print("^3[RTS MapBuilder] Removed last object. Remaining: " .. #MapEditor.placedObjects .. "^7")
    end
end, false)

RegisterCommand('clearmap', function()
    if not MapEditor.active then return end
    for _, obj in ipairs(MapEditor.placedObjects) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    MapEditor.placedObjects = {}
    MapEditor.placedModels = {}
    MapEditor.objectives = {}
    MapEditor.objectiveIndex = 0
    MapEditor.spawns = {}
    for _, m in pairs(MapEditor.objectiveMarkers) do if DoesEntityExist(m) then DeleteEntity(m) end end
    MapEditor.objectiveMarkers = {}
    if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
        DeleteEntity(MapEditor.currentPreview)
        MapEditor.currentPreview = nil
        MapEditor.currentModelName = ""
    end
    MapEditor.currentIsObjective = false
    MapEditor._isPickedUp = false
    SendBuilderInfo()
    print("^2[RTS MapBuilder] All objects cleared.^7")
end, false)

RegisterCommand('rts_breakglass', function()
    if not MapEditor.active then return end
    MapEditor.active = false
    SendNUIMessage({ type = 'drawMarkers', markers = {} })
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(true)
    CinematicMode.active = false
    if CinematicMode.cam then DestroyCam(CinematicMode.cam, false); CinematicMode.cam = nil end
    RenderScriptCams(false, true, 500, true, true)
    SendNUIMessage({ action = 'builderHide' })
    DisplayHud(true)
    DisplayRadar(true)
    for _, obj in ipairs(MapEditor.placedObjects) do if DoesEntityExist(obj) then DeleteEntity(obj) end end
    MapEditor.placedObjects = {}
    MapEditor.placedModels = {}
    if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
        DeleteEntity(MapEditor.currentPreview); MapEditor.currentPreview = nil
    end
    local ped = PlayerPedId()
    SetEntityCoords(ped, 0, 0, 1000); SetEntityVisible(ped, false); FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    TriggerServerEvent('rts-admin:togglePanel')
    print("^2[RTS MapBuilder] Builder exited - returned to admin panel.^7")
end, false)

RegisterNUICallback('exportMap', function(_, cb)
    print("^2[RTS MapBuilder] ========== MAP DATA ==========^7")
    print("Config.Maps = {")
    print('    ["builder_map"] = {')
    print('        id = 99,')
    print('        name = "Builder Map",')
    print('        description = "Custom map built with RTS Map Builder.",')
    print('        thumbnail = "custom.png",')
    print("")
    print("        music = \"main_theme.mp3\",")
    print("        time = { h = 14, m = 30 },")
    print("        weather = 'CLEAR',")
    print("")
    print(string.format("        center = vector3(%.2f, %.2f, %.2f),", MapEditor.center.x, MapEditor.center.y, MapEditor.center.z))
    print("        range = " .. MapEditor.radius .. ",")
    print("")
    print("        spawns = {")
    if MapEditor.spawns and MapEditor.spawns.team1 then
        print(string.format("            team1 = { x = %.2f, y = %.2f, z = %.2f, h = 0.0 },", MapEditor.spawns.team1.x, MapEditor.spawns.team1.y, MapEditor.spawns.team1.z))
    else
        print(string.format("            team1 = { x = %.2f, y = %.2f, z = %.2f, h = 0.0 },", MapEditor.center.x + 50, MapEditor.center.y, MapEditor.center.z))
    end
    if MapEditor.spawns and MapEditor.spawns.team2 then
        print(string.format("            team2 = { x = %.2f, y = %.2f, z = %.2f, h = 180.0 },", MapEditor.spawns.team2.x, MapEditor.spawns.team2.y, MapEditor.spawns.team2.z))
    else
        print(string.format("            team2 = { x = %.2f, y = %.2f, z = %.2f, h = 180.0 },", MapEditor.center.x - 50, MapEditor.center.y, MapEditor.center.z))
    end
    print("        },")
    print("        waterSpawns = {")
    if MapEditor.spawns and MapEditor.spawns.team1 then
        print(string.format("            team1 = { x = %.2f, y = %.2f, z = %.2f, h = 0.0 },", MapEditor.spawns.team1.x, MapEditor.spawns.team1.y, MapEditor.spawns.team1.z))
    else
        print(string.format("            team1 = { x = %.2f, y = %.2f, z = %.2f, h = 0.0 },", MapEditor.center.x + 50, MapEditor.center.y, MapEditor.center.z))
    end
    if MapEditor.spawns and MapEditor.spawns.team2 then
        print(string.format("            team2 = { x = %.2f, y = %.2f, z = %.2f, h = 180.0 },", MapEditor.spawns.team2.x, MapEditor.spawns.team2.y, MapEditor.spawns.team2.z))
    else
        print(string.format("            team2 = { x = %.2f, y = %.2f, z = %.2f, h = 180.0 },", MapEditor.center.x - 50, MapEditor.center.y, MapEditor.center.z))
    end
    print("        },")
    print("")

    if next(MapEditor.objectives) then
        print("        objectives = {")
        for _, obj in pairs(MapEditor.objectives) do
            local bonus = (obj.type == 'resource') and string.format(", bonus = %.1f", obj.bonus or 1.2) or ""
            print(string.format("            { name = \"%s\", type = \"%s\", x = %.2f, y = %.2f, z = %.2f, radius = %.1f, captureRate = %.1f%s },",
                obj.name, obj.type, obj.x, obj.y, obj.z, obj.radius or 20, obj.captureRate or 1.5, bonus))
        end
        print("        },")
        print("")
    end

    print("        decorativeObjects = {")
    for i, obj in ipairs(MapEditor.placedObjects) do
        if DoesEntityExist(obj) then
            local coords = GetEntityCoords(obj)
            local heading = GetEntityHeading(obj)
            local modelName = MapEditor.placedModels[obj] or tostring(GetEntityModel(obj))
            print(string.format("            { model = \"%s\", x = %.2f, y = %.2f, z = %.2f, h = %.2f },", modelName, coords.x, coords.y, coords.z, heading))
        end
    end
    print("        },")
    print("    }")
    print("}")
    print("^2[RTS MapBuilder] =================================^7")
    SendNUIMessage({action='builderInfo', modelName=MapEditor.currentModelName or '', count=#MapEditor.placedObjects, toast='Map exported to F8 console'})
    cb({})
end)

RegisterNUICallback('exitBuilder', function(_, cb)
    ExecuteCommand('rts_breakglass')
    cb({})
end)

RegisterNUICallback('toggleAdmin', function(_, cb)
    TriggerServerEvent('rts-admin:togglePanel')
    cb({})
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if MapEditor.active then
        MapEditor.active = false
        SendNUIMessage({ action = 'builderHide' })
        Wait(100)
        RenderScriptCams(false, true, 500, true, true)
        DisplayHud(true)
        DisplayRadar(true)
        for _, obj in ipairs(MapEditor.placedObjects) do if DoesEntityExist(obj) then DeleteEntity(obj) end end
        if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then DeleteEntity(MapEditor.currentPreview) end
        local ped = PlayerPedId()
        SetEntityCoords(ped, 0, 0, 1000); SetEntityVisible(ped, false); FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        Wait(500)
        TriggerEvent('rts-admin:openPanel')
        print("^2[RTS MapBuilder] Builder exited.^7")
    end
end)

RegisterNetEvent('rts-mapbuilder:loadMapData')
AddEventHandler('rts-mapbuilder:loadMapData', function(map)
    print("^3[RTS MapBuilder] loadMapData received, active=" .. tostring(MapEditor.active) .. "^7")
    if not MapEditor.active then print("^1[RTS MapBuilder] Map not active, cannot load.^7"); return end
    if map.decorativeObjects then
        for _, obj in ipairs(map.decorativeObjects) do
            local hash = tonumber(obj.model) or GetHashKey(obj.model)
            RequestModel(hash)
            local t = 0; while not HasModelLoaded(hash) and t < 300 do Wait(10); t = t + 1 end
            if HasModelLoaded(hash) then
                local entity
                if IsModelAVehicle(hash) then
                    entity = CreateVehicle(hash, obj.x, obj.y, obj.z, obj.h or 0.0, true, true)
                else
                    entity = CreateObject(hash, obj.x, obj.y, obj.z, true, true, false)
                end
                FreezeEntityPosition(entity, true)
                SetEntityInvincible(entity, true)
                SetEntityAsMissionEntity(entity, true, true)
                table.insert(MapEditor.placedObjects, entity)
                MapEditor.placedModels[entity] = obj.model
            end
        end
    end
    if map.objectives then
        for _, obj in ipairs(map.objectives) do
            MapEditor.objectiveIndex = MapEditor.objectiveIndex + 1
            MapEditor.objectives[MapEditor.objectiveIndex] = {
                name = obj.name, type = obj.type,
                x = obj.x, y = obj.y, z = obj.z,
                radius = obj.radius or 20,
                captureRate = obj.captureRate or 1.5,
                bonus = obj.bonus,
            }
        end
    end
    if map.spawns then
        MapEditor.spawns = map.spawns
    end
    SendBuilderInfo()
    print("^2[RTS MapBuilder] Map loaded: " .. #MapEditor.placedObjects .. " objects, " .. MapEditor.objectiveIndex .. " objectives.^7")
end)