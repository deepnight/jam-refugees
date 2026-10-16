import flash.text.TextField;
import flash.display.Sprite;
import flash.display.Bitmap;

import mt.deepnight.slb.*;
import mt.deepnight.Tweenie;
import mt.deepnight.Lib;
import mt.MLib;
import Const;

class Card {
	public static var WID = 200;
	public static var HEI = 260;

	public static var ALL : Array<Card> = [];
	public static var GC : Array<Card> = [];

	public var xx			: Float;
	public var yy			: Float;
	public var zz(default,set): Float = 0;

	public var tx			: Float;
	public var ty			: Float;

	public var dx			: Float;
	public var dy			: Float;

	public var data			: CardData;
	public var destroyAsked	: Bool;
	public var locked		: Bool;
	var delayer				: mt.Delayer;
	var tw					: mt.deepnight.Tweenie;
	var cm					: mt.deepnight.Cinematic;

	public var wrapper		: Sprite;
	public var front		: BSprite;
	public var back			: BSprite;

	public var desc			: TextField;
	public var actions		: Array<{spr:Sprite, a:Action}>;

	public function new(d:CardData) {
		ALL.push(this);
		destroyAsked = false;
		locked = false;
		data = d;
		actions = [];

		xx = yy = 0;
		tx = ty = 0;
		dx = dy = 0;

		cm = new mt.deepnight.Cinematic(Const.FPS);
		delayer = new mt.Delayer(Const.FPS);
		tw = new mt.deepnight.Tweenie(Const.FPS);

		wrapper = new flash.display.Sprite();
		Game.ME.dm.add(wrapper, Const.DP_CARD);


		front = Game.ME.tiles.get("cardFront");
		wrapper.addChild(front);
		front.x = Std.int(-WID*0.5);
		front.y = Std.int(-HEI*0.5);
		front.visible = false;

		back = Game.ME.tiles.get("cardBack");
		wrapper.addChild(back);
		back.x = Std.int(-WID*0.5);
		back.y = Std.int(-HEI*0.5);
		if( data.bad )
			back.transform.colorTransform = mt.deepnight.Color.getColorizeCT(0xFF0000, 0.5);

		desc = Game.ME.createField(data.desc);
		front.addChild(desc);
		desc.multiline = desc.wordWrap = true;
		desc.width = 180;
		desc.height = 200;
		desc.x = 10;
		desc.y = 10;
		desc.filters = [
			new flash.filters.DropShadowFilter(2,90, 0x0,0.5, 0,0),
		];

		if( data.actions.length==0 )
			createActionButton();
		else
			for( a in data.actions )
				createActionButton(a);
		zz = 0;
	}

	function createActionButton(?a:Action) {
		var s = new flash.display.Sprite();
		front.addChild(s);
		s.graphics.beginFill(0x463C80);
		s.graphics.drawRect(0,0,WID-20,30);
		s.filters = [
			new flash.filters.GlowFilter(0x0,0.5, 2,2,10),
			new flash.filters.DropShadowFilter(2,90, 0x0,0.25,0,0),
		];
		s.addEventListener( flash.events.MouseEvent.CLICK, function(_) {
			if( locked || destroyAsked )
				return;

			locked = true;
			if( a==null || a.effects.length==0 )
				Game.ME.next();
			else
				cm.create({
					for(e in a.effects) {
						Game.ME.applyEffect(e);
						400;
					}
					1200;
					Game.ME.next();
				});
		});

		var tf = Game.ME.createField(a==null ? "Continue" : a.desc);
		s.addChild(tf);
		tf.width = WID;

		actions.push({ spr:s, a:a });

		updateActions();
	}

	function updateActions() {
		var i = 0;
		for(a in actions) {
			a.spr.x = 10;
			a.spr.y = HEI-actions.length*31-10+i*31;
			i++;
		}
	}

	inline function irnd(min,max,?sign) return Lib.irnd(min,max,sign);
	inline function rnd(min,max,?sign) return Lib.rnd(min,max,sign);

	inline function set_zz(v) {
		zz = v;
		wrapper.filters = [
			new flash.filters.DropShadowFilter(2+zz,70, 0x0, 0.35, 4,4),
		];
		return zz;
	}

