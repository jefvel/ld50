package gamestates;

import entities.HeldItems;
import elke.things.Newgrounds;
import hxd.Window;
import h2d.col.Point;
import h3d.Vector;
import elke.graphics.Transition;
import entities.TutorialSteps;
import entities.UpgradeMenu;
import entities.Helper;
import elke.process.Timeout;
import h2d.Bitmap;
import elke.T;
import h3d.Matrix;
import elke.utils.EasedFloat;
import entities.Baddie;
import elke.utils.CollisionHandler;
import entities.Tree;
import entities.Catapult;
import hxd.Key;
import entities.VolcanoCam;
import entities.Fruit;
import entities.Guy;
import h2d.Tile;
import h3d.Engine;
import entities.WorldObject;
import entities.Actor;
import h2d.TileGroup;
import elke.graphics.TextureAtlas;
import h2d.Object;
import hxd.Event;

class PlayState extends elke.gamestate.GameState {
	var container:Object;
	var uiContainer:Object;

	var worldWrapper: Object;
	public var world: Object;
	public var background: Object;
	public var foreground: Object;

	public var atlas: TextureAtlas;
	var shadowTile: Tile;
	var treeShadowTile: Tile;
	public var baddieShadowTile: Tile;
	var fruitTile: Tile;
	var shadowGroup: TileGroup;
	public var actorGroup: TileGroup;

	var hpBarBgTile: Tile;
	var hpBarTile: Tile;
	var stunBartile:Tile;
	var stunDarkTile:Tile;
	var skullTile: Tile;
	public var overlayTile: Tile;
	var warningLeftTile: Tile;
	var warningRightTile: Tile;
	var warningUpTile: Tile;
	var warningDownTile: Tile;
	var carriedUi: HeldItems;
	public var hpBarsGroup: TileGroup;
	public var uiOverlayGroup: TileGroup;

	public var actors: Array<Actor> = [];
	public var objects: Array<WorldObject> = [];
	public var fruits: Array<Fruit> = [];
	public var baddies: Array<Baddie> = [];

	public var cam: VolcanoCam;

	public var input: BasicInput;

	public var guy: Guy;
	public var catapult: Catapult;

	public var levels: LevelData.LevelData;
	public var level: LevelData.LevelData_Level;

	var collisions: CollisionHandler;

	public var baddieSpawnInterval = 20.0;
	public var wave = 0;
	public var spawnIn = 1.0;

	var criticalFade = new EasedFloat(0, 2.5);
	var isCritical = false;

	public var lost = false;

	public var upgrades: UpgradeMenu;

	var damageMultiplier = 1.;

	public function new() {}

