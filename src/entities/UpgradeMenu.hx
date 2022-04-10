package entities;

import elke.process.Timeout;
import elke.Game;
import h3d.Matrix;
import elke.T;
import h2d.ScaleGrid;
import h2d.RenderContext;
import elke.utils.EasedFloat;
import h2d.Text;
import h2d.Object;
import h2d.Interactive;
import elke.entity.Entity2D;

class UpgradeButton extends Interactive {
	var paddingX = 12;
	var paddingY = 6;
	var paddingBottom = 8;
	var title: Text;

	var description: Text;
	var texts: Object;
	var frame: ScaleGrid;
	var onSelect: (Data.Upgrades, UpgradeButton) -> Void;
	public var onHover: () -> Void;
	var data: Data.Upgrades;
	var levelText: Text;
	var currentLevel = 0;

	var hoverEase = new EasedFloat(0, 0.2);
	var selectEase = new EasedFloat(0, 0.4);
	var selected = false;
	
	var matrix = new Matrix();
	var flashEase = new EasedFloat(1, 0.3);

	public var disabled = true;

	public function new(?p, data: Data.Upgrades, maxWidth: Int, onSelect: (Data.Upgrades, UpgradeButton) -> Void, currentLevel:Int) {
		super(maxWidth, 1, p);
		this.onSelect = onSelect;
		this.data = data;
		this.currentLevel = currentLevel;

		frame = new ScaleGrid(hxd.Res.img.btnframe.toTile(), 2, 2, 2, 2, this);
		texts = new Object(this);
		title = new Text(hxd.Res.fonts.equipmentpro_medium_12.toFont(), texts);
		levelText = new Text(hxd.Res.fonts.equipmentpro_medium_12.toFont(), texts);
		levelText.textAlign = Right;
		levelText.x = maxWidth - paddingX * 2;
		levelText.alpha = 0.5;
		title.text = data.Name;
		texts.x = paddingX;
		texts.y = paddingY;

		description = new Text(hxd.Res.fonts.marumonica.toFont(), texts);
		description.maxWidth = maxWidth - paddingX * 2;
		description.y = title.textHeight + title.y;
		description.text = data.Description;

		var b = texts.getBounds();
		this.width = maxWidth;
		this.height = b.height + paddingY + paddingBottom;

		frame.width = this.width;
		frame.height = this.height;

		this.onClick = onClickFn;
		levelText.text = '$currentLevel / ${data.MaxUpgrades}';

		selectEase.easeFunction = T.elasticOut;

		alpha = 0.6;

		onOver = e -> {
			alpha = 1.0;
			if (onHover != null && e != null) onHover();
			Game.instance.sound.playSfx(hxd.Res.sound.buttonhover, 0.1);
		}

		onOut = e -> {
			alpha = 0.6;
		}

		onPush = e -> {
			if (selected) return;
			hoverEase.value = -2;
			Game.instance.sound.playWobble(hxd.Res.sound.tick);
		}

		onReleaseOutside = e -> {
			if (selected) return;
			hoverEase.value = 0;
		}

		this.filter = new h2d.filter.ColorMatrix(matrix);
	}

	function onClickFn(e) {
		if (selected) return;
		if (disabled) return;
		Game.instance.sound.playWobble(hxd.Res.sound.upgradeselect, 0.5);
		selected = true;
		hoverEase.value = 0.;
		currentLevel ++;
		levelText.text = '$currentLevel / ${data.MaxUpgrades}';
		selectEase.value = 6;
		flashEase.setImmediate(100);
		flashEase.value = 1.0;
		onSelect(data, this);
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		x = Math.round(hoverEase.value + selectEase.value);
		matrix.identity();
		var v = flashEase.value;
		matrix.scale(v, v, v);
	}
}

class UpgradeMenu extends Entity2D {
	public var shown = false;

	var upgradeLevels = new Map<Data.UpgradesKind, Int>();
	var upgradeButtons = new Array<UpgradeButton>();
	var upgradesToShow = 3;
	public var onSelect : (Data.Upgrades, Int) -> Void;

	var container: Object;
	var title: Text;
	var upgradesList: Object;

	var alphaTarget = new EasedFloat(0, 0.3);


	var selectedIndex = 0;

