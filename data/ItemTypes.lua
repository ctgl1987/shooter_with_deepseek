local ItemTypes = {
    score = {
        name = "Data Cache",
        -- image_name = "orb_yellow",
        image_name = "data_cache",
        color = {1, 1, 0},
        value = 50,
        onCollide = function(target)
            target:emit("score-collected", {score = 50})
        end
    },
    shield = {
        name = "Energy Shield",
        -- image_name = "orb_blue",
        image_name = "energy_shield",
        color = {0, 0, 1},
        onCollide = function(target)
            target:addTask(PowerupTasks.ShieldPowerupTask.create())
        end
    },
    rapidFire = {
        name = "Rapid Fire Module",
        -- image_name = "orb_red",
        image_name = "Item_Powerup_28",
        color = {1, 0, 0},
        onCollide = function(target)
            target:addTask(PowerupTasks.RapidFirePowerupTask.create())
        end
    },
    health = {
        name = "Repair Kit",
        -- image_name = "orb_green",
        image_name = "Item_Box_Gem_0",
        color = {0, 1, 0},
        value = 5,
        onCollide = function(target)
            target:emit("hp-restored", {amount = 5})
        end
    },
    speedBoost = {
        name = "Speed Boost",
        -- image_name = "orb_orange",
        image_name = "Item_Powerup_26",
        color = {1, 0.5, 0},
        onCollide = function(target)
            target:addTask(PowerupTasks.FastSpeedPowerupTask.create())
        end
    },
    lifeDrain = {
        name = "Life Drain",
        -- image_name = "orb_purple",
        image_name = "Item_Powerup_Drop_0",
        color = {0.5, 0, 0.5},
        onCollide = function(target)
            target:addTask(PowerupTasks.LifeDrainPowerupTask.create())
        end
    },
    tripleShot = {
        name = "Triple Shot",
        -- image_name = "orb_white",
        image_name = "Item_Powerup_Shield_2",
        color = {1, 1, 1},
        onCollide = function(target)
            target:addTask(PowerupTasks.TripleShotPowerupTask.create())
        end
    },
    freeze = {
        name = "Freeze",
        -- image_name = "orb_gray",
        image_name = "Item_Powerup_Weapon_5",
        color = {0.5, 0.5, 0.5},
        onCollide = function(target)
            target:addTask(PowerupTasks.FreezePowerupTask.create())
        end
    },
    bomb = {
        name = "Bomb",
        -- image_name = "orb_black",
        image_name = "Item_Powerup_Weapon_8",
        color = {0, 0, 0},
        onCollide = function(target)
            target.bombs = (target.bombs or 0) + 1
        end
    }
}

return ItemTypes