	override function onEnter() {
		super.onEnter();
		container = new Object(game.s2d);

		spawnIn = baddieSpawnInterval * 0.5;

		atlas = new TextureAtlas();

		var w = new LevelData();
		levels = w;
		level = w.all_levels.Level_0;

		var bigShadow = hxd.Res.img.shadow.toTile();
		shadowTile = bigShadow.sub(0, 0, 16, 8);
		shadowTile.dx = -8;
		shadowTile.dy = -4;

		treeShadowTile = bigShadow.sub(48, 16, 80, 32);
		treeShadowTile.dx = -29;
		treeShadowTile.dy = -17;

		baddieShadowTile = bigShadow.sub(0, 80, 64, 16);
		baddieShadowTile.dx = -30;
		baddieShadowTile.dy = -8;

		fruitTile = atlas.addTile(hxd.Res.img.fruits.toTile());

		upgrades = new UpgradeMenu(game.s2d);

		worldWrapper = new Object(container);
		world = new Object(worldWrapper);
		var worldMask = new Bitmap(Tile.fromColor(0xffffff, level.pxWid, level.pxHei), world);
		worldWrapper.filter = new h2d.filter.Mask(worldMask);
		background = new Object(world);
		shadowGroup = new TileGroup(bigShadow, world);
		actorGroup = new TileGroup(atlas.atlasTile, world);
		foreground = new Object(world);

		var overlay = hxd.Res.img.overlayelements.toTile();
		overlayTile = overlay;
		hpBarTile = overlay.sub(0, 0, 1, 1);
		hpBarBgTile = overlay.sub(0, 2, 1, 1);

		stunBartile = overlay.sub(2, 0, 1, 1);
		stunDarkTile = overlay.sub(2, 2, 1, 1);
		skullTile = overlay.sub(16,0, 7, 6, -4, -3);

		warningLeftTile = overlay.sub(0, 16, 16, 16);
		warningLeftTile.dx = 4;
		warningLeftTile.dy = -8;

		warningRightTile = overlay.sub(16, 16, 16, 16);
		warningRightTile.dx = -20;
		warningRightTile.dy = -8;

		warningUpTile = overlay.sub(32, 16, 16, 16);
		warningUpTile.dx = -8;
		warningUpTile.dy = 4;

		warningDownTile = overlay.sub(48, 16, 16, 16);
		warningDownTile.dx = -8;
		warningDownTile.dy = -20;

		hpBarsGroup = new TileGroup(overlay, foreground);

		game.s2d.filter = null;

		uiContainer = new Object(container);


		input = new BasicInput(game, container);

		world.filter = new h2d.filter.ColorMatrix(colorMatrix);
		world.filter.useScreenResolution = false;

		startGame();

		uiOverlayGroup = new TileGroup(overlay, uiContainer);

		carriedUi = new HeldItems(this);

		musicChannel = game.sound.playMusic(hxd.Res.sound.playmusic, musicVol);
		musicChannel.pause = true;
		new Timeout(0.7, () -> {
			if (!leftState) {
				musicChannel.pause = false;
			}
		});

		musicEffect = new hxd.snd.effect.LowPass();
		musicChannel.addEffect(musicEffect);
	}

	var musicEffect: hxd.snd.effect.LowPass;
	var musicChannel : hxd.snd.Channel;

	var whiteFlash: Bitmap;
	var lava: TileGroup;
	public function loseGame() {
		if (lost) {
			return;
		}

		lost = true;

		uiOverlayGroup.visible = false;
		hpBarsGroup.visible = false;

		var d = GameSaveData.getCurrent();
		d.playedGames ++;
		d.save();

		musicChannel.stop();

		Newgrounds.instance.submitHighscore(11712, score);
		Newgrounds.instance.getTop10Scoreboard(11712, (scores) -> {
			var s = scores[0];
			var bestOfTheDay = false;
			if (s == null) {
				bestOfTheDay = true;
			} else if (s.scoreRaw <= score) {
				bestOfTheDay = true;
			}

			if (bestOfTheDay) {
				Newgrounds.instance.unlockMedal(68428);
			}
		}, Day);

		var llevl = levels.all_levels.Level_1;
		lava = llevl.l_Lava.render();
		foreground.addChild(lava);
		lava.y = -llevl.pxHei - 400.;

		whiteFlash = new Bitmap(Tile.fromColor(0xffffff, 1, 1), uiContainer);

		endShake.value = 1;
		criticalFade.value = 1.5;

		cam.explode();
	}

	var gameoverShown = false;
	public function showGameover() {
		if (gameoverShown) {
			return;
		}
		gameoverShown = true;
		cam.fadeOutSound();
		new Timeout(2.6, () -> {
			if (game.states.currentState == this) {
				game.states.setState(new GameOverState(this));
			}
		});
	}

	var colorMatrix = Matrix.I();

