local hudActive = false
local pullReady = false
local isTesting = false
local stats = { zero60 = 0.0, hundred200 = 0.0, best060 = 0.0 }
local pStartTime = 0

function OpenMidnightMenu()
    lib.registerContext({
        id = 'midnight_vbox',
        title = 'cjS Midnight VBOX Ultra',
        options = {
            {
                title = 'Ready New Pull',
                description = 'Arm the VBOX. Timer starts on movement.',
                icon = 'bolt',
                onSelect = function()
                    pullReady = true
                    hudActive = true
                    isTesting = false
                    lib.notify({title = 'VBOX ARMED', description = 'Launch when ready', type = 'success'})
                end
            },
            {
                title = (hudActive and 'Hide VBOX HUD' or 'Show VBOX HUD'),
                description = 'Toggle the performance overlay visibility.',
                icon = hudActive and 'eye-slash' or 'eye',
                onSelect = function()
                    hudActive = not hudActive
                    pullReady = false
                end
            },
            {
                title = 'Reset Session',
                description = 'Clear all current times and bests',
                icon = 'trash',
                onSelect = function()
                    stats = { zero60 = 0.0, hundred200 = 0.0, best060 = 0.0 }
                    lib.notify({description = 'Session Cleared', type = 'inform'})
                end
            }
        }
    })
    lib.showContext('midnight_vbox')
end

function DrawVboxUltra(speed, veh)
    DrawRect(0.88, 0.45, 0.14, 0.18, 10, 10, 10, 200) 
    DrawRect(0.88, 0.36, 0.14, 0.003, 0, 150, 255, 255) 

    local status = pullReady and "~g~READY" or (isTesting and "~y~RECORDING" or "~w~STANDBY")
    DrawTextUI("VBOX v1.0 // " .. status, 0.815, 0.365, 0.22, 4, false, {255, 255, 255, 150})

    DrawTextUI("0-60 MPH", 0.815, 0.4, 0.3, 4, false, {200, 200, 200, 255})
    local tCol = isTesting == "0-60" and {255, 255, 0, 255} or {255, 255, 255, 255}
    DrawTextUI(string.format("%.2fs", stats.zero60), 0.945, 0.39, 0.55, 7, true, tCol)
    
    if stats.best060 > 0 then
        DrawTextUI("BEST: "..stats.best060.."s", 0.815, 0.43, 0.2, 4, false, {0, 255, 0, 150})
    end

    DrawRect(0.88, 0.46, 0.12, 0.001, 255, 255, 255, 30) 
    DrawTextUI("100-200", 0.815, 0.47, 0.3, 4, false, {200, 200, 200, 255})
    DrawTextUI(string.format("%.2fs", stats.hundred200), 0.945, 0.46, 0.55, 7, true, {255, 255, 255, 255})

    local gForce = GetEntitySpeedVector(veh, true).y / 9.81
    DrawTextUI(string.format("%.2fG", math.abs(gForce)), 0.82, 0.51, 0.3, 4, false, {255, 255, 255, 255})
    DrawTextUI(math.floor(speed) .. " MPH", 0.93, 0.5, 0.6, 4, true, {0, 150, 255, 255})
end

function DrawShiftHUD(veh)
    local rpm = GetVehicleCurrentRpm(veh)
    if rpm > 0.7 then
        DrawRect(0.5, 0.05, 0.2, 0.02, 0, 0, 0, 150)
        local width = 0.2 * ((rpm - 0.7) / 0.3)
        local color = rpm > 0.9 and {255, 0, 0} or {0, 255, 0}
        DrawRect(0.5 - (0.2 - width)/2, 0.05, width, 0.02, color[1], color[2], color[3], 255)
        if rpm > 0.92 and (GetGameTimer() % 150 < 75) then
            DrawRect(0.5, 0.05, 0.21, 0.03, 255, 0, 0, 200)
        end
    end
end

CreateThread(function()
    while true do
        local sleep = 500
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)

        if veh ~= 0 then
            sleep = 0
            local speed = GetEntitySpeed(veh) * 2.23694
            DrawShiftHUD(veh)

            if hudActive then
                DrawVboxUltra(speed, veh)

                if pullReady and speed > 1.5 then
                    pullReady = false
                    isTesting = "0-60"
                    pStartTime = GetGameTimer()
                end

                if isTesting == "0-60" then
                    stats.zero60 = (GetGameTimer() - pStartTime) / 1000
                    if speed >= 60.0 then 
                        isTesting = false 
                        if stats.best060 == 0 or stats.zero60 < stats.best060 then stats.best060 = stats.zero60 end
                    end
                elseif speed >= 100.0 and not isTesting and stats.hundred200 == 0.0 then
                    isTesting = "100-200"
                    pStartTime = GetGameTimer()
                elseif isTesting == "100-200" then
                    stats.hundred200 = (GetGameTimer() - pStartTime) / 1000
                    if speed >= 200.0 then isTesting = false end
                end
            end
        end
        Wait(sleep)
    end
end)

function DrawTextUI(text, x, y, scale, font, center, color)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(color[1], color[2], color[3], color[4])
    SetTextEntry("STRING")
    AddTextComponentString(text)
    if center then SetTextCentre(true) end
    DrawText(x, y)
end

RegisterCommand('midnight', function() OpenMidnightMenu() end)

RegisterKeyMapping('midnight', 'Open VBOX', 'keyboard', 'F11')
