package ui;

import flash.display.Bitmap;
import flash.display.BitmapData;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;
import mt.MLib;

class Message extends mt.deepnight.FProcess {
	public static var CURRENT : Null<Message>;

	public var wrapper	: flash.display.Sprite;
	var tf				: flash.text.TextField;

	public function new(txt:String, ?col=0x8A1100) {
		if( CURRENT!=null )
			CURRENT.destroy();

		super();

		Game.ME.buffer.dm.add(root, Const.DP_INTERF);
		CURRENT = this;

		wrapper = new flash.display.Sprite();
		root.addChild(wrapper);
		wrapper.graphics.beginFill(col,1);

		wrapper.filters = [
			//new flash.filters.DropShadowFilter(1,-90, 0x0,0.5, 0,0,1, 1,true),
			new flash.filters.GlowFilter(0xFFFFFF,1, 2,2,10),
			new flash.filters.GlowFilter(0x0,1, 2,2,10),
		];

		tf = Game.createField(txt);
		wrapper.addChild(tf);
		tf.wordWrap = tf.multiline = true;
		tf.width = 100;
		tf.height = 200;
		tf.height = tf.textHeight+5;
		tf.x = 8;
		tf.y = 5;

		wrapper.graphics.drawRect(0, 0, tf.width+20, tf.height+10);
		root.x = Std.int(Game.ME.buffer.width*0.5 - wrapper.width*0.5) + irnd(0,20,true);
		root.y = Std.int(Game.ME.buffer.height*0.5 - wrapper.height*0.5) + irnd(0,10,true);
	}

	public function close() {
		destroy();
		Game.ME.cm.signal();
		CURRENT = null;
	}

	override function unregister() {
		super.unregister();
	}

	override function update() {
		super.update();
	}
}
