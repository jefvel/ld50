package entities;

import h2d.Tile;

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

	public var groundFriction = 0.9;

	public var hideShadow = false;

	public var customShadow: Tile = null;

	var radius: Float = 8.;
	var mass: Float = 1.;
	var uncollidable: Bool = false;
	var filterGroup: Int = 0;

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