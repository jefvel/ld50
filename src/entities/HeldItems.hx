package entities;

import h2d.Tile;
import gamestates.PlayState;

class HeldItems {
	var state: PlayState;
	var empty: Tile;
	var apple: Tile;
	var banana: Tile;
	var grape: Tile;
	var noBaddie: Tile;
	var baddie: Tile;
	var arrow: Tile;

	public var x = 0.;
	public var y = 0.;

	public function new(state: PlayState) {
		this.state = state;
		var t = state.overlayTile;
		empty = t.sub(0, 32, 16, 16, 0, -8);
		banana = t.sub(16, 32, 16, 16, 0, -8);
		apple = t.sub(32, 32, 16, 16, 0, -8);
		grape = t.sub(48, 32, 16, 16, 0, -8);
		noBaddie = t.sub(0, 48, 16, 16, 0, -8);
		baddie = t.sub(16, 48, 16, 16, 0, -8);
		arrow = t.sub(32, 48, 5, 3, -3, 0);
	}

	public function draw() {
		var totalBads = state.guy.maxBaddies;
		var bads = state.guy.enemyCount;
		var g = state.uiOverlayGroup;
		var arrowDrawn = false;

		var tx = 0.;

		var totalFruit = state.guy.maxFruit;
		for (b in 0...totalBads) {
			if (b >= bads) {
				g.add(x + tx, y, noBaddie);
			} else {
				g.add(x + tx, y, baddie);
				if (!arrowDrawn) {
					g.add(x + tx + 8, y + 12, arrow);
					arrowDrawn = true;
				}
			}

			tx += 16;
		}

		tx += 2;

		var left = totalFruit;

		for (f in state.guy.heldFruit) {
			if (f.type != Fruit) continue;
			var fruit: Fruit = cast f;
			var tile = switch (fruit.cdb.ID) {
				case Apple: apple;
				case Banana: banana;
				case Grapes: grape;
			}
			g.add(x + tx, y, tile);
			left --;

			if (!arrowDrawn) {
				g.add(x + tx + 8, y + 11, arrow);
				arrowDrawn = true;
			}

			tx += 10;
		}


		for (f in 0...left) {
			var tile = empty;
			g.add(x + tx, y, tile);
			tx += 10;
		}
	}
}