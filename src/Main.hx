package;

import gamestates.MenuState;
import gamestates.PlayState;
import elke.Game;

class Main {
	static var game:Game;

	static function main() {
		var colorString = haxe.macro.Compiler.getDefine("backgroundColor");
		colorString = StringTools.replace(colorString, "#", "0x");
		var color = Std.parseInt(colorString);
		game = new Game({
			//initialState: new PlayState(),
			initialState: new MenuState(),
			onInit: () -> {},
			tickRate: Const.TICK_RATE,
			pixelSize: Const.PIXEL_SIZE,
			backgroundColor: color,
		});
	}
}
