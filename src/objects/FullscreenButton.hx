package objects;

import h2d.Bitmap;
import h2d.RenderContext;
import hxd.Window;
import h2d.Interactive;
import h2d.Object;


class FullscreenButton extends Interactive {
	var bm: Bitmap;
	public function new(?p) {
		super(16, 16, p);

		alpha = 0.2;

		bm = new Bitmap(hxd.Res.img.fullscreenicon.toTile(), this);

		onOver = e -> {
			alpha = 1.0;
		}

		onOut = e -> {
			alpha = 0.2;
		}

		onClick = e -> {
			var w = Window.getInstance();
			if (w.displayMode == Windowed) {
				w.displayMode = Borderless;
			} else {
				w.displayMode = Windowed;
			}
		}
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		var s = getScene();
		if (s == null) {
			return;
		}

		//x = s.width - 20;
		//y = s.height - 20;
	}
}