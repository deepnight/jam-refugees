class Viewport {
	public var tw		: mt.deepnight.Tweenie;

	public var x		: Float;
	public var y		: Float;
	public var wid		: Int;
	public var hei		: Int;

	public function new() {
		tw = new mt.deepnight.Tweenie(Const.FPS);
		x = y = 0;
		wid = Game.ME.buffer.width;
		hei = Game.ME.buffer.height;
	}

	function toString() return Std.int(x)+","+Std.int(y);

	public function moveTo(x,y) {
		var d = 500;
		tw.create(this.x, x, d);
		tw.create(this.y, y, d);
	}

	public inline function getRect() return new flash.geom.Rectangle(x-wid*0.5, y-hei*0.5, wid, hei);

	public function stopTweens() {
		tw.terminateWithoutCallbacks(x);
		tw.terminateWithoutCallbacks(y);
	}

	public function randomPoint() {
		return {
			x	: x+mt.deepnight.Lib.rnd(0,0.5,true)*wid,
			y	: y+mt.deepnight.Lib.rnd(0,0.5,true)*hei,
		}
	}

	public function onScreen(xx,yy) {
		return xx>=x-wid*0.5 && xx<x+wid*0.5 && yy>=y-hei*0.5 && yy<y+hei*0.5;
	}

	public function update() {
		tw.update();

		var city = Game.ME.city;

		if( x<wid*0.5 )
			x = wid*0.5;

		if( x>city.pwid-wid*0.5 )
			x = city.pwid-wid*0.5;

		if( y<hei*0.5 )
			y = hei*0.5;

		if( y>city.phei-hei*0.5 )
			y = city.phei-hei*0.5;

		Game.ME.scroller.x = Std.int(-x+wid*0.5);
		Game.ME.scroller.y = Std.int(-y+hei*0.5);
	}
}

