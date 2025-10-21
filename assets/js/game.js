//game.js
const _WIDTH = 1280;
const _HEIGHT = 720;
const _SCALE = 1;

const GAME_WIDTH = _WIDTH * _SCALE;
const GAME_HEIGHT = _HEIGHT * _SCALE;


const BG_COLOR = '#0A0022'; // Azul espacial más oscuro
const BG_COLOR_ALPHA = '#0d0c0edd'; // Azul espacial más oscuro

const canvas = document.querySelector('canvas');
const context = canvas.getContext('2d');
context.imageSmoothingEnabled = false;

const ENTITY_SIZE = 48;
const TEXT_SIZE = 20;

const ITEM_SPAWN_CHANCE = 0.3; // 30% de probabilidad de que un enemigo suelte un ítem

const ScreenManager = new FSM();
const GameScreenManager = new FSM('game');

function bgBuilder(bg_image, speed) {

    let bg_width = GAME_WIDTH;
    let bg_height = (bg_image.height / bg_image.width) * bg_width;

    const bg = new BaseEntity({
        width: bg_width,
        height: bg_height,
        image: bg_image,
        vy: speed,
    });

    bg.addTask(EntityMoveTask.create());
    bg.on('post-update', () => {
        if (bg.y >= bg_height) {
            bg.y = 0;
        }
    });

    bg.on('post-render', () => {
        //top
        DrawManager.drawImage(bg.image, {
            ...bg.bounds(),
            y: bg.y - bg.height,
        });
        //center
        DrawManager.drawImage(bg.image, bg.bounds());
        //bottom
        DrawManager.drawImage(bg.image, {
            ...bg.bounds(),
            y: bg.y + bg.height,
        });
    });

    return bg;
}

function menuBuilder(items = []) {

    return {
        items: items,
        index: 0,
        input: function (type, code) {

            if (type == 'keydown') {
                if (code == 'ArrowUp') {
                    AudioManager.play('click');
                    this.index--;
                    if (this.index < 0) this.index = this.items.length - 1;
                }
                if (code == 'ArrowDown') {
                    AudioManager.play('click');
                    this.index++;
                    if (this.index >= this.items.length) this.index = 0;
                }
                if (code == 'Enter') {
                    let item = this.items[this.index];
                    if (item.action) {
                        item.action();
                        AudioManager.play('click');
                    }
                }
            }
        },
        render: function (y) {

            //render items using 'y' as center point

            let y_real = y - ((this.items.length - 1) * 30) * 0.5;

            this.items.forEach((item, index) => {
                let color = (index == this.index) ? 'yellow' : 'white';
                DrawManager.fillText(item.name(), GAME_WIDTH * 0.5, y_real + (index * 30), { size: 30, color: color, align: 'center' });
            });
        }
    };
}

function createLevel(id, props = {}) {
    return {
        //identity
        id: id,
        name: props.name || `Level ${id}`,
        introMessages: props.introMessages || [`Welcome to Level ${id}`],
        //enemies
        enemies: props.enemies || [],
        spawnRate: props.spawnRate || 60,
        maxEnemiesOnScreen: props.maxEnemiesOnScreen || 5,
        //objectives: survival or elimination
        objetive: props.objetive || 'elimination',
        timeLimit: props.timeLimit || 300, //in seconds for survival
        enemiesToEliminate: props.enemiesToEliminate || 20, //for elimination
        lastLevel: props.lastLevel || false,
        image_name: props.image_name || null,
    }
}

function hpBar({ value, max, x, y, width, backColor = 'gray', color = 'green' }) {
    let w = width ?? ENTITY_SIZE;
    let h = ENTITY_SIZE * 0.1;

    //background
    DrawManager.fillRect(x, y - h * 2, w, h, { color: backColor });

    let percent = (value * w / max);

    DrawManager.fillRect(x, y - h * 2, percent, h, { color: color });
}

function createBullet(props = {}) {
    let b = new BaseEntity({
        type: 'bullet',
        owner: props.owner,
        x: props.owner.center().x,
        width: (ENTITY_SIZE * 0.05),
        height: (ENTITY_SIZE * 0.5),
        color: 'red',
        damage: 1,
    });

    return b;
}

const PlayerWeapon = function () {
    return {
        _baseFireRate: 20,
        fireRate: 20,
        value: 0,
        reload: function () {
            this.value = 0;
        },
        update: function () {
            if (this.value < this.fireRate) {
                this.value++;
            }
        },
        ready: function () {
            return this.value >= this.fireRate;
        },
        reset: function () {
            this.fireRate = this._baseFireRate;
        },
    };
};

const GAME_TITLE = 'Astra Defiant';

const GAME_BRIEF = [
    // "EARTH, 2154",
    // "THE SWARM AWAKENS",
    // "ALL FLEETS HAVE FALLEN",
    // "YOU ARE THE LAST LINE OF DEFENSE",
    // "MAKE YOUR STAND",
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
];

//Enemies
const EnemyTypes = {
    scout: {
        name: 'Scout',
        color: '#ff4444', // Rojo alienígena
        image_name: 'ship_red',
        vy: (ENTITY_SIZE * 0.05),
        score: 10,
        hp: 2,
    },
    heavy: {
        name: 'Heavy',
        color: '#ffaa00', // Naranja metálico
        image_name: 'ship_orange',
        vy: (ENTITY_SIZE * 0.02),
        score: 20,
        hp: 3,
    },
    sniper: {
        name: 'Sniper',
        color: '#aa00ff', // Púrpura alienígena
        image_name: 'ship_purple',
        vy: (ENTITY_SIZE * 0.03),
        score: 30,
        hp: 2,
    },
    hunter: {
        name: 'Hunter',
        image_name: 'ship_green',
        vy: (ENTITY_SIZE * 0.04),
        score: 25,
        hp: 2,
        behavior: 'hunting', // Nueva propiedad para task específico
    },
    tank: {
        name: 'Tank',
        color: '#888888', // Gris metálico
        image_name: 'ship_gray',
        vy: (ENTITY_SIZE * 0.015),
        score: 40,
        hp: 3,
    },
    bomber: {
        name: 'Bomber',
        color: '#885522', // Marrón oxidado
        image_name: 'ship_brown',
        vy: (ENTITY_SIZE * 0.01),
        score: 50,
        hp: 4,
    },
    boss: {
        boss: true,
        //fancy name for boss
        name: 'Hive Queen',
        color: '#ffff44', // Amarillo brillante
        image_name: 'ship_yellow',
        //big size
        width: ENTITY_SIZE * 2,
        height: ENTITY_SIZE * 2,
        vy: (ENTITY_SIZE * 0.008),
        score: 200,
        hp: 50,
        build: function (e) {
            e.addTask(BossTask.create());
        },
    },
};

