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

const ObjectivesText = {
    survival: 'Survive the time limit',
    elimination: 'Eliminate all enemies',
    collectData: 'Collect all data caches',
};

const CheatManager = {
    _cheats: {},
    _buffer: [],
    _counter: 0,
    register: function (sequence, callback) {
        this._cheats[sequence] = {
            sequence: sequence,
            callback: callback,
            progress: 0,
        };
    },
    reset: function () {
        this._buffer = [];
        this._counter = 0;
        // console.log('Cheat buffer reset');
    },
    update: function () {
        this._counter++;
        if (this._counter > 30) {
            this.reset();
        }
    },
    render: function () {
        //optional render method if needed
        //test render buffer
        // DrawManager.fillText(`Cheat Buffer: ${this._buffer.join('')}`, 10, GAME_HEIGHT - 40, { color: 'yellow', bold: true, baseline: 'top' });
    },
    input: function (code) {
        if (code.length > 1) return; //only single characters
        this._buffer.push(code);
        this._counter = 0;
        if (this._buffer.length > 20) {
            this._buffer.shift();
        }

        // console.log('Cheat buffer:', this._buffer.join(''));

        for (const cheatName in this._cheats) {
            const cheat = this._cheats[cheatName];
            const seq = cheat.sequence;
            const bufLen = this._buffer.length;

            if (bufLen >= seq.length) {
                //get last n items from buffer
                const recentInput = this._buffer.slice(bufLen - seq.length).join('');
                if (recentInput === seq) {
                    //cheat activated
                    cheat.callback(cheat);
                    this.reset();
                }
            }
        }
    }
};

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
                    AudioManager.play('menu');
                    this.index--;
                    if (this.index < 0) this.index = this.items.length - 1;
                }
                if (code == 'ArrowDown') {
                    AudioManager.play('menu');
                    this.index++;
                    if (this.index >= this.items.length) this.index = 0;
                }
                if (code == 'Enter') {
                    let item = this.items[this.index];
                    if (item.action) {
                        item.action();
                        AudioManager.play('menu');
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
        //objectives: survival or elimination or collectData
        objective: props.objective || 'elimination',
        timeLimit: props.timeLimit || 300, //in seconds for survival
        enemiesToEliminate: props.enemiesToEliminate || 20, //for elimination
        dataToCollect: props.dataToCollect || 0,
        itemDropRate: props.itemDropRate || ITEM_SPAWN_CHANCE, // ← AÑADE ESTA LÍNEA
        lastLevel: props.lastLevel || false,
        image_name: props.image_name || null,
        endMessages: props.endMessages || [`Level Completed!`],
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
        height: (ENTITY_SIZE * 0.2),
        color: 'red',
        damage: 1,
    });

    return b;
}

