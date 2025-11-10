-- Primero definimos las variables globales principales
GAME_WIDTH = 1280
GAME_HEIGHT = 720
ENTITY_SIZE = 48
ITEM_SPAWN_CHANCE = 0.3
BG_COLOR = { 0.04, 0, 0.13 }

-- Textos de objetivos
ObjectivesText = {
    survival = "Survive the time limit",
    elimination = "Eliminate all enemies",
    collectData = "Collect all data caches"
}

GAME_TITLE = "Astra Defiant"
GAME_BRIEF = {
    "THE YEAR IS 2154.",
    "HUMANITY'S GOLDEN AGE OF SPACE EXPLORATION",
    "HAS COME TO A SUDDEN, VIOLENT END.",
    "",
    "THE XENOTYPES - AN ANCIENT SWARM INTELLIGENCE -",
    "HAVE AWAKENED. THEY CONSUME WORLDS, LEAVE ONLY DUST.",
    "",
    "EARTH'S FLEET HAS FALLEN. COLONIES ARE SILENT.",
    "",
    "YOU ARE THE LAST ACTIVE FIGHTER OF THE",
    "ORBITAL DEFENSE INITIATIVE - CODENAME: 'DEFIANT'.",
    "",
    "YOUR MISSION: HOLD THE LINE AT THE SOLAR GATE,",
    "THE FINAL BARRIER BETWEEN THE SWARM AND EARTH.",
    "",
    "SURVIVE. ENDURE. DEFY." 
}

-- Lista completa de imágenes
IMAGE_LIST = { -- ships
    {
        name = 'ship_yellow',
        src = 'assets/images/ships/ship_yellow.png'
    }, {
    name = 'ship_yellow2',
    src = 'assets/images/ships/ship_yellow2.png'
}, {
    name = 'ship_blue',
    src = 'assets/images/ships/ship_blue.png'
}, {
    name = 'ship_gray',
    src = 'assets/images/ships/ship_gray.png'
}, {
    name = 'ship_green',
    src = 'assets/images/ships/ship_green.png'
}, {
    name = 'ship_orange',
    src = 'assets/images/ships/ship_orange.png'
}, {
    name = 'ship_purple',
    src = 'assets/images/ships/ship_purple.png'
}, {
    name = 'ship_red',
    src = 'assets/images/ships/ship_red.png'
}, {
    name = 'ship_white',
    src = 'assets/images/ships/ship_white.png'
}, {
    name = 'ship_brown',
    src = 'assets/images/ships/ship_brown.png'
}, -- not in use ships
    {
        name = 'Dove',
        src = 'assets/images/ships/Dove.png'
    }, {
    name = 'Ligher',
    src = 'assets/images/ships/Ligher.png'
}, {
    name = 'Ninja',
    src = 'assets/images/ships/Ninja.png'
}, -- orbs
    {
        name = 'orb_yellow',
        src = 'assets/images/items/orb_yellow.png'
    }, {
    name = 'orb_blue',
    src = 'assets/images/items/orb_blue.png'
}, {
    name = 'orb_red',
    src = 'assets/images/items/orb_red.png'
}, {
    name = 'orb_green',
    src = 'assets/images/items/orb_green.png'
}, {
    name = 'orb_orange',
    src = 'assets/images/items/orb_orange.png'
}, {
    name = 'orb_purple',
    src = 'assets/images/items/orb_purple.png'
}, {
    name = 'orb_white',
    src = 'assets/images/items/orb_white.png'
}, {
    name = 'orb_gray',
    src = 'assets/images/items/orb_gray.png'
}, {
    name = 'orb_black',
    src = 'assets/images/items/orb_black.png'
}, {
    name = 'orb_pink',
    src = 'assets/images/items/orb_pink.png'
}, -- bg
    {
        name = 'bg_title',
        src = 'assets/images/bg/bg_title.png'
    }, {
    name = 'bg_intro',
    src = 'assets/images/bg/bg_intro.png'
}, {
    name = 'bg_space',
    src = 'assets/images/bg/bg_space_blue.jpg'
}, {
    name = 'bg_ice',
    src = 'assets/images/bg/bg_ice.png'
}, {
    name = 'bg_ion',
    src = 'assets/images/bg/bg_ion.png'
}, {
    name = 'bg_asteroids',
    src = 'assets/images/bg/bg_asteroids.png'
}, {
    name = 'bg_stars_purple',
    src = 'assets/images/bg/bg_stars_purple.png'
}, {
    name = 'bg_stars_blue',
    src = 'assets/images/bg/bg_stars_blue.png'
}, {
    name = 'bg_stars_red',
    src = 'assets/images/bg/bg_stars_red.png'
}, {
    name = 'bg_stars_orange',
    src = 'assets/images/bg/bg_stars_orange.png'
}, {
    name = 'bg_stars_green',
    src = 'assets/images/bg/bg_stars_green.png'
}, -- items (power-ups)
    {
        name = 'Item_Powerup_18',
        src = 'assets/images/items/Item_Powerup_18.png'
    }, {
    name = 'Item_Powerup_26',
    src = 'assets/images/items/Item_Powerup_26.png'
}, {
    name = 'Item_Powerup_28',
    src = 'assets/images/items/Item_Powerup_28.png'
}, {
    name = 'Item_Powerup_Drop_0',
    src = 'assets/images/items/Item_Powerup_Drop_0.png'
}, {
    name = 'Item_Powerup_Shield_2',
    src = 'assets/images/items/Item_Powerup_Shield_2.png'
}, {
    name = 'Item_Powerup_Weapon_5',
    src = 'assets/images/items/Item_Powerup_Weapon_5.png'
}, {
    name = 'Item_Powerup_Weapon_8',
    src = 'assets/images/items/Item_Powerup_Weapon_8.png'
}, {
    name = 'Item_Box_Gem_0',
    src = 'assets/images/items/Item_Box_Gem_0.png'
}, {
    name = 'data_cache',
    src = 'assets/images/items/data_cache.png'
},
    {
        name = 'energy_shield',
        src = 'assets/images/items/energy_shield.png'
    },
}

