local TaskSystem = require("core.TaskSystem")

local EntityMoveTask = TaskSystem:create({
    name = "EntityMoveTask",
    duration = math.huge,

    onStart = function(self, entity)
        self.entity = entity
    end,

    onUpdate = function(self, dt)
        self.entity.x = self.entity.x + self.entity.vx * dt
        self.entity.y = self.entity.y + self.entity.vy * dt

        self.entity.vx = self.entity.vx * (self.entity.friction or 1)
        self.entity.vy = self.entity.vy * (self.entity.friction or 1)
    end
})

local PlayerControllerTask = TaskSystem:create({
    name = "PlayerControllerTask",
    duration = math.huge,

    onStart = function(self, entity)
        self.entity = entity
    end,

    onUpdate = function(self, dt)
        local speed = self.entity.speed

        if KeyManager:isDown("left") then
            self.entity.vx = -speed
            self.entity.rotate = self.entity.rotate + -1
            if self.entity.rotate < -10 then
                self.entity.rotate = -10
            end
        elseif KeyManager:isDown("right") then
            self.entity.vx = speed
            self.entity.rotate = self.entity.rotate + 1
            if self.entity.rotate > 10 then
                self.entity.rotate = 10
            end
        else
            --decrease rotation to 0
            if self.entity.rotate > 0 then
                self.entity.rotate = self.entity.rotate - 2
            end
            if self.entity.rotate < 0 then
                self.entity.rotate = self.entity.rotate + 2
            end
        end
    end
})

local EnemyFireTask = TaskSystem:create({
    name = "EnemyFireTask",
    duration = math.huge,

    onStart = function(self, entity)
        self.entity = entity
        self.fireTimer = {
            value = 0,
            limit = math.random(90, 150),
            randomChance = true
        }
        self.chanceLimit = 0.70
    end,

    onUpdate = function(self, dt)
        self.fireTimer.value = self.fireTimer.value + 1

        if self.fireTimer.value >= self.fireTimer.limit then
            self.fireTimer.value = 0

            local chance = self.fireTimer.randomChance and math.random() or 0
            if chance > self.chanceLimit then
                return
            end

            local bullet = BaseEntity:new({
                type = "bullet",
                owner = self.entity,
                width = ENTITY_SIZE * 0.05,
                height = ENTITY_SIZE * 0.2,
                color = "#FF0000",
                damage = 1,
                vy = 360
            })

            bullet:centerTo({
                x = self.entity:center().x,
                y = self.entity:bottom()
            })

            bullet:addTask(EntityTasks.EntityMoveTask.create())
            AudioManager:play("shoot")

            local dataEvent = {
                bullets = { bullet }
            }

            self.entity:emit("bullet-created", dataEvent)

            self.entity:emit("enemy-fire", dataEvent)
        end
    end
})

local SideMovementTask = TaskSystem:create({
    name = "SideMovementTask",
    duration = math.huge,

    onStart = function(self, entity)
        self.entity = entity
        self.startTime = love.timer.getTime()
    end,

    onUpdate = function(self, dt)
        local time = love.timer.getTime() - self.startTime
        self.entity.vx = math.sin(time * 2) * 120
    end
})

