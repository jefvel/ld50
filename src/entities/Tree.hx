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

		fallVal.easeFunction = T.bounceOut;

		tile = state.atlas.addNamedTile(hxd.Res.img.tree.toTile(), 'tree');
		tile.dx = -29;
		tile.dy = -110;
		mass = 0;
		type = Tree;

		life = maxLife;
	}

	public function shake() {
		shakeForce.setImmediate(1);
		shakeForce.value = 0.;
	}

	override function kill() {
		if (dead) {
			return;
		}
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

		if (!dead) {
			growTime += dt;
			if (growTime >= state.timePerFruit) {
				growTime = Math.random();
				spawnFruit();
			}
		}


		if (!dead) {
			rotation = Math.sin(state.time * 90) * 0.05 * shakeForce.value;
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
		var bgColor = new Vector(1, 1, 1, 0.6);
		var color = Vector.fromColor(0xffb42313);
		var hpBarWidth = 64;
		var hpBarHeight = 4;
		var sx = Math.round(x + -hpBarWidth * 0.5 + 2);
		var sy = Math.round(y + -112 - 8);
		if (life < maxLife && !dead) {
			state.hpBarsGroup.addTransform(sx, sy, hpBarWidth, hpBarHeight, 0, bgColor, state.hpBarTile);
			var l = Math.max(0, life) / maxLife;
			state.hpBarsGroup.addTransform(sx, sy, Math.round(hpBarWidth * l), hpBarHeight, 0, color, state.hpBarTile);
		}
	}
}