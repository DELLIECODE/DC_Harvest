-- La table se crée automatiquement au lancement du script
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `dc_harvest_points` (
            `id`             INT AUTO_INCREMENT PRIMARY KEY,
            `coords`         VARCHAR(255) NOT NULL,
            `item`           VARCHAR(50)  NOT NULL,
            `quantity`       INT          NOT NULL,
            `harvest_time`   INT          NOT NULL,
            `animation_dict` VARCHAR(100),
            `animation_name` VARCHAR(100),
            `animation_flag` INT,
            `allowed_jobs`   TEXT         DEFAULT NULL,
            `min_grade`      INT          DEFAULT 0,
            `created_by`     VARCHAR(100),
            `created_at`     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    print('^2[DC_Harvest]^7 Base de données initialisée')
end)