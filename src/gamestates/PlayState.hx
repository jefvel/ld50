package gamestates;

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

	public var world: Object;
	public var background: Object;
	public var foreground: Object;

	public var atlas: TextureAtlas;
	var shadowTile: Tile;
	var treeShadowTile: Tile;
	var fruitTile: Tile;
	var shadowGroup: TileGroup;
	public var actorGroup: TileGroup;

	public var actors: Array<Actor> = [];
	public var objects: Array<WorldObject> = [];
	public var fruits: Array<Fruit> = [];

	public var cam: VolcanoCam;

	public var input: BasicInput;

	public var guy: Guy;
	public var catapult: Catapult;

	public var level: LevelData.LevelData_Level;

	var collisions: CollisionHandler;

	public function new() {}

	override function onEnter() {
		super.onEnter();
		container = new Object(game.s2d);

		atlas = new TextureAtlas();

		var bigShadow = hxd.Res.img.shadow.toTile();
		shadowTile = bigShadow.sub(0, 0, 16, 8);
		shadowTile.dx = -8;
		shadowTile.dy = -4;

		treeShadowTile = bigShadow.sub(48, 16, 80, 32);
		treeShadowTile.dx = -29;
		treeShadowTile.dy = -17;

		fruitTile = atlas.addTile(hxd.Res.img.fruits.toTile());

		world = new Object(container);
		background = new Object(world);
		shadowGroup = new TileGroup(bigShadow, world);
		actorGroup = new TileGroup(atlas.atlasTile, world);
		foreground = new Object(world);

		uiContainer = new Object(container);
		input = new BasicInput(game, container);

		world.filter = new h2d.filter.Nothing();
		world.filter.useScreenResolution = false;

		startGame();
	}

	public function startGame() {
		var w = new LevelData();
		level = w.all_levels.Level_0;

		collisions = new CollisionHandler();

		background.addChild(level.l_Background.render());
		background.addChild(level.l_Background2.render());

		guy = new Guy(this);
		guy.x = level.pxWid * 0.5;
		guy.y = level.pxHei * 0.5 + 64;
		addActor(guy);

		catapult = new Catapult(this);
		catapult.x = level.pxWid * 0.5;
		catapult.y = level.pxHei * 0.5;
		addActor(catapult);

		cam = new VolcanoCam(uiContainer);
		cam.x = cam.y = 8;

		for (t in level.l_Entities.all_Tree) {
			var tree = new Tree(this);
			tree.customShadow = treeShadowTile;
			tree.x = t.pixelX;
			tree.y = t.pixelY;
			addActor(tree);
		}

		var frkinds = Data.fruits.all.toArrayCopy();
		for (_ in 0...100) {
			spawnFruit(Math.random() * level.pxWid, Math.random() * level.pxHei, frkinds.randomElement());
		}
	}

	var fruitTiles = new Map<Data.FruitsKind, h2d.Tile>();
	public function spawnFruit(x: Float, y: Float, kind: Data.Fruits) {
		var tile = null;
		if (fruitTiles[kind.ID] != null) {
			tile = fruitTiles[kind.ID];
		} else {
			var icon = kind.Icon;
			tile = fruitTile.sub(icon.x * icon.size, icon.y * icon.size, icon.size, icon.size);
			tile.dx = -8;
			tile.dy = -16;
			fruitTiles[kind.ID] = tile;
		}

		var fruit = new Fruit(tile, kind, this);
		fruit.x = x;
		fruit.y = y;
		fruits.push(fruit);
		addActor(fruit);
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
		if (e.kind == EPush && e.button == Key.MOUSE_LEFT) {
			startAim();
		}

		if ((e.kind == ERelease || e.kind == EReleaseOutside) && e.button == Key.MOUSE_LEFT) {
			finishAim();
		}
	}

	function startAim() {
		guy.startAim();
	}

	function finishAim() {
		guy.throwFruit();
	}

	public var time = 0.0;

	override function tick(dt:Float) {
		if (game.paused) return;

		time += dt;

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

		guy.vx += vx;
		guy.vy += vy;

		objects.sort((a, b) -> (a.y - b.y < 0) ? -1 : 1);

		for (a in objects) {
			a.tick(dt);

			if (a.keepInBounds) {
				a.x = Math.max(16, a.x);
				a.y = Math.max(80, a.y);
				a.x = Math.min(level.pxWid - 16, a.x);
				a.y = Math.min(level.pxHei - 8, a.y);
			}
		}

		var rSq = guy.pickupRadius * guy.pickupRadius;
		for (f in fruits) {
			if (f.held) continue;

			var dx = guy.x - f.x;
			var dy = guy.y - f.y;
			if (dx * dx + dy * dy < rSq) {
				guy.pickupFruit(f);
			}
		}

		var o: Array<CollisionObject> = cast actors;
		collisions.resolve(o);
	}

	public function removeFruit(f) {
		fruits.remove(f);
	}

	override function onRender(e:Engine) {
		super.onRender(e);

		shadowGroup.clear();
		for (a in actors) {
			if (a.hideShadow) continue;
			var alpha = Math.max(0, 0.4 + (a.z / 64) / 0.4);
			var shadow = a.customShadow != null ? a.customShadow : shadowTile;
			shadowGroup.addAlpha(Math.round(a.x), Math.round(a.y), alpha, shadow);
		}

		actorGroup.clear();
		for (a in objects) {
			a.draw();
		}

		positionWorld();
	}

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

		world.x = Math.round(world.x);
		world.y = Math.round(world.y);
	}


	override function onLeave() {
		super.onLeave();
		container.remove();
	}
}
