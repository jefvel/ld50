package entities;

import h2d.Bitmap;
import h2d.Graphics;
import h2d.RenderContext;
import h2d.Object;

class ThrowLine extends Object {
	public var active = false;
	var graphics: Graphics;
	var arrow: Bitmap;
	var maxRadius = 64;
	var arrowRotation = 0.;
	public function new(?p) {
		super(p);
		arrow = new Bitmap(hxd.Res.img.arrow.toTile(), this);
		arrow.tile.dy = -5;
		graphics = new Graphics(this);
		filter = new h2d.filter.Glow(0x150a1f, 1, 2, 1);
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		arrow.visible = graphics.visible = active;
		if (!active) {
			return;
		}

		graphics.clear();
		graphics.lineStyle(3, 0xfffdf0);
		graphics.moveTo(0, 0);
		var dx = Math.round(Math.cos(arrowRotation) * maxRadius);
		var dy = Math.round(Math.sin(arrowRotation) * maxRadius);
		graphics.lineTo(dx, dy);
		arrow.rotation = arrowRotation;
		arrow.x = dx;
		arrow.y = dy;
	}
}