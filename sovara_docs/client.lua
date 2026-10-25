local open = false

local function notify(msg)
    TriggerEvent('esx:showNotification', msg)
end

local function closestPlayer()
    local me = PlayerId()
    local myCoords = GetEntityCoords(PlayerPedId())
    local best, bestDist = nil, Config.MaxDistance
    for _, pid in ipairs(GetActivePlayers()) do
        if pid ~= me then
            local d = #(GetEntityCoords(GetPlayerPed(pid)) - myCoords)
            if d <= bestDist then
                best, bestDist = GetPlayerServerId(pid), d
            end
        end
    end
    return best
end

local function show(payload)
    open = true
    SetNuiFocus(true, true)
    SendNUIMessage(payload)
end

local function hide()
    open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- Leeres Item benutzt -> Formular öffnen
RegisterNetEvent('sovara_docs:fill', function(docType)
    if open then return end
    show({ action = 'fill', docType = docType })
end)

-- Zweite Person soll unterschreiben
RegisterNetEvent('sovara_docs:sign', function(docType, doc)
    if open then return end
    show({ action = 'sign', docType = docType, doc = doc })
end)

-- Kopie benutzt -> eigene Dokumente anzeigen
RegisterNetEvent('sovara_docs:list', function(docType, docs)
    if open then return end
    if #docs == 0 then return notify('Keine Dokumente gefunden.') end
    show({ action = 'list', docType = docType, docs = docs })
end)

RegisterNUICallback('submit', function(body, cb)
    cb('ok')
    local target = closestPlayer()
    if not target then return notify('~r~Niemand in der Nähe.') end
    hide()
    TriggerServerEvent('sovara_docs:send', body.docType, body.doc, target)
end)

RegisterNUICallback('signed', function(body, cb)
    cb('ok')
    hide()
    TriggerServerEvent('sovara_docs:signed', body.sig)
end)

RegisterNUICallback('declined', function(_, cb)
    cb('ok')
    hide()
    TriggerServerEvent('sovara_docs:declined')
end)

RegisterNUICallback('close', function(_, cb)
    cb('ok')
    hide()
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and open then SetNuiFocus(false, false) end
end)
