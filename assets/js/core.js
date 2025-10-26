//core.js

const DrawManager = {
    //context2D
    _c: null,
    init: function (c) {
        this._c = c;
    },
    fillRect: function (x, y, w, h, { color = 'white' } = {}) {
        this._c.fillStyle = color;
        this._c.fillRect(x, y, w, h);
    },
    fillText: function (t, x, y, { color = 'white', size = 24, align = 'left', baseline = 'top', bold = false } = {}) {
        this._c.fillStyle = color;
        this._c.font = `${bold ? 'bold ' : ''}${size}px monospace`;
        this._c.textAlign = align;
        this._c.textBaseline = baseline;
        this._c.fillText(t, x, y);

    },
    fillCircle: function (x, y, r, { color = 'white' } = {}) {
        this._c.fillStyle = color;
        this._c.beginPath();
        this._c.arc(x, y, r, 0, 2 * Math.PI);
        this._c.fill();
    },
    drawImage: function (img, dst = {}, src = {}, { rotate = 0, pulse = null } = {}) {
        //rotate is in degrees
        this._c.save();
        if (rotate != 0) {
            this._c.translate(dst.x + dst.width / 2, dst.y + dst.height / 2);
            this._c.rotate(rotate * Math.PI / 180);
            this._c.translate(-(dst.x + dst.width / 2), -(dst.y + dst.height / 2));
        }

        if (pulse && pulse.amplitude !== undefined && pulse.speed !== undefined) {
            // console.log('Pulse effect applied:', pulse);
            const time = Date.now() / 1000; // Current time in seconds
            const scale = 1 + Math.sin(time * pulse.speed) * pulse.amplitude;
            this._c.translate(dst.x + dst.width / 2, dst.y + dst.height / 2);
            this._c.scale(scale, scale);
            this._c.translate(-(dst.x + dst.width / 2), -(dst.y + dst.height / 2));
        }

        this._drawImageInternal(img, dst, src);
        this._c.restore();
    },
    _drawImageInternal: function (img, dst = {}, src = {}) {
        if (src.x != undefined && src.y != undefined && src.width != undefined && src.height != undefined) {
            this._c.drawImage(img,
                src.x, src.y, src.width, src.height,
                dst.x, dst.y, dst.width, dst.height
            );
        } else {
            this._c.drawImage(img,
                dst.x.toFixed(5), dst.y.toFixed(5), dst.width, dst.height
            );
        }
    }
};

const KeyManager = {
    _k: {},
    init: function (callback) {
        document.addEventListener('keydown', (e) => {
            if (e.repeat) return;
            this._k[e.code] = true;
            callback(e.type, e.code, e);

            if (e.code == 'Escape') {
                e.preventDefault();
                e.stopPropagation();
                return false;
            }
        });

        document.addEventListener('keyup', (e) => {
            e.preventDefault();
            delete this._k[e.code];
            callback(e.type, e.code, e);
        });
    },
    isDown: function (code) {
        return !!this._k[code];
    },
};

const AudioManager = {
    _sounds: {},
    _allSounds: [],
    _muted: false,
    init: function (list) {
        let lista = Array.isArray(list) ? list : [list];
        let counter = 0;
        lista.forEach((l) => {
            let { name, src, pool = 10, volume = 0.5 } = l;
            let sound = new Audio(src);

            // console.log('Loading sound:', name, l);

            sound.onloadeddata = () => {
                this._sounds[name] = [];
                for (let i = 0; i < pool; i++) {
                    let clone = sound.cloneNode();
                    clone.preload = true;
                    clone.volume = volume;
                    clone.muted = this._muted;
                    this._sounds[name].push(clone);
                    this._allSounds.push(clone);
                }
                counter++;
                if (counter == lista.length) {
                    console.log('All sounds loaded');
                }
            };
        });
    },
    play: function (name) {
        let pool = this._sounds[name];
        if (pool) {
            for (let i = 0; i < pool.length; i++) {
                let sound = pool[i];
                if (sound.currentTime == 0 || sound.ended) {
                    sound.play().catch(console.log);
                    break;
                }
            }
        }
    },
    playLoop: function (name) {
        let pool = this._sounds[name];
        if (pool) {
            let sound = pool[0];
            sound.loop = true;
            sound.play().catch(console.log);
        }
    },
    toogleMute: function () {
        this._muted = !this._muted;
        this._allSounds.forEach((sound) => {
            sound.muted = this._muted;
        });
    },
    isMuted: function () {
        return this._muted;
    },
};

