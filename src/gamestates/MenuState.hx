package gamestates;

import h2d.filter.Glow;
import h2d.filter.Outline;
import objects.FullscreenButton;
import objects.SocialLinks;
import h2d.Interactive;
import entities.Toggle;
import h2d.Text;
import elke.graphics.Transition;
import hxd.Perlin;
import hxd.Key;
import hxd.Event;
import h3d.Engine;
import elke.utils.EasedFloat;
import h2d.Tile;
import h2d.Bitmap;
import h2d.Object;
import elke.gamestate.GameState;

class MenuState extends GameState {
	var container: Object;
	var imgContainer: Object;

	var bg: Bitmap;
	var volcano: Bitmap;
	var fg: Bitmap;
	var title: Text;
	var titleSubtitle: Text;

	var toggle: Toggle;

	public function new(){}
	var socials: SocialLinks;

	override function onEnter() {
		super.onEnter();
		container = new Object(game.s2d);
		imgContainer = new Object(container);
		bg = new Bitmap(hxd.Res.img.menubg.toTile(), imgContainer);
		volcano = new Bitmap(hxd.Res.img.mainmenuvolcano.toTile(), imgContainer);
		fg = new Bitmap(hxd.Res.img.mainmenugrass.toTile(), imgContainer);
		fg.y = 90;
		mask = new Bitmap(Tile.fromColor(0xFFFFFF), imgContainer);
		mask.width = bg.tile.width;
		mask.height = bg.tile.height;
		game.s2d.filter = null;
		imgContainer.filter = new h2d.filter.Mask(mask);

		socials = new SocialLinks(container);
		socials.color = 0xff150a1f;
		socials.filter = new Glow(0xffffff, 1);

		if (GameSaveData.getCurrent().playedGames < 2) {
			socials.visible = false;
		}

		var playBtn = new Interactive(mask.width, mask.height, imgContainer);
		playBtn.onPush = e -> {
			startGame();
			playBtn.remove();
		}

		title = new Text(hxd.Res.fonts.gridgazer.toFont(), container);
		title.textAlign = Left;
		title.text = "Volcano Maintenance";

		titleSubtitle = new Text(hxd.Res.fonts.futilepro_medium_12.toFont(), title);
		titleSubtitle.textAlign = Left;
		titleSubtitle.text = "Click to Play";

		var data = GameSaveData.getCurrent();
		toggle = new Toggle(container);
		toggle.value = data.showTutorial;

		fsBtn = new FullscreenButton(container);

		positionStuff();

		input = new BasicInput(game, container);
		input.hideJoystick = true;
	}

	var fsBtn: FullscreenButton;

	var noise = new Perlin();

	var out = new EasedFloat(0, 2.6);
	var alphaOut = new EasedFloat(1, 0.9);
	var mask: Bitmap;

	var input: BasicInput;

	var started = false;
	function startGame() {
		if(started) return;
		var s = GameSaveData.getCurrent();
		s.showTutorial = toggle.value;
		s.save();

		socials.visible = false;

		started = true;
		out.value = -200.;
		alphaOut.value = 0;
		game.sound.playSfx(hxd.Res.sound.startgame);
		Transition.to(() -> {
			game.states.setState(new PlayState());
		}, 0.5, 0.3);
	}

	var time = 0.;
	override function update(dt:Float, timeUntilTick:Float) {
		super.update(dt, timeUntilTick);
		time += dt;
		if (!started) {
			if (input.confirmPressed()) {
				startGame();
			}
		}
	}

	function positionStuff() {
		var b = mask.getBounds();
		var ox = 0;//noise.perlin1D(1333, time * 0.1, 4) * 7.;
		var oy = 0;//noise.perlin1D(1343, time * 0.13, 4) * 7.;
		var w = game.s2d.width;
		var h = game.s2d.height;

		title.scaleX = title.scaleY = 1;

		if (w <= 512 || h < 256) {
			imgContainer.scaleX = imgContainer.scaleY = 1;
			title.scaleX = title.scaleY = 0.5;
		} else if (w <= 1024 || h < 512) {
			imgContainer.scaleX = imgContainer.scaleY = 2;
		} else if (w <= 2048 || h < 1024) {
			imgContainer.scaleX = imgContainer.scaleY = 3;
		}

		imgContainer.x = Math.round((game.s2d.width - b.width) * 0.5);
		imgContainer.y = Math.round((game.s2d.height - b.height) * 0.5);

		fg.y = 90 + (out.value + oy) * 0.6;
		fg.x = 0 + (ox) * 0.6;

		volcano.y =  (out.value + oy) * 0.3;
		volcano.x = 0 + (ox) * 0.2;

		bg.y = (out.value + oy) * 0.1;
		bg.x = 0 + (ox) * 0.1;

		imgContainer.alpha = alphaOut.value;

		title.x = b.x + 12;
		title.y = b.y + b.height - title.textHeight - 4;
		titleSubtitle.x = title.textWidth + 8;
		titleSubtitle.y = Math.round((title.textHeight - titleSubtitle.textHeight - 3));
		titleSubtitle.alpha = Math.abs(Math.sin(time));

		toggle.x = title.x;
		toggle.y = title.y - 28;

		var sb = socials.getBounds();
		var ib = imgContainer.getBounds();
		socials.x = ib.x + ib.width - sb.width - 10;
		socials.y = ib.y + 8; 
		fsBtn.x = ib.x + ib.width - fsBtn.width - 8;
		fsBtn.y = ib.y + 128 * imgContainer.scaleX - fsBtn.height - 8;
		//socials.x = game.s2d.width - sb.width - 8;
		//socials.y = game.s2d.height - sb.height - 8;
	}

	override function onEvent(e:Event) {
		super.onEvent(e);
		if (e.kind == ERelease) {
			#if js
			if (game.usingTouch) {
				game.pixelSize = 1;
				hxd.Window.getInstance().displayMode = Borderless;
			}
			#end
		}
	}

	override function onRender(e:Engine) {
		super.onRender(e);
		positionStuff();
	}

	override function onLeave() {
		super.onLeave();
		container.remove();
	}
}