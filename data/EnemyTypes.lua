local EnemyTypes = {
    scout = {
        name = "Scout",
        color = {1, 0.27, 0.27}, -- #ff4444
        image_name = "new_ship_red",
        vy = 100,
        score = 10,
        hp = 1
    },
    kamikaze = {
        name = "Kamikaze",
        color = {1, 1, 1}, -- #FFFFFF
        image_name = "new_ship_white",
        vy = 180,
        score = 10,
        hp = 1
    },
    heavy = {
        name = "Heavy",
        color = {1, 0.67, 0}, -- #ffaa00
        image_name = "new_ship_orange",
        vy = 60,
        score = 20,
        hp = 3
    },
    sniper = {
        name = "Sniper",
        color = {0.67, 0, 1}, -- #aa00ff
        image_name = "new_ship_purple",
        vy = 180,
        score = 30,
        hp = 2
    },
    hunter = {
        name = "Hunter",
        image_name = "new_ship_green",
        vy = 30,
        score = 25,
        hp = 2,
        build = function(e)
            e:addTask(EntityTasks.SideMovementTask.create())
            e.width = ENTITY_SIZE * 1.5
        end
    },
    tank = {
        name = "Tank",
        color = {0.53, 0.53, 0.53}, -- #888888
        image_name = "new_ship_gray",
        vy = 45,
        score = 40,
        hp = 3
    },
    bomber = {
        name = "Bomber",
        color = {0.53, 0.33, 0.13}, -- #885522
        image_name = "new_ship_brown",
        vy = 30,
        score = 50,
        hp = 4
    },
    boss = {
        boss = true,
        name = "Hive Queen",
        color = {1, 1, 0.27}, -- #ffff44
        image_name = "new_ship_yellow",
        width = 144, -- ENTITY_SIZE * 3
        height = 144, -- ENTITY_SIZE * 3
        vy = 12,
        score = 200,
        hp = 50,
        build = function(e)
            e:addTask(EntityTasks.BossTask.create())
        end
    }
}

return EnemyTypes