import flash.display.BlendMode;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;

import mt.MLib;
import mt.deepnight.Particle;
import mt.deepnight.Lib;
import mt.deepnight.Color;
import mt.deepnight.slb.*;

import Const;

class Fx {
	public static var ME : Fx;

	var pool			: mt.deepnight.BitmapDataPool;
	var game			: Game;
	var pt0				: flash.geom.Point;
	var tiles(get,null)	: BLib;

	public function new() {
		ME = this;
		game = Game.ME;
		pt0 = new flash.geom.Point(0,0);

		pool = new mt.deepnight.BitmapDataPool();
		pool.addBitmapData( "smoke", tiles.getBitmapData("smoke") );
		pool.addBitmapData( "smokeRed", tiles.getBitmapData("smoke",1) );
		pool.addBitmapData( "explode", tiles.getBitmapData("explode") );
	}

	public function destroy() {
		game = null;

		pool.destroy();
		pool = null;

		Particle.clearAll();
	}

	inline function get_tiles() return game.tiles;

	public function register(p:Particle, ?b:BlendMode) {
		game.sdm.add(p, Const.DP_FX);
		p.blendMode = b!=null ? b : BlendMode.ADD;
	}
	public function registerBg(p:Particle, ?b:BlendMode) {
		game.sdm.add(p, Const.DP_FX_BG);
		p.blendMode = b!=null ? b : BlendMode.ADD;
	}

	inline function rnd(min,max,?sign) { return Lib.rnd(min,max,sign); }
	inline function irnd(min,max,?sign) { return Lib.irnd(min,max,sign); }
	inline function getX(cx) return (cx+0.5)*Const.GRID;
	inline function getY(cy) return (cy+0.5)*Const.GRID;


	public function pathDots(e:Entity, path:Array<{x:Int,y:Int}>) {
		var i = 0;
		var last = { x:e.cx, y:e.cy };
		while( i<path.length ) {
			var ratio = i/(path.length-1);
			var next = path[i+1];
			if( next!=null ) {
				var cur = path[i];
				var a = next!=null ? Math.atan2(next.y-cur.y, next.x-cur.x) : Math.atan2(cur.y-last.y, cur.x-last.x);
				var p = new mt.deepnight.Particle( getX(cur.x), getY(cur.y) );
				p.drawBox(1,1, 0xA8D3FF, 0.5);
				p.filters = [
					new flash.filters.GlowFilter(0x0069D2,1, 4,4,2),
				];
				p.life = 10;
				if( next!=null )
					p.moveAng(a, 0.6);
				p.frict = 0.95;
				p.delay = ratio*5;
				register(p);
				last = cur;
			}
			i++;
		}
	}

	public function plane() {
		var v = game.viewport;
		var p = new mt.deepnight.Particle(v.x+v.wid*0.5, v.y+v.hei*rnd(0,0.5,true));
		p.useBitmapData( tiles.getBitmapData("plane"), true );
		p.dx = -rnd(2,3);
		p.scaleX = p.scaleY = rnd(1, 2);
		p.alpha = rnd(0.3, 0.6);
		p.life = 240;
		p.bounds = v.getRect();
		p.bounds.x-=30;
		p.bounds.width+=60;
		register(p, NORMAL);
	}

	public function actionTarget(cx,cy) {
		var p = new mt.deepnight.Particle(getX(cx), getY(cy));
		var s = tiles.get("select", 1);
		s.setCenter(0.5,0.5);
		p.addChild(s);
		p.alpha = 0.3;
		p.fadeOutSpeed = 0.02;
		p.onKill = s.destroy;
		p.life = 0;
		register(p);
	}

	public function select(e:Entity) {
		//var p = new mt.deepnight.Particle(e.xx, e.yy-6);
		//p.drawBox(1,12, 0xFFD900, false);
		//p.ds = -0.03;
		//p.dy = 0.1;
		//p.life = 0;
		//p.filters = [
			//new flash.filters.GlowFilter(0xFF4D00,1, 8,8,3),
		//];
		//register(p);

		var p = new mt.deepnight.Particle(e.xx, e.yy);
		p.drawCircle(9, 0xFFD900, false);
		p.ds = -0.06;
		p.life = 0;
		p.scaleY = 0.8;
		p.filters = [
			new flash.filters.GlowFilter(0xFF4D00,1, 8,4,3),
		];
		registerBg(p);
	}