	public function startGame() {

		collisions = new CollisionHandler();

		background.addChild(level.l_Background.render());
		background.addChild(level.l_Background2.render());

		guy = new Guy(this);
		guy.x = level.pxWid * 0.5;
		guy.y = level.pxHei * 0.5 + 64;
		//addActor(guy);

		catapult = new Catapult(this);
		catapult.x = level.pxWid * 0.5;
		catapult.y = level.pxHei * 0.5;
		//addActor(catapult);

		cam = new VolcanoCam(uiContainer, this);
		//cam.x = cam.y = 8;

		for (t in level.l_Entities.all_Tree) {
			var tree = new Tree(this);
			tree.customShadow = treeShadowTile;
			tree.x = t.pixelX;
			tree.y = t.pixelY;
			//addActor(tree);
		}

		/*
		var frkinds = Data.fruits.all.toArrayCopy();
		for (_ in 0...100) {
			spawnFruit(Math.random() * level.pxWid, Math.random() * level.pxHei, frkinds.randomElement());
		}
		*/

		// spawnHelper();

		scrollInVal.value = 0;
		if (GameSaveData.getCurrent().showTutorial) {
			tutorial = new TutorialSteps(uiContainer, this);
		}
	}

	var tutorial : TutorialSteps;

	public function getFruitTile(kind: Data.Fruits) {
		var tile: Tile = null;
		if (fruitTiles[kind.ID] != null) {
			tile = fruitTiles[kind.ID];
		} else {
			var icon = kind.Icon;
			tile = fruitTile.sub(icon.x * icon.size, icon.y * icon.size, icon.size, icon.size);
			tile.dx = -8;
			tile.dy = -16;
			fruitTiles[kind.ID] = tile;
		}

		return tile;

	}

	public function hasTreesLeft() {
		for (a in actors) {
			if (a.type == Tree && !a.dead) return true;
		}

		return false;
	}

	var fruitTiles = new Map<Data.FruitsKind, h2d.Tile>();
	public function spawnFruit(x: Float, y: Float, kind: Data.Fruits) {
		var tile = getFruitTile(kind);
		var fruit = new Fruit(tile, kind, this);
		fruit.x = x;
		fruit.y = y;
		//fruits.push(fruit);
		//addActor(fruit);
	}

	var spawnCount = 1;
	function spawnWave() {
		if (wave == 3) {
			spawnCount = 2;
		}

		if (wave == 6) {
			spawnCount = 3;
		}

		if (wave == 8) {
			spawnCount = 4;
			baddieSpawnInterval = 17;
		}

		if (wave == 10) {
			spawnCount = 5;
		}

		if (wave > 10) {
			baddieSpawnInterval = 16;
		}

		if (wave > 16) {
			baddieSpawnInterval = 15;
		}

		if (wave > 18) {
			if (wave % 3 != 1) {
				spawnCount ++;
			}
		}

		for (_ in 0...spawnCount) {
			var onLeft = Math.random() > 0.5;
			var b = new Baddie(this);
			b.keepInBounds = false;
			b.x = level.pxWid + 32;
			if (onLeft) {
				b.x = 0 - 32;
			}

			b.y = Math.random() * level.pxHei;
		}

		wave ++;
		spawnIn = baddieSpawnInterval;
	}

	public function checkWave(dt: Float) {
		spawnIn -= dt;
		if (spawnIn < 0) {
			spawnWave();
		}
	}

	public function addActor(a: Actor) {
		actors.push(a);
		objects.push(a);
	}

	public function removeActor(a: Actor) {
		actors.remove(a);
		objects.remove(a);
	}

	var isReset = false;
	function resetGame() {
		if (isReset) {
			return;
		}

		isReset = true;

		if (musicChannel != null) {
			musicChannel.fadeTo(0, 0.3);
		}

		Transition.to(() -> {
			game.states.setState(new PlayState());
		}, 0.2, 0.3);
	}

	var toggledPause = false;
	function pauseToggle() {
		if (lost) return;
		if (!game.paused) {
			toggledPause = true;
			wasPaused = paused;
			paused = true;
			game.paused = true;
			if (musicChannel != null) {
				musicChannel.pause = true;
			}
		} else {
			toggledPause = false;
			paused = wasPaused;
			game.paused = false;
			if (musicChannel != null) {
				musicChannel.pause = false;
			}
		}
	}

