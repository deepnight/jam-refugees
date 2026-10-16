package en;

import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;

import Const;
import mt.deepnight.slb.*;
import mt.deepnight.Lib;
import mt.MLib;

class Hero extends Entity {
	public static var ALL : Map<Int,Hero> = new Map();
	public var id			: Int;
	var pendingAction		: HeroAction;
	public var inside(get,null)	: Bool;
	public var lastOut		: { cx:Int, cy:Int };
	public var aprogress	: Float;
	var bar					: flash.display.Bitmap;
	var shadow				: BSprite;
	public var type			: HeroType;
	public var name(get,null)	: String;
	public var color(get,null)	: Int;

	public var mood			: Float;
	public var food			: Float;
	public var inv			: Array<Item>;


	public function new(id, x,y) {
		super(x,y);

		setLayer(Const.DP_HERO);
		food = 100;
		mood = 100;
		inv = [];
		#if debug
		inv.push(I_Engine);
		inv.push(I_Engine);
		inv.push(I_Food);
		inv.push(I_Food);
		#end

		this.id = id;
		type = switch( id ) {
			case 0 : Dad;
			case 1 : Mum;
			case 2 : Kid;
			default : throw "error "+id;
		}
		aprogress = 0;
		lastOut = { cx:cx, cy:cy }
		pendingAction = A_None;
		ALL.set(id, this);

		spr.set("hero", switch( type ) {
			case Dad : 0;
			case Mum : 1;
			case Kid : 2;
		});


		switch( type ) {
			case Kid : speed*=0.7;
			default :
		}

		bar = new flash.display.Bitmap( new flash.display.BitmapData(2,7,false,0x0) );
		Game.ME.sdm.add(bar, Const.DP_INTERF);
		bar.filters = [ new flash.filters.GlowFilter(0x0,1, 2,2,10) ];
		bar.visible = false;

		shadow = Game.ME.tiles.get("shadow");
		Game.ME.sdm.add(shadow, Const.DP_BG);
		shadow.setCenter(0.5, 0.5);
		shadow.scaleX = 1-id*0.1;

		new ui.Infos(this);

		updateCoords();
	}

	public function isWorking()  {
		return aprogress>0;
	}

	public function die(reason, violent) {
		new ui.Notification(name+" "+reason, 0xFF0000);
		destroy();
		if( violent )
			Fx.ME.blood(this);
		new en.Cadaver(this);

		var other = null;
		for(e in ALL)
			if( e!=this )
				other = e;

		if( other!=null )
			for(i in inv)
				switch( i ) {
					case I_Engine : other.addItem(i);
					case I_Food :
				}
	}


	public function hasInvItem(i:Item) {
		for( i2 in inv )
			if( i2==i )
				return true;
		return false;
	}

	public function countItem(i:Item) {
		var n = 0;
		for( i2 in inv )
			if( i2==i )
				n++;
		return n;
	}

	public function getOtherProvider(i:Item) {
		for(e in ALL )
			if( e!=this && e.cx==cx && e.cy==cy && e.hasInvItem(i) )
				return e;
		return null;
	}


	public function removeItem(i:Item) inv.remove(i);
	public function addItem(i:Item) inv.push(i);


	function get_name() return switch( type ) {
		case Dad : "Dad";
		case Mum : "Mum";
		case Kid : "Boy";
	}
	function get_color() return switch( type ) {
		case Dad : 0x4566E9;
		case Mum : 0xFF0080;
		case Kid : 0x8DDB24;
	}

	function toString() return type+'@$cx,$cy';

	inline function get_inside() return Game.ME.city.getCell(cx,cy).collides();


	override function goto(x,y) {
		path = [];
		resetLocalAction();
		var bx = cx;
		var by = cy;
		var wasInside = inside;
		if( inside )
			leaveBuilding();

		super.goto(x,y);

		if( wasInside ) {
			cx = bx;
			cy = by;
			if( path.length==0 )
				path = [ {x:bx,y:by}, {x:x,y:y} ];
			else
				path.insert(0, { x:bx, y:by });
		}
		pendingAction = A_None;
		cd.unset("pathDots");
	}

	public function gotoAndDo(tx,ty, a:HeroAction) {
		goto(tx,ty);
		if( path.length>0 )
			pendingAction = a;
		else if( tx==cx && ty==cy ) {
			pendingAction = a;
			runPendingAction();
		}
	}

	public function bgoto(tx,ty) {
		path = mt.deepnight.Bresenham.getThinLine(cx,cy,tx,ty);
		if( path[0].x!=cx || path[0].y!=cy )
			path.reverse();
	}

	function runPendingAction() {
		switch( pendingAction ) {
			case A_None :
			case A_EnterBuilding(x,y) :
				enterBuilding(x,y);
		}
		pendingAction = A_None;
	}

	function enterBuilding(x,y) {
		bgoto(x,y);
	}

	function leaveBuilding() {
		cx = lastOut.cx;
		cy = lastOut.cy;
		xr = yr = 0.5;
	}


	override function onPathComplete() {
		super.onPathComplete();
		runPendingAction();
	}


	override function unregister() {
		super.unregister();

		ALL.remove(id);

		shadow.destroy();

		ui.Infos.getByHero(this).destroy();

		bar.bitmapData.dispose();
		bar.bitmapData = null;
		bar.parent.removeChild(bar);
		bar = null;
	}

	public inline function countOthers(x,y) {
		var n = 0;
		for( e in ALL )
			if( e!=this && e.cx==x && e.cy==y )
				n++;
		return n;
	}


