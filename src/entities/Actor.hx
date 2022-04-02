package entities;

class Actor extends WorldObject {
	public var vx = 0.;
	public var vy = 0.;
	public var vz = 0.;
	public var friction = 0.9;
	public var moveSpeed = 0.5;
	public var maxSpeed = 20.0;

	override function tick(dt:Float) {
		super.tick(dt);

		var vSq = vx * vx + vy * vy;
		if (vSq > maxSpeed * maxSpeed) {
			vSq = Math.sqrt(vSq);
			vx /= vSq;
			vy /= vSq;
			vx *= maxSpeed;
			vy *= maxSpeed;
		}

		x += vx;
		y += vy;
		vx *= friction;
		vy *= friction;

		vz -= .9;
		z += vz;
		if (z < 0) {
			z = 0;
			vz *= -0.5;
		}
	}
}