	var wasPaused = false;
	var pausePressed = false;
	override function onEvent(e:Event) {
		if (e.kind == EFocusLost) {
			if (lost) return;
			if (toggledPause) return;
			wasPaused = paused;
			paused = true;
			game.paused = true;
			if (musicChannel != null) {
				musicChannel.pause = true;
			}
		}
		if (e.kind == EFocus) {
			if (lost) return;
			if (toggledPause) return;
			paused = wasPaused;
			game.paused = false;
			if (musicChannel != null) {
				musicChannel.pause = false;
			}
		}

		if (!guy.dead && !upgrades.shown) {
			if (e.kind == EPush && e.button == Key.MOUSE_LEFT) {
				if (game.inputMethod == Touch) {
					if (e.relX < Window.getInstance().width * 0.5) {
						return;
					}
				}
				startAim();
			}

			if ((e.kind == ERelease || e.kind == EReleaseOutside) && e.button == Key.MOUSE_LEFT) {
				#if js
				if (input.joystick.touchId == e.touchId && e.touchId != null) {
					return;
				}
				#end

				finishAim();
				if (tutorial != null) {
					tutorial.threwThing = true;
				}
			}
		}

		if (e.kind == EKeyDown && e.keyCode == Key.ESCAPE && !pausePressed) {
			pauseToggle();
			pausePressed = true;
		}

		if (e.kind == EKeyUp && e.keyCode == Key.ESCAPE) {
			pausePressed = false;
		}

		if (e.kind == EKeyDown && e.keyCode == Key.R) {
			resetGame();
		}

		#if debug
		if (e.kind == EKeyDown && e.keyCode == Key.P) {
			if (!paused) {
				showUpgrades();
			} else {
				closeUpgrades();
			}
		}
		if (e.kind == EKeyDown && e.keyCode == Key.I) {
			cam.currentLevel = .0;
		}
		#end

		#if js
		if (game.inputMethod == Touch && e.kind == ERelease) {
			Window.getInstance().displayMode = Borderless;
		}
		#end
	}

	public function onUpgrade(u: Data.Upgrades, level: Int) {
		if (u.ID == Helper) {
			spawnHelper();
		}

		if (u.ID == DMG) {
			if (level == 1) {
				damageMultiplier = 1.5;
			} else if (level == 2) {
				damageMultiplier = 3.;
			}
		}

		if (u.ID == Capacity) {
			guy.maxFruit += 2;
			guy.maxBaddies ++;
		}

		if (u.ID == Farmer) {
			timePerFruit *= 0.85;
		}

		if (u.ID == Speed) {
			guy.maxSpeed *= 1.2;
			guy.moveSpeed *= 1.2;
		}

		if (u.ID == Resurrect) {
			var livingTrees = 0;
			var t: Array<Tree> = cast actors.filter(t -> t.type == Tree);
			for (tree in t) {
				if (tree.dead) {
					tree.revive();
				} else {
					livingTrees ++;
					tree.life = tree.maxLife;
				}
			}

			if (livingTrees > 0) {
				var points = livingTrees * 250;
				cam.addStatus('+${points} x${livingTrees} alive tree bonus');
				addScore(points);
			}
		}

		if (!upgrades.hasUpgradesLeft()) {
			Newgrounds.instance.unlockMedal(68426);
		}

		cam.hasUpgrades = upgrades.hasUpgradesLeft();
		closeUpgrades();
	}

	var upgradesCallback: Void -> Void;
	public function showUpgrades(?onFinish: Void -> Void) {
		if (upgrades.shown) {
			if (onFinish != null) onFinish();
			return;
		}
		if(!upgrades.showNewUpgrades()) {
			if (onFinish != null) onFinish();
			return;
		}

		triggerDown = false;
		input.disabled = true;
		upgradesCallback = onFinish;

		if (!isCritical) {
			musicEffect.gainHF = 0.5;
			musicChannel.fadeTo(0.1, 0.4);
		}

		paused = true;
		pauseFrame = true;
		blur.useScreenResolution = true;
		blurEase.value = 7;
		upgradeAlphaFade.value = 0.4;
		upgrades.onSelect = onUpgrade;
		cam.pauseSounds();
	}