//Items
const ItemTypes = {
    score: {
        name: 'Data Cache',
        image_name: 'orb_yellow',
        value: 50,
        onCollide: function (target) {
            //aumenta la puntuación del jugador
            if (target.type == 'player') {
                target.emit('score-collected', { score: this.value });
            }
        }
    },
    repair: {
        name: 'Repair Kit',
        image_name: 'orb_green',
        value: 5,
        onCollide: function (target) {
            target.hp += this.value;
            target.hp = Utils.clamp(target.hp, 0, target.maxHp);
        },
    },
    shield: {
        name: 'Energy Shield',
        image_name: 'orb_blue',
        onCollide: function (target) {
            target.addTask(ShieldBehaviorTask.create());
        },
    },
    rapidFire: {
        name: 'Rapid Fire Module',
        image_name: 'orb_purple',
        onCollide: function (target) {
            target.addTask(RapidFirePowerupTask.create());
        },
    },
    tripleShot: {
        name: 'Triple Shot',
        image_name: 'orb_white',
        onCollide: function (target) {
            target.addTask(TripleShotPowerupTask.create());
        }
    },
    fastSpeed: {
        name: 'Fast Speed',
        image_name: 'orb_orange',
        onCollide: function (target) {
            target.addTask(FastSpeedPowerupTask.create());
        },
    }
};

const Levels = [
    createLevel(1, {
        name: 'Breach in the Kuiper Belt',
        introMessages: [
            'Scanners detect unknown signatures at the edge of the system.',
            'Intercept and identify. Weapons free if hostile.',
        ],
        enemies: [EnemyTypes.scout],
        spawnRate: 90,
        maxEnemiesOnScreen: 3,
        objetive: 'elimination',
        enemiesToEliminate: 20,
        image_name: 'bg_asteroids',
    }),
    createLevel(2, {
        name: 'The Outer Rim Offensive',
        introMessages: [
            'This is no scouting party. Full invasion force confirmed.',
            'They broke through Jupiter defense grid! Fall back to Mars orbit!',
        ],
        enemies: [EnemyTypes.scout, EnemyTypes.heavy],
        spawnRate: 80,
        maxEnemiesOnScreen: 4,
        objetive: 'elimination',
        enemiesToEliminate: 30,
        image_name: 'bg_stars_purple',
    }),
    createLevel(3, {
        name: 'The Martian Gauntlet',
        introMessages: [
            'Mars Colony is evacuating. We are their only cover.',
            'Buy the transports time. Hold this position!',
        ],
        enemies: [EnemyTypes.scout, EnemyTypes.heavy],
        spawnRate: 70,
        maxEnemiesOnScreen: 5,
        objetive: 'survival',
        timeLimit: 120 * 60,
        image_name: 'bg_stars_green',

    }),
    createLevel(4, {
        name: 'Earths Orbital Siege',
        introMessages: ['The battle reaches home. All defense platforms are engaged.', 'Failure is not an option. Earth is counting on us.'],
        enemies: [EnemyTypes.scout, EnemyTypes.heavy, EnemyTypes.sniper],
        spawnRate: 60,
        maxEnemiesOnScreen: 6,
        objetive: 'elimination',
        enemiesToEliminate: 40,
        image_name: 'bg_stars_blue',
    }),
    createLevel(5, {
        name: 'Last Stand at Lunar Base',
        introMessages: ['Command is gone. We are the last organized resistance.', 'They are deploying their elite guard. This is for all the marbles.'],
        enemies: [EnemyTypes.scout, EnemyTypes.heavy, EnemyTypes.sniper, EnemyTypes.tank],
        spawnRate: 50,
        maxEnemiesOnScreen: 7,
        objetive: 'elimination',
        enemiesToEliminate: 50,
        image_name: 'bg_stars_red',
    }),
    createLevel(6, {
        name: 'The Heart of the Swarm',
        introMessages: ['There it is... the Hive Queen. The source of the invasion.', 'One shot, one kill. End this war now.'],
        enemies: [EnemyTypes.boss],
        spawnRate: 40,
        maxEnemiesOnScreen: 1,
        objetive: 'elimination',
        enemiesToEliminate: 1, //boss only
        image_name: 'bg_ion',
        lastLevel: true,
    }),
];

//Tasks
const EntityMoveTask = createTask({
    name: 'EntityMoveTask',
    duration: Infinity,
    onStart: function (entity) {
        this.entity = entity;
    },
    onUpdate: function () {
        this.entity.x += this.entity.vx;
        this.entity.y += this.entity.vy;

        this.entity.vx *= this.entity.friction;
        this.entity.vy *= this.entity.friction;
    },
});

const PlayerControllerTask = createTask({
    name: 'PlayerControllerTask',
    duration: Infinity,
    onStart: function (entity) {
        this.entity = entity;
    },
    onUpdate: function () {

        if (KeyManager.isDown('ArrowLeft')) {
            this.entity.vx = -this.entity.speed.getValue();
        }
        if (KeyManager.isDown('ArrowRight')) {
            this.entity.vx = this.entity.speed.getValue();
        }
    },
});

const ShieldBehaviorTask = createTask({
    name: 'Shield',
    duration: 300,
    powerup: true,
    onStart: function (entity) {
        this.entity = entity;
        this.r = this.entity.on('pre-render', () => {
            let pos = this.entity.center();
            DrawManager.fillCircle(pos.x, pos.y, this.entity.width * 1.5, { color: '#0091ff11' });
        });

        this.d = this.entity.on('damage-received', (data) => {
            console.log('Shield absorbed damage!', data.damage);
            data.damage = 0;
        });
    },
    onComplete: function () {
        this.r.remove();
        this.d.remove();
    }
});

