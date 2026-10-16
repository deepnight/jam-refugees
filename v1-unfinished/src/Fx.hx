import flash.display.BlendMode;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;

import mt.deepnight.Particle;
import mt.deepnight.Lib;
import mt.deepnight.Color;

import Const;

class Fx {
	public static var ME : Fx;

	var game			: Game;
	var pt0				: flash.geom.Point;

	public function new() {
		ME = this;
		game = Game.ME;
		pt0 = new flash.geom.Point(0,0);
	}

	public function register(p:Particle, ?b:BlendMode) {
		game.dm.add(p, Const.DP_FX);
		p.blendMode = b!=null ? b : BlendMode.ADD;
	}

	inline function rnd(min,max,?sign) { return Lib.rnd(min,max,sign); }
	inline function irnd(min,max,?sign) { return Lib.irnd(min,max,sign); }

	public function update() {
		Particle.update();
	}
}
