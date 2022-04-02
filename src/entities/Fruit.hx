package entities;

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
	}

	public override function tick(dt:Float) {
		super.tick(dt);
		if (held) {
			vz = 0.;
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
				remove();
			}
		}
	}

	function remove() {
		state.removeActor(this);
		state.removeFruit(this);
	}
}