function Sprite(image, { frames = 4, frameRate = 10 } = {}) {
    this.image = image;
    this.frameWidth = frames ? image.width / frames : image.width;
    this.frameHeight = image.height;
    this.frame = 0;
    this.frameCounter = 0;
    this.frames = frames;
    this.frameRate = frameRate;

    this.update = function () {
        this.frameCounter++;
        if (this.frameCounter >= this.frameRate) {
            this.frameCounter = 0;
            this.frame++;
            if (this.frame >= this.frames) {
                this.frame = 0;
            }
        }
    };

    this.render = function (bounds) {

        DrawManager.drawImage(this.image, bounds, {
            x: this.frame * this.frameWidth,
            y: 0,
            width: this.frameWidth,
            height: this.frameHeight
        });
    }
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
        vy: 2,
        score: 10,
        hp: 1,
    },
    heavy: {
        name: 'Heavy',
        color: '#ffaa00', // Naranja metálico
        image_name: 'ship_orange',
        vy: 1,
        score: 20,
        hp: 3,
    },
    sniper: {
        name: 'Sniper',
        color: '#aa00ff', // Púrpura alienígena
        image_name: 'ship_purple',
        vy: 1.5,
        score: 30,
        hp: 2,
    },
    hunter: {
        name: 'Hunter',
        image_name: 'ship_green',
        vy: 0.5,
        score: 25,
        hp: 2,
        build: function (e) {
            e.addTask(SideMovementTask.create());
        },
    },
    tank: {
        name: 'Tank',
        color: '#888888', // Gris metálico
        image_name: 'ship_gray',
        vy: 0.75,
        score: 40,
        hp: 3,
    },
    bomber: {
        name: 'Bomber',
        color: '#885522', // Marrón oxidado
        image_name: 'ship_brown',
        vy: 0.50,
        score: 50,
        hp: 4,
    },
    boss: {
        boss: true,
        //fancy name for boss
        name: 'Hive Queen',
        color: '#ffff44', // Amarillo brillante
        image_name: 'ship_yellow2',
        //big size
        width: ENTITY_SIZE * 3,
        height: ENTITY_SIZE * 3,
        vy: 0.2,
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
            target.emit('score-collected', { score: this.value });
        }
    },
    shield: {
        name: 'Energy Shield',
        image_name: 'orb_blue',
        onCollide: function (target) {
            target.addTask(ShieldPowerupTask.create());
        },
    },
    rapidFire: {
        name: 'Rapid Fire Module',
        image_name: 'orb_red',
        onCollide: function (target) {
            target.addTask(RapidFirePowerupTask.create());
        },
    },
    health: {
        name: 'Repair Kit',
        image_name: 'orb_green',
        value: 5,
        onCollide: function (target) {
            target.emit('hp-restored', { amount: this.value });
        },
    },
    speedBoost: {
        name: 'Speed Boost',
        image_name: 'orb_orange',
        onCollide: function (target) {
            target.addTask(FastSpeedPowerupTask.create());
        },
    },
    lifeDrain: {
        name: 'Life Drain',
        image_name: 'orb_purple',
        onCollide: function (target) {
            target.addTask(LifeDrainPowerupTask.create());
        },
    },
    tripleShot: {
        name: 'Triple Shot',
        image_name: 'orb_white',
        onCollide: function (target) {
            target.addTask(TripleShotPowerupTask.create());
        }
    },
    freeze: {
        name: 'Freeze',
        image_name: 'orb_gray',
        onCollide: function (target) {
            target.addTask(FreezePowerupTask.create());
        },
    },
    bomb: {
        name: 'Bomb',
        image_name: 'orb_black',
        onCollide: function (target) {
            // target.addTask(BombPowerupTask.create());
            target.bombs++;
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
        enemies: [
            { item: EnemyTypes.scout, weight: 1 },
        ],
        spawnRate: 90,
        maxEnemiesOnScreen: 3,
        objective: 'elimination',
        enemiesToEliminate: 20,
        image_name: 'bg_asteroids',
        endMessages: ['Initial contact made. Prepare for escalating hostilities.'],
    }),
    createLevel(2, {
        name: 'The Outer Rim Offensive',
        introMessages: [
            'This is no scouting party. Full invasion force confirmed.',
            'They broke through Jupiter defense grid! Fall back to Mars orbit!',
        ],
        enemies: [
            { item: EnemyTypes.scout, weight: 3 },
            { item: EnemyTypes.heavy, weight: 1 },
        ],
        spawnRate: 80,
        maxEnemiesOnScreen: 4,
        objective: 'elimination',
        enemiesToEliminate: 30,
        image_name: 'bg_stars_purple',
        endMessages: ['Mars orbit reached. Prepare for next wave.'],
    }),
    createLevel(3, {
        name: 'The Martian Gauntlet',
        introMessages: [
            'Mars Colony is evacuating. We are their only cover.',
            'Buy the transports time. Hold this position!',
        ],
        enemies: [
            { item: EnemyTypes.scout, weight: 6 },
            { item: EnemyTypes.hunter, weight: 2 },
            { item: EnemyTypes.heavy, weight: 1 },
        ],
        spawnRate: 70,
        maxEnemiesOnScreen: 5,
        objective: 'survival',
        timeLimit: 120 * 60,
        image_name: 'bg_stars_green',
        endMessages: ['Transports have cleared Mars orbit. Heading back to Earth.'],
    }),
    createLevel(4, {
        name: 'Data Recovery Operation',
        introMessages: [
            'Intelligence reports alien data cache in this sector.',
            'Recover the encrypted data before they can transmit it.',
            'Collect all data orbs to complete the mission.'
        ],
        enemies: [
            { item: EnemyTypes.scout, weight: 4 },
            { item: EnemyTypes.sniper, weight: 2 },
            { item: EnemyTypes.hunter, weight: 1 }
        ],
        spawnRate: 70,    // ← Más rápido que 100
        maxEnemiesOnScreen: 6, // ← Más enemigos que 4
        objective: 'collectData',
        dataToCollect: 8, // Número de data orbs a recolectar
        itemDropRate: 0.7, // ← AÑADE ESTO
        image_name: 'bg_stars_orange',
        endMessages: [
            'Data successfully recovered!',
            'Alien encryption protocols acquired.',
            'Returning to base for analysis.'
        ]
    }),
    createLevel(5, {
        name: 'Earths Orbital Siege',
        introMessages: ['The battle reaches home. All defense platforms are engaged.', 'Failure is not an option. Earth is counting on us.'],
        enemies: [
            { item: EnemyTypes.scout, weight: 4 },
            { item: EnemyTypes.heavy, weight: 2 },
            { item: EnemyTypes.sniper, weight: 1 },
        ],
        spawnRate: 60,
        maxEnemiesOnScreen: 6,
        objective: 'elimination',
        enemiesToEliminate: 40,
        image_name: 'bg_stars_blue',
        endMessages: ['Orbital defenses holding. Preparing for final engagement at Lunar Base.'],
    }),
    createLevel(6, {
        name: 'Last Stand at Lunar Base',
        introMessages: ['Command is gone. We are the last organized resistance.', 'They are deploying their elite guard. This is for all the marbles.'],
        enemies: [
            { item: EnemyTypes.scout, weight: 3 },
            { item: EnemyTypes.heavy, weight: 2 },
            { item: EnemyTypes.sniper, weight: 1 },
            { item: EnemyTypes.tank, weight: 1 },
        ],
        spawnRate: 50,
        maxEnemiesOnScreen: 7,
        objective: 'elimination',
        enemiesToEliminate: 50,
        image_name: 'bg_stars_red',
        endMessages: ['Lunar Base secured. All systems point to Hive Queen location. Final assault imminent.'],
    }),
    createLevel(7, {
        name: 'The Heart of the Swarm',
        introMessages: ['There it is... the Hive Queen. The source of the invasion.', 'One shot, one kill. End this war now.'],
        enemies: [
            { item: EnemyTypes.boss, weight: 1 },
        ],
        spawnRate: 40,
        maxEnemiesOnScreen: 1,
        objective: 'elimination',
        enemiesToEliminate: 1, //boss only
        image_name: 'bg_ion',
        lastLevel: true,
        endMessages: ['Hive Queen destroyed. Swarm disorganized. Earth is safe... for now.'],
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
        this.entity.x += this.entity.vx * this.entity.acceleration;
        this.entity.y += this.entity.vy * this.entity.acceleration;

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

const SideMovementTask = createTask({
    name: 'SideMovementTask',
    duration: Infinity,
    onStart: function (entity) {
        this.entity = entity;
    },
    onUpdate: function () {
        this.entity.vx = Math.sin(Date.now() * 0.002) * 2;
    },
    onComplete: function () {

    }
});

//powerup tasks

const ShieldPowerupTask = createTask({
    name: 'Shield',
    duration: 300,
    powerup: true,
    onStart: function (entity) {
        AudioManager.play('shield');
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

const FreezedTask = createTask({
    name: 'Freezed',
    duration: Infinity,
    powerup: true,
    onStart: function (entity) {
        this.entity = entity;
        this.entity.removeTask(EntityMoveTask.name);
        this.r = this.entity.on('pre-render', () => {
            let pos = this.entity.center();
            DrawManager.fillCircle(pos.x, pos.y, this.entity.width * 1, { color: '#6dbefc11' });
        });
    },
    onComplete: function () {
        this.r.remove();
        this.d.remove();
    }
});

const TripleShotPowerupTask = createTask({
    name: 'Triple Shot',
    duration: 450,
    powerup: true,
    onStart: function (entity) {
        this.l = entity.on('bullet-created', (data) => {
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
        this.l.remove();
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

const LifeDrainPowerupTask = createTask({
    name: 'Life Drain',
    duration: 600,
    powerup: true,
    onStart: function (entity) {
        this.entity = entity;
        this.l = entity.on('bullet-created', (data) => {
            // Cada vez que se crea una bala, añade un evento de colisión para drenar vida
            data.bullets.forEach((bullet) => {
                bullet.on('bullet-hit', ({ damage }) => {
                    console.log('Life Drain activated! Restoring ', damage, ' HP.');
                    this.entity.emit('hp-restored', { amount: damage });
                });
            });
        });
    },
    onComplete: function () {
        this.l.remove();
    }
});

const BombPowerupTask = createTask({
    name: 'Bomb',
    duration: 1, // Efecto instantáneo
    powerup: true,
    onStart: function (entity) {
        GamePlayScreen.enemies.forEach((enemy) => {
            enemy.emit('damage-received');
            enemy.emit('enemy-destroyed');
            enemy.dead = true; // Marca a todos los enemigos como muertos
        });
    }
});

const FreezePowerupTask = createTask({
    name: 'Freeze',
    duration: 600, // Duración del efecto
    powerup: true,
    onStart: function (entity) {
        this.entity = entity;
        this.l = entity.on('bullet-created', (data) => {
            // Cada vez que se crea una bala, añade un evento de colisión para drenar vida
            data.bullets.forEach((bullet) => {
                bullet.on('bullet-hit', ({ damage, target }) => {
                    target.addTask(FreezedTask.create(target));
                });
            });
        });
    },
    onComplete: function () {
        this.l.remove();
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
const StartScreen = new BaseScreen({
    input: function (type, code) {
        if (type == 'keydown') {
            AudioManager.playLoop('bg');
            ScreenManager.change('load');
        }
    },
    render: function () {
        DrawManager.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color: BG_COLOR });

        //press any key to start
        DrawManager.fillText('Press Any Key to Start', GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5, { size: 30, align: 'center' });
    }
});

const LoadScreen = new BaseScreen({
    enter: function () {

        ImageManager.init(IMAGE_LIST);

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

        DrawManager.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT, { color: 'rgba(100,100,100,0.1)' });

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

        //get score from GameData
        this.score = Object.values(GameState.levelsCompleted).reduce((acc, level) => acc + level.score, 0);
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

        DrawManager.fillText('Game Over!', GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5, { size: 30, align: 'center', color: 'red' });
        DrawManager.fillText(`Last Score: ${this.score}`, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5 + 40, { align: 'center', color: 'white' });
        DrawManager.fillText('Back to Menu (Escape)', GAME_WIDTH * 0.5, GAME_HEIGHT - 40, { align: 'center', color: 'white' });
    }
});

const GameEndScreen = new BaseScreen({
    enter: function (data = {}) {
        this.score = Object.values(GameState.levelsCompleted).reduce((acc, level) => acc + level.score, 0);
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

        DrawManager.fillText('Congratulations! You completed the game!', GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5, { size: 30, align: 'center', color: 'yellow' });
        DrawManager.fillText(`Total Score: ${this.score}`, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.5 + 40, { align: 'center', color: 'white' });
        DrawManager.fillText('Back to Menu (Escape)', GAME_WIDTH * 0.5, GAME_HEIGHT - 40, { align: 'center', color: 'white' });
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
    input: function (type, code, event) {
        GameScreenManager.input(type, code, event);
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

//testing level select screen
const OtherLevelSelectScreen = new BaseScreen({
    enter: function (data = {}) {

        this.bg = bgBuilder(ImageManager.get('bg_intro'), 0.5);

        // 6 levels, last is boss
        // id, name, unlocked
        this.levels = Levels.map((level) => {
            return {
                id: level.id,
                name: `Level ${level.id}: ${level.name}`,
                unlocked: GameState.levelsUnlocked[level.id] || false,
                finished: (GameState.levelsCompleted[level.id] || { completed: false, score: 0 }).completed,
                image_name: level.image_name,
                x: level.x,
                y: level.y,
            };
        });

        //selected level is last unlocked level or first level
        this.selectedLevel = data.nextLevel || 1;

        for (let i = 0; i < this.levels.length; i++) {
            if (this.levels[i].unlocked) {
                this.selectedLevel = this.levels[i].id;
            }
        }

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
            if (code == 'ArrowLeft') {
                AudioManager.play('menu');
                this.selectedLevel--;
                if (this.selectedLevel < 1) this.selectedLevel = this.levels.length;
            }
            if (code == 'ArrowRight') {
                AudioManager.play('menu');
                this.selectedLevel++;
                if (this.selectedLevel > this.levels.length) this.selectedLevel = 1;
            }

            if (code == 'Enter') {
                if (!this.levels[this.selectedLevel - 1].unlocked) {
                    return; //level locked
                }
                AudioManager.play('menu');
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

        let circleWidth = 120;

        //level positions
        //scatered
        let levelPositions = [
            { x: 100, y: 400 },
            { x: 300, y: 100 },
            { x: 500, y: 400 },
            { x: 700, y: 100 },
            { x: 900, y: 400 },
            { x: 1100, y: 100 },
        ];

        //draw line between levels
        for (let i = 0; i < levelPositions.length - 1; i++) {
            let start = levelPositions[i];
            let end = levelPositions[i + 1];
            let color = (this.levels[i].unlocked && this.levels[i + 1].unlocked) ? 'white' : 'black';
            DrawManager.drawLine(start.x + circleWidth / 2, start.y + circleWidth / 2, end.x + circleWidth / 2, end.y + circleWidth / 2, { color: color, width: 2 });
        }

        //for each level, draw a circle with level background image inside
        this.levels.forEach((level, index) => {
            let selected = (this.selectedLevel - 1) == index;
            let color = level.unlocked ? 'gray' : 'black';
            if (level.finished) {
                color = 'white';
            }
            if (selected) {
                color = 'blue';
            }
            let x = levelPositions[index].x;
            let y = levelPositions[index].y;
            DrawManager.drawImage(ImageManager.get(level.image_name), { x: x, y: y, width: circleWidth, height: circleWidth }, { x: 0, y: 0, width: 256, height: 256 }, { circle: color });
        });

        //draw only selected level
        DrawManager.fillText(`${this.levels[this.selectedLevel - 1].name}`, GAME_WIDTH * 0.5, GAME_HEIGHT - 150, { size: 30, align: 'center' });
        //show score if selected level is finished
        if (this.levels[this.selectedLevel - 1].finished) {
            DrawManager.fillText(`Completed`, GAME_WIDTH * 0.5, GAME_HEIGHT - 110, { align: 'center' });
        }
        DrawManager.fillText('Back (Escape)', GAME_WIDTH * 0.5, GAME_HEIGHT * 0.9, { align: 'center' });
    },
});

const LevelSelectScreen = new BaseScreen({
    enter: function (data = {}) {

        this.bg = bgBuilder(ImageManager.get('bg_intro'), 0.5);

        // 6 levels, last is boss
        // id, name, unlocked
        this.levels = Levels.map((level) => {
            return {
                id: level.id,
                name: `Level ${level.id}: ${level.name}`,
                unlocked: GameState.levelsUnlocked[level.id] || false,
                finished: (GameState.levelsCompleted[level.id] || { completed: false, score: 0 }).completed,
            };
        });

        //selected level is last unlocked level or first level
        this.selectedLevel = data.nextLevel || 1;

        for (let i = 0; i < this.levels.length; i++) {
            if (this.levels[i].unlocked) {
                this.selectedLevel = this.levels[i].id;
            }
        }

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
                AudioManager.play('menu');
                this.selectedLevel--;
                if (this.selectedLevel < 1) this.selectedLevel = this.levels.length;
            }
            if (code == 'ArrowDown') {
                AudioManager.play('menu');
                this.selectedLevel++;
                if (this.selectedLevel > this.levels.length) this.selectedLevel = 1;
            }

            if (code == 'Enter') {
                if (!this.levels[this.selectedLevel - 1].unlocked) {
                    return; //level locked
                }
                AudioManager.play('menu');
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
                color = 'blue';
            }
            let name = selected ? `> ${level.name} <` : level.name;
            DrawManager.fillText(name, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.3 + (index * 40), { color: color, align: 'center', shadow: true });
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
    endTimer: {
        value: 0,
        limit: 180,
    },

    player: null,
    enemies: [],
    playerBullets: [],
    enemiesBullets: [],
    items: [],
    texts: [],
    particles: [],
    score: 0,
    completed: false,

    enemySpawnTimer: {
        value: 0,
        limit: 90,
    },

    //to check level duration
    duration: 0,

    spawnEnemy: function (_e) {
        if (this.completed) return;
        if (this.enemySpawnTimer.value < this.enemySpawnTimer.limit) return;

        if (this.enemies.length >= this.level.maxEnemiesOnScreen) return;

        this.enemySpawnTimer.value = 0;

        // let template = _e ?? this.level.enemies[Utils.randomInt(0, this.level.enemies.length - 1)];
        let template = _e ?? Utils.weightedRandom(this.level.enemies);

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

        if (template.build) {
            template.build(e);
        }

        e.on('enemy-fire', (data) => {
            data.bullets.forEach((b) => {
                this.enemiesBullets.push(b);
            });
        });

        e.on('damage-received', () => {
            this.spawnParticles(e.center());
        });

        e.on('enemy-destroyed', () => {
            //increase enemy dead counter
            if (this.level.objective == 'elimination') {
                this.level.enemiesToEliminate--;
            }
            this.score += e.score;
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

        console.log('Spawning item: ', item.name);

        let i = new BaseEntity({
            width: ENTITY_SIZE * 0.75,
            height: ENTITY_SIZE * 0.75,
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

        t.render = function (offsetX = 0, offsetY = 0) {
            //with alpha based on ttl
            let alpha = this.ttl / ttl;
            DrawManager.fillText(this.text, this.x + offsetX, this.y + offsetY, { color: `rgba(255, 255, 0, ${alpha})`, align: 'center' });
        }

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

        //elimination objective
        if (this.level.objective == 'elimination') {
            //check if all enemies eliminated
            if (this.level.enemiesToEliminate <= 0) {
                this.levelCompleted();
            }
        }

        //survival objective
        if (this.level.objective == 'survival') {
            //change time limit to frames
            this.level.timeLimit--;

            //check if time limit reached
            if (this.level.timeLimit <= 0) {
                this.levelCompleted();
            }
        }

        //collectData objective
        if (this.level.objective == 'collectData') {
            //check if all data collected

            if (this.level.dataToCollect <= 0) {
                this.levelCompleted();
            }
        }

    },

    levelCompleted: function () {
        this.completed = true;

        console.log('Level Complete!');
        GameState.levelsUnlocked[this.level.id + 1] = true;
        GameState.levelsCompleted[this.level.id] = {
            completed: true,
            score: this.score,
        };
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

    },

    warpOut: function () {
        setTimeout(() => {
            AudioManager.play('warpout');
            this.player.vy = -5;
        }, 10);
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
            //duration in seconds
            duration: Math.floor(this.duration / 60),
        });
    },

    enter: function (data) {
        console.log(`Starting level: ${data.level.id} - ${data.level.name} (${data.level.objective})`);
        this.level = data.level;
        this.introTimer.limit = 120 + (this.level.introMessages.length * 60);
        this.introTimer.value = 0;
        this.endTimer.value = 0;
        this.score = 0;
        this.duration = 0;
        this.completed = false;

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
            speed: makeAttribute(5),
            bombs: 0,
        });

        this.player.addTask(PlayerControllerTask.create());
        this.player.addTask(EntityMoveTask.create());

        this.player.sprite = new Sprite(ImageManager.get('ship_blue'), {
            frames: 0,
            frameRate: 5,
        });

        this.player.on('pre-update', () => {
            this.player.weapon.update();
            this.player.sprite.update();
        });

        this.player.on('damage-received', () => {
            this.spawnParticles(this.player.center());
        });

        this.player.on('hp-restored', (data) => {
            this.player.hp += data.amount;
            this.player.hp = Utils.clamp(this.player.hp, 0, this.player.maxHp);
            this.spawnParticles(this.player.center());
            this.showText(`Healed +${data.amount} HP`, 120);
        });

        this.player.on('post-render', (evt) => {
            //draw ship
            this.player.sprite.render(this.player.bounds());

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

            if (this.level.objective == 'collectData') {
                this.level.dataToCollect--;
            }
        });

        this.player.on('defeat', () => {
            ScreenManager.change('gameover');
        });

        this.player.centerTo({ x: GAME_WIDTH * 0.5 });

        this.bg = bgBuilder(ImageManager.get(this.level.image_name ?? 'bg_space'), 1);

        this.redFlash = createScreenFlasher('rgba(255, 0, 0, 0.1)', 5);

        //add cheats
        CheatManager.reset();
        CheatManager.register('godmode', (cheat) => {
            console.log('Toggling God Mode', cheat);
            if (cheat.l1) {
                console.log('God Mode Deactivated!');
                cheat.l1.remove();
                delete cheat.l1;
                cheat.l2.remove();
                delete cheat.l2;
                this.player.sprite = new Sprite(ImageManager.get('ship_blue'), {
                    frames: 0,
                    frameRate: 5,
                });
            } else {
                console.log('God Mode Activated!');
                this.player.sprite = new Sprite(ImageManager.get('ship_white'), {
                    frames: 0,
                    frameRate: 5,
                });
                cheat.l1 = this.player.on('damage-received', (data) => {
                    data.damage = 0;
                });
                cheat.l2 = this.player.on('pre-render', () => {
                    let pos = this.player.center();
                    //gold color
                    let color = '#ffff0011';
                    DrawManager.fillCircle(pos.x, pos.y, this.player.width * 1.5, { color });

                    //render GOD MODE text
                    DrawManager.fillText('GOD MODE', this.player.x + this.player.width * 0.5, this.player.y - 30, { color: 'yellow', align: 'center' });
                });
            }
        });
        CheatManager.register('allpower', (cheat) => {
            console.log('All Powerups Activated!');
            this.player.addTask(ShieldPowerupTask.create(this.player));
            this.player.addTask(TripleShotPowerupTask.create(this.player));
            this.player.addTask(FastSpeedPowerupTask.create(this.player));
            this.player.addTask(RapidFirePowerupTask.create(this.player));
            this.player.addTask(LifeDrainPowerupTask.create(this.player));
            this.player.addTask(BombPowerupTask.create(this.player));
            this.player.addTask(FreezePowerupTask.create(this.player));
        });
        //HEALME cheat
        CheatManager.register('healme', (cheat) => {
            console.log('Heal Me Activated!');
            this.player.hp = this.player.maxHp;
            this.showText(`Healed to Full HP`, 120);
        });
    },

    input: function (type, code, event) {

        if (type == 'keydown') {
            if (code == 'Escape') GameScreenManager.push('game_pause');
            if (event.key) {
                CheatManager.input(event.key);
            }

            if (code == 'Enter') {
                //skip intro gracefully
                if (this.introTimer.value < this.introTimer.limit) {
                    this.introTimer.value = this.introTimer.limit - 60;
                }
            }

            if (code == 'KeyB') {
                if (this.player.bombs > 0) {
                    this.player.addTask(BombPowerupTask.create());
                    this.player.bombs -= 1;
                }
            }

        }

        //check cheats
    },

    update: function () {

        this.duration++;

        CheatManager.update();

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

        if (this.completed) {
            //move player slowly to center x based on this.endTimer.value
            let targetX = GAME_WIDTH * 0.5 - this.player.width * 0.5;
            this.player.x += (targetX - this.player.x) * 0.1;

            if (this.endTimer.value < this.endTimer.limit) {
                this.endTimer.value++;
            } else {
                this.warpOut();
            }
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
                    this.player.emit('defeat');
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
                    b.emit('bullet-hit', { damage: b.damage, target: e });
                    e.hp -= b.damage;
                    e.emit('damage-received');
                    if (e.hp <= 0) {
                        AudioManager.play('explosion');
                        e.emit('enemy-destroyed');
                        e.dead = true;

                        //spawn item
                        let chance = Utils.randomDouble(0, 1);

                        if (chance < this.level.itemDropRate) {
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
                    this.player.emit('defeat');
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

        CheatManager.render();

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
            t.render(GAME_WIDTH / 2, GAME_HEIGHT - 30 - (counts * 25));
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

            let messages = [...(this.level.introMessages || [this.level.introMessage]), '', `Objective: ${ObjectivesText[this.level.objective]}`];
            messages.forEach((msg) => {
                DrawManager.fillText(msg, GAME_WIDTH * 0.5, introOffsetY, { align: 'center', color: `rgba(255,255,255,${alpha})` });
                introOffsetY += 30;
            });

            return;
        }

        if (this.level.endMessages && this.completed) {

            let alpha = 1.0;
            if (this.endTimer.value < 60) {
                alpha = this.endTimer.value / 60;
            } else if (this.endTimer.value > this.endTimer.limit - 60) {
                alpha = (this.endTimer.limit - this.endTimer.value) / 60;
            }

            this.level.endMessages.forEach((msg, index) => {
                //yellow
                DrawManager.fillText(msg, GAME_WIDTH * 0.5, GAME_HEIGHT * 0.4 + index * 30, { size: 24, align: 'center', color: `rgba(255,255,0,${alpha})` });
            });
        }

        let offsetY = 10;
        DrawManager.fillText(`HP: ${this.player.hp}/${this.player.maxHp}`, 10, offsetY, { color: 'yellow', size: 24 });
        offsetY += 25;
        DrawManager.fillText(`Score: ${this.score}`, 10, offsetY, { color: 'yellow', size: 24 });
        offsetY += 25;
        //draw bombs
        DrawManager.fillText(`Bombs: ${this.player.bombs}`, 10, offsetY, { color: 'yellow', size: 24 });
        offsetY += 30;
        //level duration in seconds: right
        let durationSeconds = Math.floor(this.duration / 60);
        DrawManager.fillText(`Time: ${durationSeconds}s`, GAME_WIDTH - 10, 10, { align: 'right', color: 'yellow', size: 24 });

        //level objective
        let levelObjective = '';
        if (this.level.objective == 'elimination') {
            levelObjective = `Enemies Left: ${this.level.enemiesToEliminate}`;
        }

        if (this.level.objective == 'survival') {
            let secondsLeft = Math.ceil(this.level.timeLimit / 60);
            levelObjective = `Time Left: ${secondsLeft}s`;
        }

        if (this.level.objective == 'collectData') {
            levelObjective = `Data Left: ${this.level.dataToCollect}`;
        }

        DrawManager.fillText(levelObjective, GAME_WIDTH / 2, 10, { align: 'center', color: 'yellow', size: 24 });


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
        GameState = {
            ...GameState,
            ...JSON.parse(data),
        };
    }
    saveGame(); //save again to ensure structure
}

function resetGame() {
    GameState = {
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
        acc[level.id] = {
            completed: true,
            score: 0,
        };
        return acc;
    }, {});

    saveGame();
}

const IMAGE_LIST = [
    //ships
    { name: 'ship_yellow', src: 'assets/images/ships/ship_yellow.png' },
    { name: 'ship_yellow2', src: 'assets/images/ships/ship_yellow2.png' },
    { name: 'ship_blue', src: 'assets/images/ships/ship_blue.png' },
    { name: 'ship_gray', src: 'assets/images/ships/ship_gray.png' },
    { name: 'ship_green', src: 'assets/images/ships/ship_green.png' },
    { name: 'ship_orange', src: 'assets/images/ships/ship_orange.png' },
    { name: 'ship_purple', src: 'assets/images/ships/ship_purple.png' },
    { name: 'ship_red', src: 'assets/images/ships/ship_red.png' },
    { name: 'ship_white', src: 'assets/images/ships/ship_white.png' },
    { name: 'ship_brown', src: 'assets/images/ships/ship_brown.png' },
    //not in use ships
    { name: 'Dove', src: 'assets/images/ships/Dove.png' },
    { name: 'Ligher', src: 'assets/images/ships/Ligher.png' },
    { name: 'Ninja', src: 'assets/images/ships/Ninja.png' },

    //orbs
    { name: 'orb_yellow', src: 'assets/images/items/orb_yellow.png' },
    { name: 'orb_blue', src: 'assets/images/items/orb_blue.png' },
    { name: 'orb_red', src: 'assets/images/items/orb_red.png' },
    { name: 'orb_green', src: 'assets/images/items/orb_green.png' },
    { name: 'orb_orange', src: 'assets/images/items/orb_orange.png' },
    { name: 'orb_purple', src: 'assets/images/items/orb_purple.png' },
    { name: 'orb_white', src: 'assets/images/items/orb_white.png' },
    { name: 'orb_gray', src: 'assets/images/items/orb_gray.png' },
    { name: 'orb_black', src: 'assets/images/items/orb_black.png' },
    { name: 'orb_pink', src: 'assets/images/items/orb_pink.png' },
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

const SOUND_LIST = [
    //effects
    { name: 'shoot', src: 'assets/sounds/effects/shot.wav' },
    { name: 'powerup', src: 'assets/sounds/effects/coin.wav' },
    { name: 'explosion', src: 'assets/sounds/effects/explosion.ogg', volume: 0.2 },
    { name: 'menu', src: 'assets/sounds/effects/menu.wav', volume: 0.2 },
    { name: 'shield', src: 'assets/sounds/effects/shield.wav' },
    { name: 'warpout', src: 'assets/sounds/effects/warpout.ogg' },


    //music
    { name: 'cyclotron', src: 'assets/sounds/music/cyclotron.mp3' },
    { name: 'bg', src: 'assets/sounds/music/bg.wav' },
];

//main events
function init() {

    //load game state
    loadGame();

    //setup canvas
    canvas.width = GAME_WIDTH;
    canvas.height = GAME_HEIGHT;

    DrawManager.init(context);

    // AudioManager.toogleMute(); //start muted

    AudioManager.init(SOUND_LIST);

    KeyManager.init((type, code, e) => {
        input(type, code, e);
    });

    ScreenManager.add('start', StartScreen);
    ScreenManager.add('load', LoadScreen);
    ScreenManager.add('menu', MenuScreen);
    ScreenManager.add('intro', IntroScreen);
    ScreenManager.add('gameover', GameOverScreen);
    ScreenManager.add('game_end', GameEndScreen);
    ScreenManager.add('settings', SettingScreen);
    ScreenManager.add('game', GameScreen);

    GameScreenManager.add('game_level_select', LevelSelectScreen);
    // GameScreenManager.add('game_level_select', OtherLevelSelectScreen);
    GameScreenManager.add('game_play', GamePlayScreen);
    GameScreenManager.add('game_pause', GamePauseScreen);
    GameScreenManager.add('game_level_completed', LevelCompletedScreen);


    ScreenManager.change('start');
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
    init();
    requestAnimationFrame(() => {
        loop();
    });
}

start();