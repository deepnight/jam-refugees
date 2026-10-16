package ui;

import flash.display.Bitmap;
import flash.display.BitmapData;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;
import mt.MLib;

class StatBar {
	public var wrapper	: flash.display.Sprite;
	var bar				: flash.display.Bitmap;
	var color			: Int;
	var getter			: Void->Float;
	var label			: flash.text.TextField;

	public function new(i:Infos, g, name, col) {
		color = col;
		getter = g;

		wrapper = new flash.display.Sprite();
		i.root.addChild(wrapper);
		wrapper.x = 3;

		label = Game.createField(name, color);
		wrapper.addChild(label);
		label.x = -2;
		label.y = -3;

		bar = new flash.display.Bitmap( new flash.display.BitmapData(21,5,false,0x0) );
		wrapper.addChild(bar);
		bar.x = 22;
		bar.filters = [
			new flash.filters.GlowFilter(0xFFFFFF,0.2, 2,2,5, 1,true),
			new flash.filters.DropShadowFilter(1,90, 0x0,0.3, 0,0),
		];
	}

	public function destroy() {
		bar.bitmapData.dispose();
		bar.bitmapData = null;

		wrapper.parent.removeChild(wrapper);
	}

	public function isOver(x:Float,y:Float) {
		var pt = wrapper.globalToLocal( new flash.geom.Point(x,y) );
		return pt.x>=0 && pt.x<wrapper.width && pt.y>=0 && pt.y<wrapper.height;
	}

	public function update() {
		var bd = bar.bitmapData;
		bd.fillRect(bd.rect, 0x0);
		var f = getter()/100;
		var c = f<=0.35 ? 0xFF0000 : color;
		bd.fillRect(new flash.geom.Rectangle(0,0,bd.width*f, bd.height), c);
		if( f<=0.35 && Game.ME.time%10==0 ) {
			bar.y--;
			Game.ME.tw.create(bar.y, bar.y+1, 200).pixel = true;
		}
	}
}
