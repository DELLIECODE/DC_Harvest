Config = {}

-- PERMISSIONS
Config.AdminGroup = 'admin' -- Groupe qui peut créer/modifier/supprimer des points

-- DEBUG
Config.DebugMode = false -- Mettre à true pour voir les sphères rouges des zones de récolte

-- RÉCOLTE - PARAMÈTRES PAR DÉFAUT
Config.DefaultHarvestTime = 5000 -- Temps de récolte par défaut (en ms)
Config.DefaultAnimation = {
    dict = 'amb@prop_human_bum_bin@idle_b',
    anim = 'idle_d',
    flag = 1
}

-- ANIMATIONS DISPONIBLES
Config.Animations = {
    {
        value = 1,
        label = 'Ramasser',
        dict = 'amb@prop_human_bum_bin@idle_b',
        anim = 'idle_d',
        flag = 1
    },
    {
        value = 2,
        label = 'Miner',
        dict = 'melee@large_wpn@streamed_core',
        anim = 'ground_attack_on_spot',
        flag = 1
    },
    {
        value = 3,
        label = 'Couper',
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        anim = 'machinic_loop_mechandplayer',
        flag = 1
    },
}

-- TARGET (ox_target)
Config.TargetIcon = 'fa-solid fa-hand'
Config.TargetDistance = 2.0

-- NOTIFICATIONS
Config.Notifications = {
    harvest_success = {
        description = '~g~Vous avez récolté %s x%s'
    },
    harvest_canceled = {
        description = '~r~Récolte annulée'
    },
    no_permission = {
        description = '~r~Vous n\'avez pas la permission'
    },
    no_job_permission = {
        description = '~r~Vous n\'avez pas le job/grade requis pour récolter ici'
    },
    point_created = {
        description = '~g~Point de récolte créé avec succès'
    },
    point_deleted = {
        description = '~o~Point de récolte supprimé'
    },
    point_updated = {
        description = '~g~Point de récolte mis à jour'
    },
}

-- COMMANDES
Config.Commands = {
    create = 'createharvest',
    manage = 'manageharvest',
}