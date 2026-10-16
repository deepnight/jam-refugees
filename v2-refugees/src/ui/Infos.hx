package ui;

import flash.display.Bitmap;
import flash.display.BitmapData;
import mt.deepnight.Lib;
import mt.deepnight.slb.*;
import mt.MLib;
import Const;

class Infos extends mt.deepnight.FProcess {
	public static var ALL : Map<en.Hero, Infos> = new Map();
	public var hero	: en.Hero;
	var bg			: BSprite;

	var hname		: flash.text.TextField;
	var foodBar		: StatBar;
	var moodBar		: StatBar;
	var inv			: Array<BSprite>;
	var eatButton	: Button;

	public function new(h:en.Hero) {
		super();
		hero = h;
		ALL.set(hero, this);
		inv = [];

		Game.ME.buffer.dm.add(root, Const.DP_INTERF);

		bg = new mt.deepnight.slb.BSprite( Game.ME.tiles );
		root.addChild(bg);
		bg.graphics.beginFill(mt.deepnight.Color.brightnessInt(hero.color,-0.7),1);
		bg.graphics.drawRect(0,0,70,47);
		bg.filters = [
			new flash.filters.DropShadowFilter(2,90, 0x0,0.2, 0,0,1, 1,true),
			new flash.filters.GlowFilter(0xFFFFFF,1, 2,2,10),
			new flash.filters.GlowFilter(0x0,1, 2,2,10),
		];

		foodBar = new StatBar(this, function() return hero.food, "FOOD", 0xB5784A);
		foodBar.wrapper.y = 15;

		moodBar = new StatBar(this, function() return hero.mood, "MOOD", 0x4D4684);
		moodBar.wrapper.y = 25;

		eatButton = new ui.Button(root, 49, 13, "EAT", hero.eat);

		hname = Game.createField(hero.name, hero.color);
		root.addChild(hname);
		hname.x = 1;

		root.x = Game.ME.buffer.width - bg.width;
		root.y = 20 + hero.id*(bg.height+3);
	}

	public function updateInv() {
		for(s in inv)
			s.destroy();
		inv = [];

		var n = 0;
		for(i in hero.inv) {
			var s = Game.ME.tiles.get(Std.string(i));
			root.addChild(s);
			s.x = -1+n*10;
			s.y = 30;
			s.filters = [
				new flash.filters.DropShadowFilter(2,90, 0x0,0.3, 0,0),
			];
			inv.push(s);
			n++;
		}
	}

	public function isOver(x:Float,y:Float) {
		var pt = root.globalToLocal( new flash.geom.Point(x,y) );
		return pt.x>=0 && pt.x<bg.width && pt.y>=0 && pt.y<bg.height;
	}

	public static function getByHero(h) return ALL.get(h);

	override function unregister() {
		ALL.remove(hero);

		super.unregister();

		hero = null;
		foodBar.destroy();
		moodBar.destroy();
		bg.destroy();

		eatButton.destroy();
		eatButton = null;

		for(s in inv)
			s.destroy();
		inv = null;
	}

	override function update() {
		super.update();

		if( hero.destroyAsked )
			return;

		if( inv.length!=hero.inv.length )
			updateInv();

		if( hero==Game.ME.curHero )
			root.x = Game.ME.buffer.width - bg.width - 5;
		else
			root.x = Game.ME.buffer.width - bg.width;

		if( time%10==0 )
			if( hero.cell.canProtect() )
				hname.text = hero.name+" (SAFE)";
			else if( hero.isWorking() )
				hname.text = hero.name+" (Working...)";
			else
				hname.text = hero.name;

		foodBar.update();
		moodBar.update();
	}
}

