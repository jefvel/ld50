package entities;

import h2d.Tile;

class Fruit extends Actor {
	public var cdb: Data.Fruits = null;
	public var held = false;

	public function new(tile: Tile, data: Data.Fruits, s) {
		super(s);
		this.cdb = data;
		this.tile = tile;
		z = -(40 + Math.random() * 32);
	}

	public override function tick(dt:Float) {
		super.tick(dt);
		if (held) {
			vz = 0.;
		}
	}
}