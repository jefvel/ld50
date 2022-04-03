package entities;

import h2d.Tile;

enum ActorType {
	Fruit;
	Baddie;
	Man;
	Unspecified;
	Tree;
}

class Actor extends WorldObject {
	public var vx = 0.;
	public var vy = 0.;
	public var vz = 0.;
	public var friction = 0.9;
	public var moveSpeed = 0.5;
	public var moveSpeedMultiplier = 1.0;
	public var maxSpeed = 20.0;
	public var gravity = 0.5;
	public var bounciness = 0.3;

	public var name = "";
	public var volcanoValue = 1.;
	public var score = 100;

	public var type : ActorType = Unspecified;

	public var catapulted = false;

	public var thrown = false;
	public var heldBy: Actor = null;

	public var offsetX = .0;
	public var offsetY = 0.;

	public var beingThrown = false;

	public var groundFriction = 0.9;

	public var hideShadow = false;

	public var customShadow: Tile = null;
	
	public var catapultable = false;
	public var pickupable = false;

	public var radius: Float = 8.;
	var mass: Float = 1.;
	public var uncollidable: Bool = false;
	var filterGroup: Int = 0;

	public function onPickup() {}
	public function onThrown() {}

	override function tick(dt:Float) {
		super.tick(dt);

		var vSq = vx * vx + vy * vy;
		var max = maxSpeed * moveSpeedMultiplier;
		if (vSq > max * max) {
			vSq = Math.sqrt(vSq);
			vx /= vSq;
			vy /= vSq;
			vx *= max;
			vy *= max;
		}

		x += vx;
		y += vy;
		vx *= friction;
		vy *= friction;

		if(!held) {
			vz += gravity;
			z += vz;
			if (z > 0) {
				z = 0;
				vz *= -bounciness;
				vx *= groundFriction;
				vy *= groundFriction;
			}
		}
	}

	public var life = 3.0;
	public function hurt(damage: Float) {
		life -= damage;
		life = Math.max(0, life);
		if (life <= 0) {
			kill();
		}
	}

	public function kill() {dead = true;}

	override function onAdd() {
		super.onAdd();
		state.addActor(this);
	}

	override function onRemove() {
		super.onRemove();
		state.removeActor(this);
	}
}