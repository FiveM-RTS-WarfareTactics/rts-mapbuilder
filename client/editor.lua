RegisterNUICallback('editorAction', function(data, cb)
    if not MapEditor.active then cb({ success = false }) return end
    HandleEditorAction(data.action, data.data)
    cb({ success = true })
end)

function HandleEditorAction(action, actionData)
    if action == 'CLICK_LEFT' then
        
        if MapEditor._isPickedUp and MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
            FreezeEntityPosition(MapEditor.currentPreview, true)
            SetEntityCollision(MapEditor.currentPreview, true, true)
            SetEntityAlpha(MapEditor.currentPreview, 255, false)
            table.insert(MapEditor.placedObjects, MapEditor.currentPreview)
            MapEditor.placedModels[MapEditor.currentPreview] = MapEditor.currentModelName or 'unknown'
            MapEditor.currentPreview = nil
            MapEditor.currentModelName = ""
            MapEditor._isPickedUp = false
            SendBuilderInfo()

        elseif MapEditor.pickedUpIndex then
            MapEditor.pickedUpIndex = nil
            MapEditor.isVerticalMode = false
            MapEditor.currentVerticalOffset = 0.0

        elseif MapEditor.currentIsObjective then
            local mx, my = GetNuiCursorPosition()
            local sw, sh = GetActiveScreenResolution()
            local worldPos = GetWorldCoordFromScreen(mx / sw, my / sh)
            if worldPos then
                if MapEditor._editingObjIdx and MapEditor.objectives[MapEditor._editingObjIdx] then
                    local editingIdx = MapEditor._editingObjIdx
                    local obj = MapEditor.objectives[editingIdx]
                    obj.x, obj.y, obj.z = worldPos.x, worldPos.y, worldPos.z
                    MapEditor.currentIsObjective = false
                    MapEditor._editingObjIdx = nil
                    SendNUIMessage({action='builderInfo', modelName='', count=#MapEditor.placedObjects, objIdx=editingIdx, objData=obj})
                else
                    
                    MapEditor.objectiveIndex = MapEditor.objectiveIndex + 1
                    MapEditor.objectives[MapEditor.objectiveIndex] = {
                        name = (MapEditor._pendingObjType == 'victory') and 'Victory Point' or 'Resource Point',
                        type = MapEditor._pendingObjType or 'resource',
                        x = worldPos.x, y = worldPos.y, z = worldPos.z,
                        radius = 20.0,
                        captureRate = (MapEditor._pendingObjType == 'victory') and 0.5 or 1.5,
                        bonus = (MapEditor._pendingObjType == 'resource') and 1.2 or nil,
                    }
                    MapEditor.currentIsObjective = false
                    SendNUIMessage({action='builderInfo', modelName='', count=#MapEditor.placedObjects, objIdx=MapEditor.objectiveIndex, objData=MapEditor.objectives[MapEditor.objectiveIndex]})
                end
            end

        elseif MapEditor._isEditingSpawn and MapEditor._editingSpawnSide then
            local mx, my = GetNuiCursorPosition()
            local sw, sh = GetActiveScreenResolution()
            local worldPos = GetWorldCoordFromScreen(mx / sw, my / sh)
            if worldPos then
                MapEditor.spawns = MapEditor.spawns or {}
                MapEditor.spawns[MapEditor._editingSpawnSide] = {x=worldPos.x, y=worldPos.y, z=worldPos.z, h=0.0}
                MapEditor._isEditingSpawn = false
                MapEditor._editingSpawnSide = nil
            end

        elseif MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
            local obj = CloneEntity(MapEditor.currentPreview)
            SetEntityCollision(obj, true, true)
            table.insert(MapEditor.placedObjects, obj)
            MapEditor.placedModels[obj] = MapEditor.currentModelName or 'unknown'
            SendBuilderInfo()
        end

    elseif action == 'CLICK_RIGHT' then
        
        if MapEditor._isPickedUp and MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
            FreezeEntityPosition(MapEditor.currentPreview, true)
            SetEntityCollision(MapEditor.currentPreview, true, true)
            SetEntityAlpha(MapEditor.currentPreview, 255, false)
            table.insert(MapEditor.placedObjects, MapEditor.currentPreview)
            MapEditor.placedModels[MapEditor.currentPreview] = MapEditor.currentModelName or 'unknown'
            MapEditor.currentPreview = nil
            MapEditor.currentModelName = ""
            MapEditor._isPickedUp = false
            SendBuilderInfo()
        end
        
        MapEditor.currentIsObjective = false
        MapEditor._editingObjIdx = nil
        MapEditor._isEditingSpawn = false
        MapEditor._editingSpawnSide = nil
        
        if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
            DeleteEntity(MapEditor.currentPreview)
            MapEditor.currentPreview = nil
            MapEditor.currentModelName = ""
            SendBuilderInfo()
        end

    elseif action == 'PICKUP' then
        local hitEntity, idx = GetEntityAtCursor()
        if hitEntity and idx then
            
            if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
                DeleteEntity(MapEditor.currentPreview)
            end
            MapEditor.currentPreview = table.remove(MapEditor.placedObjects, idx)
            FreezeEntityPosition(MapEditor.currentPreview, false)
            SetEntityCollision(MapEditor.currentPreview, false, false)
            SetEntityAlpha(MapEditor.currentPreview, 180, false)
            MapEditor.currentModelName = MapEditor.placedModels[MapEditor.currentPreview] or 'Object'
            MapEditor._isPickedUp = true
            MapEditor.currentVerticalOffset = 0.0
            MapEditor.currentBasePos = GetEntityCoords(MapEditor.currentPreview)
            MapEditor.currentIsObjective = false
            MapEditor._editingObjIdx = nil
            MapEditor._isEditingSpawn = false
            SendBuilderInfo()
        else
            
            local mx, my = GetNuiCursorPosition()
            local sw, sh = GetActiveScreenResolution()
            local wp = GetWorldCoordFromScreen(mx / sw, my / sh)
            if wp then
                local nearest, nearestDist = nil, 5.0
                for k, obj in pairs(MapEditor.objectives or {}) do
                    local d = #(wp - vector3(obj.x, obj.y, obj.z))
                    if d < nearestDist then nearest, nearestDist = k, d end
                end
                if nearest then
                    MapEditor._editingObjIdx = nearest
                    MapEditor._pendingObjType = MapEditor.objectives[nearest].type
                    MapEditor.currentIsObjective = true
                    MapEditor._isEditingSpawn = false
                    if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then DeleteEntity(MapEditor.currentPreview); MapEditor.currentPreview = nil end
                    return
                end
                
                for side, pos in pairs(MapEditor.spawns or {}) do
                    local d = #(wp - vector3(pos.x, pos.y, pos.z))
                    if d < 5.0 then
                        MapEditor._editingSpawnSide = side
                        MapEditor._isEditingSpawn = true
                        MapEditor.currentIsObjective = false
                        if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then DeleteEntity(MapEditor.currentPreview); MapEditor.currentPreview = nil end
                        return
                    end
                end
            end
        end

    elseif action == 'CLONE' then
        local hitEntity, idx = GetEntityAtCursor()
        if hitEntity and idx then
            
            if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
                DeleteEntity(MapEditor.currentPreview)
            end
            local clone = CloneEntity(hitEntity)
            SetEntityCollision(clone, false, false)
            SetEntityAlpha(clone, 180, false)
            FreezeEntityPosition(clone, false)
            MapEditor.currentPreview = clone
            MapEditor.currentModelName = MapEditor.placedModels[hitEntity] or 'clone'
            MapEditor._isPickedUp = false
            MapEditor.currentVerticalOffset = 0.0
            MapEditor.currentBasePos = GetEntityCoords(clone)
            SendBuilderInfo()
        end

    elseif action == 'DELETE' then
        
        if MapEditor._editingObjIdx and MapEditor.objectives[MapEditor._editingObjIdx] then
            MapEditor.objectives[MapEditor._editingObjIdx] = nil
            MapEditor.currentIsObjective = false
            MapEditor._editingObjIdx = nil
            return
        end
        
        if MapEditor._isEditingSpawn and MapEditor._editingSpawnSide and MapEditor.spawns then
            MapEditor.spawns[MapEditor._editingSpawnSide] = nil
            MapEditor._isEditingSpawn = false
            MapEditor._editingSpawnSide = nil
            return
        end
        
        if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
            MapEditor.placedModels[MapEditor.currentPreview] = nil
            DeleteEntity(MapEditor.currentPreview)
            MapEditor.currentPreview = nil
            MapEditor.currentModelName = ""
            MapEditor._isPickedUp = false
            SendBuilderInfo()
            return
        end
        
        local hitEntity, idx = GetEntityAtCursor()
        if hitEntity and idx then
            DeleteEntity(hitEntity)
            MapEditor.placedModels[hitEntity] = nil
            table.remove(MapEditor.placedObjects, idx)
            SendBuilderInfo()
        end

    elseif action == 'ROTATE_LEFT' then
        local target = MapEditor.currentPreview
        if MapEditor.pickedUpIndex then target = MapEditor.placedObjects[MapEditor.pickedUpIndex] end
        if target and DoesEntityExist(target) then
            SetEntityHeading(target, GetEntityHeading(target) + 5.0)
        end

    elseif action == 'ROTATE_RIGHT' then
        local target = MapEditor.currentPreview
        if MapEditor.pickedUpIndex then target = MapEditor.placedObjects[MapEditor.pickedUpIndex] end
        if target and DoesEntityExist(target) then
            SetEntityHeading(target, GetEntityHeading(target) - 5.0)
        end

    elseif action == 'SHIFT_DOWN' then
        MapEditor.isVerticalMode = true
        if MapEditor.currentBasePos then
            MapEditor._savedBasePos = vector3(MapEditor.currentBasePos.x, MapEditor.currentBasePos.y, MapEditor.currentBasePos.z)
        end

    elseif action == 'SHIFT_UP' then
        MapEditor.isVerticalMode = false
        if MapEditor._savedBasePos then
            MapEditor.currentBasePos = MapEditor._savedBasePos
        end

    elseif action == 'ZOOM_IN' then
        BuilderCamZoom(-10)

    elseif action == 'ZOOM_OUT' then
        BuilderCamZoom(10)

    elseif action == 'RESET_HEIGHT' then
        if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
            local coords = GetEntityCoords(MapEditor.currentPreview)
            local _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, 1000.0, false)
            MapEditor.currentVerticalOffset = 0.0
            MapEditor.currentBasePos = vector3(coords.x, coords.y, groundZ)
        end

    elseif action == 'EXIT' then
        MapEditor.active = false
        SendNUIMessage({ type = 'drawMarkers', markers = {} })
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(true)
        RenderScriptCams(false, true, 500, true, true)
        SendNUIMessage({ action = 'builderHide' })
        Wait(100)
        DisplayHud(true)
        DisplayRadar(true)
        for _, obj in ipairs(MapEditor.placedObjects) do if DoesEntityExist(obj) then DeleteEntity(obj) end end
        MapEditor.placedObjects = {}
        MapEditor.placedModels = {}
        if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then DeleteEntity(MapEditor.currentPreview); MapEditor.currentPreview = nil end
        local ped = PlayerPedId()
        SetEntityCoords(ped, 0, 0, 1000); SetEntityVisible(ped, false); FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        TriggerEvent('rts-admin:openPanel')
        print("^2[RTS MapBuilder] Builder exited.^7")

    elseif action == 'CLEAR_ALL' then
        for _, obj in ipairs(MapEditor.placedObjects) do
            if DoesEntityExist(obj) then DeleteEntity(obj); MapEditor.placedModels[obj] = nil end
        end
        MapEditor.placedObjects = {}
        MapEditor.placedModels = {}
        MapEditor.objectives = {}
        MapEditor.objectiveIndex = 0
        MapEditor.spawns = {}
        if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
            DeleteEntity(MapEditor.currentPreview)
            MapEditor.currentPreview = nil
            MapEditor.currentModelName = ""
        end
        MapEditor.pickedUpIndex = nil
        MapEditor.currentIsObjective = false
        MapEditor.isVerticalMode = false
        MapEditor.currentVerticalOffset = 0.0
        SendBuilderInfo()
        print("^2[RTS MapBuilder] All cleared.^7")

    elseif action == 'SPAWN_MODEL' then
        local modelName = actionData and actionData.model
        if not modelName then return end

        if string.sub(modelName, 1, 4) == 'obj_' then
            MapEditor._pendingObjType = string.find(modelName, 'victory') and 'victory' or 'resource'
            MapEditor.currentIsObjective = true
            MapEditor.currentModelName = modelName
            if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
                DeleteEntity(MapEditor.currentPreview)
                MapEditor.currentPreview = nil
            end
            SendBuilderInfo()
            print("^2[RTS MapBuilder] Objective mode: " .. modelName .. " (LMB to place)^7")
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
        SetEntityCollision(entity, false, false)
        SetEntityAlpha(entity, 180, false)

        MapEditor.currentPreview = entity
        MapEditor.currentModelName = modelName
        MapEditor.currentIsObjective = false
        MapEditor.pickedUpIndex = nil
        MapEditor.currentVerticalOffset = 0.0
        SendBuilderInfo()
        print("^2[RTS MapBuilder] Spawned: " .. modelName .. "^7")

    elseif action == 'UPDATE_OBJ' then
        local idx = actionData and actionData.idx
        if idx and MapEditor.objectives[idx] then
            local obj = MapEditor.objectives[idx]
            print("^3[RTS MapBuilder] UPDATE_OBJ: idx=" .. tostring(idx) .. " radius=" .. tostring(actionData.radius) .. " old=" .. tostring(obj.radius))
            obj.name = actionData.name or obj.name
            obj.type = actionData.type or obj.type
            obj.radius = tonumber(actionData.radius) or obj.radius
            obj.captureRate = tonumber(actionData.captureRate) or obj.captureRate
            obj.bonus = tonumber(actionData.bonus) or obj.bonus
            print("^3[RTS MapBuilder] After update: radius=" .. tostring(obj.radius) .. " name=" .. obj.name)
            SendNUIMessage({action='builderInfo', modelName='', count=#MapEditor.placedObjects, objIdx=idx, objData=obj})
        else
            print("^1[RTS MapBuilder] UPDATE_OBJ failed: idx=" .. tostring(idx) .. " found=" .. tostring(MapEditor.objectives[idx] ~= nil) .. "^7")
        end

    elseif action == 'PLACE_SPAWN' then
        local side = actionData and actionData.side or 'team1'
        MapEditor._isEditingSpawn = true
        MapEditor._editingSpawnSide = side
        MapEditor.currentIsObjective = false
        MapEditor._isPickedUp = false
        if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
            DeleteEntity(MapEditor.currentPreview)
            MapEditor.currentPreview = nil
        end
        print("^2[RTS MapBuilder] Spawn mode: " .. side .. " (LMB to place)^7")
    end
end

function GetEntityAtCursor()
    local mx, my = GetNuiCursorPosition()
    local sw, sh = GetActiveScreenResolution()
    local camPos = GetGameplayCamCoord()
    local worldPos = GetWorldCoordFromScreenCoord(mx / sw, my / sh)
    if not worldPos then return nil end
    local dir = worldPos - camPos
    local rayDir = dir / #(dir)
    local endPoint = camPos + (rayDir * 500.0)
    local ray = StartShapeTestRay(camPos.x, camPos.y, camPos.z, endPoint.x, endPoint.y, endPoint.z, -1, PlayerPedId(), 0)
    local _, hit, _, _, hitEntity = GetShapeTestResult(ray)
    if hit == 1 and hitEntity then
        for i = #MapEditor.placedObjects, 1, -1 do
            if MapEditor.placedObjects[i] == hitEntity then return hitEntity, i end
        end
    end
    return nil, nil
end

CreateThread(function()
    local frameSkip = 0
    while true do
        Wait(0)
        frameSkip = frameSkip + 1
        if MapEditor.active then
            UpdateBuilderCam(MapEditor.center, MapEditor.radius)

            local mx, my = GetNuiCursorPosition()
            local sw, sh = GetActiveScreenResolution()
            local worldPos = GetWorldCoordFromScreen(mx / sw, my / sh)

            local markers = {}

            local function AddMarker(wx, wy, wz, id, icon, label, color)
                if wx and wy and wz then
                    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(wx, wy, wz)
                    if onScreen then table.insert(markers, {id=id, x=sx, y=sy, icon=icon, label=label, color=color or "#e8a838"}) end
                end
            end

            if MapEditor.currentIsObjective and worldPos then
                
                if not MapEditor._editingObjIdx then
                    local colR, colG, colB = 50, 180, 255
                    local r = 20.0
                    if MapEditor._pendingObjType == 'victory' then colR, colG, colB = 255, 80, 50 end
                    DrawMarker(1, worldPos.x, worldPos.y, worldPos.z + 0.2, 0,0,0, 0,0,0, r * 2.0, r * 2.0, 3.0, colR,colG,colB, 150, false, false, 2, false, nil, nil, false)

                    local c = MapEditor._pendingObjType == 'victory' and '#ff5032' or '#32b4ff'
                    local ic = MapEditor._pendingObjType == 'victory' and '\xF0\x9F\x8E\xAF' or '\xE2\x8F\x9B'
                    AddMarker(worldPos.x, worldPos.y, worldPos.z + 2.5, 'obj_preview', ic, 'LMB to Place', c)
                end
            end

            if MapEditor.currentPreview and DoesEntityExist(MapEditor.currentPreview) then
                if not MapEditor.isVerticalMode then
                    MapEditor.currentBasePos = vector3(worldPos.x, worldPos.y, worldPos.z)
                else
                    local deltaY = (MapEditor.lastMouseY - my) * 0.1
                    MapEditor.currentVerticalOffset = (MapEditor.currentVerticalOffset or 0.0) + deltaY
                end
                MapEditor.lastMouseY = my
                local offset = MapEditor.currentVerticalOffset or 0.0
                local base = MapEditor.currentBasePos or worldPos
                local finalPos = vector3(base.x, base.y, base.z + offset)
                SetEntityCoordsNoOffset(MapEditor.currentPreview, finalPos.x, finalPos.y, finalPos.z, false, false, false, true)

                local pLabel = MapEditor.currentModelName or 'Object'
                local pColor = '#ffffff'
                if MapEditor._isPickedUp then pLabel = '\xE2\x86\x94 ' .. pLabel; pColor = '#ffff00' end
                AddMarker(finalPos.x, finalPos.y, finalPos.z + 1.8, 'preview', '\xF0\x9F\x93\xA6', pLabel, pColor)
            end

            for k, obj in pairs(MapEditor.objectives or {}) do
                local ok, err = pcall(function()
                    local ox = (obj and obj.x) or 0
                    local oy = (obj and obj.y) or 0
                    local oz = (obj and obj.z) or 0
                    if MapEditor.currentIsObjective and MapEditor._editingObjIdx == k and worldPos then
                        ox, oy, oz = worldPos.x, worldPos.y, worldPos.z
                    end
                    local r = (obj and tonumber(obj.radius)) or 20
                    if r <= 0 or r > 1000 then r = 20 end
                    local colR, colG, colB = 50, 180, 255
                    if (obj and obj.type) == 'victory' then colR, colG, colB = 255, 80, 50 end
                    if frameSkip % 300 == 0 then print("^5[RTS Loop] Drawing obj k=" .. k .. " r=" .. r .. " type=" .. (obj and obj.type or 'nil') .. "^7") end
                    DrawMarker(1, ox, oy, oz + 0.2, 0,0,0, 0,0,0, r * 2.0, r * 2.0, 3.0, colR,colG,colB, 150, false, false, 2, false, nil, nil, false)
                    local c = (obj and obj.type) == 'victory' and '#ff5032' or '#32b4ff'
                    local ic = (obj and obj.type) == 'victory' and '\xF0\x9F\x8E\xAF' or '\xE2\x8F\x9B'
                    local label = (obj and obj.name) or 'Objective'
                    if MapEditor._editingObjIdx == k then label = '\xE2\x86\x94 ' .. label end
                    AddMarker(ox, oy, oz + 2.8, 'obj_' .. tostring(label), ic, label, c)
                end)
                if not ok then print("^1[RTS MapBuilder] Marker error: " .. tostring(err) .. "^7") end
            end

            if MapEditor._isEditingSpawn and MapEditor._editingSpawnSide and worldPos then
                local side = MapEditor._editingSpawnSide
                if not MapEditor.spawns or not MapEditor.spawns[side] then
                    local colR, colG, colB = 50, 255, 50
                    local ic, label = '\xF0\x9F\x9F\xA2', 'TEAM 1'
                    if side == 'team2' then colR, colG, colB = 50, 120, 255; ic = '\xF0\x9F\x94\xB5'; label = 'TEAM 2' end
                    DrawMarker(1, worldPos.x, worldPos.y, worldPos.z + 0.2, 0,0,0, 0,0,0, 10.0, 10.0, 4.0, colR,colG,colB, 150, false, false, 2, false, nil, nil, false)
                    AddMarker(worldPos.x, worldPos.y, worldPos.z + 4.5, 'spawn_preview', ic, 'LMB to Place ' .. label, side == 'team1' and '#32ff32' or '#3278ff')
                end
            end

            for side, pos in pairs(MapEditor.spawns or {}) do
                local sx, sy, sz = pos.x, pos.y, pos.z
                if MapEditor._isEditingSpawn and MapEditor._editingSpawnSide == side and worldPos then
                    sx, sy, sz = worldPos.x, worldPos.y, worldPos.z
                end
                local colR, colG, colB = 50, 255, 50
                if side == 'team2' then colR, colG, colB = 50, 120, 255 end
                DrawMarker(1, sx, sy, sz + 0.2, 0,0,0, 0,0,0, 10.0, 10.0, 4.0, colR,colG,colB, 150, false, false, 2, false, nil, nil, false)

                local c = side == 'team1' and '#32ff32' or '#3278ff'
                local ic = side == 'team1' and '\xF0\x9F\x9F\xA2' or '\xF0\x9F\x94\xB5'
                local label = side == 'team1' and 'TEAM 1' or 'TEAM 2'
                if MapEditor._editingSpawnSide == side then label = '\xE2\x86\x94 ' .. label end
                AddMarker(sx, sy, sz + 4.5, 'spawn_' .. side, ic, label, c)
            end

            for i, obj in ipairs(MapEditor.placedObjects or {}) do
                if DoesEntityExist(obj) then
                    local coords = GetEntityCoords(obj)
                    local model = MapEditor.placedModels[obj] or tostring(GetEntityModel(obj))
                    local shortModel = string.sub(model, 1, 16)
                    local ic = IsEntityAVehicle(obj) and '\xF0\x9F\x9A\x97' or '\xF0\x9F\x93\xA6'
                    AddMarker(coords.x, coords.y, coords.z + 1.8, 'obj_' .. i, ic, shortModel, '#cccccc')
                end
            end

            SendNUIMessage({type='drawMarkers', markers=markers})
        end
    end
end)

function CloneEntity(entity)
    local coords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    local model = GetEntityModel(entity)
    local clone

    if IsEntityAVehicle(entity) then
        clone = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, true)
    elseif IsEntityAPed(entity) then
        clone = CreatePed(4, model, coords.x, coords.y, coords.z, heading, true, true)
    else
        clone = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    end

    SetEntityHeading(clone, heading)
    SetEntityCollision(clone, true, true)
    SetEntityInvincible(clone, true)
    SetEntityAlpha(clone, 255, false)
    FreezeEntityPosition(clone, true)
    SetEntityAsMissionEntity(clone, true, true)
    return clone
end