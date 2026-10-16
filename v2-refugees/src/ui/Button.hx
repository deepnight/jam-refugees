package ui;

import flash.display.Bitmap;
import flash.display.BitmapData;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;
import mt.MLib;

class Button {
	public static var ALL : Array<Button> = [];

	public var wrapper	: flash.display.Sprite;
	var label			: flash.text.TextField;

	public function new(p:flash.display.DisplayObjectContainer, x,y, l:String, cb:Void->Void) {
		ALL.push(this);
		onClick = cb;

		wrapper = new flash.display.Sprite();
		p.addChild(wrapper);
		wrapper.x = x;
		wrapper.y = y;
		wrapper.graphics.beginFill(0x8A1100,1);
		wrapper.graphics.drawRect(0,0,17,10);

		wrapper.filters = [
			new flash.filters.DropShadowFilter(1,-90, 0x0,0.5, 0,0,1, 1,true),
			//new flash.filters.GlowFilter(0xFFFFFF,1, 2,2,10),
			new flash.filters.GlowFilter(0x0,1, 2,2,10),
		];

		label = Game.createField(l);
		wrapper.addChild(label);
		label.width = 30;
		label.height = 10;
		label.y = -1;
	}

	public function isOver(x:Float,y:Float) {
		var pt = wrapper.globalToLocal( new flash.geom.Point(x,y) );
		return pt.x>=0 && pt.x<wrapper.width && pt.y>=0 && pt.y<wrapper.height;
	}

	public dynamic function onClick() {
	}

	public function destroy() {
		ALL.remove(this);
		wrapper.parent.removeChild(wrapper);
	}
}
