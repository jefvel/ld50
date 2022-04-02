package entities;

import h2d.Tile;
import gamestates.PlayState;

class WorldObject {
	public var x = 0.;
	public var y = 0.;
	public var z = 0.;

	public var keepInBounds = true;

	public var dead = false;

	public var tile: Tile = null;

	var state: PlayState;
	public function new(state: PlayState) {
		this.state = state;
	}

	public function tick(dt: Float) {}

	public function draw() {
		if (tile != null) {
			state.actorGroup.add(Math.round(x), Math.round(y + z), tile);
		}
	}
}