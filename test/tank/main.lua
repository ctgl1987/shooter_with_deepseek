-- main.lua
function love.load()
    -- Configuración inicial
    love.window.setTitle("Battle City - Love2D")
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Definir el mapa con strings
    local map = {
        "ssssssssssssssssssss",
        "s                  s",
        "s  b  b     b  b   s",
        "s  b  b     b  b   s",
        "s                  s",
        "s    s   bb   s    s",
        "s    s   bb   s    s",
        "s         bb       s",
        "s         bb       s",
        "s    s          s  s",
        "s    s          s  s",
        "s         s        s",
        "s         s        s",
        "s  b           b   s",
        "s  b           b   s",
        "s                  s",
        "s    bb    s   bb  s",
        "s    bb    s   bb  s",
        "s                  s",
        "s  #       h       s",
        "ssssssssssssssssssss"
    }
    
    -- Tamaño de cada tile
    local tileSize = 30
    local mapWidth = #map[1] * tileSize
    local mapHeight = #map * tileSize
    
    -- Centrar la ventana o ajustar tamaño
    love.window.setMode(mapWidth, mapHeight)
    
    -- Inicializar listas
    steelWalls = {}
    brickWalls = {}
    enemies = {}
    player = nil
    base = nil
    
    -- Procesar el mapa
    for y, row in ipairs(map) do
        for x = 1, #row do
            local char = row:sub(x, x)
            local tileX = (x - 1) * tileSize
            local tileY = (y - 1) * tileSize
            
            if char == "s" then
                -- Muro de acero
                table.insert(steelWalls, {
                    x = tileX, 
                    y = tileY, 
                    width = tileSize, 
                    height = tileSize, 
                    color = {0.7, 0.7, 0.7}
                })
            elseif char == "b" then
                -- Ladrillo
                table.insert(brickWalls, {
                    x = tileX, 
                    y = tileY, 
                    width = tileSize, 
                    height = tileSize, 
                    color = {0.9, 0.6, 0.2}
                })
            elseif char == "#" then
                -- Spawn del jugador
                player = {
                    x = tileX,
                    y = tileY,
                    width = tileSize - 4,
                    height = tileSize - 4,
                    speed = 150,
                    color = {0, 1, 0},
                    direction = "up",
                    cooldown = 0
                }
            elseif char == "h" then
                -- Base (home)
                base = {
                    x = tileX,
                    y = tileY,
                    width = tileSize,
                    height = tileSize,
                    color = {1, 1, 0},
                    destroyed = false
                }
            end
        end
    end
    
    -- Agregar enemigos en las esquinas superiores
    local enemyPositions = {
        {x = tileSize, y = tileSize},                    -- Esquina superior izquierda
        {x = mapWidth - tileSize * 2, y = tileSize},     -- Esquina superior derecha
        {x = tileSize, y = tileSize * 3},                -- Cerca esquina izquierda
        {x = mapWidth - tileSize * 2, y = tileSize * 3}  -- Cerca esquina derecha
    }
    
    for _, pos in ipairs(enemyPositions) do
        table.insert(enemies, {
            x = pos.x,
            y = pos.y,
            width = tileSize - 4,
            height = tileSize - 4,
            color = {1, 0, 0},
            speed = 80,
            direction = "down",
            cooldown = math.random(1, 3)
        })
    end
    
    -- Proyectiles
    projectiles = {}
    
    -- Estado del juego
    gameState = "playing"
    score = 0
end

