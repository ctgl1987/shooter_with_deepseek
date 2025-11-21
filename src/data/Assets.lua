-- Lista completa de imágenes

local ships = { {
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
}, {
    name = 'Dove',
    src = 'assets/images/ships/Dove.png'
}, {
    name = 'Ligher',
    src = 'assets/images/ships/Ligher.png'
}, {
    name = 'Ninja',
    src = 'assets/images/ships/Ninja.png'
}, {
    name = 'Turtle',
    src = 'assets/images/ships/Turtle.png'
}, {
    name = 'new_ship_blue',
    src = 'assets/images/ships/new_ship_blue.png'
}, {
    name = 'new_ship_red',
    src = 'assets/images/ships/new_ship_red.png'
}, {
    name = 'new_ship_green',
    src = 'assets/images/ships/new_ship_green.png'
}, {
    name = 'new_ship_yellow',
    src = 'assets/images/ships/new_ship_yellow.png'
}, {
    name = 'new_ship_purple',
    src = 'assets/images/ships/new_ship_purple.png'
}, {
    name = 'new_ship_orange',
    src = 'assets/images/ships/new_ship_orange.png'
}, {
    name = 'new_ship_brown',
    src = 'assets/images/ships/new_ship_brown.png'
}, {
    name = 'new_ship_gray',
    src = 'assets/images/ships/new_ship_gray.png'
}, {
    name = 'new_ship_white',
    src = 'assets/images/ships/new_ship_white.png'
} }

local items = { {
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
} }

local bgImages = { {
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
    name = 'bg_lunar_base',
    src = 'assets/images/bg/bg_lunar_base.png'
}, {
    name = 'bg_fog',
    src = 'assets/images/bg/bg_fog.png'
}, {
    name = 'bg_stars_green',
    src = 'assets/images/bg/bg_stars_green.png'
} }

local itemImages = { {
    name = 'item_bomb',
    src = 'assets/images/items/item_bomb.png'
}, {
    name = 'item_freeze',
    src = 'assets/images/items/item_freeze.png'
}, {
    name = 'item_triple_shot',
    src = 'assets/images/items/item_triple_shot.png'
}, {
    name = 'item_drain_life',
    src = 'assets/images/items/item_drain_life.png'
}, {
    name = 'item_speed_boost',
    src = 'assets/images/items/item_speed_boost.png'
}, {
    name = 'item_repair_kit',
    src = 'assets/images/items/item_repair_kit.png'
}, {
    name = 'item_rapid_fire',
    src = 'assets/images/items/item_rapid_fire.png'
}, {
    name = 'item_data_cache',
    src = 'assets/images/items/item_data_cache.png'
}, {
    name = 'item_energy_shield',
    src = 'assets/images/items/item_energy_shield.png'
} }

local characters = { {
    name = 'character_player',
    src = 'assets/images/characters/character_player.png'
} }

IMAGE_LIST = {}

-- Add all ships
for i, ship in ipairs(ships) do
    IMAGE_LIST[#IMAGE_LIST + 1] = ship
end

-- Add all items
for i, item in ipairs(items) do
    IMAGE_LIST[#IMAGE_LIST + 1] = item
end

-- Add all background images
for i, bg in ipairs(bgImages) do
    IMAGE_LIST[#IMAGE_LIST + 1] = bg
end

-- Add all item images
for i, itemImg in ipairs(itemImages) do
    IMAGE_LIST[#IMAGE_LIST + 1] = itemImg
end

-- Add all characters
for i, character in ipairs(characters) do
    IMAGE_LIST[#IMAGE_LIST + 1] = character
end


-- Lista completa de sonidos (usaremos placeholders)
SOUND_LIST = { {
    name = "shoot",
    src = "assets/sounds/effects/shot.wav"
}, {
    name = "powerup",
    src = "assets/sounds/effects/coin.wav"
}, {
    name = "explosion",
    src = "assets/sounds/effects/explosion.ogg",
    volume = 0
}, {
    name = "menu",
    src = "assets/sounds/effects/menu.wav"
}, {
    name = "bg",
    src = "assets/sounds/music/bg.wav",
}, {
    name = "shield",
    src = "assets/sounds/effects/shield.wav"
}, {
    name = "warpout",
    src = "assets/sounds/effects/warpout.ogg"
} }
