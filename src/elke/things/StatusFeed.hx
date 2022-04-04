package elke.things;


class StatusFeed<T: h2d.Object> extends h2d.Object {
	var items: Array<T> = [];
	public var minDisplayTime = 0.3;
	public var maxDisplayTime = 1.0;

	public function new(?p) {
		super(p);
	}

	public function add(item: T) {
		items.push(item);
	}
}