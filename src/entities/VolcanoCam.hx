package entities;

import elke.things.StatusFeed;
import h2d.TileGroup;
import h2d.filter.Glow;
import elke.T;
import h2d.RenderContext;
import elke.utils.EasedFloat;
import gamestates.PlayState;
import elke.graphics.Sprite;
import h2d.Tile;
import h2d.Text;
import h2d.Object;
import h2d.Bitmap;
import h2d.ScaleGrid;
import elke.entity.Entity2D;
class ScoreAdd extends Object {
	public var text: Text;
	var fade = new EasedFloat(1, 3.4);
	var alphaFade = new EasedFloat(0, 1.5);
	public function new(label: String, p) {
		super(p);
		alphaFade.easeFunction = T.expoOut;
		text = new Text(hxd.Res.fonts.futilepro_medium_12.toFont(), this);
		text.text = label;
		text.textColor = 0xfffdf0;
		/*
		text.dropShadow = {
			dx: 1,
			dy: 1, 
			color: 0x150a1f,
			alpha: 1,
		};
		*/
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		var v = fade.value;
		var a = alphaFade.value;
		text.y = v * 46.0;
		//text.alpha = Math.min(1, a * 3.);
		text.visible = a > 0.1;
	}

	public function show(label) {
		fade.setImmediate(0);
		fade.value = 1;
		alphaFade.setImmediate(1);
		alphaFade.value = 0;
		text.text = label;
	}
}

class VolcanoCam extends Entity2D {
	var frame: ScaleGrid;
	var dot: Bitmap;
	var cameraContent: Object;
	var width = 128;
	var height = 80;
	var text: Text;
	var etaText: Text;

	var scoreBar: ScoreBar;

	var timeText: Text;
	var timeTextBg: Bitmap;

	var scoreTexts: Array<Text> = [];
	var statusFeed: StatusFeed<Text>;
	var thingsToEat: Array<Actor> = [];

	public var currentLevel = 0.;
	//public var maxLevel = 40.0;
	public var maxLevel = 40.;

	var criticalLevel = 0.8;
	//var criticalLevel = 0.1;

	var scoreInfo: Object;
	var bottomUi: Object;
	var barHeight = 8;
	var bar: Bitmap;
	var eruptionBar: ProgressBar;
	var barFill: Bitmap;
	var bg: Sprite;
	var volcano: Sprite;

	var state: PlayState;

	var upgradeLevels = [
		500,
		1500,
		4000,
		7000,
		10000,
		12500,
	];

	var currentUpgradeLevel = 0;
	var untilNextLevel = 0;

	var peopleGroup: TileGroup;
	var personTile : Tile;
	var padding = 8;

