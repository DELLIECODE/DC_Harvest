ESX = exports['es_extended']:getSharedObject()

local activeHarvesters = {}
local harvestCooldowns = {}

----------------------------------------
--           CALLBACKS                --
----------------------------------------

-- Charger tous les jobs depuis la BDD
ESX.RegisterServerCallback('dc_harvest:getJobs', function(source, cb)
    local result  = MySQL.query.await('SELECT name, label FROM jobs ORDER BY label ASC', {})
    local jobList = {{ value = '', label = 'Tout le monde', grades = {} }}

    if result then
        for _, job in ipairs(result) do
            local grades    = MySQL.query.await('SELECT grade, label FROM job_grades WHERE job_name = ? ORDER BY grade ASC', { job.name })
            local gradeList = {}
            for _, grade in ipairs(grades or {}) do
                table.insert(gradeList, { value = grade.grade, label = grade.label })
            end
            table.insert(jobList, { value = job.name, label = job.label, grades = gradeList })
        end
    end

    cb(jobList)
end)

-- Charger tous les items depuis ox_inventory
ESX.RegisterServerCallback('dc_harvest:getAllItems', function(source, cb)
    local items = exports.ox_inventory:Items()

    if not items then
        cb({})
        return
    end

    local itemList = {}
    for itemName, itemData in pairs(items) do
        if itemData and itemData.label then
            table.insert(itemList, { value = itemName, label = itemData.label })
        end
    end

    table.sort(itemList, function(a, b) return a.label < b.label end)
    cb(itemList)
end)

-- Charger tous les points de récolte
ESX.RegisterServerCallback('dc_harvest:loadPoints', function(source, cb)
    local result = MySQL.query.await('SELECT * FROM dc_harvest_points', {})
    cb(result or {})
end)

----------------------------------------
--         GESTION DES POINTS         --
----------------------------------------

-- Créer un point
RegisterNetEvent('dc_harvest:createPoint', function(data)
    local source  = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsPlayerAdmin(source) then
        if xPlayer then xPlayer.showNotification(Config.Notifications.no_permission.description) end
        return
    end

    local id = MySQL.insert.await('INSERT INTO dc_harvest_points (coords, item, quantity, harvest_time, animation_dict, animation_name, animation_flag, allowed_jobs, min_grade, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        json.encode(data.coords),
        data.item,
        data.quantity,
        data.harvest_time,
        data.animation.dict,
        data.animation.anim,
        data.animation.flag,
        json.encode(data.allowed_jobs),
        data.min_grade or 0,
        xPlayer.identifier
    })

    if id then
        TriggerClientEvent('dc_harvest:refresh', -1)
        xPlayer.showNotification(Config.Notifications.point_created.description)
    end
end)

-- Supprimer un point
RegisterNetEvent('dc_harvest:deletePoint', function(id)
    local source  = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsPlayerAdmin(source) then
        if xPlayer then xPlayer.showNotification(Config.Notifications.no_permission.description) end
        return
    end

    MySQL.query.await('DELETE FROM dc_harvest_points WHERE id = ?', { id })
    TriggerClientEvent('dc_harvest:refresh', -1)
    xPlayer.showNotification(Config.Notifications.point_deleted.description)
end)

-- Modifier un point
RegisterNetEvent('dc_harvest:updatePoint', function(id, data)
    local source  = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsPlayerAdmin(source) then
        if xPlayer then xPlayer.showNotification(Config.Notifications.no_permission.description) end
        return
    end

    MySQL.update.await('UPDATE dc_harvest_points SET item = ?, quantity = ?, harvest_time = ?, animation_dict = ?, animation_name = ?, animation_flag = ?, allowed_jobs = ?, min_grade = ? WHERE id = ?', {
        data.item,
        data.quantity,
        data.harvest_time,
        data.animation.dict,
        data.animation.anim,
        data.animation.flag,
        json.encode(data.allowed_jobs),
        data.min_grade or 0,
        id
    })

    TriggerClientEvent('dc_harvest:refresh', -1)
    xPlayer.showNotification(Config.Notifications.point_updated.description)
end)

----------------------------------------
--             RÉCOLTE                --
----------------------------------------

RegisterNetEvent('dc_harvest:checkPermissions', function(pointId)
    local source  = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local result = MySQL.query.await('SELECT item, quantity, harvest_time, allowed_jobs, min_grade FROM dc_harvest_points WHERE id = ?', { pointId })

    if not result or #result == 0 then
        TriggerClientEvent('dc_harvest:permissionResult', source, false, pointId)
        return
    end

    local row         = result[1]
    local allowedJobs = {}

    if row.allowed_jobs and row.allowed_jobs ~= '' and row.allowed_jobs ~= '[]' and row.allowed_jobs ~= '[""]' then
        local decoded = json.decode(row.allowed_jobs)
        for _, job in ipairs(decoded or {}) do
            if job and job ~= '' then
                table.insert(allowedJobs, job)
            end
        end
    end

    local minGrade      = row.min_grade or 0
    local hasPermission = true

    if #allowedJobs > 0 then
        hasPermission = false
        for _, job in ipairs(allowedJobs) do
            if xPlayer.job.name == job and xPlayer.job.grade >= minGrade then
                hasPermission = true
                break
            end
        end
    end

    if hasPermission then
        activeHarvesters[source] = {
            item         = row.item,
            quantity     = row.quantity,
            harvest_time = row.harvest_time
        }
    else
        xPlayer.showNotification(Config.Notifications.no_job_permission.description)
    end

    TriggerClientEvent('dc_harvest:permissionResult', source, hasPermission, pointId)
end)

-- Donner l'item — sécurisé avec cooldown anti-spam
RegisterNetEvent('dc_harvest:giveItem', function()
    local source  = source
    local session = activeHarvesters[source]
    if not session then return end

    local now      = GetGameTimer()
    local minDelay = (session.harvest_time or 5000) - 500
    local lastGive = harvestCooldowns[source] or 0

    if (now - lastGive) < minDelay then return end
    harvestCooldowns[source] = now

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    xPlayer.addInventoryItem(session.item, session.quantity)

    local itemLabel = ESX.GetItemLabel(session.item) or session.item
    xPlayer.showNotification(string.format(Config.Notifications.harvest_success.description, itemLabel, session.quantity))
end)

RegisterNetEvent('dc_harvest:stopHarvest', function()
    local source = source
    activeHarvesters[source] = nil
    harvestCooldowns[source] = nil
end)

AddEventHandler('playerDropped', function()
    activeHarvesters[source] = nil
    harvestCooldowns[source] = nil
end)

----------------------------------------
--            UTILITAIRES             --
----------------------------------------

function IsPlayerAdmin(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and xPlayer.getGroup() == Config.AdminGroup
end

CreateThread(function()
    while GetResourceState('ox_inventory') ~= 'started' do Wait(200) end

    print('^1[DELLIECODE]^0 DC_HARVEST chargé ^2✔^0')
    print('     ^5•^0 Système : ^6récolte configurable^0')
    print('     ^5•^0 Target : ^6ox_target^0')
    print('     ^5•^0 Inventaire : ^6ox_inventory^0')
    print('     ^5•^0 SQL : ^2actif^0')
end)