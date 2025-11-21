-- Primero definimos las variables globales principales
GAME_WIDTH = 1280
GAME_HEIGHT = 720
ENTITY_SIZE = 48
ITEM_SPAWN_CHANCE = 0.3
BG_COLOR = "#0A0022"

local canvas = nil -- Canvas for rendering
local scale = 1
local scaleX, scaleY = 1, 1
local offsetX, offsetY = 0, 0

local moonshine = require("lib.moonshine")

local shaderEnabled = true

function love.load()
    math.randomseed(os.time())

    Utils = require("src.core.Utils")
        
    Json = require("lib.json")
    Lume = require("lib.lume")    

    require("src.data.Texts") -- Cargar textos del juego
    require("src.data.Assets")

    print("")
    print("*****************************")
    print("*** " .. GAME_TITLE .. " ***")
    print("*****************************")

    
    -- Cargar módulos core y asignarlos a variables globales
    DrawManager = require("src.core.DrawManager")
    KeyManager = require("src.core.KeyManager")
    AudioManager = require("src.core.AudioManager")
    ImageManager = require("src.core.ImageManager")
    InputManager = require("src.core.InputManager")
    ScreenManager = require("src.core.ScreenManager")

    UI = require("src.core.UI")
    
    CurrenttGamepad = nil
    
    LoadGame()

    SetFullScreen(GameState.fullscreen)

    SetupViewport()

    AudioManager:init(SOUND_LIST)

    AudioManager:setMute(not GameState.sound)

    ImageManager:init(IMAGE_LIST)

    ImageManager:load(function()
    end)

    CrtEffect = moonshine.chain(moonshine.effects.scanlines)
    CrtEffect.scanlines.opacity = 0.0

    BlurEffect = moonshine.chain(moonshine.effects.boxblur)
    BlurEffect.boxblur.radius = 5



    BaseEntity = require("src.core.BaseEntity")
    BaseScreen = require("src.core.BaseScreen")
    TaskSystem = require("src.core.TaskSystem")
    CheatManager = require("src.core.CheatManager")
    Sprite = require("src.core.Sprite")

    -- Cargar tasks
    PowerupTasks = require("src.tasks.PowerupTasks")
    EntityTasks = require("src.tasks.EntityTasks")

    -- Cargar datos del juego
    Levels = require("src.data.Levels")
    EnemyTypes = require("src.data.EnemyTypes")
    ItemTypes = require("src.data.ItemTypes")

    -- Cargar pantallas
    StartScreen = require("src.screens.StartScreen")
    MenuScreen = require("src.screens.MenuScreen")
    IntroScreen = require("src.screens.IntroScreen")
    GameScreen = require("src.screens.GameScreen")

    GameOverScreen = require("src.screens.GameOverScreen")
    GameEndScreen = require("src.screens.GameEndScreen")
    SettingScreen = require("src.screens.SettingScreen")
    EnemyShowcaseScreen = require("src.screens.EnemyShowcaseScreen")

    LevelSelectScreen = require("src.screens.LevelSelectScreen")
    GamePlayScreen = require("src.screens.GamePlayScreen")
    GamePauseScreen = require("src.screens.GamePauseScreen")
    LevelCompletedScreen = require("src.screens.LevelCompletedScreen")

    -- Inicializar managers
    DrawManager:init()
    KeyManager:init()

    SetupScreens()

    ScreenManager:change("start")
end

function love.update(dt)
    ScreenManager:update(dt)
    UpdateViewport()
end

