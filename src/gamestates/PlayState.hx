package gamestates;

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

	public var hpBarTile: Tile;
	public var hpBarsGroup: TileGroup;

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

		hpBarTile = Tile.fromColor(0xffffff);
		hpBarsGroup = new TileGroup(hpBarTile, foreground);

		game.s2d.filter = null;

		uiContainer = new Object(container);
		input = new BasicInput(game, container);

		world.filter = new h2d.filter.ColorMatrix(colorMatrix);
		world.filter.useScreenResolution = false;

		startGame();

		musicChannel = game.sound.playMusic(hxd.Res.sound.playmusic, musicVol);
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

		musicChannel.stop();

		var llevl = levels.all_levels.Level_1;
		lava = llevl.l_Lava.render();
		foreground.addChild(lava);
		lava.y = -llevl.pxHei - 400.;
		lost = true;

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
			game.states.setState(new GameOverState(this));
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
	}

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

	function spawnWave() {
		var spawnCount = 1;
		if (wave > 2) {
			spawnCount = 2;
		}

		if (wave > 5) {
			spawnCount = 3;
		}

		if (wave > 7) {
			spawnCount = 4;
			baddieSpawnInterval = 17;
		}

		if (wave > 9) {
			spawnCount = 5;
		}

		if (wave > 10) {
			baddieSpawnInterval = 15;
		}

		if (wave > 11) {
			baddieSpawnInterval = 15;
		}

		for (_ in 0...spawnCount) {
			var onLeft = Math.random() > 0.5;
			var b = new Baddie(this);
			b.x = level.pxWid;
			if (onLeft) {
				b.x = 0;
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

	override function onEvent(e:Event) {
		if (!guy.dead && !upgrades.shown) {
			if (e.kind == EPush && e.button == Key.MOUSE_LEFT) {
				startAim();
			}

			if ((e.kind == ERelease || e.kind == EReleaseOutside) && e.button == Key.MOUSE_LEFT) {
				finishAim();
			}
		}

		#if debug
		if (e.kind == EKeyDown && e.keyCode == Key.P) {
			if (!paused) {
				showUpgrades();
			} else {
				closeUpgrades();
			}
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
		}

		if (u.ID == Farmer) {
			timePerFruit *= 0.85;
		}

		if (u.ID == Speed) {
			guy.maxSpeed *= 1.2;
			guy.moveSpeed *= 1.2;
		}

		if (u.ID == Resurrect) {
			var t = actors.filter(t -> t.type == Tree && t.dead);
			for (_ in 0...2) {
				var tree: Tree = cast t.randomElement();
				if (tree == null) break;
				t.remove(tree);
				tree.revive();
			}
		}

		cam.hasUpgrades = upgrades.hasUpgradesLeft();
		closeUpgrades();
	}

	public function showUpgrades() {
		if (upgrades.shown) return;
		if(!upgrades.showNewUpgrades()) {
			return;
		}

		input.disabled = true;

		if (!isCritical) {
			musicEffect.gainHF = 0.5;
			musicChannel.fadeTo(0.1, 0.4);
		}

		paused = true;
		blur.useScreenResolution = true;
		blurEase.value = 7;
		upgradeAlphaFade.value = 0.4;
		upgrades.onSelect = onUpgrade;
		cam.pauseSounds();
	}

	var scrollInVal = new EasedFloat(-400, 1.2);
	var upgradeAlphaFade = new EasedFloat(1, 0.4);

	public var timePerFruit = 7.0;
	var musicVol = 0.59;

	var blurEase = new EasedFloat(0, 0.4);
	var blur = new h2d.filter.Blur(0, 1, 1);
	public function closeUpgrades() {
		if (!upgrades.shown) return;
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
	public var score = 0;
	public var smoothedScore = new EasedFloat(0, 0.3);

	public function addScore(score: Int) {
		this.score += score;
		smoothedScore.value = this.score;
	}

	var alphaFadeout = 0.8;

	override function tick(dt:Float) {
		if (game.paused) return;
		if (paused) return;

		time += dt;
		if (!lost) {
			gameTime += dt;
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

		var vx = 0.;
		var vy = 0.;
		var sp = guy.moveSpeed;

		if (input.walkingLeft()) {
			vx -= sp;
		}
		if (input.walkingRight()) {
			vx += sp;
		}
		if (input.walkingDown()) {
			vy += sp;
		}
		if (input.walkingUp()) {
			vy -= sp;
		}

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

			if (Math.abs(f.z) < 2) {
				var dx = guy.x - f.x;
				var dy = guy.y - f.y;
				if (dx * dx + dy * dy < rSq) {
					guy.pickupFruit(f);
				}
			}

			if (f.type == Fruit) {
				if (f.thrown && !f.catapulted) {
					var fmax = f.maxSpeed * 0.5;
					if (f.vx * f.vx + f.vy * f.vy < fmax * fmax) continue;

					for (b in baddies) {
						if (b.dead) continue;
						if (b.held || b.catapulted) continue;

						var dx = b.x - f.x;
						var dy = b.y - f.y;
						var lsq = dx * dx + dy * dy;
						var r = f.radius + b.radius;
						if (lsq < r * r) {
							var l = Math.sqrt(lsq);
							dx /= l;
							dy /= l;
							var vdst = Math.sqrt(f.vx * f.vx + f.vy * f.vy);
							var dratio = Math.min(1, vdst / f.maxSpeed + 0.3) * damageMultiplier;

							b.vx += f.vx * 1;
							b.vy += f.vy * 1;

							f.vx *= -0.2;
							f.vy *= -0.2;
							f.x -= dx * 2;
							f.y -= dy * 2;
							hitWithFruit = true;
							b.hurt(dratio);

							addScore(10);
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

		hpBarsGroup.clear();
		actorGroup.clear();
		for (a in objects) {
			a.draw();
		}

		positionWorld();
	}

	var endShake = new EasedFloat(0, 0.5);

	function positionWorld(){
		world.x = Math.round(-guy.x * world.scaleX + game.s2d.width * 0.5);
		world.y = Math.round(-guy.y * world.scaleY + game.s2d.height * 0.5);

		world.x = Math.min(0, world.x);
		world.y = Math.min(0, world.y);

		var scaledWidth = level.pxWid * world.scaleX;
		var scaledHeight = level.pxHei * world.scaleX;

		world.x = Math.max((-scaledWidth + game.s2d.width ), world.x);
		world.y = Math.max((-scaledHeight + game.s2d.height ), world.y);

		if (scaledWidth < game.s2d.width) {
			world.x = Math.round((game.s2d.width - scaledWidth) * 0.5);
		}

		if (scaledHeight < game.s2d.height) {
			world.y = Math.round((game.s2d.height - scaledHeight) * 0.5);
		}

		world.x = Math.round(world.x + Math.sin(time * 60) * criticalFade.value * 1);
		world.y = Math.round(world.y);
		if (endShake.value > 0) {
			world.x += Math.cos(time * 50) * endShake.value * 3;
			world.y += Math.sin(time * 53) * endShake.value * 3;
		}

		world.y -= Math.round(scrollInVal.value);

		colorMatrix.identity();
		var v = criticalFade.value;
		var r = T.mix(1, 0.52, v);
		var g = T.mix(1, 0.54, v);
		var b = T.mix(1, 0.8, v);
		colorMatrix.scale(r, g, b);
	}


	override function onLeave() {
		super.onLeave();
		container.remove();
		upgrades.remove();
	}
}