	var scrollInVal = new EasedFloat(-400, 1.2);
	var upgradeAlphaFade = new EasedFloat(1, 0.4);

	public var timePerFruit = 7.0;
	var musicVol = 0.62;

	var blurEase = new EasedFloat(0, 0.4);
	var blur = new h2d.filter.Blur(0, 1, 1);
	public function closeUpgrades() {
		if (!upgrades.shown) return;

		if (upgradesCallback != null) upgradesCallback();

		paused = false;
		upgrades.close();
		blurEase.value = 0;
		upgradeAlphaFade.value = 1.0;
		input.disabled = false;

		if (!isCritical) {
			musicEffect.gainHF = 1.;
			musicChannel.fadeTo(musicVol, 0.4);
		}

		cam.unPauseSounds();
	}

	function startAim() {
		guy.startAim();
	}

	function finishAim() {
		guy.throwFruit();
	}

	public var time = 0.0;
	public var gameTime = 0.;
	public var score(default, set) = 0;
	public var smoothedScore = new EasedFloat(0, 0.3);

	public function addScore(score: Int) {
		this.score += score;
	}

	function set_score(s:Int) {
		smoothedScore.value = s;
		return this.score = s;
	}

	var alphaFadeout = 0.8;

	public function renderHpBar(x: Float, y: Float, life: Float, maxLife: Float, stunBar = false) {
		var hpBarWidth = 64;
		var hpBarHeight = 4;
		var sx = Math.round(x + -hpBarWidth * 0.5);
		var sy = Math.round(y - 8);
		//sx += Std.int(world.x);
		//sy += Std.int(world.y);
		hpBarsGroup.addTransform(sx, sy, hpBarWidth, hpBarHeight, 0, hpBarBgTile);
		var l = Math.min(Math.max(0, life) / maxLife, 1.);
		var stunL = Math.min(2 / 5, l);
		if(!stunBar) {
			hpBarsGroup.addTransform(sx, sy, Math.round(hpBarWidth * l), hpBarHeight, 0, hpBarTile);
		} else {
			hpBarsGroup.addTransform(sx, sy, Math.round(hpBarWidth * l), hpBarHeight, 0, stunBartile);
			hpBarsGroup.addTransform(sx, sy, Math.round(hpBarWidth * stunL), hpBarHeight, 0, stunDarkTile);
			hpBarsGroup.addTransform(sx - 5, sy + 2,1, 1, 0, skullTile);
		}
	}

	public function renderWarning(x: Float, y: Float) {
		var p = world.localToGlobal(new Point(x, y));
		var renderDx = 0.;

		var horizontal = true;
		renderDx = x - guy.x;
		var t = renderDx > 0 ? warningRightTile : warningLeftTile;
		if (p.x > 0 && p.x < game.s2d.width) {
			horizontal = false;
			if (y - guy.y < 0) {
				t = warningUpTile;
			} else {
				t = warningDownTile;
			}
			if (p.y > 0 && p.y < game.s2d.height) {
				return;
			}
		}


		p.x = Math.max(0, Math.min(game.s2d.width, p.x));
		p.y = Math.max(32, Math.min(game.s2d.height - 40, p.y));

		uiOverlayGroup.add(p.x, p.y, t);
	}

	var triggerDown = false;

