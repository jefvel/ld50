package entities;

import gamestates.PlayState;
import elke.utils.EasedFloat;
import h2d.col.Point;
import h2d.Bitmap;
import h2d.Graphics;
import h2d.RenderContext;
import h2d.Object;

class ThrowLine extends Object {
	public var active(default, set) = false;
	var graphics: Graphics;
	var arrow: Bitmap;
	var maxRadius = 64;
	var arrowRotation = 0.;

	var startX = 0.;
	var startY = 0.;

	public var throwPower = 0.;
	public var throwX = 0.;
	public var throwY = 0.;

	public var toThrowSize = 32.;

	public var aimTime = new EasedFloat(0, 0.6);

	public var relativeAim = false;

	var targetAlpha = new EasedFloat(0, 0.2);

	var state: PlayState;
	public function new(?p, s) {
		super(p);
		this.state = s;
		arrow = new Bitmap(hxd.Res.img.arrow.toTile(), this);
		arrow.tile.dy = -4;
		graphics = new Graphics(this);
		filter = new h2d.filter.Glow(0x150a1f, 1, 2, 0.5);
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		alpha = targetAlpha.value * aimTime.value;
		arrow.visible = graphics.visible = alpha > 0;
		if (!active) {
			return;
		}

		if (state.paused) {
			return;
		}

		var s = getScene();
		var p = localToGlobal();
		var dx = s.mouseX - p.x;
		var dy = s.mouseY - p.y;
		if (relativeAim) {
			dx = startX - s.mouseX;
			dy = startY - s.mouseY;
		}

		var p = parent.globalToLocal(new Point(startX, startY));
		//x = p.x;
		//y = p.y;

		var len = Math.sqrt(dx * dx + dy * dy);

		var r = Math.min(maxRadius, len);
		throwPower = aimTime.value;//r / maxRadius;
		throwX = dx / len;
		throwY = dy / len;

		arrowRotation = Math.atan2(dy, dx);

		//r = Math.max(r, 16);
		r = toThrowSize;

		r *= throwPower;

		graphics.clear();
		graphics.lineStyle(3, 0xfffdf0);
		graphics.drawPieInner(0, 0, r, r - 1, 0, Math.PI * 2 * throwPower);

		graphics.alpha = throwPower;

		var dx = (Math.cos(arrowRotation));
		var dy = (Math.sin(arrowRotation));

		/*
		graphics.moveTo(dx * 16, dy * 16);
		graphics.lineTo(dx * r, dy * r);
		graphics.moveTo(0, 0);
		*/

		arrow.rotation = arrowRotation;
		arrow.x = dx * r;
		arrow.y = dy * r;

	}

	function set_active(a) {

		var s = getScene();
		startX = s.mouseX;
		startY = s.mouseY;

		if (a) {
			targetAlpha.value = 0.9;
			aimTime.setImmediate(0);
			aimTime.value = 1.;
		} else {
			targetAlpha.setImmediate(0);
		}

		return active = a;
	}
}