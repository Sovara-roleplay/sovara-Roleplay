local ESX = exports['es_extended']:getSharedObject()
local pending = {} -- [targetSrc] = { issuer, docType, doc, time }

local FIELDS = {
    arbeitsvertrag = { 'issuer', 'signer', 'Straße', 'Beruf', 'Arbeitsstunden', 'Pause', 'Beschäftigung' },
    gewerbe        = { 'issuer', 'signer', 'Gewerbename', 'Straße', 'Art des Gewerbes' },
}

local function notify(src, msg)
    TriggerClientEvent('esx:showNotification', src, msg)
end

local function clean(docType, raw)
    if type(raw) ~= 'table' then return nil end
    local out = {}
    for _, key in ipairs(FIELDS[docType]) do
        local v = raw[key]
        if type(v) ~= 'string' then return nil end
        v = v:gsub('[%c<>]', ''):sub(1, 60)
        if v == '' then return nil end
        out[key] = v
    end
    out.nr = tostring(math.random(10000, 99999))
    out.date = os.date('%d.%m.%Y')
    return out
end

local function dist(a, b)
    return #(GetEntityCoords(GetPlayerPed(a)) - GetEntityCoords(GetPlayerPed(b)))
end

local function itemCount(xPlayer, name)
    local it = xPlayer.getInventoryItem(name)
    return it and it.count or 0
end

-- Item benutzen ------------------------------------------------------------
for docType, cfg in pairs(Config.Docs) do
    -- leeres Item: Formular öffnen
    ESX.RegisterUsableItem(docType, function(src)
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        if not Config.CanIssue(xPlayer, docType) then
            return notify(src, '~r~Dazu bist du nicht berechtigt.')
        end
        TriggerClientEvent('sovara_docs:fill', src, docType)
    end)

    -- Kopie: eigene Dokumente dieses Typs anzeigen
    ESX.RegisterUsableItem(cfg.copy, function(src)
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        MySQL.query(
            'SELECT data, sig FROM sovara_docs WHERE doc_type = ? AND (issuer = ? OR signer = ?) ORDER BY id DESC LIMIT ?',
            { docType, xPlayer.identifier, xPlayer.identifier, Config.MaxListed },
            function(rows)
                local docs = {}
                for _, r in ipairs(rows or {}) do
                    docs[#docs + 1] = { docType = docType, doc = json.decode(r.data), sig = r.sig }
                end
                TriggerClientEvent('sovara_docs:list', src, docType, docs)
            end
        )
    end)
end

-- Aussteller schickt Dokument an zweite Person -----------------------------
RegisterNetEvent('sovara_docs:send', function(docType, raw, target)
    local src = source
    target = tonumber(target)
    if not Config.Docs[docType] or not target or target == src then return end

    local xIssuer, xTarget = ESX.GetPlayerFromId(src), ESX.GetPlayerFromId(target)
    if not xIssuer or not xTarget then return end
    if not Config.CanIssue(xIssuer, docType) then return notify(src, '~r~Dazu bist du nicht berechtigt.') end
    if itemCount(xIssuer, docType) < 1 then return end
    if dist(src, target) > Config.MaxDistance + 1.0 then return notify(src, '~r~Person ist zu weit weg.') end
    if pending[target] then return notify(src, '~r~Die Person unterschreibt gerade etwas anderes.') end

    local doc = clean(docType, raw)
    if not doc then return notify(src, '~r~Bitte alle Felder korrekt ausfüllen.') end

    pending[target] = { issuer = src, docType = docType, doc = doc, time = os.time() }
    notify(src, 'Dokument wurde zur Unterschrift gesendet.')
    TriggerClientEvent('sovara_docs:sign', target, docType, doc)
end)

-- Zweite Person hat unterschrieben -----------------------------------------
RegisterNetEvent('sovara_docs:signed', function(sig)
    local target = source
    local p = pending[target]
    if not p then return end
    pending[target] = nil

    local xTarget, xIssuer = ESX.GetPlayerFromId(target), ESX.GetPlayerFromId(p.issuer)
    if not xTarget or not xIssuer then return end
    if os.time() - p.time > Config.RequestTimeout then return notify(target, '~r~Anfrage ist abgelaufen.') end
    if type(sig) ~= 'string' or #sig < 10 or #sig > 6000 or not sig:match('^[ML0-9 ]+$') then
        return notify(target, '~r~Ungültige Unterschrift.')
    end
    if dist(p.issuer, target) > Config.MaxDistance + 2.0 then
        return notify(target, '~r~Aussteller ist nicht mehr in der Nähe.')
    end
    if itemCount(xIssuer, p.docType) < 1 then
        return notify(target, '~r~Aussteller hat das Item nicht mehr.')
    end

    local copy = Config.Docs[p.docType].copy
    if not xIssuer.canCarryItem(copy, 1) or not xTarget.canCarryItem(copy, 1) then
        notify(p.issuer, '~r~Inventar voll – Vorgang abgebrochen.')
        return notify(target, '~r~Inventar voll – Vorgang abgebrochen.')
    end

    -- Dokument dauerhaft speichern
    local id = MySQL.insert.await(
        'INSERT INTO sovara_docs (doc_type, issuer, signer, data, sig) VALUES (?, ?, ?, ?, ?)',
        { p.docType, xIssuer.identifier, xTarget.identifier, json.encode(p.doc), sig }
    )
    if not id then
        return notify(target, '~r~Speichern fehlgeschlagen.')
    end

    xIssuer.removeInventoryItem(p.docType, 1)
    xIssuer.addInventoryItem(copy, 1)
    xTarget.addInventoryItem(copy, 1)

    notify(p.issuer, '~g~Unterschrieben! Du hast eine Kopie erhalten.')
    notify(target, '~g~Unterschrieben! Du hast eine Kopie erhalten.')
end)

RegisterNetEvent('sovara_docs:declined', function()
    local target = source
    local p = pending[target]
    if not p then return end
    pending[target] = nil
    notify(p.issuer, '~r~Die Person hat die Unterschrift abgelehnt.')
end)

AddEventHandler('playerDropped', function()
    local src = source
    pending[src] = nil
    for t, p in pairs(pending) do if p.issuer == src then pending[t] = nil end end
end)