const RapidFirePowerupTask = createTask({
    name: 'Rapid Fire',
    duration: 600,
    powerup: true,
    onStart: function (entity) {
        this.entity = entity;
        this.entity.weapon.fireRate /= 2;
    },
    onComplete: function () {
        this.entity.weapon.reset();
    }
});

const HuntingTask = createTask({
    name: 'HuntingTask',
    onStart: function (entity) {
        this.entity = entity;
    },
    onUpdate: function () {
        // Persigue al player suavemente
        // let dx = this.entity.scene.player.x - this.entity.x;
        // this.entity.vx = Math.sign(dx) * 0.5;
    }
});

const EnemyFireTask = createTask({
    name: 'EnemyFireTask',
    duration: Infinity,
    onStart: function (entity) {
        this.entity = entity;
        this.chanceLimit = 0.7;
        this.fireTimer = {
            value: 0,
            limit: Utils.randomInt(90, 150),
        };
    },
    onUpdate: function () {
        this.fireTimer.value++;
        if (this.fireTimer.value >= this.fireTimer.limit) {
            // this.fireTimer.limit = Utils.randomInt(90, 150);
            this.fireTimer.value = 0;
            //chance
            let chance = Utils.randomDouble(0, 1);
            if (chance > this.chanceLimit) {
                return; //30% chance to fire
            }

            let b = createBullet({
                owner: this.entity,
            });

            b.vy = (ENTITY_SIZE / 8);

            b.centerTo({
                y: this.entity.bottom(),
            });
            b.addTask(EntityMoveTask.create());
            AudioManager.play('shoot_enemy');
            let data = { bullets: [b] };
            this.entity.emit('bullet-created', data);
            this.entity.emit('enemy-fire', data);
            console.log('Enemy fired a bullet!');
        }
    },
});

const BossTask = createTask({
    name: 'BossTask',
    duration: Infinity,
    onStart: function (entity) {
        this.entity = entity;
        this.phase = 0;
        this.timer = 0;
        this.vx = 0;

        this.entity.centerTo({
            x: GAME_WIDTH / 2,
        });

        this.entity.y = -this.entity.height;
        this.entity.removeTask(EnemyFireTask.name);
    },
    onUpdate: function () {

        // Movimiento lateral - ya usa entity.vx directamente
        if (this.entity.x <= 0 || this.entity.right() >= GAME_WIDTH) {
            this.entity.vx = -this.entity.vx;
        }

        //enter on screen
        if (this.phase == 0) {
            if (this.entity.y >= 80) {
                this.entity.y = 80;
                this.entity.vy = 0;
                this.vx = 2;
                this.entity.vx = this.vx;
                this.phase = 1;
                let task = EnemyFireTask.create();
                task.chanceLimit = 0.75;
                // task.fireTimer.limit = 20;
                this.entity.addTask(task);
            }
        }

        //RAGE MODE!!!
        if (this.phase == 1) {

            if (this.entity.hp <= this.entity.maxHp * 0.25) {

                this.phase = 2;
                this.entity.vx *= 2;

                let f = this.entity.tasks.find((t) => t.name == EnemyFireTask.create().name);
                f.chanceLimit = 1.1;
                f.fireTimer.limit = 30;

                this.entity.on('bullet-created', (data) => {
                    console.log('boss fire twice?');
                    let base = data.bullets[0];

                    let b = createBullet({
                        owner: this.entity,
                    });
                    b.vy = base.vy;
                    // b.vx = -1;
                    b.centerTo({
                        x: this.entity.center().x - 20,
                        y: this.entity.bottom(),
                    });
                    b.addTask(EntityMoveTask.create());
                    data.bullets.push(b);


                    b = createBullet({
                        owner: this.entity,
                    });
                    b.vy = base.vy;
                    // b.vx = 1;
                    b.centerTo({
                        x: this.entity.center().x + 20,
                        y: this.entity.bottom(),
                    });
                    b.addTask(EntityMoveTask.create());
                    data.bullets.push(b);
                });
            }
        }
    },
});

const TripleShotPowerupTask = createTask({
    name: 'Triple Shot',
    duration: 450,
    powerup: true,
    onStart: function (entity) {
        this.originalFire = entity.on('bullet-created', (data) => {
            // Crear 3 balas en abanico
            // let bullets = this.createTripleBullets(entity);
            let base = data.bullets[0];

            let b = createBullet({
                owner: entity,
            });
            b.vy = base.vy;
            b.centerTo({
                x: entity.center().x - 20,
                y: entity.y,
            });
            b.addTask(EntityMoveTask.create());
            data.bullets.push(b);


            b = createBullet({
                owner: entity,
            });
            b.vy = base.vy;
            b.centerTo({
                x: entity.center().x + 20,
                y: entity.y,
            });
            b.addTask(EntityMoveTask.create());
            data.bullets.push(b);
        });
    },
    onComplete: function () {
        this.originalFire.remove();
    }
});

const FastSpeedPowerupTask = createTask({
    name: 'Fast Speed',
    duration: 600,
    powerup: true,
    onStart: function (entity) {
        this.entity = entity;
        this.entity.speed._modifier = 1.5;
    },
    onComplete: function () {
        this.entity.speed._modifier = 0;
    }
});

//test attributes
function makeAttribute(value) {
    return {
        _modifier: 0,
        getValue: function () {
            return value + this._modifier;
        }
    };
}

function createScreenFlasher(color = 'white', duration = 10) {

    return {
        duration: 0,
        stop: function () {
            this.duration = 0;
        },
        start: function () {
            this.duration = duration;
            console.log('Screen flasher started: ', duration, color);
        },
        update: function () {

            if (this.duration > 0) {
                this.duration--;
            }
        },
        render: function () {
            if (this.duration <= 0) return;
            DrawManager.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color });
        },
    };
}


//screens fuera del juego

