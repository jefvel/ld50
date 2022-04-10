package entities;

import h3d.Vector;
import elke.T;
import h2d.Tile;

typedef TrailPoint = {
	x: Float,
	y: Float,
	a: Float,
	tile: h2d.Tile,
}

class Fruit extends Actor {
	public var cdb: Data.Fruits = null;
	var trail: Array<TrailPoint> = [];

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

		hitTimeout -= dt;
		tp -= dt;

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

		if (thrown && !catapulted) {
			var fmax = maxSpeed * 0.5;
			var weakShot = vx * vx + vy * vy < fmax * fmax;
			if (tp < 0 && !weakShot) {
				tp = 0.001;
				var dx = x - lx;
				var dy = y + z - ly;

				var segs = 4;
				for (i in 0...segs) {
					var t = trail[tIndex];
					if (t == null) {
						t = {x: 0, a: 1, y: 0, tile: tile.clone()};
						trail.push(t);
					}

					t.x = Math.round(x - dx * (i / segs));
					t.y = Math.round(y + z - dy * (i / segs));
					t.a = 1.0;

					tIndex ++;
					tIndex %= maxTrails;
				}
				lx = x;
				ly = y + z;
			}
		} else {
			lx = x;
			ly = y + z;
		}

		for (t in trail) {
			t.a *= 0.8;
		}
	}

	public var ripeTime = 5.0;
	var maxRipeTime = 5.0;
	public function isRipe() {
		return ripeTime <= 0.;
	}

	var lx = 0.;
	var ly = 0.;
	var tp = 0.2;
	var maxTrails = 18;
	var tIndex = 0;
	var tColor = new Vector();
	override function draw() {
		for (t in trail) {
			if (t.a > 0.02) {
				tColor.set(100,100, 100, t.a * 0.8);
				var s = scale - t.a * 0.1;
				state.actorGroup.addTransform(Math.round(t.x), Math.round(t.y), s, s, rotation, tColor, t.tile);
			}
		}
		super.draw();
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