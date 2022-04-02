package entities;

import elke.graphics.Animation;

class Catapult extends Actor {
	var sprite: Animation;

	public var loadedItems:Array<Actor> = [];
	public var firing = false;

	public function new(?s) {
		super(s);

		sprite = hxd.Res.img.catapult_tilesheet.toAnimation();
		sprite.originX = 48;
		sprite.originY = 67;
		var tName = sprite.tileSheet.name;
		if (s.atlas.getNamedTile(tName) == null){
			var tile = s.atlas.addNamedTile(sprite.tileSheet.tile, tName);
			sprite.tileSheet.tile = tile;
		}
		sprite.play("idle");

		hideShadow = true;

		mass = 0;
		radius = 32;
	}

	public function fire() {
		if (firing) {
			return;
		}

		firing = true;
		sprite.play("fire", false, true, 0, finishFiring);
		state.game.sound.playSfx(hxd.Res.sound.firecatapult);
	}

	function finishFiring(_) {
		sprite.play("recover", false, true, 0, onRecover);
	}

	function onRecover(_) {
		firing = false;
		sprite.play("idle");
		untilFire = 5.0;
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
		var bx = Math.round(x);
		var by = Math.round(y);
		var sx = 1;

		state.actorGroup.addTransform(bx, by, sx, 1, 0, t);
	}
}