	public function blood(e:en.Hero) {
		var p = new mt.deepnight.Particle(e.xx, e.yy);
		p.useBitmapData( pool.get("smokeRed"), false );
		p.rotation = rnd(0,360);
		p.scaleX = p.scaleY = rnd(0.9,1.2);
		p.ds = rnd(0.1, 0.2);
		p.dr = rnd(0,0.5,true);
		p.alpha = rnd(0.8, 1);
		p.life = rnd(0, 4);
		register(p, NORMAL);


		var c = [ 0xD2040A,0xD2040A,0xD2040A,0xD2040A,0xD2040A,0xDBB564,0xDBB564 ];
		switch( e.type ) {
			case Mum : c = c.concat([0xDF20D1,0xDF20D1]);
			case Dad : c = c.concat([0x4953AB,0x4953AB]);
			case Kid : c = c.concat([0x578512,0x578512]);
		}
		for(i in 0...25) {
			var p = new mt.deepnight.Particle(e.xx+rnd(0,1,true), e.yy-rnd(0,3));
			p.drawBox(rnd(1,2),1, c[Std.random(c.length)], rnd(0.5, 0.9));
			p.dx = rnd(0,1,true);
			p.dy = -rnd(0,2);
			p.gy = 0.2;
			p.frict = 0.9;
			p.life = rnd(120,200);
			p.fadeOutSpeed = 0.03;
			p.groundY = e.yy+rnd(0,4,true);
			p.dr = rnd(0,5,true);
			p.onBounce = function() {
				p.gy = 0;
				p.dy = 0;
				p.dx*=0.5;
				p.dr = 0;
			}
			register(p, NORMAL);
		}

		for(i in 0...5) {
			var p = new mt.deepnight.Particle(e.xx+rnd(0,1,true), e.yy-rnd(0,3));
			p.drawBox(1,1, c[Std.random(c.length)], rnd(0.5, 0.7));
			p.dx = rnd(0,0.5,true);
			p.dy = -rnd(2,4);
			p.gy = 0.1;
			p.frict = 0.9;
			p.life = rnd(90,200);
			p.groundY = e.yy+rnd(0,4,true);
			p.onBounce = function() {
				p.gy = 0;
				p.dy = 0;
				p.dx*=0.5;
			}
			register(p, NORMAL);
		}
	}


	public function bleep(e:en.Hero) {
		var p = new mt.deepnight.Particle(e.xx, e.yy);
		p.drawCircle(7, e.color);
		p.scaleY = 0.6;
		p.ds = 0.02;
		p.life = 0;
		p.fadeOutSpeed = 0.15;
		p.filters = [
			new flash.filters.BlurFilter(8,4),
		];
		registerBg(p);
	}


	public function bleepShelter(cx,cy) {
		var p = new mt.deepnight.Particle(getX(cx), getY(cy));
		p.drawCircle(15, 0x80FF00);
		p.scaleY = 0.7;
		p.ds = 0.05;
		p.life = 0;
		p.fadeOutSpeed = 0.15;
		p.filters = [
			new flash.filters.BlurFilter(8,4),
		];
		registerBg(p);
	}


	public function fire(x,y) {
		var time = game.time;
		var p = new mt.deepnight.Particle(x+rnd(0,4,true), y+rnd(0,3,true));
		p.drawBox(1,1,0xFFFF00, rnd(0.5,1));
		p.filters = [
			new flash.filters.GlowFilter(0xFF4D00,0.8, 4,4,8),
		];
		p.da = 0.1;
		p.alpha = 0;
		p.dy = -rnd(0,0.2);
		p.gx = rnd(0,0.03);
		p.gy = -rnd(0,0.05);
		p.frict = rnd(0.85, 0.90);
		p.life = rnd(5, 10);
		register(p);

		var p = new mt.deepnight.Particle(x+rnd(0,4,true), y+rnd(0,3,true));
		p.useBitmapData( pool.get("smoke"), false );
		p.da = 0.03;
		p.alpha = 0;
		p.scaleX = p.scaleY = rnd(0.3, 0.5);
		p.dr = rnd(0,1);
		p.gx = rnd(0.02, 0.03);
		p.gy = -rnd(0, 0.10);
		p.frict = rnd(0.85, 0.90);
		p.life = rnd(20, 30);
		p.fadeOutSpeed = 0.02;
		register(p,NORMAL);
	}


	public function explosion(x,y) {
		var p = new mt.deepnight.Particle(x,y);
		p.useBitmapData( pool.get("smoke"), false );
		p.rotation = rnd(0,360);
		p.scaleX = p.scaleY = rnd(1,2);
		p.ds = rnd(0.005, 0.008, true);
		p.dr = rnd(0,0.5,true);
		p.alpha = rnd(0.8, 1);
		p.life = rnd(50, 80);
		register(p, NORMAL);

		var p = new mt.deepnight.Particle(x,y);
		p.useBitmapData( pool.get("explode"), false );
		p.scaleX = p.scaleY = rnd(1,2);
		p.ds = -rnd(0.02, 0.04);
		p.life = rnd(0, 2);
		register(p);

		if( Std.random(100)<50 ) {
			var n = irnd(0,2);
			for( i in 0...n ) {
				var p = new mt.deepnight.Particle(x+rnd(4,12,true), y+rnd(4,12,true));
				p.useBitmapData( pool.get("explode"), false );
				p.scaleX = p.scaleY = rnd(0.5,0.8);
				p.ds = -rnd(0.02, 0.04);
				p.life = 0;
				p.delay = i*3 + rnd(0, 2);
				register(p);
			}
		}
	}


	public function update() {
		Particle.update();
	}
}
