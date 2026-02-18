ESX = exports['es_extended']:getSharedObject()

harvestPoints = {}
allItems      = {}
allJobs       = {}

----------------------------------------
--           CHARGEMENT               --
----------------------------------------

CreateThread(function()
    ESX.TriggerServerCallback('dc_harvest:getAllItems', function(items)
        allItems = (type(items) == 'table') and items or {}
        print('^2[DC_Harvest] ' .. #allItems .. ' items chargés^7')
    end)

    ESX.TriggerServerCallback('dc_harvest:getJobs', function(jobs)
        allJobs = (type(jobs) == 'table') and jobs or {}
        print('^2[DC_Harvest] ' .. #allJobs .. ' jobs chargés^7')
    end)

    ESX.TriggerServerCallback('dc_harvest:loadPoints', function(points)
        if type(points) == 'table' and #points > 0 then
            harvestPoints = points
            print('^2[DC_Harvest] ' .. #points .. ' points chargés^7')
            RefreshTargets()
        else
            harvestPoints = {}
            print('^3[DC_Harvest] Aucun point de récolte en base de données^7')
        end
    end)
end)

-- Refresh déclenché par le serveur (create/update/delete)
RegisterNetEvent('dc_harvest:refresh', function()
    ESX.TriggerServerCallback('dc_harvest:loadPoints', function(points)
        harvestPoints = (type(points) == 'table') and points or {}
        RefreshTargets()
    end)
end)

----------------------------------------
--           COMMANDES                --
----------------------------------------

RegisterCommand(Config.Commands.create, function()
    OpenCreateMenu()
end)

RegisterCommand(Config.Commands.manage, function()
    OpenManageMenu()
end)

----------------------------------------
--        MENU CRÉATION               --
----------------------------------------

function OpenCreateMenu()
    if #allItems == 0 then
        ESX.ShowNotification('~r~Erreur: items non chargés')
        return
    end

    if #allJobs == 0 then
        ESX.ShowNotification('~r~Erreur: jobs non chargés')
        return
    end

    local input = lib.inputDialog('Créer un point de récolte', {
        {
            type        = 'select',
            label       = 'Item à récolter',
            description = 'Recherchez un item par son nom',
            options     = allItems,
            searchable  = true,
            required    = true
        },
        {
            type        = 'number',
            label       = 'Quantité',
            description = 'Quantité donnée par récolte',
            default     = 1,
            min         = 1,
            max         = 100,
            required    = true
        },
        {
            type        = 'number',
            label       = 'Temps de récolte (ms)',
            description = 'Durée de la récolte en millisecondes',
            default     = Config.DefaultHarvestTime,
            min         = 1000,
            max         = 60000,
            required    = true
        },
        {
            type        = 'select',
            label       = 'Animation',
            description = 'Animation jouée pendant la récolte',
            options     = Config.Animations,
            required    = true
        },
        {
            type        = 'multi-select',
            label       = 'Jobs autorisés',
            description = 'Laissez vide pour tout le monde',
            options     = allJobs,
            required    = false
        },
        {
            type        = 'number',
            label       = 'Grade minimum',
            description = 'Grade minimum requis (0 = tous les grades)',
            default     = 0,
            min         = 0,
            max         = 10,
            required    = false
        }
    })

    if not input then return end

    local selectedAnim = nil
    for _, anim in ipairs(Config.Animations) do
        if anim.value == input[4] then
            selectedAnim = anim
            break
        end
    end

    if not selectedAnim then
        ESX.ShowNotification('~r~Erreur: animation invalide')
        return
    end

    local coords = GetEntityCoords(PlayerPedId())

    TriggerServerEvent('dc_harvest:createPoint', {
        coords       = { x = coords.x, y = coords.y, z = coords.z },
        item         = input[1],
        quantity     = input[2],
        harvest_time = input[3],
        animation    = { dict = selectedAnim.dict, anim = selectedAnim.anim, flag = selectedAnim.flag },
        allowed_jobs = input[5] or {},
        min_grade    = input[6] or 0
    })
end

----------------------------------------
--        MENU GESTION                --
----------------------------------------

function OpenManageMenu()
    if #harvestPoints == 0 then
        lib.registerContext({
            id      = 'harvest_manage',
            title   = 'Gestion des points de récolte',
            options = {
                {
                    title       = 'Aucun point de récolte',
                    description = 'Utilisez /createharvest pour en créer',
                    icon        = 'circle-info',
                    disabled    = true
                }
            }
        })
        lib.showContext('harvest_manage')
        return
    end

    local options = {}

    for _, point in ipairs(harvestPoints) do
        local coords    = json.decode(point.coords)
        local itemLabel = GetItemLabel(point.item)

        local jobsText = 'Tout le monde'
        if point.allowed_jobs and point.allowed_jobs ~= '' and point.allowed_jobs ~= '[]' then
            local jobs = json.decode(point.allowed_jobs)
            if jobs and #jobs > 0 and jobs[1] ~= '' then
                jobsText = table.concat(jobs, ', ') .. ' (Grade ' .. (point.min_grade or 0) .. '+)'
            end
        end

        table.insert(options, {
            title       = string.format('%s x%s', itemLabel, point.quantity),
            description = string.format('Pos: %.2f, %.2f, %.2f | Temps: %sms | Jobs: %s', coords.x, coords.y, coords.z, point.harvest_time, jobsText),
            icon        = 'location-dot',
            metadata    = {
                { label = 'Item',  value = point.item },
                { label = 'ID',    value = point.id },
                { label = 'Jobs',  value = jobsText }
            },
            onSelect = function()
                OpenPointActions(point)
            end
        })
    end

    lib.registerContext({ id = 'harvest_manage', title = 'Gestion des points de récolte', options = options })
    lib.showContext('harvest_manage')
end

function OpenPointActions(point)
    lib.registerContext({
        id      = 'harvest_actions',
        title   = 'Actions',
        menu    = 'harvest_manage',
        options = {
            {
                title       = 'Modifier',
                description = 'Modifier les paramètres du point',
                icon        = 'pen-to-square',
                onSelect    = function() OpenEditMenu(point) end
            },
            {
                title       = 'Téléporter',
                description = 'Se téléporter au point',
                icon        = 'location-arrow',
                onSelect    = function()
                    local coords = json.decode(point.coords)
                    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
                end
            },
            {
                title       = 'Supprimer',
                description = 'Supprimer définitivement le point',
                icon        = 'trash',
                iconColor   = 'red',
                onSelect    = function()
                    local alert = lib.alertDialog({
                        header  = 'Confirmation',
                        content = 'Voulez-vous vraiment supprimer ce point de récolte ?',
                        centered = true,
                        cancel  = true
                    })
                    if alert == 'confirm' then
                        TriggerServerEvent('dc_harvest:deletePoint', point.id)
                    end
                end
            }
        }
    })
    lib.showContext('harvest_actions')
end

----------------------------------------
--        MENU ÉDITION                --
----------------------------------------

function OpenEditMenu(point)
    local currentJobs = {}
    if point.allowed_jobs and point.allowed_jobs ~= '' and point.allowed_jobs ~= '[]' then
        currentJobs = json.decode(point.allowed_jobs)
    end

    local input = lib.inputDialog('Modifier le point de récolte', {
        {
            type        = 'select',
            label       = 'Item à récolter',
            description = 'Recherchez un item par son nom',
            options     = allItems,
            searchable  = true,
            default     = point.item,
            required    = true
        },
        {
            type        = 'number',
            label       = 'Quantité',
            description = 'Quantité donnée par récolte',
            default     = point.quantity,
            min         = 1,
            max         = 100,
            required    = true
        },
        {
            type        = 'number',
            label       = 'Temps de récolte (ms)',
            description = 'Durée de la récolte en millisecondes',
            default     = point.harvest_time,
            min         = 1000,
            max         = 60000,
            required    = true
        },
        {
            type        = 'select',
            label       = 'Animation',
            description = 'Animation jouée pendant la récolte',
            options     = Config.Animations,
            required    = true
        },
        {
            type        = 'multi-select',
            label       = 'Jobs autorisés',
            description = 'Laissez vide pour tout le monde',
            options     = allJobs,
            default     = currentJobs,
            required    = false
        },
        {
            type        = 'number',
            label       = 'Grade minimum',
            description = 'Grade minimum requis (0 = tous les grades)',
            default     = point.min_grade or 0,
            min         = 0,
            max         = 10,
            required    = false
        }
    })

    if not input then return end

    local selectedAnim = nil
    for _, anim in ipairs(Config.Animations) do
        if anim.value == input[4] then
            selectedAnim = anim
            break
        end
    end

    if not selectedAnim then
        ESX.ShowNotification('~r~Erreur: animation invalide')
        return
    end

    TriggerServerEvent('dc_harvest:updatePoint', point.id, {
        item         = input[1],
        quantity     = input[2],
        harvest_time = input[3],
        animation    = { dict = selectedAnim.dict, anim = selectedAnim.anim, flag = selectedAnim.flag },
        allowed_jobs = input[5] or {},
        min_grade    = input[6] or 0
    })
end

----------------------------------------
--           RÉCOLTE                  --
----------------------------------------

local isHarvesting        = false
local waitingPermissionFor = nil

RegisterNetEvent('dc_harvest:permissionResult', function(hasPermission, pointId)
    if waitingPermissionFor ~= pointId then return end
    waitingPermissionFor = nil

    if not hasPermission then return end

    for _, point in ipairs(harvestPoints) do
        if point.id == pointId then
            StartHarvestExecution(point)
            break
        end
    end
end)

function StartHarvest(point)
    if not point or not point.id then return end

    if isHarvesting then
        ESX.ShowNotification('~o~Vous êtes déjà en train de récolter')
        return
    end

    waitingPermissionFor = point.id
    TriggerServerEvent('dc_harvest:checkPermissions', point.id)
end

function StartHarvestExecution(point)
    isHarvesting = true
    local ped    = PlayerPedId()

    RequestAnimDict(point.animation_dict)
    while not HasAnimDictLoaded(point.animation_dict) do
        Wait(100)
    end

    CreateThread(function()
        while isHarvesting do
            TaskPlayAnim(ped, point.animation_dict, point.animation_name, 8.0, -8.0, -1, point.animation_flag, 0, false, false, false)

            local success = lib.progressCircle({
                duration     = point.harvest_time,
                position     = 'bottom',
                label        = 'Récolte en cours... ([X] pour arrêter)',
                useWhileDead = false,
                canCancel    = true,
                disable      = { move = true, car = true, combat = true }
            })

            if success then
                -- On ne passe plus item/quantity au serveur, il utilise la session stockée
                TriggerServerEvent('dc_harvest:giveItem')
                Wait(500)
            else
                isHarvesting = false
                ClearPedTasks(ped)
                TriggerServerEvent('dc_harvest:stopHarvest')
                ESX.ShowNotification(Config.Notifications.harvest_canceled.description)
            end
        end

        ClearPedTasks(ped)
    end)
end

----------------------------------------
--           UTILITAIRES              --
----------------------------------------

function GetItemLabel(itemName)
    for _, item in ipairs(allItems) do
        if item.value == itemName then
            return item.label
        end
    end
    return itemName
end