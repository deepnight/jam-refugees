import mt.deepnight.slb.*;
import mt.deepnight.Lib;
import flash.display.Sprite;
import mt.MLib;
import Const;
import City;

class Entity {
	public static var ALL : Array<Entity> = [];
	public static var GC : Array<Entity> = [];

	public var speed		: Float;

	public var cx			: Int;
	public var cy			: Int;

	public var xr			: Float;
	public var yr			: Float;

	public var xx			: Float;
	public var yy			: Float;

	public var dx			: Float;
	public var dy			: Float;

	public var spr			: BSprite;
	public var destroyAsked	: Bool;
	public var dir			: Int;

	public var path			: Array<{x:Int, y:Int}>;

	public var delayer		: mt.Delayer;
	public var cd			: mt.Cooldown;
	var autoCenter			: Bool;

	var city(get,null)		: City;
	public var cell(get,null): Cell;

	public function new(x,y) {
		ALL.push(this);
		destroyAsked = false;
		path = [];
		dir = 1;

		autoCenter = true;
		speed = 0.012;
		#if debug
		speed*=2.5;
		#end
		cx = x;
		cy = y;
		xr = yr = 0.5;
		xx = yy = 0;
		dx = dy = 0;

		delayer = new mt.Delayer(Const.FPS);
		cd = new mt.Cooldown();

		spr = new mt.deepnight.slb.BSprite(Game.ME.tiles);
		setLayer(Const.DP_HERO);
		spr.setCenter(0.5, 1);

		updateCoords();
	}

	inline function setLayer(v) Game.ME.sdm.add(spr, v);

	inline function get_city() return Game.ME.city;
	inline function get_cell() return Game.ME.city.getCell(cx,cy);

	public function goto(tx,ty) {
		path = Game.ME.city.getPath(cx,cy, tx,ty);
	}

	public function setPos(cx,cy) {
		this.cx = cx;
		this.cy = cy;
		xr = yr = 0.5;
		dx = dy = 0;
		updateCoords();
	}

	public inline function destroy() {
		if( !destroyAsked ) {
			destroyAsked = true;
			GC.push(this);
		}
	}

	public function unregister() {
		ALL.remove(this);
		GC.remove(this);
		path = null;

		spr.destroy();

		delayer.destroy();
		cd.destroy();
	}

	function updateCoords()  {
		xx = ( cx+xr )*Const.GRID;
		yy = ( cy+yr )*Const.GRID;
		spr.x = Std.int(xx);
		spr.y = Std.int(yy);
		spr.scaleX = dir==-1 ? -MLib.fabs(spr.scaleX) : MLib.fabs(spr.scaleX);
	}

	function getCellCenter(x,y) {
		return { xr:0.5, yr:0.5 }
	}

	function onPathComplete() {
	}

	public function isMoving() {
		return path.length>0;
	}

	public function update() {
		cd.update();
		delayer.update();

		if( path.length>0 ) {
			// Follow path
			var next = { cx:path[0].x, cy:path[0].y };
			if( cx==path[0].x && cy==path[0].y ) {
				path.shift();
				if( path.length==0 )
					onPathComplete();
			}
			else {
				var r = getCellCenter(next.cx, next.cy);
				var a = Math.atan2( (next.cy+r.yr)-(cy+yr), (next.cx+r.xr)-(cx+xr) );
				dx+=Math.cos(a)*speed;
				dy+=Math.sin(a)*speed;
			}
			if( dx>0 ) dir = 1;
			if( dx<0 ) dir = -1;
		}
		else {
			// Auto center
			if( autoCenter ) {
				var r = getCellCenter(cx,cy);
				if( Lib.distanceSqr(xr, yr , r.xr, r.yr) > 0.1*0.1 ) {
					var a = Math.atan2( r.yr-yr, r.xr-xr );
					dx+=Math.cos(a)*speed*0.5;
					dy+=Math.sin(a)*speed*0.5;
				}
			}
		}

		xr+=dx;
		dx*=0.8;
		if( MLib.fabs(dx)<=0.001 )
			dx = 0;
		while( xr>1 ) { xr--; cx++; }
		while( xr<0 ) { xr++; cx--; }

		yr+=dy;
		dy*=0.8;
		if( MLib.fabs(dy)<=0.001 )
			dy = 0;
		while( yr>1 ) { yr--; cy++; }
		while( yr<0 ) { yr++; cy--; }

		updateCoords();
	}
}
