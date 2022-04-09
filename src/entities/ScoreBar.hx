package entities;

import h2d.Tile;
import h2d.Bitmap;
import h2d.ScaleGrid;
import elke.utils.EasedFloat;
import h2d.RenderContext;
import h2d.Text;
import h2d.Object;

class ScoreBar extends Object {
	var easedScore = new EasedFloat(0);
	public var score(default, set) = 0;
 	var previousLevelScore = 0;

	public var levelScore(default, set) = 0;
	function set_levelScore(s) {
		if (s > levelScore) {
			previousLevelScore = levelScore;
		}

		return levelScore = s;
	}


	function set_score(s:Int) {
		if (score != s) {
			easedScore.value = s;
		}

		return score = s;
	}

	public var width = 128.;
	public var height = 24.;

	var label:Text;
	var frame:ScaleGrid;

	var paddingX = 6;
	var paddingY = 5;

	var bar: Bitmap;

	public function new(?p) {
		super(p);

		bar = new Bitmap(Tile.fromColor(0x118337), this);

		frame = new ScaleGrid(hxd.Res.img.xpbarbg.toTile(), 3, 3, 4, 4, this);
		frame.width = width;
		frame.height = height;

		label = new Text(hxd.Res.fonts.gridgazer.toFont(), this);
		label.scale(0.5);
		label.dropShadow = {
			color: 0x150a1f,
			dx: 2,
			dy: 2,
			alpha: 1
		};

		label.x = paddingX;
		label.text = "0 / 500";
		var b = label.getBounds();
		label.y = Math.round(((height - paddingY * 2) - b.height) * 0.5 + paddingY);
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		var untilNext = levelScore.toMoneyString();
		var scr = Math.round(easedScore.value);

		if (levelScore > 0) {
			scr = Std.int(Math.min(levelScore, scr));
			label.text = '${scr.toMoneyString()} / $untilNext';
			bar.visible = true;
			var d = levelScore - previousLevelScore;
			var ds = scr - previousLevelScore;
			var s = Math.min(1, Math.max(0, ds));
			var p = 1;
			var w = Math.round(s * (width - p * 2 - 1));
			var h = height - p * 2;
			bar.tile.scaleToSize(w, h);
			bar.x = p;
			bar.y = p;
		} else {
			label.text = '${scr.toMoneyString()}';
			bar.visible = false;
		}
	}
}
