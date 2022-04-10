import hxd.Window;
import h2d.Object;
import hxd.Key;
import elke.utils.Joystick;
import elke.Game;

class BasicInput extends Object {
	var game:Game;

	public var disabled(default, set) = false;
	public var joystick:Joystick;

	public function new(game:Game, ?p) {
		super(p);
		this.game = game;
		joystick = new Joystick(this);
	}

	override function onAdd() {
		super.onAdd();
		Window.getInstance().addEventTarget(handleEvent);
	}

	function handleEvent(e: hxd.Event) {
		if (disabled) return;
		joystick.handleEvent(e);
	}

	override function onRemove() {
		super.onRemove();
		Window.getInstance().removeEventTarget(handleEvent);
	}

	final BTNS = hxd.Pad.DEFAULT_CONFIG;

	public function walkingLeft() {
		if (disabled)
			return false;

		var pads = game.gamepads;
		var ctrlLeft = joystick.goingLeft() || pads.pressingLeft() || pads.isBtnDown(BTNS.dpadLeft);
		return leftPressed() || ctrlLeft;
	}

	public function walkingRight() {
		if (disabled)
			return false;

		var pads = game.gamepads;
		var ctrlRight = joystick.goingRight() || pads.pressingRight() || pads.isBtnDown(BTNS.dpadRight);
		return rightPressed() || ctrlRight;
	}

	public function walkingUp() {
		if (disabled)
			return false;

		var pads = game.gamepads;
		var ctrlUp = joystick.goingUp() || pads.pressingUp() || pads.isBtnDown(BTNS.dpadUp);
		return upPressed() || ctrlUp;
	}

	public function walkingDown() {
		if (disabled)
			return false;

		var pads = game.gamepads;
		var ctrlDown = joystick.goingDown() || pads.pressingDown() || pads.isBtnDown(BTNS.dpadDown);
		return downPressed() || ctrlDown;
	}

	public function rightPressed() {
		var pads = game.gamepads;
		var press = pads.isBtnDown(BTNS.dpadRight) || pads.getStickX() > 0.5;
		return Key.isDown(Key.D) || Key.isDown(Key.RIGHT) || press;
	}

	public function leftPressed() {
		var pads = game.gamepads;
		var press = pads.isBtnDown(BTNS.dpadLeft) || pads.getStickX() < -0.5;
		return Key.isDown(Key.A) || Key.isDown(Key.LEFT) || press;
	}

	public function upPressed() {
		var pads = game.gamepads;
		var upPress = pads.isBtnDown(BTNS.dpadUp) || pads.getStickY() < -0.5;
		return Key.isDown(Key.W) || Key.isDown(Key.UP) || upPress;
	}

	public function downPressed() {
		var pads = game.gamepads;
		var downPress = pads.isBtnDown(BTNS.dpadDown) || pads.getStickY() > 0.5;
		return Key.isDown(Key.S) || Key.isDown(Key.DOWN) || downPress;
	}

	public var moveX = 0.;
	public var moveY = 0.;

	public function update() {
		var dx = 0.;
		var dy = 0.;

		if (disabled) {
			moveX = moveY = 0;
			return;
		}

		if (game.inputMethod == KeyboardAndMouse) {
			if (leftPressed()) {
				dx -= 1;
			}

			if (rightPressed()) {
				dx += 1;
			}

			if (upPressed()) {
				dy -= 1;
			}

			if (downPressed()) {
				dy += 1;
			}
		}

		if (game.inputMethod == Touch) {
			dx = joystick.mx;
			dy = joystick.my;
		}

		var l = Math.sqrt(dx * dx + dy * dy);
		if (l > 0) {
			dx /= l;
			dy /= l;
		}

		moveX = dx;
		moveY = dy;

		if (game.inputMethod == Touch) {
			moveX *= Math.max(0.1, Math.min(1, joystick.magnitude));
			moveY *= Math.max(0.1, Math.min(1, joystick.magnitude));
		}
	}

	function set_disabled(d) {
		if (d) {
			joystick.end();
		}

		return disabled = d;
	}
}