const LoadScreen = new BaseScreen({
    enter: function ({ images = [] }) {

        ImageManager.init(images);

        ImageManager.load(() => {
            console.log('All images loaded');
            setTimeout(() => {
                ScreenManager.change('menu');
            }, 500);
        });
    },
    render: function () {
        DrawManager.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color: BG_COLOR });
        DrawManager.fillText('Loading...', GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5, { size: 30, align: 'center' });
    }
});

const MenuScreen = new BaseScreen({

    enter: function () {
        this.bg = bgBuilder(ImageManager.get('bg_title'), 0);

        this.menu = menuBuilder([
            {
                name: function () {
                    return `Play Game`;
                },
                action: function () {
                    ScreenManager.change('intro');
                }
            },
            {
                name: function () {
                    return `Settings`;
                },
                action: function () {
                    ScreenManager.push('settings');
                }
            },
        ]);

        if (window.nw != undefined) {
            this.menu.items.push({
                name: function () {
                    return `Quit`;
                },
                action: function () {
                    nw.App.quit();
                }
            });
        }

        // AudioManager.play('cyclotron');
    },
    input: function (type, code) {
        if (type == 'keydown') {
            if (code == 'KeyM') {
                // Toggle mute con la tecla M
                AudioManager.toogleMute();
            }
            this.menu.input(type, code);
        }
    },
    render: function () {

        DrawManager.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color: BG_COLOR });

        this.bg.render();

        DrawManager.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color: 'rgba(100,100,100,0.3)' });

        // DrawManager.fillText(`${GAME_TITLE}`, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.1, { size: 40, align: 'center', bold: true });

        this.menu.render(GAME_HEIGHT * 0.7);
    }
});

const IntroScreen = new BaseScreen({
    enter: function () {
        this.currentLine = 0;
        this.counter = 0;
        this.bg = bgBuilder(ImageManager.get('bg_intro'), 0.5);
    },
    input: function (type, code) {
        if (type == 'keydown') {
            if (code == 'Enter') {
                ScreenManager.change('game');
            }
        }
    },
    update: function () {

        // this.bg.update();

        this.counter++;

        if (this.counter % 90 == 0 && this.currentLine < GAME_BRIEF.length) {
            this.currentLine++;
        }

        if (this.currentLine >= GAME_BRIEF.length && this.counter > (GAME_BRIEF.length * 90) + 180) {
            ScreenManager.change('game');
        }
    },
    render: function () {
        DrawManager.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color: BG_COLOR });

        this.bg.render();

        // Calcular posición vertical centrada
        const totalLines = GAME_BRIEF.length;
        const lineHeight = 30;
        const totalTextHeight = totalLines * lineHeight;
        const startY = (GAME_HEIGHT - totalTextHeight) * 0.5;

        GAME_BRIEF.slice(0, this.currentLine + 1).forEach((line, index) => {
            // Calcula el progreso del fade in basado en cuánto tiempo ha estado visible la línea
            let lineStartTime = index * 90;
            let lineVisibleTime = Math.max(0, this.counter - lineStartTime);
            let alpha = Math.min(1, lineVisibleTime / 45);

            DrawManager.fillText(line, GAME_WIDTH * 0.5, startY + (index * lineHeight), {
                align: 'center',
                color: `rgba(255, 255, 255, ${alpha})`
            });
        });
    },
});

const GameOverScreen = new BaseScreen({
    enter: function (data = {}) {
        this.score = data.score;
    },
    input: function (type, code) {
        if (type == 'keydown') {
            if (code == 'Escape') {
                ScreenManager.change('menu');
            }
        }
    },
    render: function () {
        DrawManager.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color: BG_COLOR });

        DrawManager.fillText('Game Over!', GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5, { size: 30, align: 'center' });
        DrawManager.fillText(`Last Score: ${this.score}`, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5 + 40, { align: 'center' });
        DrawManager.fillText('Back to Menu (Escape)', GAME_WIDTH * 0.5, GAME_HEIGHT - 40, { align: 'center' });
    }
});

const SettingScreen = new BaseScreen({
    enter: function () {
        this.menu = menuBuilder([
            {
                name: function () {
                    return `Sound: ${AudioManager.isMuted() ? 'OFF' : 'ON'}`;
                },
                action: function () {
                    AudioManager.toogleMute();
                }
            },
        ]);
    },
    input: function (type, code) {
        if (type == 'keydown') {
            if (code == 'Escape') {
                ScreenManager.pop();
            }
            this.menu.input(type, code);
        }
    },
    render: function () {
        DrawManager.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color: BG_COLOR });

        DrawManager.fillText('Settings', GAME_WIDTH * 0.5, GAME_HEIGHT * 0.1, { size: 30, align: 'center' });

        this.menu.render(GAME_HEIGHT * 0.5);

        DrawManager.fillText('Back (Escape)', GAME_WIDTH * 0.5, GAME_HEIGHT * 0.9, { align: 'center' });
    }
});

const GameScreen = new BaseScreen({
    enter: function () {
        GameScreenManager.change('game_level_select');
    },
    input: function (type, code) {
        GameScreenManager.input(type, code);
    },
    update: function () {
        GameScreenManager.update();
    },
    render: function () {
        GameScreenManager.render();
    },
});


//screens dentro del juego

const GamePauseScreen = new BaseScreen({
    enter: function () {
        this.menu = menuBuilder([
            {
                name: function () {
                    return `Settings`;
                },
                action: function () {
                    ScreenManager.push('settings');
                }
            },
            {
                name: function () {
                    return `Menu`;
                },
                action: function () {
                    ScreenManager.change('menu');
                }
            },
        ]);
    },
    input: function (type, code) {
        if (type == 'keydown') {
            if (code == 'Escape') {
                GameScreenManager.pop();
            }
            if (code == 'KeyM') {
                // Toggle mute con la tecla M
                AudioManager.toogleMute();
            }

            this.menu.input(type, code);
        }
    },
    render: function () {
        DrawManager.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color: BG_COLOR_ALPHA });
        DrawManager.fillText('Pause', GAME_WIDTH * 0.5, GAME_HEIGHT * 0.1, { size: 30, align: 'center' });

        this.menu.render(GAME_HEIGHT * 0.5);

        DrawManager.fillText('Back (Escape)', GAME_WIDTH * 0.5, GAME_HEIGHT * 0.9, { align: 'center' });
    }
});

