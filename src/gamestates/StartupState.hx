package gamestates;

import elke.graphics.Transition;
import h2d.Object;
import h2d.Text;
import elke.things.Newgrounds;
import hxd.Event;
import elke.gamestate.GameState;

class StartupState extends GameState {
	var loaded = false;
	var startText: Text;
	var container: Object;

	var leaving = false;


	public function new() {

	}

	override function onEnter() {
		super.onEnter();
		Newgrounds.initializeAndLogin(() -> {
			loaded = true;
		}, () -> {
			loaded = true;
		});

		container = new Object(game.s2d);

		var t = new Text(hxd.Res.fonts.daisyhud.toFont(), container);
		t.text = "Click or Tap\nto Start";
		t.textAlign = Center;
		t.visible = false;
		startText = t;
	}

	override function update(dt:Float, timeUntilTick:Float) {
		super.update(dt, timeUntilTick);
		startText.x = Math.round(game.s2d.width * 0.5);
		startText.y = Math.round(game.s2d.height * 0.5 - startText.textHeight);
		startText.visible = loaded;
	}

	override function onEvent(e:Event) {
		super.onEvent(e);
		if (e.kind == EPush) {
			if (!leaving && loaded) {
				goToGame();
			}
		}

		if (e.kind == ERelease) {
			#if js
			if (game.usingTouch) {
				game.pixelSize = 1;
				hxd.Window.getInstance().displayMode = Borderless;
			}
			#end
		}
	}

	function goToGame(instant = false) {
		if (leaving) {
			return;
		}

		leaving = true;
		game.sound.playSfx(hxd.Res.sound.entergame, 0.3);

		Transition.to(() -> {
			game.states.setState(new MenuState());
		}, 0.2, 0.2);
	}

	override function onLeave() {
		super.onLeave();
		container.remove();
	}
}