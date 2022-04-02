package entities;

import gamestates.PlayState;

class WorldObject {
	public var x = 0.;
	public var y = 0.;

	public var dead = false;

	var state: PlayState;
	public function new(state: PlayState) {
		this.state = state;
	}

	public function tick(dt: Float) {}

	public function draw() {

	}
}