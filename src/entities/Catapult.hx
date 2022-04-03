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

	var toCatapult: Array<Actor> = [];
	public function putIntoCatapult(a: Actor) {
		if (a.held || a.thrown) return;
		if (!a.catapultable) return;
		a.uncollidable = true;
		a.held = true;
		a.heldBy = this;
		toCatapult.push(a);
	}

	var lastFrame = -1;
	function enterFrame(index: Int) {
		if (index == 3) {
			var threwBaddie = false;
			for (f in toCatapult) {
				f.vy = -20 - Math.random() * 20;
				f.vz = -11 - Math.random() * 10;
				f.vx = (Math.random() - 0.5) * 4; 
				f.thrown = true;
				f.keepInBounds = false;
				f.maxSpeed = 35.;
				f.catapulted = true;
				if (f.type == Baddie) {
					threwBaddie = true;
				}
			}

			if (toCatapult.length > 0) {
				state.game.sound.playWobble(hxd.Res.sound.fruitfly, 0.2);
				if (threwBaddie) {
					state.game.sound.playWobble(hxd.Res.sound.baddiefling, 0.2);
				}
			}

			toCatapult.splice(0, toCatapult.length);
		}
	}

	function positionThingsInCatapult() {
		var rightArm = sprite.getSlice("bowl");

		var spaceY = 0.;

		var ratio = firing ? 1 : 0.5;

		for(f in toCatapult) {
			var p = rightArm;

			var px = x + p.x - sprite.originX;
			var py = -sprite.originY + p.y;

			f.x += (px - f.x) * ratio;
			f.y += ((y + 0.2 - spaceY * 0.01) - f.y) * ratio;
			f.z += ((py + spaceY) + 2 - f.z) * 0.5;
			f.vz = 0.;

			spaceY -= 4;
		}
	}

	var untilFire = 1.0;
	override function tick(dt:Float) {
		super.tick(dt);
		sprite.update(dt);
		untilFire -= dt;
		if (untilFire < 0) {
			fire();
		}

		positionThingsInCatapult();

		if (!firing) {
			for (a in state.actors) {
				if (a == this) continue;
				if (a.held) continue;
				if (Math.abs(a.z) > 1) continue;
				if (!a.catapultable) continue;

				var dx = a.x - x;
				var dy = a.y - y;
				if (dx * dx  + dy * dy < 64 * 64) {
					putIntoCatapult(a);
				}
			}
		}

		if (sprite.currentFrame != lastFrame) {
			enterFrame(sprite.currentFrame);
			lastFrame = sprite.currentFrame;
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