-- Lista completa de sonidos (usaremos placeholders)
SOUND_LIST = { {
    name = "shoot",
    src = "assets/sounds/effects/shot.wav"
}, {
    name = "powerup",
    src = "assets/sounds/effects/coin.wav"
}, {
    name = "explosion",
    src = "assets/sounds/effects/explosion.ogg"
}, {
    name = "menu",
    src = "assets/sounds/effects/menu.wav"
}, {
    name = "bg",
    src = "assets/sounds/music/bg.wav"
}, {
    name = "shield",
    src = "assets/sounds/effects/shield.wav"
}, {
    name = "warpout",
    src = "assets/sounds/effects/warpout.ogg"
} }

local canvas = nil -- Canvas for rendering
local scale = 1
local scaleX, scaleY = 1, 1
local offsetX, offsetY = 0, 0

function love.load()
    math.randomseed(os.time())

    SetupViewport()

    CurrentShader = nil

    -- >>> AGREGAR: Definir el shader neon global <<<
    NeonShader = love.graphics.newShader([[
        extern number neonIntensity = 0.8;
        extern number time;

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec4 pixel = Texel(texture, texture_coords);

            // Efecto de brillo neon
            float brightness = (pixel.r + pixel.g + pixel.b) / 3.0;
            float pulse = sin(time * 3.0) * 0.1 + 0.9; // Parpadeo sutil

            // Aumentar saturación y contraste
            vec3 boosted = pixel.rgb * (1.0 + neonIntensity * 0.5);
            boosted = mix(pixel.rgb, boosted, neonIntensity);

            // Aplicar el pulso
            boosted *= pulse;

            return vec4(boosted, pixel.a);
        }
    ]])

    StrongNeonShader = love.graphics.newShader([[
        extern number neonIntensity = 1.2;
        extern number time;
        extern vec3 glowColor = vec3(0.3, 0.5, 1.0);

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec4 pixel = Texel(texture, texture_coords);

            // Detectar bordes y áreas brillantes
            float edge = 0.0;
            for (int x = -1; x <= 1; x++) {
                for (int y = -1; y <= 1; y++) {
                    if (x != 0 || y != 0) {
                        vec2 offset = vec2(x, y) / love_ScreenSize.xy;
                        vec4 neighbor = Texel(texture, texture_coords + offset);
                        edge += length(pixel.rgb - neighbor.rgb);
                    }
                }
            }
            edge = clamp(edge * 2.0, 0.0, 1.0);

            // Combinar color original con glow
            vec3 finalColor = mix(pixel.rgb, glowColor, edge * neonIntensity);
            float alpha = max(pixel.a, edge * 0.3);

            // Efecto de pulso sutil
            float pulse = sin(time * 4.0) * 0.05 + 0.95;
            finalColor *= pulse;

            return vec4(finalColor, alpha);
        }
    ]])

    CurrentShader = NeonShader

    Json = require("lib.json")

    Serpent = require("serpent")

    -- Cargar módulos core y asignarlos a variables globales
    DrawManager = require("core.DrawManager")
    KeyManager = require("core.KeyManager")
    AudioManager = require("core.AudioManager")
    ImageManager = require("core.ImageManager")
    InputManager = require("core.InputManager")
    Utils = require("core.Utils")
    FSM = require("core.FSM")
    BaseEntity = require("core.BaseEntity")
    BaseScreen = require("core.BaseScreen")
    TaskSystem = require("core.TaskSystem")
    CheatManager = require("core.CheatManager")
    Sprite = require("core.Sprite")

    -- Cargar tasks
    PowerupTasks = require("tasks.PowerupTasks")
    EntityTasks = require("tasks.EntityTasks")

    -- Cargar datos del juego
    Levels = require("data.Levels")
    EnemyTypes = require("data.EnemyTypes")
    ItemTypes = require("data.ItemTypes")

    -- Cargar pantallas
    StartScreen = require("screens.StartScreen")
    LoadScreen = require("screens.LoadScreen")
    MenuScreen = require("screens.MenuScreen")
    IntroScreen = require("screens.IntroScreen")
    GameScreen = require("screens.GameScreen")

    GameOverScreen = require("screens.GameOverScreen")
    GameEndScreen = require("screens.GameEndScreen")
    SettingScreen = require("screens.SettingScreen")

    LevelSelectScreen = require("screens.LevelSelectScreen")
    GamePlayScreen = require("screens.GamePlayScreen")
    GamePauseScreen = require("screens.GamePauseScreen")
    LevelCompletedScreen = require("screens.LevelCompletedScreen")

    -- Inicializar managers
    DrawManager:init()
    KeyManager:init()
    AudioManager:init(SOUND_LIST)
    ImageManager:init(IMAGE_LIST)

    -- >>> AGREGAR: Inicialización del gamepad <<<

    CurrenttGamepad = nil
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        CurrenttGamepad = joysticks[1]
        print("Gamepad conectado: " .. CurrenttGamepad:getName())
    end

    -- Cargar estado del juego
    LoadGame()

    ScreenManager = FSM:new("main")
    GameScreenManager = FSM:new("game")

    SetupScreens()

    ScreenManager:change("start")
