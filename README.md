# DC_Harvest

Système de récolte configurable pour FiveM — ESX + ox_inventory.

Les points de récolte sont créés en jeu via une commande, stockés en base de données et chargés automatiquement au démarrage. Chaque point est configurable : item, quantité, temps de récolte, animation, restriction par job/grade.

---

## Fonctionnalités

- Création, modification et suppression de points de récolte en jeu
- Restriction par job et grade minimum
- Animations configurables (ramasser, miner, couper)
- Progress circle avec possibilité d'annuler
- Sécurité anti-spam côté serveur (cooldown basé sur le harvest_time)
- Table SQL créée automatiquement au démarrage

---

## Prérequis

- [`es_extended`](https://github.com/esx-framework/esx_core)
- [`ox_inventory`](https://github.com/overextended/ox_inventory)
- [`ox_target`](https://github.com/overextended/ox_target)
- [`ox_lib`](https://github.com/overextended/ox_lib)
- [`oxmysql`](https://github.com/overextended/oxmysql)

---

## Installation

1. Place le dossier `DC_Harvest` dans `resources/`
2. Ajoute dans `server.cfg` dans cet ordre :

```
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure es_extended
ensure DC_Harvest
```

3. La table SQL `dc_harvest_points` est créée automatiquement au premier lancement.

---

## Commandes

Les commandes sont réservées au groupe défini dans `config.lua` (`admin` par défaut).

| Commande | Description |
|---|---|
| `/createharvest` | Ouvre le menu de création d'un point de récolte à ta position actuelle |
| `/manageharvest` | Liste tous les points existants avec options de modification/suppression |

---

## Configuration

Tout se passe dans `config.lua`.

```lua
Config.AdminGroup = 'admin'       -- Groupe autorisé à gérer les points
Config.DebugMode  = false         -- Affiche les sphères ox_target en rouge
Config.DefaultHarvestTime = 5000  -- Temps de récolte par défaut (ms)
Config.TargetDistance = 2.0       -- Rayon de la zone d'interaction
```

**Ajouter une animation :**
```lua
Config.Animations = {
    {
        value = 4,
        label = 'Pêcher',
        dict  = 'amb@world_human_stand_fishing@idle_a',
        anim  = 'idle_a',
        flag  = 1
    },
}
```

---

## Structure des fichiers

```
DC_Harvest/
├── config.lua
├── fxmanifest.lua
├── client/
│   ├── main.lua       -- Menus, logique de récolte, callbacks
│   └── target.lua     -- Gestion des zones ox_target
└── server/
    ├── main.lua       -- Events, vérifications, sécurité
    └── sql.lua        -- Création automatique de la table
```

---

## Sécurité

- Les items sont donnés uniquement côté serveur
- Le client ne transmet ni l'item ni la quantité — tout est lu depuis la base de données
- Un cooldown serveur basé sur le `harvest_time` du point empêche le spam de l'event `giveItem`
- Les permissions admin sont vérifiées côté serveur sur chaque action (création, modification, suppression)

---

## Licence

MIT — libre à utiliser, modifier et redistribuer.

## DISCORD

https://discord.gg/XnkrNnqFtK