	public function new(?p) {
		super(p);
		container = new Object(this);
		title = new Text(hxd.Res.fonts.gridgazer.toFont(), container);
		title.text = "Choose Upgrade";
		title.textAlign = Center;
		upgradesList = new Object(container);
	}

	var selected = false;
	public function showNewUpgrades() {
		if (shown) return false;
		selected = false;

		upgradesList.removeChildren();

		var upgrades = Data.upgrades.all.toArrayCopy();
		upgrades = upgrades.filter(u -> {
			if (!upgradeLevels.exists(u.ID)) {
				return true;
			}

			return upgradeLevels[u.ID] < u.MaxUpgrades;
		});

		if (upgrades.length == 0) {
			return false;
		}

		var maxWidth = Math.round(title.textWidth);
		selectedIndex = 0;
		upgradeButtons = [];

		var bY = 0.;
		for (i in 0...upgradesToShow) {
			var t = upgrades.randomElement();
			if (t == null) break;
			upgrades.remove(t);
			var l = !upgradeLevels.exists(t.ID) ? 0 : upgradeLevels[t.ID];
			var btn = new UpgradeButton(upgradesList, t, maxWidth, selectUpgrade, l);
			btn.onHover = () -> {
				selectIndex(i);
			}
			btn.y = bY;
			bY += btn.height + 4;
			upgradeButtons.push(btn);
		}

		shown = true;
		alphaTarget.value = 1;

		Game.instance.sound.playWobble(hxd.Res.sound.upgradeopen, 0.4);

		if (Game.instance.inputMethod == Gamepad) {
			selectIndex(0);
		}
		new Timeout(0.5, () -> {
			for (b in upgradeButtons) b.disabled = false;
		});

		return true;
	}

	public function hasUpgradesLeft() {
		var upgrades = Data.upgrades.all.toArrayCopy();
		upgrades = upgrades.filter(u -> {
			if (!upgradeLevels.exists(u.ID)) {
				return true;
			}

			return upgradeLevels[u.ID] < u.MaxUpgrades;
		});

		return upgrades.length > 0;
	}

	public function selectUpgrade(u: Data.Upgrades, btn: UpgradeButton) {
		if (selected) return;
		if (!upgradeLevels.exists(u.ID)) {
			upgradeLevels[u.ID] = 0;
		}


		for (c in upgradeButtons) {
			if (c != btn) {
				c.alpha = 0.;
			}
			c.onOver = c.onOut = c.onClick = c.onPush = e -> {};
		}

		btn.alpha = 1.0;
		upgradeLevels[u.ID] ++;

		selected = true;
		if (onSelect != null) {
			onSelect(u, upgradeLevels[u.ID]);
		}
	}

	function positionStuff() {
		var s = getScene();
		title.x = Math.round(s.width * 0.5);
		var b = container.getBounds();
		container.y = Math.round((s.height - b.height) * 0.5);

		var t = title.getBounds();

		upgradesList.x = t.x;
		upgradesList.y = title.textHeight + 7;
	}

	function selectPrevious() {
		var i = selectedIndex - 1;
		if (i < 0) i = upgradeButtons.length - 1;
		selectIndex(i);
	}

	function selectNext() {
		var i = selectedIndex + 1;
		if (i >= upgradeButtons.length) i = 0;
		selectIndex(i);
	}

	function selectIndex(i) {
		upgradeButtons[selectedIndex].onOut(null);
		upgradeButtons[i].onOver(null);
		selectedIndex = i;
	}

	var nonePressed = true;
	var confirmPressed = true;
	override function update(dt:Float) {
		super.update(dt);
		positionStuff();
		if (shown) {
			var s = Game.instance;
			if (s.gamepads.pressingUp()) {
				if (nonePressed) {
					selectPrevious();
				}
				nonePressed = false;
			} else if (s.gamepads.pressingDown()) {
				if (nonePressed) {
					selectNext();
				}
				nonePressed = false;
			} else {
				nonePressed = true;
			}

			if (!confirmPressed && s.gamepads.pressingConfirm()) {
				upgradeButtons[selectedIndex].onClick(null);
			} else if (!s.gamepads.pressingConfirm()) {
				confirmPressed = false;
			}
		}
	}

	public function close() {
		if (!shown) return;
		alphaTarget.value = 0;
		shown = false;
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		if (shown) {
			upgradesList.alpha = title.alpha;
		}

		title.alpha = alphaTarget.value;

		container.visible = title.alpha > 0;
	}
}