	override function getCellCenter(x,y) {
		return countOthers(x,y)==0 ? super.getCellCenter(x,y) : switch( id ) {
			case 0 : { xr:0.2, yr:0.8 };
			case 1 : { xr:0.45, yr:0.4 };
			case 2 : { xr:0.8, yr:0.7 };
			default : super.getCellCenter(x,y);
		}
	}


	function resetLocalAction() {
		bar.visible = false;
		aprogress = 0;
	}

	public function eat() {
		var pow = 40;

		if( food>100-pow ) {
			new ui.Notification(name+" isn't hungry.", color);
			return;
		}

		var possibles = Lambda.array(ALL).filter( function(e) {
			return e.cx==cx && e.cy==cy && e.hasInvItem(I_Food);
		});
		possibles.sort( function(a,b) return -Reflect.compare(a.countItem(I_Food), b.countItem(I_Food)) );
		if( possibles.length==0 )
			new ui.Notification(name+" has no FOOD!", color);
		else {
			var e = possibles[0];
			if( e.countItem(I_Food)==countItem(I_Food) )
				e = this;
			e.removeItem(I_Food);
			food+=pow;
			if( e==this )
				new ui.Notification(name+" consumed 1 FOOD", color);
			else
				new ui.Notification(name+" consumed 1 FOOD from "+e.name+"'s stock", color);
		}
	}

	function advanceLocalAction() {
		if( cell.depleted ) {
			resetLocalAction();
			return;
		}

		if( cell.type==C_TrainEngine && !hasInvItem(I_Engine) ) {
			if( !cd.hasSet("engineInfo",Const.seconds(30)) )
				new ui.Notification(name+" need an ENGINE PART to repair the train.", color);
			return;
		}

		//switch( type ) {
			//case Kid : aprogress+=0.75;
			//case Dad, Mum : aprogress+=1;
		//}
		aprogress++;

		var max = switch( cell.type ) {
			case C_Loot : Const.seconds(5);
			case C_Garage : Const.seconds(5);
			case C_TrainEngine : Const.seconds(3);
			case C_Shelter : -1;
			case C_Park, C_Road, C_Building, C_Rail, C_Train : -1;
		}
		if( max>0 ) {
			bar.visible = true;
			bar.bitmapData.fillRect(bar.bitmapData.rect, 0x621800);
			var h = bar.bitmapData.height*aprogress/max;
			var r = new flash.geom.Rectangle(0, bar.bitmapData.height-h, 2, h);
			bar.bitmapData.fillRect(r, 0xFFFF00);
			r = null;
		}
		if( max>0 && aprogress>=max ) {
			resetLocalAction();
			switch( cell.type ) {
				case C_Loot :
					addItem(I_Food);
					new ui.Notification(name+" found FOOD", color);
					cell.depleted = true;

				case C_Garage :
					addItem(I_Engine);
					new ui.Notification(name+" found an ENGINE PART", color);
					cell.depleted = true;

				case C_TrainEngine :
					removeItem(I_Engine);
					Game.ME.onTrainRepair(this);
					cd.set("engineInfo",Const.seconds(30));

				default :
			}

		}
	}


	override function updateCoords() {
		super.updateCoords();
		if( bar!=null ) {
			bar.x = Std.int(xx+5);
			bar.y = Std.int(yy-6);

			shadow.x = Std.int(xx-1);
			shadow.y = Std.int(yy-1);
		}
	}

	function updateFrame() {
		spr.set( inside?"heroInside":"hero", spr.frame );
	}

	override function update() {
		var oldInside = inside;

		super.update();

		if( oldInside!=inside )
			updateFrame();

		var c = Game.ME.city.getCell(cx,cy);

		if( c.collides() ) {
			//spr.setFrame(1);
		}
		else {
			//spr.setFrame(0);
			lastOut.cx = cx;
			lastOut.cy = cy;
		}

		if( inside && !isMoving() )
			advanceLocalAction();

		if( path.length>0 && !cd.hasSet("pathDots",20) ) {
			Fx.ME.pathDots(this, path);
			switch( pendingAction ) {
				case A_None :
					Fx.ME.actionTarget(path[path.length-1].x, path[path.length-1].y);

				case A_EnterBuilding(x,y) :
					Fx.ME.actionTarget(x,y);
			}
		}

		city.revealFogBox(cx, cy);
		for( pt in mt.deepnight.Bresenham.getDisc(cx,cy, 4) )
			if( city.sightCheck(cx,cy, pt.x, pt.y) )
				city.revealFogCell(pt.x, pt.y);

		//if( !cd.hasSet("bleep", 20) )
			//Fx.ME.bleep(this);

		var fs = 0.02 * (mood<=0?3:1);
		var cs = 0.05;
		var alone = countOthers(cx,cy)==0;
		var oldMood = mood;
		switch( type ) {
			case Dad :
				food -= fs*1.2;
				mood += alone ? -cs : cs*10;

			case Mum :
				food-=fs;
				mood += alone ? -cs : cs*10;

			case Kid :
				food-=fs*2;
				mood += alone ? -cs : cs*10;
		}

		mood = MLib.fclamp(mood, 0, 100);
		food = MLib.fclamp(food, 0, 100);
		if( oldMood>0 && mood==0 )
			new ui.Notification(name+" is depressed and will consume food faster!", 0xFF0000);

		if( food<=0 )
			die("died from starvation!", false);
	}

}