const ImageManager = {
    _temp: [],
    _images: {},
    init: function (list) {
        this._temp = Array.isArray(list) ? list : [list];
    },
    load: function (callback) {
        let loadedCount = 0;
        let totalCount = this._temp.length;

        this._temp.forEach((imgData) => {
            let img = new Image();
            img.src = imgData.src;
            img.onload = () => {
                this._images[imgData.name] = img;
                loadedCount++;
                if (loadedCount >= totalCount) {
                    if (callback) callback();
                }
            };
            img.onerror = () => {
                console.error(`Failed to load image: ${imgData.src}`);
                loadedCount++;
                if (loadedCount >= totalCount) {
                    if (callback) callback();
                }
            };
        });
    },
    get: function (name) {
        return this._images[name];
    },
};

const Utils = {
    collision: function (a, b) {
        return a.x < b.x + b.width &&
            a.x + a.width > b.x &&
            a.y < b.y + b.height &&
            a.y + a.height > b.y;
    },
    randomInt: function (min, max) {
        return Math.floor(Math.random() * (max - min) + min);
    },
    randomDouble: function (min, max) {
        return Math.random() * (max - min) + min;
    },
    randomItem: function (list) {
        return list[Math.floor((Math.random() * list.length))];
    },
    clamp: function (value, min, max) {
        return Math.min(Math.max(value, min), max);
    },
    weightedRandom: function (items) {
        // Calculate total weight
        const totalWeight = items.reduce((sum, { weight }) => sum + weight, 0);

        // Generate random number between 0 and totalWeight
        const random = Math.random() * totalWeight;

        // Find the item that corresponds to the random number
        let currentWeight = 0;
        for (const { item, weight } of items) {
            currentWeight += weight;
            if (random < currentWeight) {
                return item;
            }
        }

        // Fallback (should rarely happen due to floating point precision)
        return items[items.length - 1].item;
    }
};

const FSM = function (name = 'default') {
    return {
        name: name,
        _s: {},
        current: [],
        add: function (n, s) {
            this._s[n] = s;
            s.name = n;
        },
        change: function (n, d = {}) {
            let s = this._s[n];
            if (!s) {
                console.error(`No scene found: ${n}`);
                return;
            }
            this.current.forEach((_) => {
                _.exit();
            });

            this.current = [s];
            s.enter(d);
        },

        pop: function () {
            if (this.current.length <= 1) return;

            let s = this.current.shift();
            s.exit();
        },
        push: function (n, d = {}) {
            let s = this._s[n];
            if (!s) {
                console.error(`No scene found: ${n}`);
                return;
            }

            this.current.unshift(s);
            s.enter(d);
        },

        input: function (t, c, e) {
            if (!this.current.length) return;
            this.current[0].input(t, c, e);
        },
        update: function () {
            if (!this.current.length) return;
            this.current[0].update();
        },
        render: function () {
            this.current.slice().reverse().forEach((_) => {
                _.render();
            });

            //debug fsm name
            // DrawManager.fillText(`FSM: ${this.name}`, 10, GAME_HEIGHT - 20, { color: 'yellow', size: 14, bold: true, baseline: 'top' } );
        },
    };
}

