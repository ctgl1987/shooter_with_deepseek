local TaskSystem = require("core.TaskSystem")

local EntityMoveTask = TaskSystem:create({
    name = "EntityMoveTask",
    duration = math.huge,
    
    onStart = function(self, entity)
        self.entity = entity
    end,
    
    onUpdate = function(self, dt)
        self.entity.x = self.entity.x + self.entity.vx * (self.entity.acceleration or 1)
        self.entity.y = self.entity.y + self.entity.vy * (self.entity.acceleration or 1)
        
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
        local speed = self.entity.speed or 5
        
        if KeyManager:isDown("left") then
            self.entity.vx = -speed
        elseif KeyManager:isDown("right") then
            self.entity.vx = speed
        else
            self.entity.vx = 0
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
            limit = math.random(90, 150)
        }
        self.chanceLimit = 0.7
    end,

    onUpdate = function(self, dt)
        self.fireTimer.value = self.fireTimer.value + 1

        if self.fireTimer.value >= self.fireTimer.limit then
            self.fireTimer.value = 0
            self.fireTimer.limit = math.random(90, 150)

            local chance = math.random()
            if chance > self.chanceLimit then
                return
            end

            local bullet = BaseEntity:new({
                type = "bullet",
                owner = self.entity,
                width = ENTITY_SIZE * 0.05,
                height = ENTITY_SIZE * 0.2,
                color = {1, 0, 0},
                damage = 1,
                vy = ENTITY_SIZE / 8
            })

            bullet:centerTo({
                x = self.entity:center().x,
                y = self.entity:bottom()
            })

            bullet:addTask(EntityTasks.EntityMoveTask.create())
            AudioManager:play("shoot")

            self.entity:emit("bullet-created", {
                bullets = {bullet}
            })
            self.entity:emit("enemy-fire", {
                bullets = {bullet}
            })
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
        self.entity.vx = math.sin(time * 2) * 2
    end
})

local BossTask = TaskSystem:create({
    name = "BossTask",
    duration = math.huge,
    
    onStart = function(self, entity)
        self.entity = entity
        self.phase = 0
        self.timer = 0
        self.vx = 2
        
        self.entity:centerTo({x = GAME_WIDTH / 2})
        self.entity.y = -self.entity.height
        self.entity:removeTask("EnemyFireTask")
    end,
    
    onUpdate = function(self, dt)
        -- Movimiento lateral
        if self.entity.x <= 0 or self.entity:right() >= GAME_WIDTH then
            self.entity.vx = -self.entity.vx
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
        if self.phase == 1 and self.entity.hp <= self.entity.maxHp * 0.25 then
            self.phase = 2
            self.entity.vx = self.entity.vx * 2
            
            -- Encontrar y modificar la tarea de disparo
            for _, task in ipairs(self.entity.tasks) do
                if task.name == "EnemyFireTask" then
                    task.chanceLimit = 1.1
                    task.fireTimer.limit = 30
                    
                    -- Configurar disparo triple
                    task.entity.onBulletCreated = function(data)
                        local baseBullet = data.bullets[1]
                        
                        -- Bala izquierda
                        local leftBullet = BaseEntity:new({
                            type = "bullet",
                            owner = self.entity,
                            width = ENTITY_SIZE * 0.05,
                            height = ENTITY_SIZE * 0.2,
                            color = {1, 0, 0},
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
                            color = {1, 0, 0},
                            damage = 1,
                            vy = baseBullet.vy
                        })
                        rightBullet:centerTo({
                            x = self.entity:center().x + 20,
                            y = self.entity:bottom()
                        })
                        rightBullet:addTask(EntityTasks.EntityMoveTask.create())
                        table.insert(data.bullets, rightBullet)
                    end
                    break
                end
            end
        end
    end
})

return {
    EntityMoveTask = EntityMoveTask,
    PlayerControllerTask = PlayerControllerTask,
    EnemyFireTask = EnemyFireTask,
    SideMovementTask = SideMovementTask,
    BossTask = BossTask
}