	public function new(?s, state) {
		super(s);
		this.state = state;

		untilNextLevel = upgradeLevels[0];

		cameraContent = new Object(this);
		frame = new ScaleGrid(hxd.Res.img.cameraframe.toTile(), 3, 3, 4, 4, this);
		frame.width = width + frame.borderLeft + frame.borderRight - 2;
		frame.height = height + frame.borderTop + frame.borderBottom - 2;
		bg = hxd.Res.img.cambg_tilesheet.toSprite2D(cameraContent);
		bg.animation.currentFrame = 0;
		volcano = hxd.Res.img.volcano_tilesheet.toSprite2D(cameraContent);
		volcano.animation.play("idle");
		personTile = Tile.fromColor(0xffffff, 2, 2);
		peopleGroup = new TileGroup(personTile, cameraContent);

		frame.x = frame.y = padding;
		cameraContent.x = frame.x;
		cameraContent.y = frame.y;

		var camMask = new Bitmap(Tile.fromColor(0xffffff, width, height), cameraContent);

		cameraContent.filter = new h2d.filter.Mask(camMask);

		text = new Text(hxd.Res.fonts.marumonica.toFont(), cameraContent);
		text.text = "LIVE";
		text.textColor = 0xb42313;
		dot = new Bitmap(hxd.Res.img.camdot.toTile(), text);
		dot.x = -6;
		dot.y = 6;

		timeTextBg = new Bitmap(Tile.fromColor(0x280b26), cameraContent);
		timeText = new Text(hxd.Res.fonts.marumonica.toFont(), cameraContent);
		timeText.x = 4;
		timeText.y = 1;

		timeTextBg.scaleX = width;
		timeTextBg.scaleY = timeText.y * 2 + timeText.textHeight; 
		timeTextBg.alpha = 0.2;

		bottomUi = new Object(this);
		bottomUi.x = width + 11 + frame.x;
		bottomUi.y = cameraContent.y;

		scoreInfo = new Object(this);
		scoreInfo.x = width + 11 + frame.x;
		scoreInfo.y = bottomUi.y + 30;

		bar = new Bitmap(Tile.fromColor(0xffffff), bottomUi);
		barFill = new Bitmap(Tile.fromColor(0xb42313), bar);

		eruptionBar = new ProgressBar(bottomUi);

		scoreBar = new ScoreBar(scoreInfo);

		var barY = 0.; // bar.y + barHeight + 2

		etaText = new Text(hxd.Res.fonts.gridgazer.toFont(), bottomUi);
		etaText.y = barHeight - 8;
		etaText.x = bar.x + 4;
		//bar.y = Math.round(etaText.y + etaText.textHeight * 0.5 + 3);
		etaText.scale(0.5);
		etaText.dropShadow = {
			color: 0x150a1f,
			dx: 2,
			dy: 2,
			alpha: 1
		};

		rumbleSound = state.game.sound.playSfx(hxd.Res.sound.volcanorumbl, 0, true);

		var scoreTextContainer = new Object(scoreInfo);
		//scoreTextContainer.filter = new h2d.filter.Glow(0x150a1f, 1, 2, 1, 1, true);
		scoreTextContainer.y = barY + scoreBar.height + 2;
		statusFeed = new StatusFeed<Text>(scoreTextContainer);

		for (i in 0...maxScoreTexts) {
			var s = new Text(hxd.Res.fonts.gridgazer.toFont());
			s.scale(0.5);
			s.dropShadow = {
				color: 0x150a1f,
				dx: 2,
				dy: 2,
				alpha: 1
			};
			//text.text = label;
			text.textColor = 0xfffdf0;
			scoreTexts.push(s);
		}
	}

	var t = 0.;

	var isMooding = false;
	var scoreIndex = 0;
	var maxScoreTexts = 25;
	public function feed(a: Actor) {
		if (state.lost) {
			return;
		}

		a.launchX = Math.random() * 16 - 8;
		thingsToEat.push(a);
	}

	var scoreTimeout = 0.;
	var launchTime = 0.2;
	function checkScoreQueue(dt: Float) {
		scoreTimeout -= dt;
		if (scoreTimeout > 0) {
			return;
		}
		
		var a = thingsToEat[0];
		if (a == null) {
			return;
		}

		if (a.launchProgress < launchTime) return;

		thingsToEat.remove(a);

		state.game.sound.playWobble(hxd.Res.sound.burn);
		scoreTimeout = 0.2;

		volcano.animation.play("happy", false, true, 0, resetVolcanoMood);
		currentLevel -= a.volcanoValue;
		currentLevel = Math.max(0, currentLevel);
		isMooding = true;

		state.addScore(a.score);

		addStatus('+${a.score.toMoneyString()} ${a.name}');
	}

	public function addStatus(status: String) {
		var s = scoreTexts[scoreIndex];
		scoreIndex ++;
		scoreIndex %= scoreTexts.length;
		s.text = status;
		statusFeed.add(s);
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
		rumbleSound.fadeTo(0.28, 1.6);
	}

	function leaveCritical() {
		rumbleSound.fadeTo(0.0);
	}

