package entities;

import h2d.Bitmap;
import elke.graphics.Animation;

class Guy extends Actor {
	var sprite: Animation;
	var originX = 16;
	var originY = 32;
	var flipX = false;

	public var pickupRadius = 20.;

	public var maxFruit = 4;

	public var heldFruit: Array<Fruit> = [];

	public function new(?s) {
		super(s);

		maxSpeed = 9;
		moveSpeed = 1.0;
		friction = 0.7;

		sprite = hxd.Res.img.guy_tilesheet.toAnimation();
		var tName = hxd.Res.img.guy_tilesheet.name;
		if (s.atlas.getNamedTile(tName) == null){
			var tile = s.atlas.addNamedTile(sprite.tileSheet.tile, tName);
			sprite.tileSheet.tile = tile;
		}
	}

	public function pickupFruit(fruit: Fruit) {
		if (heldFruit.length >= maxFruit) {
			return;
		}

		if (fruit.held) {
			return;
		}
		fruit.held = true;
		heldFruit.push(fruit);
	}

	var lastFrame = -1;
	var sounds = [
		hxd.Res.sound.steps._1,
		hxd.Res.sound.steps._2,
		hxd.Res.sound.steps._3,
		hxd.Res.sound.steps._4,
		hxd.Res.sound.steps._5,
	];

	function enterFrame(index: Int) {
		if (index == 3 || index == 5) {
			state.game.sound.playWobble(sounds.randomElement(), 0.1);
		}
	}

	var toThrow: Fruit = null;
	public function startAim() {
		if (heldFruit.length == 0) {
			return false;
		}

		toThrow = heldFruit[0];

		return true;
	}

	override function tick(dt:Float) {
		super.tick(dt);
		sprite.update(dt);

		var p = sprite.getSlice("leftArm");
		var rightArm = sprite.getSlice("rightArm");

		if (p != null) {
			var px = x + p.x - originX;
			if (flipX) {
				px = x + sprite.tileSheet.width - originX - p.x - 2;
			}
			var py = -originY + p.y;

			var spaceY = 0.;
			for (f in heldFruit) {
				f.x = px;
				f.y = y - 0.2 - spaceY * 0.01;
				f.z = (py + spaceY) + 2;
				f.vz = 0.;
				spaceY -= 4;
			}
		}

		if (vx * vx + vy * vy > 1) {
			sprite.play("walk");
		} else {
			sprite.play("idle");
		}

		if (sprite.currentFrame != lastFrame) {
			enterFrame(sprite.currentFrame);
			lastFrame = sprite.currentFrame;
		}

		if (vx < -0.4) {
			flipX = true;
		} else if (vx > 0.4) {
			flipX = false;
		}
	}

	override function draw() {
		var t = sprite.getCurrentTile();
		var bx = Math.round(x - (flipX ? -originX : originX));
		var by = Math.round(y - originY);
		var sx = flipX ? -1 : 1;

		state.actorGroup.addTransform(bx, by, sx, 1, 0, t);
	}
}