end

-- >>> AGREGAR: Estas nuevas funciones de eventos <<<
function love.joystickadded(joystick)
    print("Gamepad conectado: " .. joystick:getName())
    if CurrenttGamepad == nil then
        CurrenttGamepad = joystick
    end
end

function love.joystickremoved(joystick)
    print("Gamepad desconectado: " .. joystick:getName())
    if CurrenttGamepad == joystick then
        CurrenttGamepad = nil
    end
end

function love.update(dt)
    ScreenManager:update(dt)

    -- >>> AGREGAR: Actualizar tiempo en el shader <<<
    if CurrentShader then
        CurrentShader:send("time", love.timer.getTime())
    end
end

function love.draw()
    if canvas == nil then
        return
    end

    -- Dibujar todo en el canvas
    love.graphics.setCanvas(canvas)
    love.graphics.clear()

    love.graphics.clear(0.04, 0, 0.13) -- BG_COLOR similar
    ScreenManager:render()

    -- Mostrar FPS
    love.graphics.setColor(1, 1, 1)
    -- fps on bottom right
    DrawManager:fillText("FPS: " .. tostring(love.timer.getFPS()), GAME_WIDTH - 10, GAME_HEIGHT - 10, {
        align = 'right',
        baseline = 'bottom',
        color = 'white'
    })

    love.graphics.setCanvas()

    -- Dibujar el canvas escalado en la ventana
    -- love.graphics.setColor(1, 1, 1)
    -- >>> FASE 2: Aplicar shader al canvas escalado <<<
    -- love.graphics.setShader(CurrentShader)
    love.graphics.draw(canvas, offsetX, offsetY, 0, scale, scale)
    love.graphics.setShader()
end

function love.keypressed(key)
    if key == "f11" then
        ToggleFullscreen()
        return
    end

    if key == "f10" then
        DebugGameState()
        return
    end

    if key == "f9" then
        CurrentShader = (CurrentShader == NeonShader) and StrongNeonShader or NeonShader
        return
    end

    local action = InputManager:getActionForKey(key)
    KeyManager:keypressed(action)
    ScreenManager:input("keydown", action, key)
end

