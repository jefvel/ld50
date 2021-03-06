package gamestates;

import elke.things.Newgrounds;
import elke.graphics.Sprite;
import elke.process.Timeout;
import elke.graphics.Transition;
import hxd.Event;
import elke.utils.EasedFloat;
import h3d.Engine;
import h2d.Object;
import h2d.Text;
import elke.gamestate.GameState;

class GameOverState extends GameState {
	var title: Text;
	var container: Object;
	var state : PlayState;
	var textContainer: Object;
	public function new(s: PlayState) {
		this.state = s;
	}

	var titleAlpha = new EasedFloat(0, 0.0);
	var subtitleAlpha = new EasedFloat(0, 0.4);
	var scoreAlpha = new EasedFloat(0, 0.4);
	var rankAlpha = new EasedFloat(0, 0.4);

	var timeV = new EasedFloat(0, 1.2);
	var scoreV = new EasedFloat(0, 1.0);

	var subtitle: Text;
	var score: Text;
	var maxUnitWidth = 0.;
	var canLeave = false;
	var scoreThresholds = [
		1000, // E
		3000, // D
		5000, // C
		7000, // B
		10000, // A
		15000, // S
	];

	var thresholdMedals = [
		68383,
		68384,
		68385,
		68386,
		68387,
		68388,
		68389,
	];

	var rankSprite: Sprite;
	var input: BasicInput;
	override function onEnter() {
		container = new Object(game.s2d);
		input = new BasicInput(game, container);

		textContainer = new Object(container);
		title = new Text(hxd.Res.fonts.gridgazer.toFont(), textContainer);
		title.text = "GAME OVER";
		title.textAlign = Center;

		subtitle = new Text(hxd.Res.fonts.futilepro_medium_12.toFont(), textContainer);
		subtitle.textAlign = Center;

		score = new Text(hxd.Res.fonts.futilepro_medium_12.toFont(), textContainer);
		score.textAlign = Center;

		maxUnitWidth = Math.max(maxUnitWidth, score.calcTextWidth('Final Score'));
		maxUnitWidth = Math.max(maxUnitWidth, subtitle.calcTextWidth('Survival Time'));

		rankSprite = hxd.Res.img.ranks_tilesheet.toSprite2D(textContainer);
		rankSprite.originX = rankSprite.originY = 20;

		var index = 0;
		Newgrounds.instance.unlockMedal(thresholdMedals[0]);
		for (i in 0...scoreThresholds.length) {
			if (scoreThresholds[i] > state.score) {
				break;
			}
			index ++;
			Newgrounds.instance.unlockMedal(thresholdMedals[index]);
		}

		rankSprite.animation.currentFrame = index;

		positionTexts();

		new Timeout(0.3, () -> {
			titleAlpha.value = 1.0;
			game.sound.playSfx(hxd.Res.sound.gameover, 0.5);
			new Timeout(0.6, () -> {
				subtitleAlpha.value = 1;

				game.sound.playSfx(hxd.Res.sound.scorepop, 0.45);
				timeV.value = state.gameTime;

				new Timeout(0.3, () -> {
					scoreAlpha.value = 1;
					game.sound.playSfx(hxd.Res.sound.scorepop, 0.47);
					scoreV.value = state.score;
					new Timeout(1.2, () -> {
						game.sound.playSfx(hxd.Res.sound.rankshow, 0.47);
						rankAlpha.value = 1;

						new Timeout(0.3, () -> {
							canLeave = true;
						});
					});

				});
			});
		});
	}

	var left = false;
	override function onEvent(e:Event) {
		super.onEvent(e);
		if (left) return;
		if (!canLeave) return;

		if (e.kind == EPush) {
			gotoMenu();
		}
	}

	function gotoMenu() {
		if (left) return;
		left = true;
		Transition.to(() -> {
			game.states.setState(new MenuState());
		});
	}

	override function update(dt:Float, timeUntilTick:Float) {
		if (left) return;
		if (!canLeave) return;

		if (input.confirmPressed()) {
			gotoMenu();
		}
	}

	function positionTexts() {
		title.x = Math.round(game.s2d.width * 0.5);
		title.y = 0.;
		title.alpha = titleAlpha.value;

		subtitle.x = Math.round(game.s2d.width * 0.5 - (1 - subtitleAlpha.value) * 4);
		subtitle.y = Math.round(title.y + title.textHeight + 24);
		subtitle.alpha = subtitleAlpha.value;

		score.x = Math.round(game.s2d.width * 0.5 - (1 - scoreAlpha.value) * 4);
		score.y = Math.round(subtitle.y + subtitle.textHeight + 8);
		score.alpha = scoreAlpha.value;

		rankSprite.x = Math.round(game.s2d.width * 0.5 - (1 - rankAlpha.value) * 4);
		rankSprite.y = Math.round(score.y + score.textHeight + 32 + 20);
		rankSprite.alpha = rankAlpha.value;

		var b = textContainer.getBounds();
		textContainer.y = Math.round((game.s2d.height - b.height) * 0.5);

		subtitle.text = 'Survival Time  ${timeV.value.toTimeString()}';
		score.text = 'Final Score  ${Math.round(scoreV.value).toMoneyString()}';

	}

	override function onRender(e:Engine) {
		super.onRender(e);
		positionTexts();
	}

	override function onLeave() {
		super.onLeave();
		container.remove();
	}
}