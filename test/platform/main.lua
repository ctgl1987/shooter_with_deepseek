-- main.lua
function love.load()
    -- Configuración inicial
    love.window.setTitle("Platformer - Love2D")
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Definir el mapa con strings
    map = {
        "                                ",
        "                                ",
        "                                ",
        "                                ",
        "                                ",
        "            p                   ",
        "                                ",
        "                        c       ",
        "                                ",
        "         p      p               ",
        "                                ",
        "    p              p            ",
        "                                ",
        "                    p           ",
        "                                ",
        "        p                       ",
        "                                ",
        "                           c    ",
        "                                ",
        "pppppppppppppppppppppppppppppppp"
    }
    
    -- Tamaño de cada tile
    tileSize = 32
    local mapWidth = #map[1] * tileSize
    local mapHeight = #map * tileSize
    
    -- Centrar la ventana o ajustar tamaño
    love.window.setMode(mapWidth, mapHeight)
    
    -- Inicializar listas
    platforms = {}
    coins = {}
    enemies = {}
    
    -- Procesar el mapa
    for y, row in ipairs(map) do
        for x = 1, #row do
            local char = row:sub(x, x)
            local tileX = (x - 1) * tileSize
            local tileY = (y - 1) * tileSize
            
            if char == "p" then
                -- Plataforma
                table.insert(platforms, {
                    x = tileX, 
                    y = tileY, 
                    width = tileSize, 
                    height = tileSize
                })
            elseif char == "c" then
                -- Moneda
                table.insert(coins, {
                    x = tileX + 8,
                    y = tileY + 8,
                    radius = 8,
                    collected = false
                })
            elseif char == "#" then
                -- Spawn del jugador
                player = {
                    x = tileX,
                    y = tileY,
                    width = 24,
                    height = 32,
                    speed = 200,
                    jumpForce = -400,
                    color = {0.2, 0.6, 1},
                    velocityX = 0,
                    velocityY = 0,
                    isGrounded = false,
                    facing = 1  -- 1: derecha, -1: izquierda
                }
            end
        end
    end
    
    -- Si no se definió spawn del jugador, ponerlo en posición por defecto
    if not player then
        player = {
            x = 100,
            y = 100,
            width = 24,
            height = 32,
            speed = 200,
            jumpForce = -400,
            color = {0.2, 0.6, 1},
            velocityX = 0,
            velocityY = 0,
            isGrounded = false,
            facing = 1
        }
    end
    
    -- Agregar algunos enemigos
    local enemyPositions = {
        {x = 300, y = 500},
        {x = 600, y = 300},
        {x = 800, y = 200}
    }
    
    for _, pos in ipairs(enemyPositions) do
        table.insert(enemies, {
            x = pos.x,
            y = pos.y,
            width = 28,
            height = 28,
            speed = 60,
            color = {1, 0.3, 0.3},
            direction = 1,
            moveDistance = 100,
            startX = pos.x
        })
    end
    
    -- Gravedad
    gravity = 800
    
    -- Cámara
    camera = {x = 0, y = 0}
    
    -- Estado del juego
    gameState = "playing"
    score = 0
    lives = 3
    
    -- Efectos visuales
    jumpParticles = {}
end