	public var exploded = false;
	public function explode() {
		isMooding = true;
		state.game.sound.playSfx(hxd.Res.sound.endboom, 0.7);
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

	var tickTock = false;
	function playTickTock() {
		tickTock = !tickTock;
		if (tickTock) {
			state.game.sound.playSfx(hxd.Res.sound.tick, 0.7);
		} else {
			state.game.sound.playSfx(hxd.Res.sound.tock, 0.7);
		}
	}

	public function pauseSounds() {
		rumbleSound.pause = true;
	}

	public function unPauseSounds() {
		rumbleSound.pause = false;
	}

	function drawPeople(dt: Float) {
		peopleGroup.clear();

		for(a in thingsToEat) {
			a.launchProgress += dt;
			var r = Math.min(a.launchProgress / launchTime, 1);
			if (r >= 1) continue;
			var ry = 80 - (60 * T.sineIn(r));
			var rx = 64 + T.quintOut(1 - r) * a.launchX;
			peopleGroup.add(rx, ry, personTile);
		}
	}
	
	var loseImminent = 1.0;
	var graceTime = 1.0;
	var previousSecond = 0;
	var eatScale = 1.;
	var untilSuperSpeed = 3.;
	var superSpeedScale = new EasedFloat(1, 0.8);
	var ffwd = false;
	override function update(dt:Float) {
		super.update(dt);
		if (state.paused) return;

		t += dt;

		cameraContent.alpha = 1.0;
		if (state.guy.x < 300 && state.game.s2d.mouseX < 300 && state.game.s2d.mouseY < 100) {
			//frame.x = getScene().width - 8 - width - 8;
			//scoreInfo.x = frame.x - scoreInfo.getBounds().width - 14;
			cameraContent.alpha = 0.5;
		} else if (state.guy.x > state.level.pxWid - 200) {
			//frame.x = 8;
			//scoreInfo.x = width + 14 + frame.x;
			//scoreInfo.y = frame.y;
		}
		cameraContent.x = frame.x + frame.borderLeft - 1;
		cameraContent.y = frame.y + frame.borderTop - 1;

		drawPeople(dt);

		checkScoreQueue(dt);

		timeText.text = state.gameTime.toTimeString();

		dot.visible = Math.sin(t * 3.0) < 0 && !exploded;

		text.y = height - text.textHeight - 2;
		text.x = width - 2 - text.textWidth - 2;

		eatScale = 1.0;
		if (!state.hasTreesLeft() && !ffwd && state.catapult.toCatapult.length == 0) {
			ffwd = true;
			superSpeedScale.value = 13.;
		} else {
			if (state.hasTreesLeft() || state.catapult.toCatapult.length > 0) {
				ffwd = false;
				superSpeedScale.value = 1.;
			}
		}

		if (ffwd) {
			eatScale = superSpeedScale.value;
		}

		currentLevel += dt * eatScale;//dt * scale;
		currentLevel = Math.min(currentLevel, maxLevel);
		var wasCritical = isCritical;
		isCritical = currentLevel / maxLevel > criticalLevel;

		if (currentLevel >= maxLevel) {
			loseImminent -= dt;
			if (loseImminent < 0) {
				state.loseGame();
			}
		} else {
			loseImminent = graceTime;
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

		var s = getScene();
		if (s != null) {
			var barWidth = (s.width - bottomUi.x) - padding;
			bar.tile.scaleToSize(barWidth, barHeight);
			barFill.tile.scaleToSize(Math.round((currentLevel / maxLevel) * barWidth), barHeight);
			var b = bottomUi.getBounds();
			//bottomUi.x = padding;
			//bottomUi.y = s.height - b.height - padding;
		}

		var timeLeft = Math.round((maxLevel - currentLevel) / eatScale);
		if (timeLeft < previousSecond) {
			if (timeLeft <= 5) {
				playTickTock();
			} else {
				tickTock = false;
			}
		}
		previousSecond = timeLeft;

		if (timeLeft > 0) {
			etaText.text = 'ERUPTION ETA ${timeLeft} s';
		} else {
			etaText.text = 'ERUPTION IMMINENT';
		}

		if (state.upgrades.shown) {
			return;
		}

		if (hasUpgrades) {
			scoreBar.levelScore = untilNextLevel;
		} else {
			scoreBar.levelScore = 0;
		}

		var scr = Math.round(state.smoothedScore.value);
		if (!state.lost && hasUpgrades) {
			if (state.score >= untilNextLevel) {
				scr = untilNextLevel;
				levelUp();
			}
		}

		scoreBar.score = state.score;
	}

	public var hasUpgrades = true;

	function levelUp() {
		scoreBar.levellingUp = true;
		state.showUpgrades(() -> {
			currentUpgradeLevel ++;
			if (currentUpgradeLevel >= upgradeLevels.length) {
				untilNextLevel = Math.round(untilNextLevel * 1.18);
			} else {
				untilNextLevel = upgradeLevels[currentUpgradeLevel];
			}
			scoreBar.levellingUp = false;
		});
	}
}
