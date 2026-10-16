package ui;

class Notification extends mt.deepnight.FProcess {
	static var ALL : Array<Notification> = [];

	public function new(str:Dynamic, ?col=0xFFFFFF) {
		super();
		Game.ME.dm.add(root, Const.DP_INTERF);
		ALL.push(this);

		var c = Game.ME.cur;

		var tf = Game.ME.createField(str, col);
		root.addChild(tf);
		tf.scaleX = tf.scaleY = 2;
		tf.alpha = 0;
		tw.create(tf.alpha, 1, 500);
		tf.x = c.xx-100;
		tf.y = c.yy-Card.HEI*c.wrapper.scaleY*0.4 + (ALL.length-1)*25;
		tf.width = 200;
		tw.create(tf.x, c.xx+Card.WID*c.wrapper.scaleX*0.6, 300);

		cd.set("alive", Const.seconds(1.5));
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