function love.update(dt)
    if gameState == "playing" then
        -- Aplicar gravedad
        player.velocityY = player.velocityY + gravity * dt
        
        -- Movimiento horizontal del jugador
        player.velocityX = 0
        if love.keyboard.isDown("left", "a") then
            player.velocityX = -player.speed
            player.facing = -1
        elseif love.keyboard.isDown("right", "d") then
            player.velocityX = player.speed
            player.facing = 1
        end
        
        -- Salto
        if love.keyboard.isDown("up", "w", "space") and player.isGrounded then
            player.velocityY = player.jumpForce
            player.isGrounded = false
            createJumpParticles(player.x + player.width/2, player.y + player.height)
        end
        
        -- MOVIMIENTO SEPARADO: Primero en X
        local newX = player.x + player.velocityX * dt
        local canMoveX = true
        
        for _, platform in ipairs(platforms) do
            if checkCollisionRectangles(newX, player.y, player.width, player.height, 
                                      platform.x, platform.y, platform.width, platform.height) then
                canMoveX = false
                break
            end
        end
        
        if canMoveX then
            player.x = newX
        end
        
        -- Luego en Y
        local newY = player.y + player.velocityY * dt
        local canMoveY = true
        player.isGrounded = false
        
        for _, platform in ipairs(platforms) do
            if checkCollisionRectangles(player.x, newY, player.width, player.height, 
                                      platform.x, platform.y, platform.width, platform.height) then
                canMoveY = false
                
                -- Determinar si está arriba o abajo de la plataforma
                if player.velocityY > 0 then  -- Cayendo
                    player.y = platform.y - player.height
                    player.velocityY = 0
                    player.isGrounded = true
                else  -- Saltando hacia arriba
                    player.velocityY = 0
                end
                break
            end
        end
        
        if canMoveY then
            player.y = newY
        end
        
        -- Actualizar enemigos (movimiento horizontal simple)
        for _, enemy in ipairs(enemies) do
            enemy.x = enemy.x + enemy.speed * enemy.direction * dt
            
            -- Cambiar dirección si se aleja demasiado
            if math.abs(enemy.x - enemy.startX) > enemy.moveDistance then
                enemy.direction = enemy.direction * -1
            end
            
            -- Verificar colisión jugador-enemigo
            if checkCollisionRectangles(player.x, player.y, player.width, player.height,
                                      enemy.x, enemy.y, enemy.width, enemy.height) then
                -- El jugador salta sobre el enemigo
                if player.velocityY > 0 and player.y + player.height < enemy.y + enemy.height/2 then
                    -- Destruir enemigo
                    enemy.toRemove = true
                    player.velocityY = player.jumpForce * 0.7  -- Rebote pequeño
                    score = score + 50
                    createJumpParticles(enemy.x + enemy.width/2, enemy.y + enemy.height)
                else
                    -- El jugador es dañado
                    respawnPlayer()
                    lives = lives - 1
                    if lives <= 0 then
                        gameState = "gameover"
                    end
                end
            end
        end
        
        -- Remover enemigos marcados
        for i = #enemies, 1, -1 do
            if enemies[i].toRemove then
                table.remove(enemies, i)
            end
        end
        
        -- Recolectar monedas
        for i = #coins, 1, -1 do
            local coin = coins[i]
            if not coin.collected then
                local distance = math.sqrt((player.x + player.width/2 - coin.x)^2 + 
                                          (player.y + player.height/2 - coin.y)^2)
                if distance < player.width/2 + coin.radius then
                    coin.collected = true
                    score = score + 10
                    table.remove(coins, i)
                end
            end
        end
        
        -- Actualizar partículas de salto
        for i = #jumpParticles, 1, -1 do
            local particle = jumpParticles[i]
            particle.y = particle.y + particle.speed * dt
            particle.life = particle.life - dt
            if particle.life <= 0 then
                table.remove(jumpParticles, i)
            end
        end
        
        -- Actualizar cámara para seguir al jugador
        camera.x = player.x - love.graphics.getWidth() / 2
        camera.y = player.y - love.graphics.getHeight() / 2
        
        -- Limitar cámara a los bordes del mapa
        camera.x = math.max(0, math.min(camera.x, #map[1] * tileSize - love.graphics.getWidth()))
        camera.y = math.max(0, math.min(camera.y, #map * tileSize - love.graphics.getHeight()))
        
        -- Verificar si el jugador cayó del mapa
        if player.y > love.graphics.getHeight() then
            respawnPlayer()
            lives = lives - 1
            if lives <= 0 then
                gameState = "gameover"
            end
        end
        
        -- Verificar victoria (todas las monedas recolectadas)
        if #coins == 0 and #enemies == 0 then
            gameState = "victory"
        end
    end
end

function love.draw()
    -- Aplicar transformación de cámara
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)
    
    -- Dibujar fondo (cielo)
    love.graphics.setColor(0.4, 0.6, 0.8)
    love.graphics.rectangle("fill", 0, 0, #map[1] * tileSize, #map * tileSize)
    
    -- Dibujar plataformas
    for _, platform in ipairs(platforms) do
        love.graphics.setColor(0.3, 0.7, 0.3)
        love.graphics.rectangle("fill", platform.x, platform.y, platform.width, platform.height)
        
        -- Textura de hierba en la parte superior
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.rectangle("fill", platform.x, platform.y, platform.width, 4)
    end
    
    -- Dibujar monedas
    for _, coin in ipairs(coins) do
        if not coin.collected then
            love.graphics.setColor(1, 0.8, 0)
            love.graphics.circle("fill", coin.x, coin.y, coin.radius)
            love.graphics.setColor(1, 1, 0)
            love.graphics.circle("line", coin.x, coin.y, coin.radius)
        end
    end
    
    -- Dibujar enemigos
    for _, enemy in ipairs(enemies) do
        love.graphics.setColor(enemy.color)
        love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.width, enemy.height)
        
        -- Ojos del enemigo
        love.graphics.setColor(1, 1, 1)
        local eyeOffset = enemy.direction > 0 and 8 or -4
        love.graphics.rectangle("fill", enemy.x + eyeOffset, enemy.y + 8, 4, 4)
        love.graphics.rectangle("fill", enemy.x + eyeOffset, enemy.y + 18, 4, 4)
    end
    
    -- Dibujar jugador
    love.graphics.setColor(player.color)
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
    
    -- Ojos del jugador
    love.graphics.setColor(1, 1, 1)
    local eyeOffset = player.facing > 0 and 14 or 6
    love.graphics.rectangle("fill", player.x + eyeOffset, player.y + 10, 4, 4)
    love.graphics.rectangle("fill", player.x + eyeOffset, player.y + 20, 4, 4)
    
    -- Dibujar partículas
    for _, particle in ipairs(jumpParticles) do
        love.graphics.setColor(1, 1, 1, particle.life)
        love.graphics.rectangle("fill", particle.x, particle.y, 2, 2)
    end
    
    love.graphics.pop()
    
    -- UI (sin transformación de cámara)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Puntaje: " .. score, 10, 10)
    love.graphics.print("Vidas: " .. lives, 10, 30)
    love.graphics.print("Controles: WASD/Flechas, Espacio para saltar", 10, love.graphics.getHeight() - 30)
    
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
        love.graphics.print("Puntaje final: " .. score, love.graphics.getWidth()/2 - 60, love.graphics.getHeight()/2 + 10)
        love.graphics.print("Presiona R para reiniciar", love.graphics.getWidth()/2 - 80, love.graphics.getHeight()/2 + 30)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "r" and (gameState == "gameover" or gameState == "victory") then
        love.load()
    end
end

function respawnPlayer()
    player.x = 100
    player.y = 100
    player.velocityX = 0
    player.velocityY = 0
    player.isGrounded = false
end

function createJumpParticles(x, y)
    for i = 1, 8 do
        table.insert(jumpParticles, {
            x = x + math.random(-10, 10),
            y = y,
            speed = math.random(50, 150),
            life = math.random(0.3, 0.8)
        })
    end
end

-- Funciones de colisión
function checkCollisionRectangles(r1x, r1y, r1w, r1h, r2x, r2y, r2w, r2h)
    return r1x < r2x + r2w and
           r1x + r1w > r2x and
           r1y < r2y + r2h and
           r1y + r1h > r2y
end