function love.keyreleased(key)
    local action = InputManager:getActionForKey(key)
    KeyManager:keyreleased(action)
    ScreenManager:input("keyup", action, key)
end

-- >>> AGREGAR: Manejo de botones presionados <<<
function love.gamepadpressed(joystick, button)
    if joystick == CurrenttGamepad then
        local b = "button_" .. button
        local action = InputManager:getActionForKey(b)
        KeyManager:keypressed(action)
        ScreenManager:input("keydown", action, b)
    end
end

-- >>> AGREGAR: Manejo de botones liberados <<<
function love.gamepadreleased(joystick, button)
    if joystick == CurrenttGamepad then
        local b = "button_" .. button
        local action = InputManager:getActionForKey(b)
        KeyManager:keyreleased(action)
        ScreenManager:input("keyup", action, b)
    end
end

function love.resize(w, h)
    UpdateViewport()
end

-- Configuración de pantallas
function SetupScreens()
    -- Pantallas principales
    ScreenManager:add("start", StartScreen)
    ScreenManager:add("load", LoadScreen)
    ScreenManager:add("menu", MenuScreen)
    ScreenManager:add("intro", IntroScreen)
    ScreenManager:add("gameover", GameOverScreen)
    ScreenManager:add("game_end", GameEndScreen)
    ScreenManager:add("settings", SettingScreen)
    ScreenManager:add("game", GameScreen)

    -- Pantallas del juego
    GameScreenManager:add("game_level_select", LevelSelectScreen)
    GameScreenManager:add("game_play", GamePlayScreen)
    GameScreenManager:add("game_pause", GamePauseScreen)
    GameScreenManager:add("game_level_completed", LevelCompletedScreen)
end

-- Sistema de guardado simplificado
function LoadGame()
    print("LoadGame: " .. love.filesystem.getSaveDirectory())
    if love.filesystem.getInfo("savegame.json") then
        print("Archivo de guardado encontrado. Cargando...")

        local data = love.filesystem.read("savegame.json")
        local success, gameState = pcall(Json.decode, data)
        if success and gameState then
            GameState = gameState
            return
        end
    else
        print("No se encontró archivo de guardado.")
        -- Si no existe el archivo, crear uno por defecto
        ResetGame()
    end
end

function SaveGame()
    local data = Json.encode(GameState)
    love.filesystem.write("savegame.json", data)
    print("SaveGame: " .. love.filesystem.getSaveDirectory())
end

function ResetGame()
    GameState = {
        levelsUnlocked = {
            [1] = true
        },
        levelsCompleted = {}
    }
    SaveGame()
end

function SetupViewport()
    if not canvas then
        canvas = love.graphics.newCanvas(GAME_WIDTH, GAME_HEIGHT)
    end
    UpdateViewport()
end

function UpdateViewport()
    local windowWidth, windowHeight = love.graphics.getDimensions()

    -- Calcular escala manteniendo aspect ratio
    scaleX = windowWidth / GAME_WIDTH
    scaleY = windowHeight / GAME_HEIGHT
    scale = math.min(scaleX, scaleY) -- Usar la escala más pequeña

    -- Calcular offsets para centrar
    offsetX = (windowWidth - (GAME_WIDTH * scale)) / 2
    offsetY = (windowHeight - (GAME_HEIGHT * scale)) / 2
end

function ToggleFullscreen()
    IsFullscreen = not IsFullscreen

    if IsFullscreen then
        -- Entrar en pantalla completa
        local success = love.window.setFullscreen(true, "desktop")
        if success then
            print("🖥️  Modo pantalla completa activado")
        end
    else
        -- Salir de pantalla completa
        love.window.setFullscreen(false)
        love.window.setMode(GAME_WIDTH, GAME_HEIGHT, {
            resizable = true,
            minwidth = GAME_WIDTH,
            minheight = GAME_HEIGHT
        })
        print("📺 Modo ventana activado")
    end

    -- Actualizar viewport
    UpdateViewport()
end

-- Función para debug
function DebugGameState()
    print("=== GAME STATE ===")
    print("Levels Unlocked:")
    for levelId, unlocked in pairs(GameState.levelsUnlocked) do
        print("  Level " .. levelId .. ": " .. tostring(unlocked))
    end
    print("Levels Completed:")
    for levelId, levelData in pairs(GameState.levelsCompleted) do
        print("  Level " .. levelId .. ": " .. tostring(levelData.completed) .. " (score: " .. (levelData.score or 0) ..
            ")")
    end
    print("==================")
end