const LevelSelectScreen = new BaseScreen({
    enter: function (data = {}) {

        this.bg = bgBuilder(ImageManager.get('bg_intro'), 0.5);

        //6 levels, last is boss
        // id, name, unlocked
        this.levels = Levels.map((level) => {
            return {
                id: level.id,
                name: `Level ${level.id}: ${level.name}`,
                unlocked: GameState.levelsUnlocked[level.id] || false,
                finished: (GameState.levelsCompleted[level.id] || false),
            };
        });

        //selected level is last unlocked level or first level
        this.selectedLevel = data.nextLevel || 1;

        for (let i = 0; i < this.levels.length; i++) {
            if (this.levels[i].unlocked) {
                this.selectedLevel = this.levels[i].id;
            }
        }

        console.log(this.selectedLevel, this.levels.length);

        if (this.selectedLevel >= this.levels.length) {
            this.selectedLevel = 1;
        }
    },
    input: function (type, code) {
        if (type == 'keydown') {

            //escape to menu
            if (code == 'Escape') {
                ScreenManager.change('menu');
            }

            //up/down to select level
            if (code == 'ArrowUp') {
                this.selectedLevel--;
                if (this.selectedLevel < 1) this.selectedLevel = this.levels.length;
            }
            if (code == 'ArrowDown') {
                this.selectedLevel++;
                if (this.selectedLevel > this.levels.length) this.selectedLevel = 1;
            }

            if (code == 'Enter') {
                AudioManager.play('click');
                if (!this.levels[this.selectedLevel - 1].unlocked) {
                    return; //level locked
                }
                GameScreenManager.change('game_play', {
                    level: {
                        ...Levels[this.selectedLevel - 1]
                    },
                });
            }
        }
    },
    render: function () {
        DrawManager.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color: BG_COLOR });

        this.bg.render();

        DrawManager.fillText('Select Level', GAME_WIDTH * 0.5, GAME_HEIGHT * 0.1, { size: 30, align: 'center' });

        this.levels.forEach((level, index) => {
            let selected = (this.selectedLevel - 1) == index;
            let color = level.unlocked ? 'white' : 'gray';
            if (level.finished) {
                color = 'lightgreen';
            }
            let name = selected ? `> ${level.name} <` : level.name;
            DrawManager.fillText(name, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.3 + (index * 40), { color: color, align: 'center' });
        });


        DrawManager.fillText('Back (Escape)', GAME_WIDTH * 0.5, GAME_HEIGHT * 0.9, { align: 'center' });
    }
});

const LevelCompletedScreen = new BaseScreen({
    enter: function (data) {
        this.score = data.score;
        this.level = data.level;
    },
    input: function (type, code) {
        if (type == 'keydown') {
            if (code == 'Enter') {
                GameScreenManager.change('game_level_select', {
                    nextLevel: this.level.lastLevel ? null : this.level.id + 1,
                });
            }
        }
    },
    render: function () {
        DrawManager.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color: BG_COLOR });

        DrawManager.fillText(`Level ${this.level.id} Completed!`, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5, { size: 30, align: 'center' });
        DrawManager.fillText(`Score: ${this.score}`, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5 + 40, { align: 'center' });
        DrawManager.fillText('Continue (Enter)', GAME_WIDTH * 0.5, GAME_HEIGHT - 40, { align: 'center' });
    }
});

