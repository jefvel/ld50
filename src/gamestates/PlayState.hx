package gamestates;

import entities.Guy;
import h2d.Tile;
import h3d.Engine;
import entities.WorldObject;
import entities.Actor;
import h2d.TileGroup;
import elke.graphics.TextureAtlas;
import h2d.Object;
import elke.graphics.Transition;
import hxd.Event;

class PlayState extends elke.gamestate.GameState {
	var container:Object;
	var uiContainer:Object;

	public var world: Object;
	public var background: Object;
	public var foreground: Object;

	public var atlas: TextureAtlas;
	var shadowTile: Tile;
	var shadowGroup: TileGroup;
	public var actorGroup: TileGroup;

	public var actors: Array<Actor> = [];
	public var objects: Array<WorldObject> = [];

	public var input: BasicInput;

	public var guy: Guy;

	public var level: LevelData.LevelData_Level;

	public function new() {}

	override function onEnter() {
		super.onEnter();
		container = new Object(game.s2d);

		atlas = new TextureAtlas();

		shadowTile = hxd.Res.img.shadow.toTile();
		shadowTile.dx = -8;
		shadowTile.dy = -4;

		world = new Object(container);
		background = new Object(world);
		shadowGroup = new TileGroup(shadowTile, world);
		actorGroup = new TileGroup(atlas.atlasTile, world);
		foreground = new Object(world);


		uiContainer = new Object(container);
		input = new BasicInput(game, container);


		startGame();
	}

	public function startGame() {
		var w = new LevelData();
		level = w.all_levels.Level_0;

		background.addChild(level.l_Background.render());
		background.addChild(level.l_Background2.render());

		guy = new Guy(this);
		guy.x = level.pxWid * 0.5;
		guy.y = level.pxHei * 0.5 + 64;

		addActor(guy);
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
	}

	var time = 0.0;

	override function tick(dt:Float) {
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

		objects.sort((a, b) -> Std.int(a.y - b.y));

		for (a in objects) {
			a.tick(dt);

			a.x = Math.max(16, a.x);
			a.y = Math.max(80, a.y);
			a.x = Math.min(level.pxWid - 16, a.x);
			a.y = Math.min(level.pxHei - 8, a.y);
		}
	}

	override function onRender(e:Engine) {
		super.onRender(e);
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

		shadowGroup.clear();
		for (a in actors) {
			shadowGroup.addAlpha(a.x, a.y, 0.4,shadowTile);
		}

		actorGroup.clear();
		for (a in objects) {
			a.draw();
		}
	}

	override function onLeave() {
		super.onLeave();
		container.remove();
	}
}