function love.update(dt)
    if gameState == "playing" then
        -- Actualizar cooldown del jugador
        if player.cooldown > 0 then
            player.cooldown = player.cooldown - dt
        end
        
        -- Movimiento del jugador SEPARADO EN X e Y
        local dx, dy = 0, 0
        
        if love.keyboard.isDown("up") then
            dy = -1
            player.direction = "up"
        elseif love.keyboard.isDown("down") then
            dy = 1
            player.direction = "down"
        end
        
        if love.keyboard.isDown("left") then
            dx = -1
            player.direction = "left"
        elseif love.keyboard.isDown("right") then
            dx = 1
            player.direction = "right"
        end
        
        -- MOVIMIENTO SEPARADO: Primero en X, luego en Y
        if dx ~= 0 then
            local newX = player.x + dx * player.speed * dt
            local canMoveX = true
            
            -- Verificar colisiones en X
            for _, wall in ipairs(steelWalls) do
                if checkCollisionRectangles(newX, player.y, player.width, player.height, 
                                          wall.x, wall.y, wall.width, wall.height) then
                    canMoveX = false
                    break
                end
            end
            
            for _, wall in ipairs(brickWalls) do
                if checkCollisionRectangles(newX, player.y, player.width, player.height, 
                                          wall.x, wall.y, wall.width, wall.height) then
                    canMoveX = false
                    break
                end
            end
            
            -- Verificar colisión con base
            if base and not base.destroyed and checkCollisionRectangles(newX, player.y, player.width, player.height, 
                                                                     base.x, base.y, base.width, base.height) then
                canMoveX = false
            end
            
            -- Verificar colisión con enemigos
            for _, enemy in ipairs(enemies) do
                if checkCollisionRectangles(newX, player.y, player.width, player.height, 
                                          enemy.x, enemy.y, enemy.width, enemy.height) then
                    canMoveX = false
                    break
                end
            end
            
            if canMoveX then
                player.x = newX
            end
        end
        
        if dy ~= 0 then
            local newY = player.y + dy * player.speed * dt
            local canMoveY = true
            
            -- Verificar colisiones en Y
            for _, wall in ipairs(steelWalls) do
                if checkCollisionRectangles(player.x, newY, player.width, player.height, 
                                          wall.x, wall.y, wall.width, wall.height) then
                    canMoveY = false
                    break
                end
            end
            
            for _, wall in ipairs(brickWalls) do
                if checkCollisionRectangles(player.x, newY, player.width, player.height, 
                                          wall.x, wall.y, wall.width, wall.height) then
                    canMoveY = false
                    break
                end
            end
            
            -- Verificar colisión con base
            if base and not base.destroyed and checkCollisionRectangles(player.x, newY, player.width, player.height, 
                                                                     base.x, base.y, base.width, base.height) then
                canMoveY = false
            end
            
            -- Verificar colisión con enemigos
            for _, enemy in ipairs(enemies) do
                if checkCollisionRectangles(player.x, newY, player.width, player.height, 
                                          enemy.x, enemy.y, enemy.width, enemy.height) then
                    canMoveY = false
                    break
                end
            end
            
            if canMoveY then
                player.y = newY
            end
        end
        
        -- Actualizar enemigos
        for _, enemy in ipairs(enemies) do
            enemy.cooldown = enemy.cooldown - dt
            
            -- Movimiento aleatorio de enemigos
            if math.random(100) < 3 then  -- 5% de chance de cambiar dirección
                local directions = {"up", "down", "left", "right"}
                enemy.direction = directions[math.random(4)]
            end
            
            -- Disparo aleatorio de enemigos
            if enemy.cooldown <= 0 then
                createProjectile(enemy.x + enemy.width/2, enemy.y + enemy.height/2, enemy.direction, false)
                enemy.cooldown = math.random(2, 4)
            end
            
            -- Movimiento del enemigo SEPARADO
            local edx, edy = 0, 0
            if enemy.direction == "up" then edy = -1
            elseif enemy.direction == "down" then edy = 1
            elseif enemy.direction == "left" then edx = -1
            elseif enemy.direction == "right" then edx = 1 end
            
            -- Movimiento en X del enemigo
            if edx ~= 0 then
                local newX = enemy.x + edx * enemy.speed * dt
                local canMoveX = true
                
                for _, wall in ipairs(steelWalls) do
                    if checkCollisionRectangles(newX, enemy.y, enemy.width, enemy.height, 
                                              wall.x, wall.y, wall.width, wall.height) then
                        canMoveX = false
                        enemy.direction = math.random() > 0.5 and "up" or "down"
                        break
                    end
                end
                
                for _, wall in ipairs(brickWalls) do
                    if checkCollisionRectangles(newX, enemy.y, enemy.width, enemy.height, 
                                              wall.x, wall.y, wall.width, wall.height) then
                        canMoveX = false
                        enemy.direction = math.random() > 0.5 and "up" or "down"
                        break
                    end
                end
                
                -- Colisión con jugador
                if checkCollisionRectangles(newX, enemy.y, enemy.width, enemy.height, 
                                          player.x, player.y, player.width, player.height) then
                    canMoveX = false
                    enemy.direction = math.random() > 0.5 and "up" or "down"
                end
                
                -- Colisión con otros enemigos
                for _, otherEnemy in ipairs(enemies) do
                    if otherEnemy ~= enemy and checkCollisionRectangles(newX, enemy.y, enemy.width, enemy.height, 
                                                                      otherEnemy.x, otherEnemy.y, otherEnemy.width, otherEnemy.height) then
                        canMoveX = false
                        enemy.direction = math.random() > 0.5 and "up" or "down"
                        break
                    end
                end
                
                if canMoveX then
                    enemy.x = newX
                end
            end
            
            -- Movimiento en Y del enemigo
            if edy ~= 0 then
                local newY = enemy.y + edy * enemy.speed * dt
                local canMoveY = true
                
                for _, wall in ipairs(steelWalls) do
                    if checkCollisionRectangles(enemy.x, newY, enemy.width, enemy.height, 
                                              wall.x, wall.y, wall.width, wall.height) then
                        canMoveY = false
                        enemy.direction = math.random() > 0.5 and "left" or "right"
                        break
                    end
                end
                
                for _, wall in ipairs(brickWalls) do
                    if checkCollisionRectangles(enemy.x, newY, enemy.width, enemy.height, 
                                              wall.x, wall.y, wall.width, wall.height) then
                        canMoveY = false
                        enemy.direction = math.random() > 0.5 and "left" or "right"
                        break
                    end
                end
                
                -- Colisión con jugador
                if checkCollisionRectangles(enemy.x, newY, enemy.width, enemy.height, 
                                          player.x, player.y, player.width, player.height) then
                    canMoveY = false
                    enemy.direction = math.random() > 0.5 and "left" or "right"
                end
                
                -- Colisión con otros enemigos
                for _, otherEnemy in ipairs(enemies) do
                    if otherEnemy ~= enemy and checkCollisionRectangles(enemy.x, newY, enemy.width, enemy.height, 
                                                                      otherEnemy.x, otherEnemy.y, otherEnemy.width, otherEnemy.height) then
                        canMoveY = false
                        enemy.direction = math.random() > 0.5 and "left" or "right"
                        break
                    end
                end
                
                if canMoveY then
                    enemy.y = newY
                end
            end
        end
        
        -- Actualizar proyectiles
        for i = #projectiles, 1, -1 do
            local proj = projectiles[i]
            
            -- Mover proyectil según dirección
            if proj.direction == "up" then
                proj.y = proj.y - proj.speed * dt
            elseif proj.direction == "down" then
                proj.y = proj.y + proj.speed * dt
            elseif proj.direction == "left" then
                proj.x = proj.x - proj.speed * dt
            elseif proj.direction == "right" then
                proj.x = proj.x + proj.speed * dt
            end
            
            -- Colisión con muros de acero
            for _, wall in ipairs(steelWalls) do
                if checkCollisionRectangles(proj.x, proj.y, proj.width, proj.height, 
                                          wall.x, wall.y, wall.width, wall.height) then
                    table.remove(projectiles, i)
                    break
                end
            end
            
            -- Colisión con ladrillos (destruirlos)
            for j = #brickWalls, 1, -1 do
                local wall = brickWalls[j]
                if checkCollisionRectangles(proj.x, proj.y, proj.width, proj.height, 
                                          wall.x, wall.y, wall.width, wall.height) then
                    table.remove(brickWalls, j)
                    table.remove(projectiles, i)
                    break
                end
            end
            
            -- Colisión con tanques enemigos
            if proj.fromPlayer then
                for j = #enemies, 1, -1 do
                    local enemy = enemies[j]
                    if checkCollisionRectangles(proj.x, proj.y, proj.width, proj.height, 
                                              enemy.x, enemy.y, enemy.width, enemy.height) then
                        table.remove(enemies, j)
                        table.remove(projectiles, i)
                        score = score + 100
                        break
                    end
                end
            else
                -- Colisión con jugador
                if checkCollisionRectangles(proj.x, proj.y, proj.width, proj.height, 
                                          player.x, player.y, player.width, player.height) then
                    gameState = "gameover"
                    table.remove(projectiles, i)
                    break
                end
            end
            
            -- Colisión con base
            if base and not base.destroyed and checkCollisionRectangles(proj.x, proj.y, proj.width, proj.height, 
                                                                     base.x, base.y, base.width, base.height) then
                base.destroyed = true
                base.color = {0.3, 0.3, 0.3}
                gameState = "gameover"
                table.remove(projectiles, i)
            end
            
            -- Eliminar proyectiles fuera de pantalla
            if proj.x < -50 or proj.x > love.graphics.getWidth() + 50 or 
               proj.y < -50 or proj.y > love.graphics.getHeight() + 50 then
                table.remove(projectiles, i)
            end
        end
        
        -- Verificar victoria
        if #enemies == 0 then
            gameState = "victory"
        end
    end
