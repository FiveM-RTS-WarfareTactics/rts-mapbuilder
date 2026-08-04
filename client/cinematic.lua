-- =============================================================================
--  RTS MAP BUILDER - Cinematic Freecam
--  WASD + Q/E + Shift boost fly camera
-- =============================================================================

CreateThread(function()
    while true do
        Wait(0)
        if CinematicMode.active and CinematicMode.cam then
            local moveX, moveY, moveZ = 0.0, 0.0, 0.0
            local speed = CinematicMode.speed

            if IsControlPressed(0, 32) then moveX = moveX + speed end
            if IsControlPressed(0, 33) then moveX = moveX - speed end
            if IsControlPressed(0, 34) then moveY = moveY - speed end
            if IsControlPressed(0, 35) then moveY = moveY + speed end
            if IsControlPressed(0, 44) then moveZ = moveZ - speed end
            if IsControlPressed(0, 38) then moveZ = moveZ + speed end

            if IsControlPressed(0, 21) then
                moveX = moveX * 3
                moveY = moveY * 3
                moveZ = moveZ * 3
            end

            if moveX ~= 0 or moveY ~= 0 or moveZ ~= 0 then
                local pos = GetCamCoord(CinematicMode.cam)
                SetCamCoord(CinematicMode.cam, pos.x + moveX, pos.y + moveY, pos.z + moveZ)
            end
        end
    end
end)