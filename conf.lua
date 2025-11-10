function love.conf(t)
    t.window.title = "Astra Defiant"
    t.identity = "AstraDefiant"
    t.window.width = 1280
    t.window.height = 720
    t.window.highdpi = true
    t.window.resizable = true
    t.modules.joystick = true
    t.window.icon = "assets/icon.png"
    -- t.window.fullscreen = true
    -- t.window.fullscreentype = "desktop"  -- Pantalla completa "borderless"
    t.console = true
end