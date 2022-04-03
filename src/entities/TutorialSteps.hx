package entities;

import h2d.Tile;
import h2d.Bitmap;
import h2d.col.Point;
import h2d.RenderContext;
import elke.utils.EasedFloat;
import h2d.Text;
import h2d.Object;
import gamestates.PlayState;

class TutorialSteps extends Object {
	var state: PlayState;
	var text: Text;

	var currentStep = -1;
	var steps = [
		"Move with WASD",
		"Pick up fruit by walking near them",
		"Place objects in the catapult to feed the volcano",
		"Hold Left Mouse to aim and throw carried objects",
		"Knock out enemies by throwing things at them",
		"Knocked out enemies can be carried",
		"Good luck",
	];

	var a = new EasedFloat(1, 0.6);
	var finished = false;
	var bg : Bitmap;
	var paddingX = 8;
	var paddingTop = 4;
	var paddingBottom = 5;
	public function new(?p, state) {
		super(p);
		this.state = state;
		bg = new Bitmap(Tile.fromColor(0x0e092f), this);
		bg.alpha = 0.4;
		text = new Text(hxd.Res.fonts.marumonica.toFont(), this);
		text.textAlign = Left;
		text.maxWidth = 110;
		bg.width = text.maxWidth + paddingX * 2;
		nextStep();
	}

	public var threwThing = false;

	function nextStep() {
		currentStep ++;
		if (currentStep >= steps.length) {
			finished = true;
			a.value = 0.;
			return;
		}

		text.text = steps[currentStep];
		minTimePerStep = 1.9;
	}

	var minTimePerStep = 1.9;

	function checkCurrentStep() {
		if (currentStep == 0) {
			if (Math.abs(state.guy.vx) + Math.abs(state.guy.vy) > 0.2) {
				return true;
			}
		}

		if (currentStep == 1) {
			if (state.guy.heldFruit.length > 0) {
				return true;
			}
		}

		if (currentStep == 2) {
			if (state.catapult.toCatapult.length > 0) {
				return true;
			}
		}

		if (currentStep == 3) {
			if (threwThing) {
				return true;
			}
		}

		if (currentStep == 4) {
			if (minTimePerStep < -2) {
				return true;
			}
		}

		if (currentStep == 5) {
			if (minTimePerStep < -2) {
				return true;
			}
		}

		if (currentStep == 6) {
			if (minTimePerStep < 0) {
				return true;
			}
		}

		return false;
	}

	public function update(dt: Float) {
		this.alpha = a.value;
		if (a.value <= 0) {
			remove();
		}
		minTimePerStep -= dt;

		if (minTimePerStep < 0) {
			if (checkCurrentStep()) {
				nextStep();
			}
		}
	}

	public function updatePos() {
		var p = state.world.localToGlobal(new Point(Math.round(state.guy.x), Math.round(state.guy.y)));
		bg.height = paddingTop + paddingBottom + text.textHeight;
		var s = getScene();
		if (s == null) {
			return;
		}

		bg.x = Math.round(p.x - bg.width * 0.5);
		bg.y = Math.round(p.y + 24);

		bg.x = Math.max(8, bg.x);
		bg.x = Math.min(s.width - bg.width - 8, bg.x);

		bg.y = Math.max(8, bg.y);
		bg.y = Math.min(s.height - bg.height - 8, bg.y);
		text.x = bg.x + paddingX;
		text.y = bg.y + paddingTop;

	}
}