	public function toString() return data.toString();

	public function destroy() {
		if( !destroyAsked ) {
			destroyAsked = true;
			GC.push(this);
		}
	}

	public function unregister() {
		GC.remove(this);

		tw.destroy();
		tw = null;

		delayer.destroy();
		delayer = null;

		cm.destroy();
		cm = null;

		front.destroy();
		front = null;

		back.destroy();
		back = null;

		wrapper.parent.removeChild(wrapper);
		wrapper = null;

		actions = null;
		desc = null;
	}

	public function insertIntoDeck(delay:Int) {
		wrapper.visible = true;
		var x = Const.DECK_X+irnd(0,10,true);
		var y = Const.DECK_Y+irnd(0,10,true);
		setPos(Game.ME.w()+WID, yy+rnd(0,100,true));
		wrapper.rotation = rnd(0,5,true);
		delayer.add( function() {
			cm.create({
				slideTo(x,y, irnd(700,900));
			});
		}, delay);
	}

	public function draw() {
		cm.create({
			tw.create(zz, 50, 300);
			slideTo(xx+20,yy-50, 600);
			400;
			toFront() > end("flip");
			tw.create(wrapper.rotation, 0, 400);
			tw.create(zz, 0, 300);
			slideTo(300,300);
			scaleTo(2);
		});
	}

	public function discard() {
		locked = true;
		cm.create({
			slideTo(irnd(100,300), -300) > end;
			destroy();
		});
	}

	public function scaleTo(s:Float) {
		tw.create(wrapper.scaleX, s, 500).onUpdate = function() {
			wrapper.scaleY = wrapper.scaleX;
		}
	}

	public function slideTo(x,y, duration=500) {
		tx = x;
		ty = y;
		//var n = 0;
		//tw.create(xx, x, duration, TEaseIn).onEnd = function() if( ++n>=2 ) cm.signal("slide");
		//tw.create(yy, y, duration, TEaseIn).onEnd = function() if( ++n>=2 ) cm.signal("slide");
	}

	public function setPos(x,y) {
		xx = x;
		yy = y;
		tx = x;
		ty = y;
		dx = dy = 0;
		updateCoords();
	}

	public function toFront() {
		var p = new flash.geom.PerspectiveProjection();
		p.projectionCenter.x = wrapper.x;
		p.projectionCenter.y = wrapper.y;
		wrapper.transform.perspectiveProjection = p;
		cm.create({
			tw.create(wrapper.rotationY, 90, TEaseIn, 250);
			250;
			back.visible = false;
			front.visible = true;
			wrapper.rotationY = -90;
			tw.create(wrapper.rotationY, 0, TEaseOut, 400);
			cm.signal("flip");
		});
	}

	public function toBack() {
		var p = new flash.geom.PerspectiveProjection();
		p.projectionCenter.x = wrapper.x;
		p.projectionCenter.y = wrapper.y;
		wrapper.transform.perspectiveProjection = p;
		cm.create({
			tw.create(wrapper.rotationY, -90, TEaseIn, 500);
			500;
			back.visible = true;
			front.visible = false;
			wrapper.rotationY = 90;
			tw.create(wrapper.rotationY, 0, TEaseOut, 500);
			cm.signal("flip");
		});
	}

	function updateCoords() {
		wrapper.x = Std.int(xx);
		wrapper.y = Std.int(yy-zz);
	}

	public function update() {
		cm.update();
		tw.update();
		delayer.update();

		var a = Math.atan2(ty-yy, tx-xx);
		var spd : Float = tx!=xx || ty!=yy ? 7 : 0;
		var d = Lib.distanceSqr(xx,yy, tx,ty);
		var frict = 0.9;
		if( d<=30*30 )
			frict = 0.4;
		else if( d<=120*120 )
			frict = 0.7;
		spd*=frict;

		if( d<=3*3 ) {
			spd = 0;
			setPos(tx,ty);
		}

		// X move
		dx+=Math.cos(a)*spd;
		xx+=dx;
		dx*=frict;


		// Y move
		dy+=Math.sin(a)*spd;
		yy+=dy;
		dy*=frict;


		updateCoords();
	}
}