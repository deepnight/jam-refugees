package ui;

class Notification extends mt.deepnight.FProcess {
	static var ALL : Array<Notification> = [];

	public var tf		: flash.text.TextField;

	public function new(str:Dynamic, ?col=0xFFFFFF, ?big=false) {
		super();
		var str = Std.string(str);

		Game.ME.buffer.dm.add(root, Const.DP_INTERF);
		ALL.push(this);

		tf = Game.createField(str, col);
		root.addChild(tf);
		tf.width = 250;
		if( !big )
			tf.filters = [
				new flash.filters.GlowFilter(0x0,1, 2,2,4),
			];
		tf.scaleX = tf.scaleY = big?2:1;
		tf.height = tf.textHeight+5;

		if( big )
			tf.x = -2;

		root.x = -tf.textWidth;
		root.y = 110;
		tw.create(root.x, 20, 300);

		cd.set("alive", Const.seconds(2.2+0.05*str.length));

		updateAll();
	}

	static function updateAll() {
		var h = 0.;
		for( n in ALL )
			h += n.root.height;
		if( ALL.length>0 )
			h -= ALL[0].root.height;

		var y = 100-h;
		for( n in ALL ) {
			n.tw.create(n.root.y, y, 200);
			y += n.root.height;
		}
	}

	override function unregister() {
		super.unregister();
		ALL.remove(this);
	}

	override function update() {
		super.update();
		if( !cd.has("alive") )
			root.alpha-=0.02;
			if( root.alpha<=0 )
				destroy();
	}
}