function love.draw()
    if canvas == nil then
        return
    end

    -- Dibujar en el canvas
    love.graphics.setCanvas(canvas)

    -- Limpiar el canvas
    -- love.graphics.clear()

    CrtEffect(function()
        -- Limpiar con color de fondo
        DrawManager:fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, BG_COLOR)
        -- Dibujar la pantalla
        ScreenManager:render()
        -- Mostrar FPS
        DrawManager:fillText("FPS: " .. tostring(love.timer.getFPS()), GAME_WIDTH - 10, GAME_HEIGHT - 10, {
            align = 'right',
            baseline = 'bottom',
            color = '#FFFFFF'
        })
    end)

    love.graphics.setCanvas()

    -- Dibujar el canvas escalado en la ventana
    love.graphics.draw(canvas, offsetX, offsetY, 0, scale, scale)

    -- debug: mostrar cuantos gamepads conectados y sus nombres
    -- local joysticks = love.joystick.getJoysticks()

    -- love.graphics.print("Gamepads connected: " .. #joysticks, 10, 10)
    -- for i, joystick in ipairs(joysticks) do
    --     love.graphics.print(">" .. joystick:getName(), 10, 10 + i * 20)
    -- end
end

function love.keypressed(key)
    -- ctrl + r to reset game
    if key == "r" and (love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")) then
        love.event.quit('restart')
        return
    end

    if key == "f10" then
        DebugGameState()
        return
    end

    if key == "f9" then
        -- toogle shaders
        if shaderEnabled then
            CrtEffect:disable("crt", "scanlines", "vignette")
            shaderEnabled = false
            print("Shaders disabled")
        else
            CrtEffect:enable("crt", "scanlines", "vignette")
            shaderEnabled = true
            print("Shaders enabled")
        end
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

-- >>> AGREGAR: Manejo de conexión y desconexión de gamepads <<<
function love.joystickadded(joystick)
    print("Gamepad conectado: " .. joystick:getName())
    -- if name includes "fpc" or "accelerometer" return
    local name = joystick:getName():lower()
    if name:find("fpc") or name:find("accelerometer") then
        print("Gamepad ignorado: " .. joystick:getName())
        return
    end
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
    ScreenManager = ScreenManager:new("main")
    GameScreenManager = ScreenManager:new("game")

    -- Pantallas principales
    ScreenManager:add("start", StartScreen)
    ScreenManager:add("menu", MenuScreen)
    ScreenManager:add("intro", IntroScreen)
    ScreenManager:add("gameover", GameOverScreen)
    ScreenManager:add("game_end", GameEndScreen)
    ScreenManager:add("settings", SettingScreen)
    ScreenManager:add("game", GameScreen)
    ScreenManager:add("enemy_showcase", EnemyShowcaseScreen)

    -- Pantallas del juego
    GameScreenManager:add("game_level_select", LevelSelectScreen)
    GameScreenManager:add("game_play", GamePlayScreen)
    GameScreenManager:add("game_pause", GamePauseScreen)
    GameScreenManager:add("game_level_completed", LevelCompletedScreen)
end

-- Sistema de guardado simplificado
function LoadGame()
    print("> Checking save directory: " .. love.filesystem.getSaveDirectory())
    if not love.filesystem.getInfo("savegame.json") then
        ResetGame()
        return
    end

    print("> Save file found. Loading...")

    local data = love.filesystem.read("savegame.json")
    local success, gameState = pcall(Json.decode, data)
    if success and gameState then
        print("> Game loaded successfully.")
        GameState = gameState
        return
    else
        print("> Error loading save file. Starting new game.")
        ResetGame()
    end
end

function SaveGame()
    local data = Json.encode(GameState)
    love.filesystem.write("savegame.json", data)
    print("> SaveGame: " .. love.filesystem.getSaveDirectory())
end

function ResetGame()
    GameState = {
        sound = false,
        fullscreen = false,
        levelsUnlocked = {
            [1] = true
        },
        levelsCompleted = {}
    }
    print("> No save file found. Starting new game.")
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

function SetFullScreen(enabled)
    IsFullscreen = enabled
    if enabled then
        -- Entrar en pantalla completa
        local success = love.window.setFullscreen(true, "desktop")
        if success then
            print("> Switch to Fullscreen mode!")
        end
    else
        -- Salir de pantalla completa
        love.window.setFullscreen(false)
        love.window.setMode(GAME_WIDTH, GAME_HEIGHT, {
            resizable = true
            -- minwidth = GAME_WIDTH,
            -- minheight = GAME_HEIGHT
        })
        print("> Switch to Windowed mode!")
    end

    -- Actualizar viewport
    UpdateViewport()
end

function ToggleFullscreen()
    SetFullScreen(not IsFullscreen)
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