	var pauseFrame = false;
	var confirmWasPressed = false;
	override function tick(dt:Float) {
		if (!pausePressed) {
			if (input.startPressed()) {
				pauseToggle();
				pausePressed = true;
			}
		} else if (!input.startPressed()) {
			pausePressed = false;
		}

		if (!paused) {
			if (pauseFrame) {
				pauseFrame = false;
			}
		}

		if (pauseFrame) {
			if (input.confirmPressed(true)) {
				confirmWasPressed = true;
			}
		}

		if (pauseFrame) return;

		if (game.paused) return;
		if (paused) return;

		input.update();

		if (tutorial != null) {
			tutorial.update(dt);
		}

		time += dt;
		if (!lost) {
			gameTime += dt;
		}

		if (confirmWasPressed && !input.confirmPressed()) {
			confirmWasPressed = false;
		} else {
			if (!triggerDown) {
				if (input.triggerPressed() || (input.confirmPressed() && !confirmWasPressed)) {
					triggerDown = true;
					startAim();
				}
			}
		}

		if(triggerDown) {
			if (!input.triggerPressed() && !input.confirmPressed()) {
				finishAim();
				triggerDown = false;
			}
		}

		checkWave(dt);

		if (lava != null) {
			lava.y += 3.;
			lava.y = Math.min(lava.y, 128);
			if (cam.exploded) {
				cam.alpha *= 0.91;
			}

			if (lava.y + levels.all_levels.Level_1.pxHei > guy.y) {
				if (!guy.dead) {
					guy.kill();
					whiteFlash.alpha = 1.0;
				}
				alphaFadeout -= dt;
				if (alphaFadeout < 0) {
					world.alpha *= 0.94;
				}
				showGameover();
			}
		}

		var sp = guy.moveSpeed;
		var vx = input.moveX * sp;
		var vy = input.moveY * sp;

		if (!guy.dead) {
			guy.vx += vx;
			guy.vy += vy;
		}

		objects.sort((a, b) -> (a.y - b.y < 0) ? -1 : 1);

		// Check for catapulted objects
		var index = actors.length - 1;
		for (_ in 0...actors.length) {
			if (index < 0) {
				break;
			}

			var a = actors[index];
			if (a.catapulted) {
				if (a.y < -10) {
					a.onRemove();
					cam.feed(a);
					index --;
				}
			}
			index --;
		}

		for (a in objects) {
			a.tick(dt);

			if (a.keepInBounds && !a.held) {
				a.x = Math.max(16 + a.edgePadding, a.x);
				a.y = Math.max(80 + a.edgePadding, a.y);
				a.x = Math.min(level.pxWid - 16 - a.edgePadding, a.x);
				a.y = Math.min(level.pxHei - 8 - a.edgePadding, a.y);
			}
		}

		var hitWithFruit = false;
		for (f in actors) {
			if (f == guy) continue;
			if (f.held) continue;
			if (!f.pickupable) continue;
			if (f.dead) continue;

			var r = guy.pickupRadius + f.radius;
			var rSq = r * r;

			if (Math.abs(f.z) < 9) {
				var dx = guy.x - f.x;
				var dy = guy.y - f.y;
				if (dx * dx + dy * dy < rSq) {
					guy.pickupFruit(f);
					if (!f.hitFloor) {
						if (!heldFruitAchievementGot) {
							Newgrounds.instance.unlockMedal(68427);
							heldFruitAchievementGot = true;
						}

						addScore(50);
						cam.addStatus('+50 Air Catch');
					}
				}
			}

			if (f.type == Fruit) {
				if (f.thrown && !f.catapulted && f.hitTimeout <= 0) {
					var fmax = f.maxSpeed * 0.5;

					for (b in baddies) {
						if (b.dead) continue;
						if (b.held || b.catapulted) continue;

						var dx = b.x - f.x;
						var dy = (b.y - 8) - f.y;
						var lsq = dx * dx + dy * dy;
						var r = f.radius + b.radius;
						if (lsq < r * r) {
							var l = Math.sqrt(lsq);
							f.hitTimeout = 0.1;
							dx /= l;
							dy /= l;
							var vdst = Math.sqrt(f.vx * f.vx + f.vy * f.vy);
							var dratio = Math.min(1, vdst / f.maxSpeed + 0.3) * damageMultiplier;

							var weakShot = f.vx * f.vx + f.vy * f.vy < fmax * fmax;

							var nx = f.vx;
							var ny = f.vy;

							f.vx *= -0.2;
							f.vy *= -0.2;
							f.x -= dx * 2;
							f.y -= dy * 2;

							if (weakShot) continue;

							b.vx += nx * 1;
							b.vy += ny * 1;

							hitWithFruit = true;
							addScore(10);
							cam.addStatus('+10 Hit');

							b.hurt(dratio);
						}
					}
				}
			}
		}

		if (hitWithFruit) {
			game.sound.playWobble(hxd.Res.sound.fruithit);
		}

		var o: Array<CollisionObject> = cast actors;
		collisions.resolve(o);

		if (!isCritical) {
			if (cam.isCritical) {
				isCritical = true;
				criticalFade.value = 1.0;
				musicChannel.fadeTo(0., 0.8);
			}
		} else if (!cam.isCritical) {
			criticalFade.value = 0.;
			isCritical = false;
			musicChannel.fadeTo(musicVol, 0.8);
		}

		if (whiteFlash != null) {
			whiteFlash.alpha *= 0.94;
		}
	}