local BossTask = TaskSystem:create({
    name = "BossTask",
    duration = math.huge,

    onStart = function(self, entity)
        self.entity = entity
        self.phase = 0
        self.timer = 0
        self.vy = 50
        self.vx = 80

        self.entity:centerTo({ x = GAME_WIDTH / 2 })
        self.entity.y = -self.entity.height
    end,

    onUpdate = function(self, dt)
        -- Movimiento lateral
        if self.entity:right() >= GAME_WIDTH - ENTITY_SIZE then
            self.entity.vx = self.entity.vx * -1
            self.entity.x = self.entity.x - 1
        end
        if self.entity.x <= ENTITY_SIZE then
            self.entity.vx = self.entity.vx * -1
            self.entity.x = self.entity.x + 1
        end

        -- Fase 0: Entrada en pantalla
        if self.phase == 0 then
            if self.entity.y >= 80 then
                self.entity.y = 80
                self.entity.vy = 0
                self.entity.vx = self.vx
                self.phase = 1

                local fireTask = EntityTasks.EnemyFireTask.create()
                fireTask.chanceLimit = 0.75
                self.entity:addTask(fireTask)
            end
        end

        -- Fase 1: Rage mode al 25% de HP
        if self.phase == 1 then
            if self.entity.hp <= self.entity.maxHp * 0.4 then

                self.phase = 2
                self.entity.vx = self.entity.vx * 2

                -- Find and modify the fire task directly in the entity's task list
                local fireTask = self.entity.tasks["EnemyFireTask"]
                if fireTask then
                    fireTask.fireTimer.randomChance = false
                    fireTask.fireTimer.limit = 20
                    fireTask.chanceLimit = 1
                end

                print("Boss has entered rage mode!")

                -- Configurar disparo triple
                self.entity:on("bullet-created", function(data)
                    local baseBullet = data.bullets[1]

                    -- Bala izquierda
                    local leftBullet = BaseEntity:new({
                        type = "bullet",
                        owner = self.entity,
                        width = ENTITY_SIZE * 0.05,
                        height = ENTITY_SIZE * 0.2,
                        color = "#FF0000",
                        damage = 1,
                        vy = baseBullet.vy
                    })

                    leftBullet:centerTo({
                        x = self.entity:center().x - 20,
                        y = self.entity:bottom()
                    })

                    leftBullet:addTask(EntityTasks.EntityMoveTask.create())
                    table.insert(data.bullets, leftBullet)

                    -- Bala derecha
                    local rightBullet = BaseEntity:new({
                        type = "bullet",
                        owner = self.entity,
                        width = ENTITY_SIZE * 0.05,
                        height = ENTITY_SIZE * 0.2,
                        color = "#FF0000",
                        damage = 1,
                        vy = baseBullet.vy
                    })

                    rightBullet:centerTo({
                        x = self.entity:center().x + 20,
                        y = self.entity:bottom()
                    })

                    rightBullet:addTask(EntityTasks.EntityMoveTask.create())
                    table.insert(data.bullets, rightBullet)
                end)
            end
        end
    end
})

local KeepOnScreenTask = TaskSystem:create({
    name = "KeepOnScreenTask",
    duration = math.huge,

    onStart = function(self, entity)
        self.entity = entity
    end,

    onUpdate = function(self, dt)
        if self.entity.x < 0 then
            self.entity.x = 0
            self.entity.vx = 0
        elseif self.entity:right() > GAME_WIDTH then
            self.entity.x = GAME_WIDTH - self.entity.width
            self.entity.vx = 0
        end
    end
})

local MotorBurstTask = TaskSystem:create({
    name = "MotorBurstTask",
    duration = math.huge,

    onStart = function(self, entity)
        self.entity = entity
    end,

    onUpdate = function(self, dt)
        if math.random() < 0.5 then -- 50% de probabilidad por frame
            self.entity:emit("spawn-particles", {
                position = {
                    x = self.entity:center().x,
                    y = self.entity:bottom() - 10 -- ajustar un poco hacia arriba
                },
                options = {
                    color = "#FFFFFFCC", -- white, normal motor burst
                    size = 2,
                    speed = 30,
                    spread = math.pi,
                    amount = 5,
                    ttl = 30
                }
            })
        end
    end,

    onComplete = function(self)

    end
})

return {
    EntityMoveTask = EntityMoveTask,
    PlayerControllerTask = PlayerControllerTask,
    EnemyFireTask = EnemyFireTask,
    SideMovementTask = SideMovementTask,
    BossTask = BossTask,
    KeepOnScreenTask = KeepOnScreenTask,
    MotorBurstTask = MotorBurstTask,
}
