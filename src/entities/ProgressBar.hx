package entities;

import elke.Game;
import elke.T;
import h2d.Tile;
import h2d.Bitmap;
import h2d.ScaleGrid;
import elke.utils.EasedFloat;
import h2d.RenderContext;
import h2d.Text;
import h2d.Object;

class ProgressBar extends Object {
	var easedScore = new EasedFloat(0, 0.3);

	public var progress(default, set) = 0.;
	var cutoffProgress = 0.;
	public var maxProgress = 1.0;
 	public var minProgress = 0.;

	public var width(default, set) = 128.;
	public var height(default, set) = 24.;

	var val = 0.;

	//var label:Text;
	var frame:ScaleGrid;

	var paddingX = 6;
	var paddingY = 5;

	var cutoffBar: Bitmap;
	var bar: Bitmap;

	public var levellingUp = false;

	public function new(?p) {
		super(p);

		cutoffBar = new Bitmap(Tile.fromColor(0x361027), this);
		bar = new Bitmap(Tile.fromColor(0xb42313), this);

		frame = new ScaleGrid(hxd.Res.img.xpbarbg.toTile(), 3, 3, 4, 4, this);
		frame.width = width;
		frame.height = height;
		var p = 1;
		bar.x = p;
		bar.y = p;
		cutoffBar.x = cutoffBar.y = p;
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
	}

	public function update(dt: Float) {
		var scr = Math.round(Math.min(easedScore.value, maxProgress));

		updateScale();

		scr = Std.int(Math.min(maxProgress, scr));
		//label.text = '${scr.toMoneyString()} / $untilNext';
		bar.visible = true;
		var p = 1;
		var h = height - p * 2;

		var w = Math.max(0, Math.min(width - p * 2, val * width - p * 2));

		var cutoffW = Math.max(0, Math.min(width - p * 2, cutoffProgress * width - p * 2));

		if (levellingUp) {
			w = width - p * 2;
		}

		bar.tile.scaleToSize(w, h);
		cutoffBar.tile.scaleToSize(cutoffW, h);

		if (cutoffProgress > val) {
			sinceCutoff += dt;
			if (sinceCutoff > 0.8) {
				cutoffProgress *= 0.98;
			}
		}
	}

	function updateScale() {
		var d = maxProgress - minProgress;
		var ds = progress - minProgress;
		var s = Math.min(1, Math.max(0, ds / d));

		val = s;
	}

	function set_width(w) {
		frame.width = w;
		return width = w;
	}

	function set_height(h) {
		frame.height = h;
		return height = h;
	}

	var sinceCutoff = 0.;
	var cutOffThing = 1.0;
	function set_progress(s:Float) {
		if (s > cutoffProgress) {
			cutoffProgress = s;
			cutOffThing = s;
		} else {
			if (s < cutOffThing) {
				cutOffThing = s; 
				sinceCutoff = 0.;
			}
		}

		return progress = s;
	}
}
