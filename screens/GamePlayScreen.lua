local BaseScreen = require("core.BaseScreen")
local PowerupTasks = require("tasks.PowerupTasks")

local GamePlayScreen = BaseScreen:new({
    name = "game_play",

    enter = function(self, data)
        print("Starting level: " .. data.level.id .. " - " .. data.level.name .. " (" .. data.level.objective .. ")")
        self.level = data.level
        self:initializeGame()
    end,

    initializeGame = function(self)
        self.introTimer = {
            value = 0,
            limit = 120 + (#self.level.introMessages * 60)
        }
        self.endTimer = {
            value = 0,
            limit = 180
        }

        self.enemies = {}
        self.playerBullets = {}
        self.enemiesBullets = {}
        self.items = {}
        self.texts = {}
        self.particles = {}

        self.score = 0
        self.duration = 0
        self.completed = false
        self.warped = false

        self.enemySpawnTimer = {
            value = 0,
            limit = self.level.spawnRate
        }

        self:createPlayer()
        self:createBackground()
        self:setupCheats()

        self.redFlash = Utils.createScreenFlasher({ 1, 0, 0, 0.1 }, 5)
    end,

    createPlayer = function(self)
        self.player = BaseEntity:new({
            type = "player",
            x = (GAME_WIDTH - ENTITY_SIZE) / 2,
            y = GAME_HEIGHT - ENTITY_SIZE * 1.5,
            width = ENTITY_SIZE,
            height = ENTITY_SIZE,
            color = { 0, 0, 0, 0 }, -- transparent
            hp = 10,
            maxHp = 10,
            friction = 0.8,
            speed = 5,
            bombs = 0
        })

        self.player.weapon = Utils.createPlayerWeapon()

        self.player:addTask(EntityTasks.PlayerControllerTask.create())
        self.player:addTask(EntityTasks.EntityMoveTask.create())

        -- add player sprite
        self.player.sprite = Sprite:new(ImageManager:get("ship_blue"), {
            frames = 0,
            frameRate = 5
        })

        self.player:on("pre-update", function()
            self.player.weapon:update()
            self.player.sprite:update()
        end)

        self.player:on("damage-received", function(data)
            self:spawnParticles(self.player:center())
        end)

        self.player:on("hp-restored", function(data)
            self.player.hp = math.min(self.player.hp + data.amount, self.player.maxHp)
            self:spawnParticles(self.player:center())
            self:showText("Healed +" .. data.amount .. " HP", 120)
        end)

        self.player:on("score-collected", function(data)
            self.score = self.score + data.score
            self:showText("+" .. data.score .. " Score", 120)

            if self.level.objective == "collectData" then
                self.level.dataToCollect = math.max(0, self.level.dataToCollect - 1)
            end
        end)

        self.player:on("defeat", function()
            ScreenManager:change("gameover")
        end)

        self.player:on("post-render", function()
            self.player.sprite:render(self.player:bounds());

            -- Barra de HP
            Utils.drawHpBar({
                value = self.player.hp,
                max = self.player.maxHp,
                x = self.player.x,
                y = self.player.y,
            })
        end)
    end,

    createBackground = function(self)
        local bgImage = ImageManager:get(self.level.image_name or "bg_space")
        self.bg = Utils.createScrollingBackground(bgImage, 1)
    end,

    setupCheats = function(self)
        CheatManager:reset()

        CheatManager:register("godmode", function(cheat)
            print("Toggling God Mode")
            if cheat.l1 then
                print("God Mode Deactivated!")
                cheat.l1:remove()
                cheat.l2:remove()
                cheat.l1 = nil
                cheat.l2 = nil
            else
                print("God Mode Activated!")
                cheat.l1 = self.player:on("damage-received", function(data)
                    data.damage = 0
                end)
                cheat.l2 = self.player:on("pre-render", function()
                    local pos = self.player:center()
                    DrawManager:fillCircle(pos.x, pos.y, self.player.width * 1.5, {
                        color = { 1, 1, 0, 0.07 }
                    })
                    DrawManager:fillText("GOD MODE", self.player.x + self.player.width * 0.5, self.player.y - 30, {
                        color = "yellow",
                        align = "center"
                    })
                end)
            end
        end)

        CheatManager:register("allpower", function(cheat)
            print("All Powerups Activated!")
            self.player:addTask(PowerupTasks.ShieldPowerupTask.create())
            self.player:addTask(PowerupTasks.TripleShotPowerupTask.create())
            self.player:addTask(PowerupTasks.FastSpeedPowerupTask.create())
            self.player:addTask(PowerupTasks.RapidFirePowerupTask.create())
            self.player:addTask(PowerupTasks.LifeDrainPowerupTask.create())
            self.player:addTask(PowerupTasks.FreezePowerupTask.create())
        end)

        CheatManager:register("healme", function(cheat)
            print("Heal Me Activated!")
            self.player.hp = self.player.maxHp
            self:showText("Healed to Full HP", 120)
        end)
    end,

    spawnEnemy = function(self, specificEnemy)
        if self.completed then
            return
        end
        if self.enemySpawnTimer.value < self.enemySpawnTimer.limit then
            return
        end
        if #self.enemies >= self.level.maxEnemiesOnScreen then
            return
        end

        self.enemySpawnTimer.value = 0

        local enemyType = specificEnemy or Utils.weightedRandom(self.level.enemies)
        local template = EnemyTypes[enemyType]

        local enemy = BaseEntity:new({
            type = "enemy",
            x = math.random(10, GAME_WIDTH - ENTITY_SIZE - 10),
            y = -ENTITY_SIZE,
            width = template.width or ENTITY_SIZE,
            height = template.height or ENTITY_SIZE,
            color = { 0, 0, 0, 0 }, -- transparent
            maxHp = template.hp,
            hp = template.hp,
            vy = template.vy,
            score = template.score,
            name = template.name
        })

        -- Extender con propiedades del template
        for k, v in pairs(template) do
            if enemy[k] == nil then
                enemy[k] = v
            end
        end

        enemy.image = ImageManager:get(template.image_name)

        local r = 0

        enemy:on("post-render", function()
            -- draw white rectangle around enemy for debugging
            -- DrawManager:fillRect(enemy.x, enemy.y, enemy.width, enemy.height, {color = "white"})

            local dst = {
                x = enemy.x,
                y = enemy.y,
                width = enemy.width,
                height = enemy.height
            }

            local options = {
                rotate = 180
            }
            DrawManager:drawImage(enemy.image, dst, nil, options)

            -- Dibujar nombre
            r = r + 2
            DrawManager:fillText(enemy.name, enemy:center().x, enemy.y - 20, {
                color = "white",
                align = "center",
                baseline = "middle",
                size = 16
            })

            -- Barra de HP
            Utils.drawHpBar({
                value = enemy.hp,
                max = enemy.maxHp,
                x = enemy.x,
                y = enemy.y,
            })
        end)

        enemy:addTask(EntityTasks.EntityMoveTask.create())
        enemy:addTask(EntityTasks.EnemyFireTask.create())

        if template.build then
            template.build(enemy)
        end

        enemy:on("enemy-fire", function(data)
            for _, bullet in ipairs(data.bullets) do
                table.insert(self.enemiesBullets, bullet)
            end
        end)

        enemy:on("damage-received", function()
            self:spawnParticles(enemy:center())
        end)

        enemy:on("enemy-destroyed", function()
            if self.level.objective == "elimination" then
                self.level.enemiesToEliminate = math.max(0, self.level.enemiesToEliminate - 1)
            end
            self.score = self.score + enemy.score
        end)

        table.insert(self.enemies, enemy)
    end,

    playerFire = function(self)
        if self.completed then
            return
        end
        if not self.player.weapon:ready() then
            return
        end

        self.player.weapon:reload()

        local bullet = BaseEntity:new({
            type = "bullet",
            owner = self.player,
            width = ENTITY_SIZE * 0.05,
            height = ENTITY_SIZE * 0.2,
            color = { 1, 0, 0 },
            damage = 1,
            vy = -ENTITY_SIZE / 8
        })

        bullet:centerTo({
            x = self.player:center().x,
            y = self.player.y
        })

        bullet:addTask(EntityTasks.EntityMoveTask.create())
        AudioManager:play("shoot")

        local data = {
            bullets = { bullet }
        }
        self.player:emit("bullet-created", data)

        for _, b in ipairs(data.bullets) do
            table.insert(self.playerBullets, b)
        end
    end,

    spawnItem = function(self, position, specificItem)
        if self.completed then
            return
        end

        local template = specificItem or Utils.randomItem(Utils.values(ItemTypes))

        local item = BaseEntity:new({
            width = ENTITY_SIZE * 0.75,
            height = ENTITY_SIZE * 0.75,
            vy = 2,
            color = { 0, 0, 0, 0 } -- transparent
        })

        -- Extender con propiedades del template
        for k, v in pairs(template) do
            if item[k] == nil then
                item[k] = v
            end
        end

        item:centerTo(position)
        item.image = ImageManager:get(template.image_name)

        item:on("post-render", function()
            -- local color = template.color

            -- love.graphics.setColor(color[1], color[2], color[3], 0.3)
            -- love.graphics.circle("fill", item:center().x, item:center().y, item.width * 0.75)

            -- -- Núcleo brillante
            -- love.graphics.setColor(color[1], color[2], color[3], 1)
            -- love.graphics.circle("fill", item:center().x, item:center().y, item.width * 0.6)

            -- -- Efecto de resplandor
            -- love.graphics.setColor(1, 1, 1, 0.8)
            -- love.graphics.arc("line", item:center().x, item:center().y, item.width * 0.8, 0, math.pi * 0.3)

            local dst = {
                x = item.x,
                y = item.y,
                width = item.width,
                height = item.height
            }

            local options = {
                pulse = {
                    amplitude = 0.1,
                    speed = 5
                }
            }

            DrawManager:drawImage(item.image, dst, nil, options)
        end)

        item:addTask(EntityTasks.EntityMoveTask.create())

        table.insert(self.items, item)
    end,

    showText = function(self, text, ttl)
        local textEntity = BaseEntity:new({
            text = text,
            ttl = ttl,
            x = GAME_WIDTH / 2,
            y = GAME_HEIGHT - 30,
            --transparent
            color = { 0, 0, 0, 0 }
        })

        textEntity:on("post-update", function()
            textEntity.ttl = textEntity.ttl - 1
            if textEntity.ttl <= 0 then
                textEntity.dead = true
            end
        end)

        textEntity.render = function(self, offsetX, offsetY)
            local alpha = textEntity.ttl / ttl
            DrawManager:fillText(textEntity.text, textEntity.x + (offsetX or 0), textEntity.y + (offsetY or 0), {
                align = "center",
                color = { 1, 1, 1, alpha }
            })
        end

        table.insert(self.texts, textEntity)
    end,

    spawnParticles = function(self, position)
        local ttl = 30
        for i = 1, 10 do
            local particle = BaseEntity:new({
                x = position.x,
                y = position.y,
                width = ENTITY_SIZE * 0.05,
                height = ENTITY_SIZE * 0.05,
                color = { 1, 0.65, 0 }, -- orange
                vx = math.random() * 4 - 2,
                vy = math.random() * 4 - 2,
                ttl = ttl
            })

            particle:addTask(EntityTasks.EntityMoveTask.create())

            particle:on("post-update", function()
                particle.ttl = particle.ttl - 1
                if particle.ttl <= 0 then
                    particle.dead = true
                end
                local alpha = particle.ttl / ttl
                particle.color = { 1, 0.65, 0, alpha }
            end)

            table.insert(self.particles, particle)
        end
    end,

    checkLevelComplete = function(self)
        if self.completed then
            return
        end

        if self.level.objective == "elimination" then
            if self.level.enemiesToEliminate <= 0 then
                self:levelCompleted()
            end
        elseif self.level.objective == "survival" then
            self.level.timeLimit = self.level.timeLimit - 1
            if self.level.timeLimit <= 0 then
                self:levelCompleted()
            end
        elseif self.level.objective == "collectData" then
            if self.level.dataToCollect <= 0 then
                self:levelCompleted()
            end
        end
    end,

    levelCompleted = function(self)
        self.completed = true
        print("Level Complete!")

        GameState.levelsUnlocked[self.level.id + 1] = true
        GameState.levelsCompleted[self.level.id] = {
            completed = true,
            score = self.score
        }
        SaveGame()

        self.enemySpawnTimer.limit = math.huge

        -- Destruir todos los enemigos
        for _, enemy in ipairs(self.enemies) do
            self:spawnParticles(enemy:center())
            self:spawnParticles(enemy:center())
            self:spawnParticles(enemy:center())
            enemy.dead = true
        end

        -- Destruir todas las balas
        for _, bullet in ipairs(self.enemiesBullets) do
            bullet.dead = true
        end

        for _, bullet in ipairs(self.playerBullets) do
            bullet.dead = true
        end

        -- Destruir todos los ítems
        for _, item in ipairs(self.items) do
            item.dead = true
        end

        -- Detener movimiento del jugador
        self.player.vx = 0
        self.player.friction = 1
        self.player:removeTask("PlayerControllerTask")
    end,

    warpOut = function(self)
        if self.warped then
            return
        end
        self.warped = true
        self.player.vy = -5
        AudioManager:play("warpout")
    end,

    changeLevel = function(self)
        if self.level.lastLevel then
            ScreenManager:change("game_end", {
                score = self.score
            })
            return
        end
        GameScreenManager:change("game_level_completed", {
            score = self.score,
            level = self.level,
            duration = math.floor(self.duration / 60)
        })
    end,

    handleLevelCompletion = function(self)
        -- Mover jugador al centro
        local targetX = (GAME_WIDTH - self.player.width) / 2
        self.player.x = self.player.x + (targetX - self.player.x) * 0.1

        if self.endTimer.value < self.endTimer.limit then
            self.endTimer.value = self.endTimer.value + 1
        else
            self:warpOut()
        end
    end,

    handleGameplay = function(self, dt)
        -- Disparar con espacio
        if KeyManager:isDown("fire") then
            self:playerFire()
        end

        self.enemySpawnTimer.value = self.enemySpawnTimer.value + 1
        self:spawnEnemy()

        -- Actualizar enemigos
        for i = #self.enemies, 1, -1 do
            local enemy = self.enemies[i]
            enemy:update(dt)

            if enemy.y > GAME_HEIGHT then
                enemy.dead = true
            end

            if Utils.collision(enemy, self.player) then
                enemy.dead = true
                local damageEvent = {
                    damage = enemy.hp
                }
                self.player:emit("damage-received", damageEvent)
                self.player.hp = self.player.hp - damageEvent.damage

                if damageEvent.damage > 0 then
                    self.redFlash:start()
                end

                if self.player.hp <= 0 then
                    self.player:emit("defeat")
                end
            end

            if enemy.dead then
                table.remove(self.enemies, i)
            end
        end

        -- Actualizar ítems
        for i = #self.items, 1, -1 do
            local item = self.items[i]
            item:update(dt)

            if item.y > GAME_HEIGHT then
                item.dead = true
            end

            if Utils.collision(item, self.player) then
                item.dead = true
                self:showText("Got " .. item.name, 120)
                item.onCollide(self.player)
                AudioManager:play("powerup")
            end

            if item.dead then
                table.remove(self.items, i)
            end
        end

        -- Actualizar balas del jugador
        for i = #self.playerBullets, 1, -1 do
            local bullet = self.playerBullets[i]
            bullet:update(dt)

            if bullet.y + bullet.height < 0 then
                bullet.dead = true
            end

            -- Colisión con enemigos
            for j, enemy in ipairs(self.enemies) do
                if Utils.collision(bullet, enemy) then
                    bullet.dead = true
                    bullet:emit("bullet-hit", {
                        damage = bullet.damage,
                        target = enemy
                    })
                    enemy.hp = enemy.hp - bullet.damage
                    enemy:emit("damage-received")

                    if enemy.hp <= 0 then
                        AudioManager:play("explosion")
                        enemy:emit("enemy-destroyed")
                        enemy.dead = true

                        -- Spawnear ítem
                        local chance = math.random()
                        if chance < self.level.itemDropRate then
                            self:spawnItem(enemy:center())
                        end
                    end
                    break
                end
            end

            if bullet.dead then
                table.remove(self.playerBullets, i)
            end
        end

        -- Actualizar balas enemigas
        for i = #self.enemiesBullets, 1, -1 do
            local bullet = self.enemiesBullets[i]
            bullet:update(dt)

            if bullet.y > GAME_HEIGHT then
                bullet.dead = true
            end

            if Utils.collision(bullet, self.player) then
                bullet.dead = true
                local damageEvent = {
                    damage = bullet.damage
                }
                self.player:emit("damage-received", damageEvent)
                self.player.hp = self.player.hp - damageEvent.damage

                if damageEvent.damage > 0 then
                    self.redFlash:start()
                end

                if self.player.hp <= 0 then
                    self.player:emit("defeat")
                end
            end

            if bullet.dead then
                table.remove(self.enemiesBullets, i)
            end
        end

        -- Actualizar textos
        for i = #self.texts, 1, -1 do
            local text = self.texts[i]
            text:update(dt)
            if text.dead then
                table.remove(self.texts, i)
            end
        end

        -- Actualizar partículas
        for i = #self.particles, 1, -1 do
            local particle = self.particles[i]
            particle:update(dt)
            if particle.dead then
                table.remove(self.particles, i)
            end
        end
    end,

    input = function(self, eventType, key, realKey)
        if eventType == "keydown" then
            if key == "pause" then
                GameScreenManager:push("game_pause")
            elseif key == "fire" then
                -- Saltar intro solo si introTimer está activo y le queda mas de 60 frames
                if self.introTimer.value < self.introTimer.limit and self.introTimer.value + 60 < self.introTimer.limit then
                    self.introTimer.value = self.introTimer.limit - 60
                end
            elseif key == "bomb" then
                if self.player.bombs > 0 then
                    self.player.bombs = self.player.bombs - 1
                    -- Activar bomba - destruir todos los enemigos
                    for _, enemy in ipairs(self.enemies) do
                        enemy.dead = true
                        self:spawnParticles(enemy:center())
                        AudioManager:play("explosion")
                    end
                end
            end

            -- print("GamePlayScreen received key: " .. tostring(realKey))

            -- Cheats
            if realKey and #realKey == 1 then
                CheatManager:input(realKey)
            end
        end
    end,

    update = function(self, dt)
        InputManager:setContext("game")

        self.duration = self.duration + 1

        CheatManager:update(dt)
        self.redFlash:update()

        if self.completed and self.player:bottom() < -50 then
            self:changeLevel()
            return
        end

        self.bg:update(dt)
        self.player:update(dt)

        -- Mantener al jugador en pantalla
        self.player.x = math.max(ENTITY_SIZE * 0.5,
            math.min(self.player.x, GAME_WIDTH - self.player.width - ENTITY_SIZE * 0.5))

        if self.introTimer.value < self.introTimer.limit then
            self.introTimer.value = self.introTimer.value + 1
            return
        end

        if self.completed then
            self:handleLevelCompletion()
        end
        self:handleGameplay(dt)

        self:checkLevelComplete()
    end,

    renderUI = function(self)
        local offsetY = 10

        -- HP
        DrawManager:fillText("HP: " .. self.player.hp .. "/" .. self.player.maxHp, 10, offsetY, {
            color = "yellow",
            size = 24
        })
        offsetY = offsetY + 25

        -- Score
        DrawManager:fillText("Score: " .. self.score, 10, offsetY, {
            color = "yellow",
            size = 24
        })
        offsetY = offsetY + 25

        -- Bombs
        DrawManager:fillText("Bombs: " .. self.player.bombs, 10, offsetY, {
            color = "yellow",
            size = 24
        })
        offsetY = offsetY + 30

        -- Tiempo
        local durationSeconds = math.floor(self.duration / 60)
        DrawManager:fillText("Time: " .. durationSeconds .. "s", GAME_WIDTH - 10, 10, {
            align = "right",
            color = "yellow",
            size = 24
        })

        -- Objetivo del nivel
        local objectiveText = ""
        if self.level.objective == "elimination" then
            objectiveText = "Enemies Left: " .. self.level.enemiesToEliminate
        elseif self.level.objective == "survival" then
            local secondsLeft = math.ceil(self.level.timeLimit / 60)
            objectiveText = "Time Left: " .. secondsLeft .. "s"
        elseif self.level.objective == "collectData" then
            objectiveText = "Data Left: " .. self.level.dataToCollect
        end

        DrawManager:fillText(objectiveText, GAME_WIDTH / 2, 10, {
            align = "center",
            color = "yellow",
            size = 24
        })

        -- Tareas/powerups del jugador
        offsetY = GAME_HEIGHT - 20
        for _, task in ipairs(self.player.tasks) do
            if task.powerup then
                DrawManager:fillText(task.name, 10, offsetY, {
                    color = "yellow",
                    align = "left",
                    baseline = "bottom"
                })

                -- Barra de duración del powerup
                Utils.drawHpBar({
                    value = task.time,
                    max = task.duration,
                    x = 10,
                    y = offsetY + 10,
                    width = 150,
                    backColor = 'gray',
                    color = 'yellow',
                })

                offsetY = offsetY - 35
            end
        end

        -- Textos flotantes
        for i, text in ipairs(self.texts) do
            text:render(0, -i * 25)
        end
    end,

    renderIntro = function(self)
        if self.introTimer.value >= self.introTimer.limit then
            return
        end

        local alpha = 1.0
        if self.introTimer.value < 60 then
            alpha = self.introTimer.value / 60
        elseif self.introTimer.value > self.introTimer.limit - 60 then
            alpha = (self.introTimer.limit - self.introTimer.value) / 60
        end

        local introOffsetY = GAME_HEIGHT * 0.4

        DrawManager:fillText("-- Level " .. self.level.id .. ": " .. self.level.name .. " --", GAME_WIDTH * 0.5,
            introOffsetY, {
                size = 30,
                align = "center",
                color = { 1, 1, 0, alpha }
            })
        introOffsetY = introOffsetY + 40

        local messages = {}
        for _, msg in ipairs(self.level.introMessages) do
            table.insert(messages, msg)
        end
        table.insert(messages, "")
        table.insert(messages, "Objective: " .. ObjectivesText[self.level.objective])

        for _, msg in ipairs(messages) do
            DrawManager:fillText(msg, GAME_WIDTH * 0.5, introOffsetY, {
                align = "center",
                color = { 1, 1, 1, alpha }
            })
            introOffsetY = introOffsetY + 30
        end
    end,

    renderCompletion = function(self)
        if not self.completed or not self.level.endMessages then
            return
        end

        local alpha = 1.0
        if self.endTimer.value < 60 then
            alpha = self.endTimer.value / 60
        elseif self.endTimer.value > self.endTimer.limit - 60 then
            alpha = (self.endTimer.limit - self.endTimer.value) / 60
        end

        for i, msg in ipairs(self.level.endMessages) do
            DrawManager:fillText(msg, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.4 + i * 30, {
                size = 24,
                align = "center",
                color = { 1, 1, 0, alpha }
            })
        end
    end,

    render = function(self)
        self.bg:render()
        -- CheatManager:render()

        -- Renderizar entidades
        for _, enemy in ipairs(self.enemies) do
            enemy:render()
        end

        for _, item in ipairs(self.items) do
            item:render()
        end

        self.player:render()

        for _, bullet in ipairs(self.playerBullets) do
            bullet:render()
        end

        for _, bullet in ipairs(self.enemiesBullets) do
            bullet:render()
        end

        for _, particle in ipairs(self.particles) do
            particle:render()
        end

        self.redFlash:render()
        self:renderUI()
        self:renderIntro()
        self:renderCompletion()
    end
})

return GamePlayScreen