const BaseScreen = function (p = {}) {

    for (const k in p) {
        this[k] = p[k];
    }

    this.name = 'screen';

    //init defaults
    this.enter = p.enter || function (data = {}) { };
    this.exit = p.exit || function () { };

    this.input = p.input || function (t, c, e) { };
    this.update = p.update || function () { };
    this.render = p.render || function () { };
}

const BaseEntity = function (p = {}) {

    //base props for entities

    //identity
    this.type = 'entity';
    //pos
    this.x = 0;
    this.y = 0;
    //size
    this.width = 32;
    this.height = 32;
    //movement
    this.vx = 0;
    this.vy = 0;
    this.friction = 1;
    this.acceleration = 1;
    //visual
    this.color = 'white';
    //state
    this.dead = false;

    for (const k in p) {
        this[k] = p[k];
    }

    this.clone = function () {

    }

    this.bounds = function ({ scale = 1 } = {}) {

        return {
            x: this.x - (this.width * (scale - 1)) / 2,
            y: this.y - (this.height * (scale - 1)) / 2,
            width: this.width * scale,
            height: this.height * scale,
        };
    }

    this.center = function () {
        return {
            x: this.x + (this.width / 2),
            y: this.y + (this.height / 2),
        };
    }

    this.centerTo = function ({ x, y } = {}) {
        if (x != undefined) {
            this.x = x - (this.width / 2);
        }
        if (y != undefined) {
            this.y = y - (this.height / 2);
        }
    }

    this.bottom = function () {
        return this.y + this.height;
    };

    this.right = function (val) {
        return this.x + this.width;
    };

    this.update = function () {

        this.emit('pre-update');

        this.updateTasks();

        this.emit('post-update');
    }

    this.render = function () {
        this.emit('pre-render');
        DrawManager.fillRect(this.x, this.y, this.width, this.height, { color: this.color });
        this.emit('post-render');
    }

    //new
    this.extend = function (_p = {}) {
        for (const k in _p) {
            this[k] = _p[k];
        }
    };

    //event system
    this.events = {};

    this.on = function (event, callback) {
        if (!this.events[event]) {
            this.events[event] = [];
        }
        this.events[event].push(callback);

        return {
            remove: () => {
                this.events[event] = this.events[event].filter((cb) => cb != callback);
            }
        };
    }

    this.emit = function (event, data = {}) {
        let cbs = this.events[event];
        if (cbs) {
            cbs.forEach((cb) => {
                cb(data);
            });
        }
    }

    //task/behavior system
    this.tasks = [];

    this.addTask = function (task) {
        //check if task is already added and reset duration
        let existing = this.tasks.find((t) => t.name == task.name);
        if (existing) {
            existing.reset();
            return;
        }
        this.tasks.push(task);
        task.onStart(this);
    }

    this.updateTasks = function () {
        this.tasks.forEach((t) => {
            t.update();
        });
        this.tasks = this.tasks.filter((t) => { return !t.isComplete() });
    }

    this.removeTask = function (name) {
        let existing = this.tasks.find((t) => t.name == name);
        if (existing) {
            existing.onComplete();
            this.tasks = this.tasks.filter((t) => t != existing);
        }
    }
}

function createTask(p = {}) {

    const Task = function (p = {}) {

        this.name = p.name || 'task';
        this.powerup = p.powerup || false;
        this.duration = p.duration || 60;
        this.time = this.duration;
        this.onStart = p.onStart || function () { };
        this.onUpdate = p.onUpdate || function () { };
        this.onComplete = p.onComplete || function () { };

        this.isComplete = function () {
            return this.time <= 0;
        }

        this.update = function () {

            this.onUpdate();

            if (this.duration != Infinity) {

                this.time--;

                if (this.isComplete()) {
                    this.onComplete();
                }
            }
        }

        this.reset = function () {
            this.time = this.duration;
        }
    }

    return {
        create: function () {
            return new Task(p);;
        },
        name: p.name,
    };
}