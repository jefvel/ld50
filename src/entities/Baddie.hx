package entities;

import h3d.Vector;
import elke.graphics.Animation;

class Baddie extends Actor {
	var sprite: Animation;
	var flipX = false;

	public var pickupRadius = 20.;

	public var target: Actor = null;
	var color = new Vector(1, 1, 1);

	public function new(?s) {
		super(s);

		maxSpeed = 4;
		moveSpeed = 0.2;
		friction = 0.7;
		radius = 20.;
		mass = 4.0;

		pickupable = false;
		catapultable = true;

		score = 200;

		volcanoValue = 4.0;

		name = "Baddie";

		life = 3.;

		sprite = hxd.Res.img.baddie_tilesheet.toAnimation();
		sprite.originX = 32;
		sprite.originY = 64;

		var tName = sprite.tileSheet.name;
		if (s.atlas.getNamedTile(tName) == null){
			var tile = s.atlas.addNamedTile(sprite.tileSheet.tile, tName);
			sprite.tileSheet.tile = tile;
		}

		customShadow = state.baddieShadowTile;

		edgePadding = 32.;

		type = Baddie;
	}

	var hurting = false;
	override function hurt(damage:Float) {
		if (dead) {
			return;
		}

		life -= damage;
		hurting = true;

		if (target != null && target.heldBy == this) {
			target.heldBy = null;
			target.held = false;
		}

		target = null;
		eating = false;
		attacking = false;
		color.set(100, 100, 100);
		if (life <= 0) {
			knockout();
		} else {
			sprite.play("thrown", false, true, 0, resetHurt);
		}
	}

	function resetHurt(_) {
		hurting = false;
	}

	override function onPickup() {
		super.onPickup();
		uncollidable = true;
		target = null;
		eating = false;
	}

	override function onThrown() {
		super.onThrown();
		uncollidable = false;
	}

	public var knockedOut = false;
	var knockoutTime = 0.0;
	public function knockout() {
		pickupable = true;
		knockedOut = true;
		knockoutTime = 5.0;
		hurting = false;
		eating = false;
		if (life <= -2) {
			kill();
		}
	}

	override function kill() {
		if (dead) return;
		dead = true;
		state.addScore(Math.round(score * 0.5));
		sprite.play("dead", false, true, 0, finishDead);
	}

	function finishDead(_) {
		fadingOut = true;
		hideShadow = true;
		uncollidable = true;
	}

	public function resetKnockout() {
		pickupable = false;
		knockedOut = false;
		life = 3;
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
			state.game.sound.playWobble(sounds.randomElement(), 0.04);
		}

