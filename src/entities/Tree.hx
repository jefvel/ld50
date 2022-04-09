package entities;

import h3d.Vector;
import elke.T;
import elke.utils.EasedFloat;

class Tree extends Actor {
	var shakeForce = new EasedFloat(0, 0.4);
	public var growTime = .0;

	var fallVal = new EasedFloat(0, 1.1);
	var heldFruit: Array<Fruit> = [];

	var maxLife = 30.;

	public function new(s) {
		super(s);
		growTime = (Math.random() * 0.1 + 0.9) * state.timePerFruit;

		shakeForce.easeFunction = T.elasticOut;


		tile = state.atlas.addNamedTile(hxd.Res.img.tree.toTile(), 'tree');
		tile.dx = -29;
		tile.dy = -110;
		mass = 0;
		type = Tree;

		life = maxLife;
	}

	public function revive() {
		life = maxLife;
		dead = false;
		fallVal.easeFunction = T.elasticOut;
		fallVal.value = 0.;
		uncollidable = false;
		hideShadow = false;
	}

	var shakeSfxTimeout = 0.;

	public override function hurt(damage:Float) {
		super.hurt(damage);
		if (shakeSfxTimeout < 0) {
			shakeSfxTimeout = 0.8;
			state.game.sound.playWobble(hxd.Res.sound.treeshake, 0.2);
		}
	}

	public function shake() {
		shakeForce.setImmediate(1);
		shakeForce.value = 0.;
	}

	override function kill() {
		if (dead) {
			return;
		}
		fallVal.easeFunction = T.bounceOut;
		if (Math.random() > 0.5) {
			fallVal.value = Math.PI * 0.5;
		} else {
			fallVal.value = -Math.PI * 0.5;
		}

		hideShadow = true;
		uncollidable = true;

		for (f in heldFruit) f.ripeTime = 0;

		dead = true;
		super.kill();
	}


	function spawnFruit() {
		var frkinds = Data.fruits.all.toArrayCopy();
		var kind = frkinds.randomElement();
		var f = new Fruit(state.getFruitTile(kind), kind, state);
		f.held = true;
		f.heldBy = this;
		f.x = this.x;
		f.y = this.y;
		f.offsetX = 2 * 56 * (Math.random() * 0.5);
		f.offsetY = 2 * 35 * (Math.random() * 0.5);
		f.hideShadow = true;

		heldFruit.push(f);
	}


	override function tick(dt:Float) {
		super.tick(dt);
		var shaking = shakeForce.value > 0.7;

		shakeSfxTimeout -= dt;

		if (!dead) {
			growTime += dt;
			if (growTime >= state.timePerFruit) {
				growTime = Math.random();
				spawnFruit();
			}
		}


		if (!dead) {
			rotation = fallVal.value + Math.sin(state.time * 90) * 0.05 * shakeForce.value;
		} else {
			rotation = fallVal.value;
		}

		for (f in heldFruit) {
			f.x = x - tile.width * 0.5 + f.offsetX + 4;
			f.y = y + 1.1;
			f.z = -84 + f.offsetY;
			f.vz = f.vx = f.vy = 0;
			if (f.isRipe()) {
				f.held = false;
				f.vx = (Math.random() - 0.5) * 9;
				f.vy = (Math.random() - 0.5) * 9;
				f.vz = (-Math.random()) * 4;
				f.heldBy = null;
				f.hideShadow = false;
				heldFruit.remove(f);
			}
		}
	}
	override function draw() {
		super.draw();
		if (life < maxLife && !dead) {
			state.renderHpBar(x + 2, y - 112, life, maxLife);
		}
	}
}