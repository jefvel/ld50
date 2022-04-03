package entities;

import elke.Game;
import h2d.Text;
import elke.graphics.Sprite;
import h2d.Interactive;

class Toggle extends Interactive {
	var s: Sprite;
	var text: Text;
	public var value(default, set) = false;
	public function new(?p) {
		super(1, 1, p);
		s = hxd.Res.img.toggle_tilesheet.toSprite2D(this);
		text = new Text(hxd.Res.fonts.futilepro_medium_12.toFont(), this);
		text.text = "Show tutorial";
		text.x = 22;
		text.y = 1;
		text.alpha = 0.9;
		width = 16 + text.textWidth + 4;
		height = 24;
		onPush = e -> {
			value = !value;
			Game.instance.sound.playWobble(hxd.Res.sound.tock, 0.2);
		}
		value = value;
	}

	function set_value(v) {
		if (v) {
			s.animation.currentFrame = 0;
		} else {
			s.animation.currentFrame = 1;
		}
		return value = v;
	}
}