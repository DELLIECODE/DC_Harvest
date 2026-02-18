function RefreshTargets()
    if not harvestPoints or type(harvestPoints) ~= 'table' then return end

    -- Supprimer les anciennes zones
    for _, point in ipairs(harvestPoints) do
        pcall(function()
            exports.ox_target:removeZone('harvest_' .. point.id)
        end)
    end

    -- Créer les nouvelles zones
    for _, point in ipairs(harvestPoints) do
        local coords = json.decode(point.coords)

        exports.ox_target:addSphereZone({
            name   = 'harvest_' .. point.id,
            coords = vector3(coords.x, coords.y, coords.z),
            radius = Config.TargetDistance,
            debug  = Config.DebugMode,
            options = {
                {
                    name     = 'harvest_point_' .. point.id,
                    icon     = Config.TargetIcon,
                    label    = string.format('Récolter %s', GetItemLabel(point.item)),
                    onSelect = function()
                        StartHarvest(point)
                    end
                }
            }
        })
    end

    if Config.DebugMode then
        print('^2[DC_Harvest] ' .. #harvestPoints .. ' point(s) chargé(s)^7')
    end
end