	var heldFruitAchievementGot = false;

	public function removeFruit(f) {
		fruits.remove(f);
	}

	public var paused = false;

	public function spawnHelper() {
		var helper = new Helper(this);
		helper.x = level.pxWid * 0.5 + (Math.random() * 0.5 - 0.5) * 2 * 64;
		helper.y = level.pxHei * 0.5 + (Math.random() * 0.5 - 0.5) * 2 * 64;
	}

	override function onRender(e:Engine) {
		super.onRender(e);


		if (blurEase.value > 0) {
			blur.radius = blurEase.value;
			container.filter = blur;
		} else {
			container.filter = null;
		}
		container.alpha = upgradeAlphaFade.value;
		if (game.paused) {
			container.alpha = 0.6;
		}

		if (whiteFlash != null) {
			whiteFlash.scaleX = game.s2d.width;
			whiteFlash.scaleY = game.s2d.height;
		}

		shadowGroup.clear();
		for (a in actors) {
			if (a.hideShadow) continue;
			var alpha = Math.max(0, 0.4 + (a.z / 64) / 0.4);
			var shadow = a.customShadow != null ? a.customShadow : shadowTile;
			shadowGroup.addAlpha(Math.round(a.x), Math.round(a.y), alpha, shadow);
		}

		uiOverlayGroup.clear();
		hpBarsGroup.clear();
		actorGroup.clear();
		for (a in objects) {
			a.draw();
		}

		carriedUi.x = 7;
		carriedUi.y = 104;
		carriedUi.draw();

		positionWorld();
	}

	var endShake = new EasedFloat(0, 0.5);

	function positionWorld(){
		inline function round(f) {
			return (f);
		}
		world.x = round(-guy.x * world.scaleX + game.s2d.width * 0.5);
		world.y = round(-guy.y * world.scaleY + game.s2d.height * 0.5);

		world.x = Math.min(0, world.x);
		world.y = Math.min(0, world.y);

		var scaledWidth = level.pxWid * world.scaleX;
		var scaledHeight = level.pxHei * world.scaleX;

		world.x = Math.max((-scaledWidth + game.s2d.width ), world.x);
		world.y = Math.max((-scaledHeight + game.s2d.height ), world.y);


		if (scaledWidth < game.s2d.width) {
			world.x = round((game.s2d.width - scaledWidth) * 0.5);
		}

		if (scaledHeight < game.s2d.height) {
			world.y = round((game.s2d.height - scaledHeight) * 0.5);
		}

		if (tutorial != null) {
			tutorial.updatePos();
		}

		world.x = round(world.x + Math.sin(time * 60) * criticalFade.value * 1);
		world.y = round(world.y);
		if (endShake.value > 0) {
			world.x += Math.cos(time * 50) * endShake.value * 3;
			world.y += Math.sin(time * 53) * endShake.value * 3;
		}

		world.y -= round(scrollInVal.value);

		colorMatrix.identity();
		var v = criticalFade.value;
		var r = T.mix(1, 0.52, v);
		var g = T.mix(1, 0.54, v);
		var b = T.mix(1, 0.8, v);
		colorMatrix.scale(r, g, b);

	}


	var leftState = false;
	override function onLeave() {
		super.onLeave();
		leftState = true;
		container.remove();
		upgrades.remove();
		if (musicChannel != null) {
			musicChannel.stop();
		}
	}
}
