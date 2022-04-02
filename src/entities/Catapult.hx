package entities;

import elke.graphics.Animation;

class Catapult extends Actor {
	var sprite: Animation;
	var originX = 48;
	var originY = 67;

	public var loadedItems:Array<Actor> = [];
	public var firing = false;

	public function new(?s) {
		super(s);

		sprite = hxd.Res.img.catapult_tilesheet.toAnimation();
		var tName = sprite.tileSheet.name;
		if (s.atlas.getNamedTile(tName) == null){
			var tile = s.atlas.addNamedTile(sprite.tileSheet.tile, tName);
			sprite.tileSheet.tile = tile;
		}
		sprite.play("idle");

		hideShadow = true;
	}

	public function fire() {
		if (firing) {
			return;
		}

		firing = true;
		sprite.play("fire", false, true, 0, finishFiring);
	}

	function finishFiring(_) {
		firing = false;
		sprite.play("idle");
		untilFire = 1.0;
	}

	var untilFire = 1.0;
	override function tick(dt:Float) {
		super.tick(dt);
		sprite.update(dt);
		untilFire -= dt;
		if (untilFire < 0) {
			fire();
		}

	}

	override function draw() {
		super.draw();
		var t = sprite.getCurrentTile();
		var bx = Math.round(x - originX);
		var by = Math.round(y - originY);
		var sx = 1;

		state.actorGroup.addTransform(bx, by, sx, 1, 0, t);
	}
}
