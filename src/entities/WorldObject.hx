package entities;

import h2d.Tile;
import gamestates.PlayState;

class WorldObject {
	public var x = 0.;
	public var y = 0.;
	public var z = 0.;

	public var rotation: Float = 0.;

	public var keepInBounds = true;
	public var edgePadding = 0.;

	public var dead = false;
	public var held = false;

	public var tile: Tile = null;

	var state: PlayState;
	public function new(state: PlayState) {
		this.state = state;
		onAdd();
	}

	public function tick(dt: Float) {}

	public function onRemove(){}
	public function onAdd() {}

	public function draw() {
		if (tile != null) {
			state.actorGroup.addTransform(Math.round(x), Math.round(y + z), 1, 1, rotation, tile);
		}
	}
}