		var eatFrame = 11;
		if (index == eatFrame) {
			if (target != null) {
				target.onRemove();
			}
		}
	}

	function pickTarget() {
		if (hurting) return;
		if (knockedOut) return;

		eating = false;
		attacking = false;

		var t: Actor = null;
		var d = Math.POSITIVE_INFINITY;
		for (a in state.actors) {
			if (Math.abs(a.z) > 2) continue;
			var valid = false;
			if (a.type == Tree && needToEat > 0) valid = true;
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

		if (target == null) {
			needToEat = 4.0;
		}

		target = t;
	}

	override function onAdd() {
		super.onAdd();
		state.baddies.push(this);
	}

	override function onRemove() {
		super.onRemove();
		state.baddies.remove(this);
	}

	var toThrow: Fruit = null;
	
	var attacking = false;
	var needToEat = 0.0;

	var eating = false;

	function eatTarget() {
		needToEat = 8.0;
		eating = true;
		target.held = true;
		target.heldBy = this;
		sprite.play("eat", false, true, 0, finishEat);
		state.game.sound.playWobble(hxd.Res.sound.eat, 0.21);
	}

	function finishEat(_) {
		eating = false;
		target = null;
	}

	function doTargetStuff() {
		if (target.dead) {
			target = null;
			return false;
		}

		if (eating) return false;
		if (target.held) {
			target = null;
			return false;
		}

		if (needToEat < 0 && target.type != Fruit) {
			target = null;
			return false;
		}

		var dx = target.x - x;
		if (dx < 0) dx += 16; else dx -= 16;
		var dy = target.y - y;
		var l = Math.sqrt(dx * dx + dy * dy);
		dx /= l;
		dy /= l;
		var r = radius;
		if (target.type == Tree) {
			r += 10;
		}
		vx += dx * Math.min(l - radius + 5, moveSpeed);
		vy += dy * Math.min(l - radius + 5, moveSpeed);
		if (l < r) {
			if (target.type == Tree) {
				var t: Tree = cast target;
				t.shake();
			}

			if (target.type == Fruit) {
				eatTarget();
			}

			return true;
		}

		return false;
	}

	var fadingOut = false;

	override function tick(dt:Float) {
		super.tick(dt);
		sprite.update(dt);

		color.r += (1 - color.r) * 0.3;
		color.g += (1 - color.g) * 0.3;
		color.b += (1 - color.b) * 0.3;

		if (state.lost) return;

		if (dead) {
			vx *= 0.8;
			vy *= 0.8;
			if (fadingOut) {
				alpha *= 0.9;
				if (alpha <= 0.05) {
					onRemove();
				}
			}
			return;
		}

		needToEat -= dt;
		if (knockedOut && !thrown && !held) {
			knockoutTime -= dt;
			if (knockoutTime <= 0) {
				resetKnockout();
			}
		}

		var rightArm = sprite.getSlice("rightArm");
		var spaceY = 0.;

		attacking = false;

		if (!thrown && !held) {
			if (target == null) {
				pickTarget();
			} else {
				attacking = doTargetStuff();
			}
		}

		if (Math.abs(z) > 1) moveSpeedMultiplier = 3.0;
		else moveSpeedMultiplier = 1.0;

		var f = toThrow;
		if (f != null) {
			var p = rightArm;

			var px = x + p.x - sprite.originX;
			if (flipX) {
				px = x + sprite.tileSheet.width - sprite.originX - p.x - 2;
			}
			var py = -sprite.originY + p.y;

			f.x = px;
			f.y = y - 0.2 - spaceY * 0.01;
			f.z += ((py + spaceY) + 2 - f.z) * 0.5;
			f.vz = 0.;

			if (f != toThrow) {
				spaceY -= 4;
			}
		}

		updateAnim(dt);

		if (held || thrown) {
			uncollidable = true;
		} else {
			uncollidable = false;
		}

		if (sprite.currentFrame != lastFrame) {
			enterFrame(sprite.currentFrame);
			lastFrame = sprite.currentFrame;
		}

		var lookX = vx;
		if (attacking) {
			lookX = target.x - x;
		}

		if (lookX < -0.1) {
			flipX = true;
		} else if (lookX > 0.1) {
			flipX = false;
		}

		if (thrown) {
			friction = 0.99;
			groundFriction = 0.5;
			if (vx * vx + vy * vy < 0.3 * 0.3 && Math.abs(z) < 1) {
				thrown = false;
			}
		} else {
			friction = 0.9;
			groundFriction = 1.0;
		}
	}

	function updateAnim(dt) {
		if (hurting) return;
		if (dead) return;

		if (!thrown && !held) {
			sprite.originY = 64;
			if (attacking && target.type != Fruit) {
				target.hurt(dt);
				sprite.play("shake");
			} else if(eating) {
			}else if (knockedOut) {
				sprite.play("knockout");
			}else if (vx * vx + vy * vy > 1) {
				sprite.play("walk");
			} else {
				sprite.play("idle");
			}
		} else {
			sprite.play("thrown");
			if (heldBy != null) {
				if (heldBy.type == Man) {
					sprite.originY = 70;
				} else {
					sprite.originY = 32;
				}
			}
		}
	}

	override function draw() {
		var t = sprite.getCurrentTile();
		var bx = Math.round(x);
		var by = Math.round(y);
		var sx = flipX ? -1 : 1;

		color.a = alpha;

		state.actorGroup.addTransform(bx, by, sx, 1, 0, color, t);
	}
}