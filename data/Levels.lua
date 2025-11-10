local Levels = {}

function createLevel(id, props)
    return {
        id = id,
        name = props.name or "Level " .. id,
        introMessages = props.introMessages or {"Welcome to Level " .. id},
        enemies = props.enemies or {},
        spawnRate = props.spawnRate or 60,
        maxEnemiesOnScreen = props.maxEnemiesOnScreen or 5,
        objective = props.objective or "elimination",
        timeLimit = props.timeLimit or 300,
        enemiesToEliminate = props.enemiesToEliminate or 20,
        dataToCollect = props.dataToCollect or 0,
        itemDropRate = props.itemDropRate or 0.3,
        lastLevel = props.lastLevel or false,
        image_name = props.image_name or nil,
        endMessages = props.endMessages or {"Level Completed!"}
    }
end

Levels.list = {
    createLevel(1, {
        name = "Breach in the Kuiper Belt",
        introMessages = {
            "Scanners detect unknown signatures at the edge of the system.",
            "Intercept and identify. Weapons free if hostile.",
        },
        enemies = {
            {item = "scout", weight = 1},
        },
        spawnRate = 90,
        maxEnemiesOnScreen = 3,
        objective = "elimination",
        enemiesToEliminate = 20,
        image_name = "bg_asteroids",
        endMessages = {"Initial contact made. Prepare for escalating hostilities."},
    }),
    createLevel(2, {
        name = "The Outer Rim Offensive",
        introMessages = {
            "This is no scouting party. Full invasion force confirmed.",
            "They broke through Jupiter defense grid! Fall back to Mars orbit!",
        },
        enemies = {
            {item = "scout", weight = 3},
            {item = "heavy", weight = 1},
        },
        spawnRate = 80,
        maxEnemiesOnScreen = 4,
        objective = "elimination",
        enemiesToEliminate = 30,
        image_name = "bg_stars_purple",
        endMessages = {"Mars orbit reached. Prepare for next wave."},
    }),
    createLevel(3, {
        name = "The Martian Gauntlet",
        introMessages = {
            "Mars Colony is evacuating. We are their only cover.",
            "Buy the transports time. Hold this position!",
        },
        enemies = {
            {item = "scout", weight = 6},
            {item = "hunter", weight = 2},
            {item = "heavy", weight = 1},
        },
        spawnRate = 70,
        maxEnemiesOnScreen = 5,
        objective = "survival",
        timeLimit = 120 * 60,
        image_name = "bg_stars_orange",
        endMessages = {"Transports have cleared Mars orbit. Heading back to Earth."},
    }),
    createLevel(4, {
        name = "Data Recovery Operation",
        introMessages = {
            "Intelligence reports alien data cache in this sector.",
            "Recover the encrypted data before they can transmit it.",
            "Collect all data orbs to complete the mission."
        },
        enemies = {
            {item = "scout", weight = 4},
            {item = "sniper", weight = 2},
            {item = "hunter", weight = 1}
        },
        spawnRate = 70,
        maxEnemiesOnScreen = 6,
        objective = "collectData",
        dataToCollect = 8,
        itemDropRate = 0.7,
        image_name = "bg_stars_green",
        endMessages = {
            "Data successfully recovered!",
            "Alien encryption protocols acquired.",
            "Returning to base for analysis."
        }
    }),
    createLevel(5, {
        name = "Earths Orbital Siege",
        introMessages = {
            "The battle reaches home. All defense platforms are engaged.", 
            "Failure is not an option. Earth is counting on us."
        },
        enemies = {
            {item = "scout", weight = 4},
            {item = "heavy", weight = 2},
            {item = "sniper", weight = 1},
        },
        spawnRate = 60,
        maxEnemiesOnScreen = 6,
        objective = "elimination",
        enemiesToEliminate = 40,
        image_name = "bg_stars_blue",
        endMessages = {"Orbital defenses holding. Preparing for final engagement at Lunar Base."},
    }),
    createLevel(6, {
        name = "Last Stand at Lunar Base",
        introMessages = {
            "Command is gone. We are the last organized resistance.", 
            "They are deploying their elite guard. This is for all the marbles."
        },
        enemies = {
            {item = "scout", weight = 3},
            {item = "heavy", weight = 2},
            {item = "sniper", weight = 1},
            {item = "tank", weight = 1},
        },
        spawnRate = 50,
        maxEnemiesOnScreen = 7,
        objective = "elimination",
        enemiesToEliminate = 50,
        image_name = "bg_stars_red",
        endMessages = {"Lunar Base secured. All systems point to Hive Queen location. Final assault imminent."},
    }),
    createLevel(7, {
        name = "The Heart of the Swarm",
        introMessages = {
            "There it is... the Hive Queen. The source of the invasion.", 
            "One shot, one kill. End this war now."
        },
        enemies = {
            {item = "boss", weight = 1},
        },
        spawnRate = 40,
        maxEnemiesOnScreen = 1,
        objective = "elimination",
        enemiesToEliminate = 1,
        image_name = "bg_ion",
        lastLevel = true,
        endMessages = {"Hive Queen destroyed. Swarm disorganized. Earth is safe... for now."},
    }),
}

return Levels