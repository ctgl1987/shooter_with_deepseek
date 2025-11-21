local ItemTypes = {
    score = {
        name = "Data Cache",
        -- image_name = "orb_yellow",
        image_name = "item_data_cache",
        color = "#FFFF00",
        value = 50,
        onCollide = function(target)
            target:emit("score-collected", {score = 50})
        end
    },
    shield = {
        name = "Energy Shield",
        -- image_name = "orb_blue",
        image_name = "item_energy_shield",
        color = "#0000FF",
        onCollide = function(target)
            target:addTask(PowerupTasks.ShieldPowerupTask.create())
        end
    },
    rapidFire = {
        name = "Rapid Fire Module",
        -- image_name = "orb_red",
        image_name = "item_rapid_fire",
        color = "#FF0000",
        onCollide = function(target)
            target:addTask(PowerupTasks.RapidFirePowerupTask.create())
        end
    },
    health = {
        name = "Repair Kit",
        -- image_name = "orb_green",
        image_name = "item_repair_kit",
        color = "#00FF00",
        value = 5,
        onCollide = function(target)
            target:emit("hp-restored", {amount = 5})
        end
    },
    speedBoost = {
        name = "Speed Boost",
        -- image_name = "orb_orange",
        image_name = "item_speed_boost",
        color = "#FF8000",
        onCollide = function(target)
            target:addTask(PowerupTasks.FastSpeedPowerupTask.create())
        end
    },
    lifeDrain = {
        name = "Life Drain",
        -- image_name = "orb_purple",
        image_name = "item_drain_life",
        color = "#800080",
        onCollide = function(target)
            target:addTask(PowerupTasks.LifeDrainPowerupTask.create())
        end
    },
    tripleShot = {
        name = "Triple Shot",
        -- image_name = "orb_white",
        image_name = "item_triple_shot",
        color = "#FFFFFF",
        onCollide = function(target)
            target:addTask(PowerupTasks.TripleShotPowerupTask.create())
        end
    },
    freeze = {
        name = "Freeze",
        -- image_name = "orb_gray",
        image_name = "item_freeze",
        color = "#808080",
        onCollide = function(target)
            target:addTask(PowerupTasks.FreezePowerupTask.create())
        end
    },
    bomb = {
        name = "Bomb",
        -- image_name = "orb_black",
        image_name = "item_bomb",
        color = "#000000",
        onCollide = function(target)
            target.bombs = (target.bombs or 0) + 1
        end
    }
}

return ItemTypes