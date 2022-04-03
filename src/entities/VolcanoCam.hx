package entities;

import gamestates.PlayState;
import elke.graphics.Sprite;
import h2d.Tile;
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
	var etaText: Text;

	public var currentLevel = 0.;
	//public var maxLevel = 60.0;
	public var maxLevel = 10.;

	var criticalLevel = 0.8;
	//var criticalLevel = 0.1;

	var lowerInfo: Object;
	var bar: Bitmap;
	var barFill: Bitmap;
	var bg: Sprite;
	var volcano: Sprite;

	var state: PlayState;

	public function new(?s, state) {
		super(s);
		this.state = state;

		cameraContent = new Object(this);
		frame = new ScaleGrid(hxd.Res.img.cameraframe.toTile(), 5, 5, 5, 5, this);
		frame.width = width + 8;
		frame.height = height + 8;
		bg = hxd.Res.img.cambg_tilesheet.toSprite2D(cameraContent);
		bg.animation.currentFrame = 0;
		volcano = hxd.Res.img.volcano_tilesheet.toSprite2D(cameraContent);
		volcano.animation.play("idle");
		cameraContent.x = cameraContent.y = 4;

		var camMask = new Bitmap(Tile.fromColor(0xffffff, width, height), cameraContent);

		cameraContent.filter = new h2d.filter.Mask(camMask);

		text = new Text(hxd.Res.fonts.marumonica.toFont(), cameraContent);
		text.text = "LIVE";
		text.textColor = 0xb42313;
		dot = new Bitmap(hxd.Res.img.camdot.toTile(), text);
		dot.x = -6;
		dot.y = 6;

		lowerInfo = new Object(this);
		lowerInfo.x = width + 14;
		lowerInfo.y = cameraContent.y;

		var barHeight = 6;
		bar = new Bitmap(Tile.fromColor(0xffffff, width, barHeight), lowerInfo);

		barFill = new Bitmap(Tile.fromColor(0xb42313, Std.int(bar.tile.width), Std.int(bar.tile.height)), bar);

		etaText = new Text(hxd.Res.fonts.gridgazer.toFont(), lowerInfo);
		etaText.x = bar.x;
		bar.y = Math.round(etaText.textHeight * 0.5 + 3);
		etaText.scale(0.5);
		etaText.dropShadow = {
			color: 0x150a1f,
			dx: 2,
			dy: 2,
			alpha: 1
		};
		rumbleSound = state.game.sound.playSfx(hxd.Res.sound.volcanorumbl, 0, true);
	}

	var t = 0.;

	var isMooding = false;
	public function feed(a: Actor) {
		if (state.lost) {
			return;
		}

		currentLevel -= a.volcanoValue;
		currentLevel = Math.max(0, currentLevel);
		volcano.animation.play("happy", false, true, 0, resetVolcanoMood);
		isMooding = true;
	}

	function resetVolcanoMood(_) {
		isMooding = false;
		if (isCritical) {
			volcano.animation.play("angry");
		} else {
			volcano.animation.play("idle");
		}
	}

	public var isCritical = false;

	var rumbleSound: hxd.snd.Channel;
	function enterCritical() {
		rumbleSound.fadeTo(0.2, 1.6);
	}

	function leaveCritical() {
		rumbleSound.fadeTo(0.0);
	}

	public var exploded = false;
	public function explode() {
		isMooding = true;
		state.game.sound.playSfx(hxd.Res.sound.endboom);
		volcano.animation.play("explode", false, true, 0, s-> {
			exploded = true;
			volcano.animation.play("static");
			text.text = "CAM OFFLINE";
		});
	}

	public function fadeOutSound() {
		rumbleSound.fadeTo(0.0, 1.6, () -> rumbleSound.stop());
	}

	override function onRemove() {
		super.onRemove();
		rumbleSound.stop();
	}
	
	var loseImminent = 0.6;
	override function update(dt:Float) {
		super.update(dt);
		t += dt;

		dot.visible = Math.sin(t * 3.0) < 0 && !exploded;

		text.y = height - text.textHeight - 2;
		text.x = width - 2 - text.textWidth - 2;

		currentLevel += dt;
		currentLevel = Math.min(currentLevel, maxLevel);
		var wasCritical = isCritical;
		isCritical = currentLevel / maxLevel > criticalLevel;

		if (currentLevel >= maxLevel) {
			loseImminent -= dt;
			state.loseGame();
		} else {
			loseImminent = 0.5;
		}

		if (isCritical != wasCritical) {
			if (isCritical) {
				enterCritical();
			} else {
				leaveCritical();
			}
		}

		if (isCritical) {
			bg.animation.currentFrame = 1;
			volcano.x = Math.round(Math.sin(state.time * 90));
		} else {
			bg.animation.currentFrame = 0;
			volcano.x = 0;
		}

		if (!isMooding) {
			if (isCritical) {
				volcano.animation.play("angry");
			} else {
				volcano.animation.play("idle");
			}
		}

		barFill.scaleX = (currentLevel / maxLevel);

		etaText.text = 'Eruption ETA ${Math.round(maxLevel -currentLevel)} s';
	}
}
