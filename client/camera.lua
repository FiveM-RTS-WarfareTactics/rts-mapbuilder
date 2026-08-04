local _SavedPlayerCoords = nil
local _RTS_IsActive = false
local _RTS_LoopRunning = false
_CamPitch = -80.0
_CamHeading = 0.0

local function RestorePlayer()
    local ped = PlayerPedId()
    SetEntityVisible(ped, false, false)
    ResetEntityAlpha(ped)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
    FreezeEntityPosition(ped, false)
    ClearFocus()
    SetGameplayCamRelativePitch(0.0, 1.0)
    SetGameplayCamRelativeHeading(0.0)
    if _SavedPlayerCoords then
        local pX, pY, pZ = _SavedPlayerCoords.x, _SavedPlayerCoords.y, _SavedPlayerCoords.z
        local found, groundZ = GetGroundZFor_3dCoord(pX, pY, pZ + 100.0, 0)
        if found then
            SetEntityCoords(ped, pX, pY, groundZ + 1.0, false, false, false, false)
        else
            SetEntityCoords(ped, pX, pY, pZ, false, false, false, false)
        end
        _SavedPlayerCoords = nil
    end
end

function CreateCam(camName, active)
    local ped = PlayerPedId()
    if not _SavedPlayerCoords then _SavedPlayerCoords = GetEntityCoords(ped) end
    return 1337
end

function SetCamCoord(cam, p1, p2, p3)
    local x, y, z
    if type(p1) == 'vector3' or type(p1) == 'table' then
        x, y, z = p1.x, p1.y, p1.z
    else
        x, y, z = p1, p2, p3
    end
    if not x or not y or not z then return end
    local ped = PlayerPedId()
    SetEntityCoords(ped, x, y, z, false, false, false, false)
end

function SetCamRot(cam, rotX, rotY, rotZ, order)
    local ped = PlayerPedId()
    _CamPitch = rotX
    _CamHeading = rotZ
    SetEntityHeading(ped, _CamHeading)
    SetGameplayCamRelativePitch(_CamPitch, 1.0)
    SetGameplayCamRelativeHeading(0.0)
end

function RenderScriptCams(render, ease, easeTime, p3, p4)
    _RTS_IsActive = render
    local ped = PlayerPedId()
    if render then
        if not _SavedPlayerCoords then _SavedPlayerCoords = GetEntityCoords(ped) end
        SetEntityVisible(ped, false, false)
        SetEntityAlpha(ped, 0, false)
        SetEntityCollision(ped, false, false)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        if not _RTS_LoopRunning then
            _RTS_LoopRunning = true
            Citizen.CreateThread(function()
                while _RTS_IsActive do
                    SetEntityHeading(ped, _CamHeading)
                    SetGameplayCamRelativePitch(_CamPitch, 1.0)
                    SetGameplayCamRelativeHeading(0.0)
                    Wait(0)
                end
                _RTS_LoopRunning = false
            end)
        end
    else
        RestorePlayer()
    end
end

function DestroyCam(cam, destroy)
    _RTS_IsActive = false
    RestorePlayer()
end

function GetCamCoord(cam)
    return GetEntityCoords(PlayerPedId())
end

function GetCamRot(cam, order)
    return vector3(_CamPitch, 0.0, _CamHeading)
end

function SetCamActive(cam, active) end
function SetCamFov(cam, fov) end

function InitBuilderCam(center)
    if not center then center = vector3(0, 0, 0) end
    local ped = PlayerPedId()
    if not _SavedPlayerCoords then _SavedPlayerCoords = GetEntityCoords(ped) end
    _CamPitch = -80.0
    _CamHeading = 0.0
    _TargetHeight = center.z + 40.0
    SetEntityCoords(ped, center.x, center.y - 15.0, _TargetHeight, false, false, false, false)
    SetEntityHeading(ped, _CamHeading)
    RenderScriptCams(true, false, 0, true, true)
    SetFocusPosAndVel(center.x, center.y, _TargetHeight, 0.0, 0.0, 0.0)
end

local _TargetHeight = 40.0
local _CamSmooth = 0.05

function UpdateBuilderCam(center, radius)
    local camPos = GetCamCoord(1337)
    local mouseX = GetDisabledControlNormal(0, 239)
    local mouseY = GetDisabledControlNormal(0, 240)
    local moveX, moveY = 0.0, 0.0

    if mouseX < 0.02 then moveX = -1.5
    elseif mouseX > 0.98 then moveX = 1.5 end
    if mouseY < 0.02 then moveY = 1.5
    elseif mouseY > 0.98 then moveY = -1.5 end

    local targetZ = _TargetHeight
    local newX = camPos.x + moveX
    local newY = camPos.y + moveY

    local dist = #(vector2(newX, newY) - vector2(center.x, center.y))
    if dist >= radius then
        newX = camPos.x
        newY = camPos.y
    end

    local newZ = camPos.z + (targetZ - camPos.z) * _CamSmooth
    SetCamCoord(1337, newX, newY, newZ)
    SetFocusPosAndVel(newX, newY, newZ, 0.0, 0.0, 0.0)
end

function BuilderCamZoom(delta)
    _TargetHeight = _TargetHeight + delta
    if _TargetHeight < 5.0 then _TargetHeight = 5.0 end
    if _TargetHeight > 200.0 then _TargetHeight = 200.0 end
end

function GetWorldCoordFromScreen(relX, relY)
    local camPos = GetGameplayCamCoord()
    local worldPos = GetWorldCoordFromScreenCoord(relX, relY)
    if not worldPos then return nil end

    local direction = worldPos - camPos
    local rayDir = direction / #(direction)

    local endPoint = camPos + (rayDir * 1000.0)
    local rayHandle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, endPoint.x, endPoint.y, endPoint.z, -1, PlayerPedId(), 0)
    local _, hit, hitPos = GetShapeTestResult(rayHandle)

    local _, waterZ = GetWaterHeight(camPos.x, camPos.y, camPos.z)
    if rayDir.z < 0 then
        local t = (waterZ - camPos.z) / rayDir.z
        local waterIntersection = camPos + (rayDir * t)
        if hit == 0 or #(waterIntersection - camPos) < #(hitPos - camPos) then
            return waterIntersection + vector3(0.0, 0.0, 1.5)
        end
    end

    return hit == 1 and hitPos or nil
end