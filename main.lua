-- Primero definimos las variables globales principales
GAME_WIDTH = 1280
GAME_HEIGHT = 720
ENTITY_SIZE = 48
ITEM_SPAWN_CHANCE = 0.3
BG_COLOR = { 0.04, 0, 0.13 }

local canvas = nil -- Canvas for rendering
local scale = 1
local scaleX, scaleY = 1, 1
local offsetX, offsetY = 0, 0

local moonshine = require("lib.moonshine")

local shaderEnabled = true

function love.load()
    math.randomseed(os.time())

    require("data.Texts")  -- Cargar textos del juego
    require("data.Assets") -- Cargar listas de imágenes y sonidos

    SetupViewport()

    CrtEffect = moonshine.chain(moonshine.effects.scanlines)
    -- CrtEffect.chain(moonshine.effects.ctr)
    -- CrtEffect.chain(moonshine.effects.vignette)
    -- CrtEffect.chain(moonshine.effects.boxblur)
    BlurEffect = moonshine.chain(moonshine.effects.boxblur)

    -- CrtEffect.scanlines.width = 1
    CrtEffect.scanlines.opacity = 0.3
    -- CrtEffect.vignette.radius = 1.2

    Json = require("lib.json")

    Serpent = require("serpent")

    -- Cargar módulos core y asignarlos a variables globales
    DrawManager = require("core.DrawManager")
    KeyManager = require("core.KeyManager")
    AudioManager = require("core.AudioManager")
    ImageManager = require("core.ImageManager")
    InputManager = require("core.InputManager")
    ScreenManager = require("core.ScreenManager")

    Utils = require("core.Utils")

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
    EnemyShowcaseScreen = require("screens.EnemyShowcaseScreen")

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

    -- Aplicar configuración de sonido
    AudioManager:setMute(not GameState.sound)
    -- Aplicar configuración de pantalla completa
    SetFullScreen(GameState.fullscreen)

    ScreenManager = ScreenManager:new("main")
    GameScreenManager = ScreenManager:new("game")

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
end

function love.draw()
    if canvas == nil then
        return
    end

    -- Dibujar en el canvas
    love.graphics.setCanvas(canvas)

    -- Limpiar el canvas
    love.graphics.clear()



    -- CrtEffect(function()
        -- Limpiar con color de fondo
        love.graphics.clear(BG_COLOR)
        -- Dibujar la pantalla
        ScreenManager:render()
        -- Mostrar FPS
        DrawManager:fillText("FPS: " .. tostring(love.timer.getFPS()), GAME_WIDTH - 10, GAME_HEIGHT - 10, {
            align = 'right',
            baseline = 'bottom',
            color = 'white'
        })
    -- end)

    love.graphics.setCanvas()

    -- Dibujar el canvas escalado en la ventana
    love.graphics.draw(canvas, offsetX, offsetY, 0, scale, scale)
end

function love.keypressed(key)
    -- if key == "f11" then
    --     ToggleFullscreen()
    --     return
    -- end

    if key == "f10" then
        DebugGameState()
        return
    end

    if key == "f9" then
        --toogle shaders
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
    ScreenManager:add("enemy_showcase", EnemyShowcaseScreen)

    -- Pantallas del juego
    GameScreenManager:add("game_level_select", LevelSelectScreen)
    GameScreenManager:add("game_play", GamePlayScreen)
    GameScreenManager:add("game_pause", GamePauseScreen)
    GameScreenManager:add("game_level_completed", LevelCompletedScreen)
end

-- Sistema de guardado simplificado
function LoadGame()
    print("LoadGame: " .. love.filesystem.getSaveDirectory())
    if not love.filesystem.getInfo("savegame.json") then
        ResetGame()
        return
    end

    print("Archivo de guardado encontrado. Cargando...")

    local data = love.filesystem.read("savegame.json")
    local success, gameState = pcall(Json.decode, data)
    if success and gameState then
        GameState = gameState
        return
    end
end

function SaveGame()
    local data = Json.encode(GameState)
    love.filesystem.write("savegame.json", data)
    print("SaveGame: " .. love.filesystem.getSaveDirectory())
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
            print("[]  Modo pantalla completa activado")
        end
    else
        -- Salir de pantalla completa
        love.window.setFullscreen(false)
        love.window.setMode(GAME_WIDTH, GAME_HEIGHT, {
            resizable = true,
            minwidth = GAME_WIDTH,
            minheight = GAME_HEIGHT
        })
        print("[] Modo ventana activado")
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
