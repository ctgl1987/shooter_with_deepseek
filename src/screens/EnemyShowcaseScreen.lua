local EnemyShowcaseScreen = BaseScreen:new({
    name = "enemy_showcase",
    enter = function(self)
        self.enemyMap = {}

        local enemyNames = {'scout', 'kamikaze', 'heavy', 'sniper', 'hunter', 'tank', 'bomber', 'boss'}

        for i, name in ipairs(enemyNames) do
            local enemyType = EnemyTypes[name]
            
            local enemy = BaseEntity:new({
                type = "enemy",
                x = 0,
                y = 0,
                width = ENTITY_SIZE * 1.5,
                height = ENTITY_SIZE * 1.5,
                color = { 0, 0, 0, 0 },
                name = enemyType.name
            })
            enemy.image = ImageManager:get(enemyType.image_name)
            self.enemyMap[i] = {
                name = enemyType.name,
                image = enemy.image,
                width = enemy.width,
                height = enemy.height
            }
        end
    end,
    input = function(self, eventType, key)
        if eventType == "keydown" then
            if key == "back" then
                ScreenManager:pop()
            end
        end
    end,
    update = function(self, dt)

    end,
    render = function(self)
        DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color = BG_COLOR })

        DrawManager:fillText("Enemy Showcase", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.2,
            { size = 30, align = "center" })

        -- dibujar todos los enemigos, con nombre desde self.enemyMap
        -- horizontalmente, con un margen
        -- centrados
        local count = 0
        for key, value in pairs(self.enemyMap) do
            count = count + 1
        end

        local margin = 50
        local startX = margin
        local startY = GAME_HEIGHT * 0.5
        local spacingX = (GAME_WIDTH - margin * 2) / count

        local i = 0

        for key, enemy in pairs(self.enemyMap) do
            local posX = startX + i * spacingX + spacingX / 2
            local posY = startY

            -- dibujar enemigo
            DrawManager:drawImage(enemy.image, {
                x = posX - enemy.width / 2,
                y = posY - enemy.height / 2,
                width = enemy.width,
                height = enemy.height
            })

            -- dibujar nombre
            DrawManager:fillText(enemy.name, posX, posY + enemy.height / 2 + 20, {
                align = "center",
                -- size = 14,
                color = "white"
            })
            i = i + 1
        end


        DrawManager:fillText("Back (Escape or Button B)", GAME_WIDTH * 0.5, GAME_HEIGHT * 0.8,
            { align = "center" })
    end
})

return EnemyShowcaseScreen
