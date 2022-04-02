package entities;

import h2d.Text;
import h2d.Object;
import h2d.Bitmap;
import h2d.ScaleGrid;
import elke.entity.Entity2D;

class VolcanoCam extends Entity2D {
	var frame: ScaleGrid;
	var dot: Bitmap;
	var cameraContent: Object;
	var width = 128;
	var height = 80;
	var text: Text;
	public function new(?s) {
		super(s);
		cameraContent = new Object(this);
		frame = new ScaleGrid(hxd.Res.img.cameraframe.toTile(), 5, 5, 5, 5, this);
		frame.width = width + 10;
		frame.height = height + 10;
		cameraContent.x = cameraContent.y = 5;

		text = new Text(hxd.Res.fonts.marumonica.toFont(), cameraContent);
		text.text = "LIVE";
		text.textColor = 0xb42313;
		dot = new Bitmap(hxd.Res.img.camdot.toTile(), text);
		dot.x = -6;
		dot.y = 6;
	}

	var t = 0.;
	
	override function update(dt:Float) {
		super.update(dt);
		t += dt;
		dot.visible = Math.sin(t * 3.0) < 0;
		text.y = height - text.textHeight;
		text.x = width - 2 - text.textWidth;
	}
}
