package entities;

import elke.T;
import h2d.Tile;

class Fruit extends Actor {
	public var cdb: Data.Fruits = null;

	public function new(tile: Tile, data: Data.Fruits, s) {
		super(s);
		this.cdb = data;
		this.tile = tile;
		z = -(40 + Math.random() * 32);
		maxSpeed = 30.;
		bounciness = 0.5;

		uncollidable = true;
		catapultable = true;
		pickupable = true;

		type = Fruit;
		name = data.Name;

		edgePadding = 40;

		volcanoValue = data.Power;
	}

	public override function tick(dt:Float) {
		super.tick(dt);
		if (held) {
			vz = 0.;
		}

		ripeTime -= dt;
		if (scale < 1 || ripeTime > 0) {
			var t = Math.min(1 - (ripeTime / maxRipeTime), 1);
			var s = T.smoothstep(0.94, 1.0, t);
			scale = 0.75 * T.expoOut(t) + T.elasticOut(s) * 0.3;
		} else {
			scale = 1.;
		}

		if (thrown) {
			keepInBounds = false;
			friction = 0.99;
			groundFriction = 0.5;
			if (vx * vx + vy * vy < 0.3 * 0.3 && Math.abs(z) < 1) {
				thrown = false;
			}
		} else {
			friction = 0.9;
			groundFriction = 1.0;
			keepInBounds = true;
			if (x < 0 || y < 0 || x > state.level.pxWid || y > state.level.pxHei) {
				onRemove();
			}
		}
	}

	public var ripeTime = 5.0;
	var maxRipeTime = 5.0;
	public function isRipe() {
		return ripeTime <= 0.;
	}

	public override function onAdd() {
		super.onAdd();
		state.fruits.push(this);
	}

	public override function onRemove() {
		super.onRemove();
		state.removeFruit(this);
	}
}