const GamePlayScreen = new BaseScreen({

    introTimer: {
        value: 0,
        limit: 240,
    },

    player: null,
    enemies: [],
    playerBullets: [],
    enemiesBullets: [],
    items: [],
    texts: [],
    particles: [],
    score: 0,

    enemySpawnTimer: {
        value: 0,
        limit: 90,
    },

    spawnEnemy: function (_e) {
        if (this.completed) return;
        if (this.enemySpawnTimer.value < this.enemySpawnTimer.limit) return;

        if (this.enemies.length >= this.level.maxEnemiesOnScreen) return;

        this.enemySpawnTimer.value = 0;

        let template = _e ?? this.level.enemies[Utils.randomInt(0, this.level.enemies.length - 1)];

        let e = new BaseEntity({
            type: 'enemy',
            x: Utils.randomInt(10, GAME_WIDTH - ENTITY_SIZE - 10),
            y: -ENTITY_SIZE,
            width: ENTITY_SIZE,
            height: ENTITY_SIZE,
            maxHp: template.hp,
        });

        e.extend({ ...template, color: 'transparent' });



        e.image = ImageManager.get(template.image_name);

        e.on('post-render', () => {
            //draw ship
            DrawManager.drawImage(e.image, e.bounds(), {}, { rotate: 180 });
            //draw name
            DrawManager.fillText(e.name, e.center().x, e.y - 20, { color: 'white', align: 'center', baseline: 'middle', size: 16 });
            //draw hp bar
            hpBar({
                value: e.hp,
                max: e.maxHp,
                x: e.x,
                y: e.y,
                width: e.width,
            });


        });

        e.addTask(EntityMoveTask.create());
        e.addTask(EnemyFireTask.create());

        // if (e.boss) {
        //     e.addTask(BossTask.create());
        // } else {
        // }

        if (template.build) {
            template.build(e);
        }

        e.on('enemy-fire', (data) => {
            console.log(data.bullets.length);
            data.bullets.forEach((b) => {
                this.enemiesBullets.push(b);
            });
        });

        e.on('damage-received', () => {
            this.spawnParticles(e.center());
        });

        e.on('enemy-destroyed', () => {
            //increase enemy dead counter
            if (this.level.objetive == 'elimination') {
                this.level.enemiesToEliminate--;
            }
        });

        this.enemies.push(e);
    },

    playerFire: function () {
        if (this.completed) return;
        if (!this.player.weapon.ready()) return;
        this.player.weapon.reload();

        let b = createBullet({
            owner: this.player,
        });

        b.vy = -(ENTITY_SIZE / 8);

        b.centerTo({
            y: this.player.y,
        });

        AudioManager.play('shoot');

        b.addTask(EntityMoveTask.create());

        let data = { bullets: [b] };

        this.player.emit('bullet-created', data);

        data.bullets.forEach((b) => {
            this.playerBullets.push(b);
        });
    },

    spawnItem: function ({ x, y }, _i) {
        if (this.completed) return;

        let item = _i || Utils.randomItem(Object.values(ItemTypes));

        let i = new BaseEntity({
            width: ENTITY_SIZE * 0.5,
            height: ENTITY_SIZE * 0.5,
            vy: 2,

        });

        i.extend({ ...item, color: 'transparent' });
        i.centerTo({ x, y });

        i.image = ImageManager.get(item.image_name);

        i.on('post-render', () => {
            //draw orb
            DrawManager.drawImage(i.image, i.bounds(), {}, { pulse: { amplitude: 0.1, speed: 5 } });
        });

        i.addTask(EntityMoveTask.create());

        this.items.push(i);
    },

    showText: function (text, ttl) {

        let t = new BaseEntity({
            text: text,
            ttl: ttl,
        });

        t.update = function () {
            this.ttl--;
            if (this.ttl <= 0) {
                this.dead = true;
            }
        };

        this.texts.push(t);
    },

    spawnParticles: function ({ x, y }) {
        let ttl = 30;
        //explosion effect
        for (let i = 0; i < 10; i++) {
            let exp = new BaseEntity({
                x: x,
                y: y,
                width: ENTITY_SIZE * 0.05,
                height: ENTITY_SIZE * 0.05,
                color: 'orange',
                vx: Utils.randomDouble(-2, 2),
                vy: Utils.randomDouble(-2, 2),
                ttl: ttl,
            });
            exp.addTask(EntityMoveTask.create());
            exp.on('post-update', () => {
                exp.ttl--;
                if (exp.ttl <= 0) {
                    exp.dead = true;
                }
                //alpha based on ttl
                let alpha = exp.ttl / ttl;
                exp.color = `rgba(255,165,0,${alpha})`;
            });
            this.particles.push(exp);
        }
    },

    checkLevelComplete: function () {
        if (this.completed) return;
        if (this.level.objetive == 'elimination') {
            //check if all enemies eliminated
            if (this.level.enemiesToEliminate <= 0) {
                this.levelCompleted();
            }
        }

        if (this.level.objetive == 'survival') {
            //change time limit to frames
            this.level.timeLimit--;

            //check if time limit reached
            if (this.level.timeLimit <= 0) {
                this.levelCompleted();
            }
        }
    },

    levelCompleted: function () {
        this.completed = true;
        console.log('Level Complete!');
        GameState.levelsUnlocked[this.level.id + 1] = true;
        GameState.levelsCompleted[this.level.id] = true;
        saveGame();

        this.enemySpawnTimer.limit = Infinity;

        //destroy all enemies
        this.enemies.forEach((e) => {
            this.spawnParticles(e.center());
            this.spawnParticles(e.center());
            this.spawnParticles(e.center());
            e.dead = true;
        });

        //destroy all enemy bullets
        this.enemiesBullets.forEach((b) => {
            b.dead = true;
        });

        //destroy all items
        this.items.forEach((i) => {
            i.dead = true;
        });

        //destroy all player bullets
        this.playerBullets.forEach((b) => {
            b.dead = true;
        });

        //stop player movement
        this.player.vx = 0;
        this.player.friction = 1;
        this.player.removeTask(PlayerControllerTask.name);

        setTimeout(() => {
            this.player.vy = -5;
        }, 1000);
    },

    changeLevel: function () {
        if (this.level.lastLevel) {
            ScreenManager.change('game_end', {
                score: this.score,
            });
            return;
        }
        GameScreenManager.change('game_level_completed', {
            score: this.score,
            level: this.level,
        });
    },

    enter: function (data) {
        console.log('Starting level:', data.level);
        this.level = data.level;
        this.introTimer.value = 0;
        this.score = 0;

        this.enemySpawnTimer.value = 0;
        this.enemySpawnTimer.limit = this.level.spawnRate;

        this.enemies = [];
        this.playerBullets = [];
        this.enemiesBullets = [];
        this.items = [];
        this.texts = [];
        this.particles = [];

        this.player = new BaseEntity({
            type: 'player',
            y: GAME_HEIGHT - ENTITY_SIZE * 1.5,
            width: ENTITY_SIZE,
            height: ENTITY_SIZE,
            color: 'transparent',
            hp: 10,
            maxHp: 10,
            friction: 0.8,
            weapon: PlayerWeapon(),
            speed: makeAttribute(ENTITY_SIZE * 0.1),
        });

        this.player.addTask(PlayerControllerTask.create());
        this.player.addTask(EntityMoveTask.create());
        this.player.on('pre-update', () => {
            this.player.weapon.update();
        });
        this.player.on('damage-received', () => {
            this.spawnParticles(this.player.center());
        });

        this.player.image = ImageManager.get('ship_blue');

        this.player.on('post-render', (evt) => {
            //draw ship
            DrawManager.drawImage(this.player.image, this.player.bounds());
            //draw hp bar
            hpBar({
                value: this.player.hp,
                max: this.player.maxHp,
                x: this.player.x,
                y: this.player.y,
            });
        });

        this.player.on('score-collected', (data) => {
            this.score += data.score;
            this.showText(`+${data.score} Score`, 120);
            AudioManager.play('powerup');
        });

        this.player.centerTo({ x: GAME_WIDTH * 0.5 });

        this.bg = bgBuilder(ImageManager.get(this.level.image_name ?? 'bg_space'), 2);

        this.redFlash = createScreenFlasher('rgba(255, 0, 0, 0.1)', 5);
    },

    input: function (type, code) {
        if (type == 'keydown') {
            if (code == 'Escape') GameScreenManager.push('game_pause');
        }
    },

    update: function () {

        this.redFlash.update();

        if (this.player.bottom() < 0) {
            this.changeLevel();
            return;
        }

        this.bg.update();

        this.player.update();

        this.player.x = Utils.clamp(this.player.x, ENTITY_SIZE * 0.5, GAME_WIDTH - this.player.width - (ENTITY_SIZE * 0.5));

        //info
        if (this.introTimer.value < this.introTimer.limit) {
            this.introTimer.value++;
            return;
        }

        if (KeyManager.isDown('Space')) this.playerFire();

        this.enemySpawnTimer.value++;

        this.spawnEnemy();

        //update enemies
        this.enemies.forEach((e) => {
            e.update();

            if (e.y > GAME_HEIGHT) {
                e.dead = true;
                return;
            }

            if (Utils.collision(e, this.player)) {
                e.dead = true;
                let evt = {
                    damage: e.hp,
                }

                this.player.emit('damage-received', evt);

                this.player.hp -= evt.damage;

                if (evt.damage > 0) {
                    this.redFlash.start();
                }

                if (this.player.hp <= 0) {
                    ScreenManager.change('gameover', {
                        score: this.score,
                    });
                }
            }
        });

        this.items.forEach((i) => {
            i.update();

            if (i.y > GAME_HEIGHT) {
                i.dead = true;
                return;
            }

            if (Utils.collision(i, this.player)) {
                i.dead = true;
                this.showText(`Got ${i.name}`, 120);
                i.onCollide(this.player);
                AudioManager.play('powerup');
                return;
            }
        });

        //update player bullets
        this.playerBullets.forEach((b) => {
            b.update();

            if (b.bottom() < 0) {
                b.dead = true;
                return;
            }
            //enemy collision
            for (let e of this.enemies) {
                if (e.dead) return;

                if (Utils.collision(e, b)) {
                    b.dead = true;
                    e.hp -= b.damage;
                    e.emit('damage-received');
                    if (e.hp <= 0) {
                        AudioManager.play('explosion');
                        e.emit('enemy-destroyed');
                        e.dead = true;
                        this.score += e.score; // ← AÑADIDO, GRACIAS DEEPSEEK!

                        //spawn item
                        let chance = Utils.randomDouble(0, 1);
                        console.log('Item spawn chance:', chance);
                        if (chance < ITEM_SPAWN_CHANCE) {
                            this.spawnItem(e.center());
                        }
                    }
                    break;
                }
            }
        });

        //update enemy bullets
        this.enemiesBullets.forEach((b) => {
            b.update();

            if (b.y > GAME_HEIGHT) {
                b.dead = true;
                return;
            }

            if (Utils.collision(b, this.player)) {
                b.dead = true;

                let evt = {
                    damage: b.damage,
                }

                this.player.emit('damage-received', evt);

                this.player.hp -= evt.damage;

                if (evt.damage > 0) {
                    this.redFlash.start();
                }

                if (this.player.hp <= 0) {
                    ScreenManager.change('gameover', {
                        score: this.score,
                    });
                }
            }
        });

        this.texts.forEach((t) => t.update());

        this.particles.forEach((p) => p.update());

        //remove deads
        this.enemies = this.enemies.filter((_) => !_.dead);
        this.playerBullets = this.playerBullets.filter((_) => !_.dead);
        this.enemiesBullets = this.enemiesBullets.filter((_) => !_.dead);
        this.items = this.items.filter((_) => !_.dead);
        this.texts = this.texts.filter((_) => !_.dead);
        this.particles = this.particles.filter((_) => !_.dead);

        //check level complete
        this.checkLevelComplete();
    },

    render: function () {
        DrawManager.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color: BG_COLOR });

        //render bg
        this.bg.render();

        //render entities

        this.enemies.forEach((_) => {
            _.render();
        });

        this.items.forEach((_) => {
            _.render();
        });

        this.player.render();

        this.playerBullets.forEach((_) => {
            _.render();
        });

        this.enemiesBullets.forEach((_) => {
            _.render();
        });

        this.particles.forEach((_) => {
            _.render();
        });

        //flashers
        this.redFlash.render();

        //render info texts
        let counts = 0;
        this.texts.slice().reverse().forEach((t) => {
            DrawManager.fillText(t.text, GAME_WIDTH / 2, GAME_HEIGHT - 30 - (counts * 20), { align: 'center' });
            counts++;
        });

        let introOffsetY = GAME_HEIGHT * 0.5;

        if (this.introTimer.value < this.introTimer.limit) {

            let alpha = 1.0;
            if (this.introTimer.value < 60) {
                alpha = this.introTimer.value / 60;
            } else if (this.introTimer.value > this.introTimer.limit - 60) {
                alpha = (this.introTimer.limit - this.introTimer.value) / 60;
            }

            DrawManager.fillText(`-- Level ${this.level.id}: ${this.level.name} --`, GAME_WIDTH * 0.5, introOffsetY, { size: 30, align: 'center', color: `rgba(255,255,0,${alpha})` });
            introOffsetY += 40;

            let messages = this.level.introMessages || [this.level.introMessage];
            messages.forEach((msg) => {
                DrawManager.fillText(msg, GAME_WIDTH * 0.5, introOffsetY, { align: 'center', color: `rgba(255,255,255,${alpha})` });
                introOffsetY += 30;
            });

            return;
        }

        let offsetY = 10;
        DrawManager.fillText(`HP: ${this.player.hp}/${this.player.maxHp}`, 10, offsetY, { color: 'yellow', size: 24 });
        offsetY += 25;
        DrawManager.fillText(`Score: ${this.score}`, 10, offsetY, { color: 'yellow', size: 24 });
        offsetY += 25;

        //level objetive
        let levelObjetive = '';
        if (this.level.objetive == 'elimination') {
            levelObjetive = `Enemies Left: ${this.level.enemiesToEliminate}`;
        }

        if (this.level.objetive == 'survival') {
            let secondsLeft = Math.ceil(this.level.timeLimit / 60);
            levelObjetive = `Time Left: ${secondsLeft}s`;
        }
        DrawManager.fillText(levelObjetive, GAME_WIDTH / 2, 10, { align: 'center', color: 'yellow', size: 24 });


        //player tasks on lower left
        offsetY = GAME_HEIGHT - 20;
        this.player.tasks.filter(t => t.powerup).forEach((t) => {
            DrawManager.fillText(`${t.name}`, 10, offsetY, { color: 'yellow', align: 'left', baseline: 'bottom' });
            hpBar({
                value: t.time,
                max: t.duration,
                x: 10,
                y: offsetY + 10,
                backColor: 'gray',
                color: 'yellow',
                width: 150,
            });
            offsetY -= 35;
        });
    }
});

