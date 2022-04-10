package elke.things;

import elke.utils.EasedFloat;
import h2d.RenderContext;


class StatusFeed<T: h2d.Object> extends h2d.Object {
	var items: Array<T> = [];

	public var minDisplayTime = 0.3;
	public var maxDisplayTime = 1.2;

	public var travelTime = 0.3;

	public var travelDistance = 16.;
	public var fadeOutTime = 0.15;

	public var easingFunc:(Float) -> Float = T.expoOut;

	var moveInVal: EasedFloat = null;
	var fadeOutVal: EasedFloat = null;

	public var directionX = 0.;
	public var directionY = 1.;

	var current: T = null;
	var previous: T = null;

	var currentActiveTime = 0.;

	public function new(?p) {
		super(p);
		moveInVal = new EasedFloat(1, travelTime);
		fadeOutVal = new EasedFloat(1, fadeOutTime);
	}

	public function add(item: T) {
		items.push(item);
	}

	function pickNewCurrent() {
		if (previous != null) {
			previous.remove();
		}

		previous = current;
		if (previous != null) {
			fadeOutVal.setImmediate(previous.alpha);
			fadeOutVal.value = 0.;
		}

		current = items.shift();
		if (current != null) {
			addChild(current);
			moveInVal.setImmediate(1);
			moveInVal.value = 0.;
			currentActiveTime = 0.;
		}
	}

	override function sync(ctx:RenderContext) {
		super.sync(ctx);
		if (current == null) {
			pickNewCurrent();
		} else {
			current.y = Math.round(travelDistance * moveInVal.value);
			current.alpha = 1 - moveInVal.value;
			currentActiveTime += ctx.elapsedTime;
			var untilPickNew = items.length > 0 ? minDisplayTime : maxDisplayTime;
			if (currentActiveTime > untilPickNew) {
				pickNewCurrent();
			}
		}

		if (previous != null) {
			previous.alpha = fadeOutVal.value;
		}
	}
}