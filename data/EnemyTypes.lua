local EnemyTypes = {
    scout = {
        name = "Scout",
        color = {1, 0.27, 0.27}, -- #ff4444
        image_name = "ship_red",
        vy = 2,
        score = 10,
        hp = 1
    },
    heavy = {
        name = "Heavy",
        color = {1, 0.67, 0}, -- #ffaa00
        image_name = "ship_orange",
        vy = 1,
        score = 20,
        hp = 3
    },
    sniper = {
        name = "Sniper",
        color = {0.67, 0, 1}, -- #aa00ff
        image_name = "ship_purple",
        vy = 1.5,
        score = 30,
        hp = 2
    },
    hunter = {
        name = "Hunter",
        image_name = "ship_green",
        vy = 0.5,
        score = 25,
        hp = 2,
        build = function(e)
            e:addTask(EntityTasks.SideMovementTask.create())
        end
    },
    tank = {
        name = "Tank",
        color = {0.53, 0.53, 0.53}, -- #888888
        image_name = "ship_gray",
        vy = 0.75,
        score = 40,
        hp = 3
    },
    bomber = {
        name = "Bomber",
        color = {0.53, 0.33, 0.13}, -- #885522
        image_name = "ship_brown",
        vy = 0.50,
        score = 50,
        hp = 4
    },
    boss = {
        boss = true,
        name = "Hive Queen",
        color = {1, 1, 0.27}, -- #ffff44
        image_name = "ship_yellow2",
        width = 144, -- ENTITY_SIZE * 3
        height = 144, -- ENTITY_SIZE * 3
        vy = 0.2,
        score = 200,
        hp = 50,
        build = function(e)
            e:addTask(EntityTasks.BossTask.create())
        end
    }
}

return EnemyTypes