end

function love.draw()
    -- Dibujar fondo
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Dibujar base
    if base then
        love.graphics.setColor(base.color)
        love.graphics.rectangle("fill", base.x, base.y, base.width, base.height)
        -- Detalles de la base
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.rectangle("line", base.x, base.y, base.width, base.height)
        love.graphics.line(base.x, base.y, base.x + base.width, base.y + base.height)
        love.graphics.line(base.x + base.width, base.y, base.x, base.y + base.height)
    end
    
    -- Dibujar muros de acero
    for _, wall in ipairs(steelWalls) do
        love.graphics.setColor(wall.color)
        love.graphics.rectangle("fill", wall.x, wall.y, wall.width, wall.height)
        -- Patrón de acero
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("line", wall.x, wall.y, wall.width, wall.height)
        love.graphics.line(wall.x, wall.y + wall.height/2, wall.x + wall.width, wall.y + wall.height/2)
        love.graphics.line(wall.x + wall.width/2, wall.y, wall.x + wall.width/2, wall.y + wall.height)
    end
    
    -- Dibujar ladrillos
    for _, wall in ipairs(brickWalls) do
        love.graphics.setColor(wall.color)
        love.graphics.rectangle("fill", wall.x, wall.y, wall.width, wall.height)
        -- Patrón de ladrillos
        love.graphics.setColor(0.7, 0.4, 0.1)
        love.graphics.rectangle("line", wall.x, wall.y, wall.width, wall.height)
        love.graphics.line(wall.x + wall.width/2, wall.y, wall.x + wall.width/2, wall.y + wall.height)
        love.graphics.line(wall.x, wall.y + wall.height/2, wall.x + wall.width, wall.y + wall.height/2)
    end
    
    -- Dibujar enemigos
    for _, enemy in ipairs(enemies) do
        love.graphics.setColor(enemy.color)
        love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.width, enemy.height)
        -- Cañón del tanque
        love.graphics.setColor(0.5, 0, 0)
        drawTankGun(enemy.x, enemy.y, enemy.width, enemy.height, enemy.direction)
    end
    
    -- Dibujar jugador
    if player then
        love.graphics.setColor(player.color)
        love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
        -- Cañón del tanque
        love.graphics.setColor(0, 0.5, 0)
        drawTankGun(player.x, player.y, player.width, player.height, player.direction)
    end
    
    -- Dibujar proyectiles
    for _, proj in ipairs(projectiles) do
        love.graphics.setColor(proj.color)
        love.graphics.rectangle("fill", proj.x, proj.y, proj.width, proj.height)
    end
    
    -- UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Puntaje: " .. score, 10, 10)
    love.graphics.print("Enemigos: " .. #enemies, 10, 30)
    
    if gameState == "gameover" then
        love.graphics.setColor(1, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("GAME OVER", love.graphics.getWidth()/2 - 40, love.graphics.getHeight()/2 - 20)
        love.graphics.print("Presiona R para reiniciar", love.graphics.getWidth()/2 - 80, love.graphics.getHeight()/2 + 10)
    elseif gameState == "victory" then
        love.graphics.setColor(0, 0.5, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("VICTORIA!", love.graphics.getWidth()/2 - 40, love.graphics.getHeight()/2 - 20)
        love.graphics.print("Presiona R para reiniciar", love.graphics.getWidth()/2 - 80, love.graphics.getHeight()/2 + 10)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "r" and (gameState == "gameover" or gameState == "victory") then
        love.load()
    elseif key == "space" and gameState == "playing" and player and player.cooldown <= 0 then
        createProjectile(player.x + player.width/2, player.y + player.height/2, player.direction, true)
        player.cooldown = 0.5  -- Cooldown de medio segundo
    end
end

function createProjectile(x, y, direction, fromPlayer)
    local proj = {
        x = x - 2,  -- Centrar el proyectil
        y = y - 2,
        width = 4,
        height = 4,
        speed = 300,
        direction = direction,
        fromPlayer = fromPlayer,
        color = fromPlayer and {1, 1, 1} or {1, 0.5, 0.5}  -- Blanco para jugador, rosa claro para enemigos
    }
    table.insert(projectiles, proj)
end

function drawTankGun(x, y, width, height, direction)
    local gunX, gunY, gunW, gunH
    
    if direction == "up" then
        gunX = x + width/2 - 2
        gunY = y - 8
        gunW = 4
        gunH = 8
    elseif direction == "down" then
        gunX = x + width/2 - 2
        gunY = y + height
        gunW = 4
        gunH = 8
    elseif direction == "left" then
        gunX = x - 8
        gunY = y + height/2 - 2
        gunW = 8
        gunH = 4
    elseif direction == "right" then
        gunX = x + width
        gunY = y + height/2 - 2
        gunW = 8
        gunH = 4
    end
    
    love.graphics.rectangle("fill", gunX, gunY, gunW, gunH)
end

-- Funciones de colisión
function checkCollisionRectangles(r1x, r1y, r1w, r1h, r2x, r2y, r2w, r2h)
    return r1x < r2x + r2w and
           r1x + r1w > r2x and
           r1y < r2y + r2h and
           r1y + r1h > r2y
end