//game state management
let GameState = {
    highScore: 0,
    score: 0,
    levelsUnlocked: {
        1: true,
    },
    levelsCompleted: {},
};

function saveGame() {
    localStorage.setItem('nebula_defender_save', JSON.stringify(GameState));
}

function loadGame() {
    let data = localStorage.getItem('nebula_defender_save');
    if (data) {
        GameState = JSON.parse(data);
    }
    saveGame(); //save again to ensure structure
}

function resetGame() {
    GameState = {
        score: 0,
        levelsUnlocked: {
            1: true,
        },
        levelsCompleted: {},
    };
    saveGame();
}

function completeGame() {
    GameState.levelsUnlocked = Levels.reduce((acc, level) => {
        acc[level.id] = true;
        return acc;
    }, {});

    GameState.levelsCompleted = Levels.reduce((acc, level) => {
        acc[level.id] = true;
        return acc;
    }, {});

    saveGame();
}

//main events
function init() {

    //load game state
    loadGame();

    //setup canvas
    canvas.width = GAME_WIDTH;
    canvas.height = GAME_HEIGHT;

    DrawManager.init(context);

    // AudioManager.toogleMute(); //start muted

    const IMAGE_LIST = [
        //ships
        { name: 'ship_yellow', src: 'assets/images/ships/ship_yellow.png' },
        { name: 'ship_blue', src: 'assets/images/ships/ship_blue.png' },
        { name: 'ship_gray', src: 'assets/images/ships/ship_gray.png' },
        { name: 'ship_green', src: 'assets/images/ships/ship_green.png' },
        { name: 'ship_orange', src: 'assets/images/ships/ship_orange.png' },
        { name: 'ship_purple', src: 'assets/images/ships/ship_purple.png' },
        { name: 'ship_red', src: 'assets/images/ships/ship_red.png' },
        { name: 'ship_white', src: 'assets/images/ships/ship_white.png' },
        { name: 'ship_brown', src: 'assets/images/ships/ship_brown.png' },
        { name: 'ship_pale', src: 'assets/images/ships/ship_pale.png' },
        //orbs
        { name: 'orb_yellow', src: 'assets/images/items/orb_yellow.png' },
        { name: 'orb_blue', src: 'assets/images/items/orb_blue.png' },
        { name: 'orb_gray', src: 'assets/images/items/orb_gray.png' },
        { name: 'orb_green', src: 'assets/images/items/orb_green.png' },
        { name: 'orb_orange', src: 'assets/images/items/orb_orange.png' },
        { name: 'orb_purple', src: 'assets/images/items/orb_purple.png' },
        { name: 'orb_red', src: 'assets/images/items/orb_red.png' },
        { name: 'orb_white', src: 'assets/images/items/orb_white.png' },
        { name: 'orb_brown', src: 'assets/images/items/orb_brown.png' },
        //bg
        { name: 'bg_title', src: 'assets/images/bg/bg_title.png' },
        { name: 'bg_intro', src: 'assets/images/bg/bg_intro.png' },
        { name: 'bg_space', src: 'assets/images/bg/bg_space_blue.jpg' },
        { name: 'bg_ice', src: 'assets/images/bg/bg_ice.png' },
        { name: 'bg_ion', src: 'assets/images/bg/bg_ion.png' },

        { name: 'bg_asteroids', src: 'assets/images/bg/bg_asteroids.png' },

        { name: 'bg_stars_purple', src: 'assets/images/bg/bg_stars_purple.png' },
        { name: 'bg_stars_blue', src: 'assets/images/bg/bg_stars_blue.png' },
        { name: 'bg_stars_red', src: 'assets/images/bg/bg_stars_red.png' },
        { name: 'bg_stars_orange', src: 'assets/images/bg/bg_stars_orange.png' },
        { name: 'bg_stars_green', src: 'assets/images/bg/bg_stars_green.png' },
    ];

    AudioManager.init([
        { name: 'shoot', src: 'assets/sounds/laser6.mp3' },
        { name: 'powerup', src: 'assets/sounds/powerUp5.mp3' },
        { name: 'click', src: 'assets/sounds/tone1.mp3' },
        { name: 'cyclotron', src: 'assets/sounds/music/cyclotron.mp3', pool: 1 },
    ]);

    KeyManager.init((type, code, e) => {
        input(type, code, e)
    });

    ScreenManager.add('load', LoadScreen);
    ScreenManager.add('menu', MenuScreen);
    ScreenManager.add('intro', IntroScreen);
    ScreenManager.add('gameover', GameOverScreen);
    ScreenManager.add('settings', SettingScreen);
    ScreenManager.add('game', GameScreen);

    GameScreenManager.add('game_level_select', LevelSelectScreen);
    GameScreenManager.add('game_play', GamePlayScreen);
    GameScreenManager.add('game_pause', GamePauseScreen);
    GameScreenManager.add('game_level_completed', LevelCompletedScreen);


    ScreenManager.change('load', { images: IMAGE_LIST });


}

function input(type, code, e) {
    ScreenManager.input(type, code, e);
    if (type == 'keydown') {
        if (code == 'KeyF') {
            //fullscreen
            if (document.fullscreenElement) {
                document.exitFullscreen();
            } else {
                canvas.requestFullscreen();
            }
        }
    }
}

function update() {
    ScreenManager.update();
}

function render() {

    ScreenManager.render();
}

function loop() {

    update();

    render();

    requestAnimationFrame(() => {
        loop();
    });
}

function start() {
    // alert(nw);
    canvas.requestFullscreen();
    init();
    requestAnimationFrame(() => {
        loop();
    });
}

start();