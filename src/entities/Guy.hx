package entities;

import elke.T;
import h2d.Bitmap;
import elke.graphics.Animation;

class Guy extends Actor {
	var sprite: Animation;
	var originX = 16;
	var originY = 32;
	var flipX = false;

	var shaking = false;

	public var pickupRadius = 20.;

	public var maxFruit = 4;

	public var heldFruit: Array<Actor> = [];

	public var throwLine: ThrowLine;

	public function new(?s) {
		super(s);

		maxSpeed = 9;
		moveSpeed = 1.1;
		friction = 0.7;

		sprite = hxd.Res.img.guy_tilesheet.toAnimation();
		sprite.originX = originX;
		sprite.originY = originY;
		var tName = hxd.Res.img.guy_tilesheet.name;
		if (s.atlas.getNamedTile(tName) == null){
			var tile = s.atlas.addNamedTile(sprite.tileSheet.tile, tName);
			sprite.tileSheet.tile = tile;
		}

		throwLine = new ThrowLine(state.foreground, state);
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
			state.game.sound.playWobble(sounds.randomElement(), 0.08);
		}
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
		state.game.sound.playWobble(hxd.Res.sound.pickup, 0.3);
	}

	var toThrow: Actor = null;
	var aiming = false;
	var throwing = false;
	public function startAim() {
		if (aiming) {
			return false;
		}


		if (heldFruit.length == 0) {
			return false;
		}

		toThrow = null;
		for (f in heldFruit) {
			if (f.type == Baddie) {
				toThrow = f;
				break;
			}
		}

		if (toThrow == null) {
			toThrow = heldFruit[0];
		}

		toThrow.beingThrown = true;
		aiming = true;

		if (toThrow.type == Baddie) {
			throwLine.toThrowSize = 40;
		} else {
			throwLine.toThrowSize = 30;
		}

		throwLine.active = true;
		throwLine.toThrow = toThrow;

		state.game.sound.playWobble(hxd.Res.sound.preparethrow, 0.3);

		//shaking = true;

		return true;
	}

	var timeSinceAim = 0.;

	public function throwFruit() {
		if (!aiming) {
			return;
		}

		//shaking = false;
		toThrow.beingThrown = false;

		toThrow.held = false;
		toThrow.heldBy = null;
		toThrow.thrown = true;

		heldFruit.remove(toThrow);
		toThrow.vz = -4;

		toThrow.onThrown();
		
		var power = 45.;
		var interpThrow = T.quintIn(throwLine.throwPower);

		toThrow.vx = throwLine.throwX * interpThrow * power;
		toThrow.vy = throwLine.throwY * interpThrow * power;

		state.game.sound.playWobble(hxd.Res.sound._throw, 0.3);

		toThrow = null;
		aiming = false;
		throwing = true;
		sprite.play("throw", false, true, 0, finishThrow);

		throwLine.active = false;
	}

	function finishThrow(_) {
		throwing = false;
	}

	public var lookX = 0.;
	public var lookY = 0.;

	override function tick(dt:Float) {
		super.tick(dt);
		sprite.update(dt);

		var leftArm = sprite.getSlice("leftArm");
		var rightArm = sprite.getSlice("rightArm");

		var spaceY = 0.;

		//if (!aiming) {
		var rx = state.game.gamepads.getRightStickX();
		var ry = state.game.gamepads.getRightStickY();
		if (rx * rx + ry * ry > 0.6 * 0.6) {
			timeSinceAim = 0.;
			lookX = rx;
			lookY = ry;
		} else {
			timeSinceAim += dt;
		}

		if (timeSinceAim > 0.5) {
			lookX = vx;
			lookY = vy;
		}

		moveSpeedMultiplier = (aiming || throwing) ? 0.2 : 1;

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
			if (vx * vx + vy * vy > 0.2 * 0.2) {
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
		if (aiming || throwing) {
			lookX = throwLine.throwX;
		}

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

		if (toThrow != null) {
			throwLine.x = Math.round(toThrow.x);
			throwLine.y = Math.round(toThrow.y + toThrow.z - 8);
		}

		var r = 0.;
		if (shaking) r = Math.sin(state.time * 120) * 0.05;

		state.actorGroup.addTransform(bx, by, sx, 1, r, t);
	}
}