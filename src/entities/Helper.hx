package entities;

import elke.graphics.Animation;

class Helper extends Actor {
	var sprite: Animation;
	var originX = 16;
	var originY = 32;
	var flipX = false;

	var shaking = false;

	public var pickupRadius = 20.;

	public var maxFruit = 1;

	public var heldFruit: Array<Actor> = [];

	public function new(?s) {
		super(s);

		maxSpeed = 0.6;
		moveSpeed = 1.0;
		friction = 0.7;

		sprite = hxd.Res.img.helper_tilesheet.toAnimation();
		sprite.originX = originX;
		sprite.originY = originY;
		var tName = hxd.Res.img.helper_tilesheet.name;
		if (s.atlas.getNamedTile(tName) == null){
			var tile = s.atlas.addNamedTile(sprite.tileSheet.tile, tName);
			sprite.tileSheet.tile = tile;
		}

		type = Man;
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
			//state.game.sound.playWobble(sounds.randomElement(), 0.1);
		}
	}

	var target: Actor = null;
	function pickTarget() {
		var t: Actor = null;
		var d = Math.POSITIVE_INFINITY;
		for (a in state.actors) {
			if (Math.abs(a.z) > 2) continue;
			var valid = false;
			if (a.type == Fruit && !a.held) valid = true;

			if (!valid) continue;
			if (a.dead) continue;

			var dx = a.x - x;
			var dy = a.y - y;

			var lsq = dx * dx + dy * dy;
			if (lsq < d) {
				t = a;
				d = lsq;
			}
		}

		target = t;
	}

	function doTargetStuff() {
		if (target == null) return false;

		if (target.held && target.heldBy != this) {
			target = null;
			return false;
		}

		var dx = target.x - x;
		if (dx < 0) dx += 16; else dx -= 16;
		var dy = target.y - y;
		var l = Math.sqrt(dx * dx + dy * dy);
		dx /= l;
		dy /= l;
		vx += dx * Math.min(l - radius + 5, moveSpeed);
		vy += dy * Math.min(l - radius + 5, moveSpeed);
		if (l < radius) {
			if (target.type == Fruit) {
				pickupFruit(target);
				target = state.catapult;
			} else if (target.type == Catapult) {
				target = null;
			}

			return true;
		}

		return false;
	}

	override function kill() {
		if (dead) {
			return;
		}
		super.kill();
		state.game.sound.playSfx(hxd.Res.sound.playerdead, 0.7);
	}

	public function pickupFruit(fruit: Actor) {
		if (heldFruit.length >= maxFruit) {
			return;
		}

		if (fruit.held || fruit.thrown) {
			return;
		}

		fruit.held = true;
		fruit.heldBy = this;
		heldFruit.push(fruit);
		fruit.onPickup();
		//state.game.sound.playWobble(hxd.Res.sound.pickup, 0.3);
	}

	var toThrow: Actor = null;
	var aiming = false;
	var throwing = false;

	function finishThrow(_) {
		throwing = false;
	}

	override function tick(dt:Float) {
		super.tick(dt);
		sprite.update(dt);

		var leftArm = sprite.getSlice("leftArm");
		var rightArm = sprite.getSlice("rightArm");

		var spaceY = 0.;

		moveSpeedMultiplier = (aiming || throwing) ? 0.2 : 1;

		if (target == null || heldFruit.length == 0) {
			pickTarget();
		}

		doTargetStuff();

		for (f in heldFruit) {
			if (f.heldBy != this) {
				heldFruit.remove(f);
			}

			var p = f == toThrow ? rightArm : leftArm;

			var px = x + p.x - originX;
			if (flipX) {
				px = x + sprite.tileSheet.width - originX - p.x - 2;
			}
			var py = -originY + p.y;

			f.x = px;
			f.y = y - 0.2 - spaceY * 0.01;
			f.z += ((py + spaceY) + 2 - f.z) * 0.5;
			f.vz = 0.;

			if (f != toThrow) {
				spaceY -= 4;
			}
		}


		if (!throwing) {
			if (vx * vx + vy * vy > 1) {
				sprite.play("walk");
			} else {
				sprite.play("idle");
			}
		}

		if (sprite.currentFrame != lastFrame) {
			enterFrame(sprite.currentFrame);
			lastFrame = sprite.currentFrame;
		}

		var lookX = vx;

		if (lookX < -0.1) {
			flipX = true;
		} else if (lookX > 0.1) {
			flipX = false;
		}
	}

	override function draw() {
		var t = sprite.getCurrentTile();
		var bx = Math.round(x);
		var by = Math.round(y);
		var sx = flipX ? -1 : 1;

		var r = 0.;
		if (shaking) r = Math.sin(state.time * 120) * 0.05;

		state.actorGroup.addTransform(bx, by, sx, 1, r, t);
	}
}