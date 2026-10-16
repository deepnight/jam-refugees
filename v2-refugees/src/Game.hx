import mt.deepnight.Lib;
import mt.deepnight.Buffer;
import mt.deepnight.mui.*;
import mt.deepnight.slb.*;
import mt.flash.Sfx;
import mt.MLib;
import mt.flash.Key;
import flash.display.*;
import Const;

@:bitmap("assets/tiles.png") class GfxTiles extends flash.display.BitmapData {}

class Game extends mt.deepnight.FProcess { //}
	public static var ME : Game;
	public static var MUSIC : Sfx;

	public static var SBANK = Sfx.importDirectory("assets/sounds");

	public var cm			: mt.deepnight.Cinematic;
	public var buffer		: Buffer;
	public var scroller		: Sprite;
	//public var dm			: mt.flash.DepthManager;
	public var sdm			: mt.flash.DepthManager;
	public var fx			: Fx;
	public var tiles		: BLib;

	public var viewport		: Viewport;
	public var city			: City;
	var drag				: Null<{ x:Float, y:Float, active:Bool }>;
	public var curHero		: Null<en.Hero>;
	var select				: BSprite;
	public var day			: Int;
	public var nightFilter	: Bitmap;
	public var shake		: Float;
	public var trainCounter	: Int;
	public var locked		: Bool;

	public function new() {
		super();
		ME = this;

		shake = 0;
		day = 1;
		trainCounter = 0;
		locked = false;

		if( MUSIC!=null )
			MUSIC.stop();

		MUSIC = SBANK.music();
		MUSIC.playLoopOnChannel(1, 9999, 1);
		Sfx.setChannelVolume(1, 0.35);

		cm = new mt.deepnight.Cinematic(Const.FPS);

		tiles = new mt.deepnight.slb.BLib( new GfxTiles(0,0) );
		tiles.slice("level", 0,0,64,32);
		tiles.slice("dark", 0,352, 128,128);

		tiles.setSliceGrid(16,16);
		tiles.sliceGrid("roadBase", 0,4);
		tiles.sliceGrid("road", 1,4, 4);
		tiles.sliceGrid("shelter", 1,5);
		tiles.sliceGrid("tool", 5,5);
		tiles.sliceGrid("loot", 2,5);
		tiles.sliceGrid("brokenShelter", 6,5);
		tiles.sliceGrid("rail", 7,5);
		tiles.sliceGrid("wagon", 8,5, 2);
		tiles.sliceGrid("park", 3,5, 2);
		tiles.sliceGrid("roof", 0,6, 10);
		tiles.sliceGrid("building", 0,7, 6);
		tiles.sliceGrid("bshadow", 0,8, 5);
		tiles.sliceGrid("tree", 0,9, 2);

		tiles.sliceGrid("hero", 0,10, 3);
		tiles.sliceGrid("heroInside", 4,10, 3);
		tiles.sliceGrid("heroBlood", 7,10);
		tiles.sliceGrid("heroNoArrow", 8,10,3);
		tiles.sliceGrid("shadow", 3,10);
		tiles.sliceGrid("select", 0,11, 2);
		tiles.sliceGrid("marker", 0,12, 4);
		tiles.sliceGrid("I_Food", 0,13);
		tiles.sliceGrid("I_Engine", 1,13);

		tiles.slice("smoke", 0,256, 32, 32, 2);
		tiles.slice("explode", 64,256, 32, 32);
		tiles.slice("dirt", 96,256, 32, 32);
		tiles.slice("plane", 0,304, 16*3, 16*3);

		tiles.initBdGroups();

		fx = new Fx();

		//dm = new mt.flash.DepthManager(root);

		buffer = new Buffer(MLib.ceil(w()/Const.UPSCALE),MLib.ceil(h()/Const.UPSCALE), Const.UPSCALE, true, 0x0);
		//dm.add(buffer.render, Const.DP_BG);
		root.addChild(buffer.render);
		buffer.setTexture( Buffer.makeMosaic2(Const.UPSCALE), 0.2, true );


		scroller = new flash.display.Sprite();
		buffer.dm.add(scroller, Const.DP_BG);
		sdm = new mt.flash.DepthManager(scroller);

		viewport = new Viewport();

		root.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, onMouseDown);
		root.addEventListener(flash.events.MouseEvent.MOUSE_UP, onMouseUp);

		root.addEventListener(flash.events.MouseEvent.RIGHT_MOUSE_DOWN, onRightDown);
		root.addEventListener(flash.events.MouseEvent.RIGHT_MOUSE_UP, onRightUp);

		root.addEventListener(flash.events.MouseEvent.RELEASE_OUTSIDE, onMouseUp);
		root.addEventListener(flash.events.Event.MOUSE_LEAVE, onMouseUp);

		city = new City();

		nightFilter = new flash.display.Bitmap( buffer.createSimilarBitmap(true) );
		buffer.dm.add(nightFilter, Const.DP_NIGHT);
		nightFilter.bitmapData.fillRect(nightFilter.bitmapData.rect, alpha(0x22005B,0.4));

		var x = 7;
		var y = 4;
		new en.Hero(0, x,y);
		new en.Hero(1, x,y);
		new en.Hero(2, x,y);

		for( cx in 0...city.mwid )
			for( cy in 0...city.mhei ) {
				var c = city.getCell(cx,cy);
				switch( c.type ) {
					case C_Loot, C_Shelter, C_Garage, C_TrainEngine :
						new en.Marker(cx,cy);

					default :
				}
			}

		select = tiles.get("select");
		select.setCenter(0.5,0.5);
		select.blendMode = ADD;
		sdm.add(select, Const.DP_BG);

		selectHero(en.Hero.ALL[0]);

		//var stats = new mt.flash.Stats(0,h()-100, false);
		//root.addChild(stats);

		for( pt in mt.deepnight.Bresenham.getDisc(curHero.cx, curHero.cy, 8) )
			if( !city.has(pt.x, pt.y, C_Building) )
				city.revealFogCell(pt.x, pt.y);


		var mask = new flash.display.Sprite();
		buffer.addChild(mask);
		mask.graphics.beginFill(0x0, 1);
		mask.graphics.drawRect(0,0,buffer.width,buffer.height);
		tw.create(mask.alpha, 0, 2000).onEnd = function() {
			mask.parent.removeChild(mask);
		}

		cm.create({
			locked = true;
			msg("Your goal is to survive and escape a city at war.") > end;
			msg("LEFT CLICK to select a character, RIGHT CLICK to move him/her.", 0x272756) > end;
			msg("Each character needs FOOD (gathered inside specific buildings). No food means death by STARVATION.", 0x272756) > end;
			msg("If a character is alone, he also loses MOOD (which can lead to death too). Regroup to 'heal' the mood.", 0x272756) > end;
			msg("Goodies alliance will throw peace bombs over your home every few minutes. You need to move all your family inside blue SHELTERS.") > end;
			locked = false;
			delayer.add( function() {
				new ui.Notification("Day "+day,true);
				delayer.add( function() new ui.Notification("6:"+irnd(10,59)+"am", 0x9BA8B7), 1000 );
			}, 1000);
			cd.set("bombingDelay", Const.seconds(80));
			//cd.set("bombingDelay", Const.seconds(10));
		});
	}

	public function msg(txt, ?col) {
		new ui.Message(txt, col);
	}

	public function onTrainRepair(e:en.Hero) {
		trainCounter--;
		if( trainCounter>0 ) {
			new ui.Notification("Good job! Train has been repaired by "+e.name+"!", 0xFFFF00);
			new ui.Notification("Remaining repairs: "+trainCounter, 0xFFFF00);
		}
		else
			win();
	}

	public function win() {
		new ui.Notification("You made it!!", 0xFFFF00, true);
		new ui.Notification("You can now leave this hell!", 0xFFFF00, true);
		cd.unset("bombing");
		cd.set("bombingDelay", Const.seconds(70));
		delayer.add( function() {
			new Ending(en.Hero.ALL.exists(0), en.Hero.ALL.exists(1), en.Hero.ALL.exists(2) );
			destroy();
		}, 1500);
	}

	function selectHero(e:en.Hero) {
		curHero = e;
		fx.select(e);
	}


	public static function createField(str:Dynamic, ?col=0xFFFFFF) {
		var tf = new flash.text.TextField();

		var f = new flash.text.TextFormat("def", 8, col);
		//f.leading = -3;
		tf.setTextFormat(f);
		tf.defaultTextFormat = f;

		tf.selectable = tf.mouseEnabled = false;
		tf.multiline = tf.wordWrap = false;
		tf.embedFonts = true;
		tf.text = Std.string(str);

		return tf;
	}


	function onMouseDown(_) {
		var m = getMouse();
		drag = {
			x		: m.gx,
			y		: m.gy,
			active	: false,
		}
	}

	function onMouseUp(_) {
		if( drag!=null && !drag.active )
			onLeftClick();

		drag = null;
	}


	function onRightDown(_) {
		var m = getMouse();
		drag = {
			x		: m.gx,
			y		: m.gy,
			active	: false,
		}
	}

	function onRightUp(_) {
		if( drag!=null && !drag.active )
			onRightClick();

		drag = null;
	}


	function getClosestHero(x,y) {
		var closes = [];
		for(e in en.Hero.ALL)
			if( Lib.distanceSqr(e.xx, e.yy, x, y)<=30*30 )
				closes.push(e);

		if( closes.length==0 )
			return null;

		closes.sort( function(a,b) {
			return Reflect.compare( Lib.distanceSqr(a.xx, a.yy, x, y), Lib.distanceSqr(b.xx, b.yy, x, y) );
		});

		return closes[0];
	}



	function onLeftClick() {
		if( ui.Message.CURRENT!=null ) {
			ui.Message.CURRENT.close();
			return;
		}

		var m = getMouse();

		for( b in ui.Button.ALL )
			if( b.isOver(m.bx,m.by) ) {
				b.onClick();
				return;
			}

		for( i in ui.Infos.ALL )
			if( i.isOver(m.bx,m.by) ) {
				if( curHero==i.hero || !viewport.onScreen(i.hero.xx, i.hero.yy) )
					viewport.moveTo(curHero.xx, curHero.yy);
				selectHero( i.hero );
				return;
			}

		var h = getClosestHero(m.sx, m.sy);
		if( h!=null )
			selectHero(h);
	}

	function onRightClick() {
		var m = getMouse();
		if( curHero==null )
			return;

		var c = city.getCell(m.cx, m.cy);

		switch( c.type ) {
			case C_Shelter, C_Loot, C_Garage, C_TrainEngine :
				var pt = city.getClosestNear(curHero.lastOut.cx, curHero.lastOut.cy, c.cx, c.cy);
				if( pt!=null )
					curHero.gotoAndDo(pt.cx, pt.cy, A_EnterBuilding(m.cx, m.cy));

			case C_Road, C_Park, C_Rail :
				curHero.goto(m.cx, m.cy);

			case C_Building, C_Train :
				var pt = city.getClosestNear(curHero.cx, curHero.cy, c.cx, c.cy);
				if( pt!=null )
					curHero.goto(pt.cx, pt.cy);
		}
	}

	public function getMouse() {
		var gx = root.mouseX;
		var gy = root.mouseY;
		var sx = MLib.round(gx/Const.UPSCALE) - scroller.x;
		var sy = MLib.round(gy/Const.UPSCALE) - scroller.y;
		return {
			gx		: gx,
			gy		: gy,

			bx		: MLib.round(gx/Const.UPSCALE),
			by		: MLib.round(gy/Const.UPSCALE),

			sx		: sx,
			sy		: sy,

			cx		: Std.int(sx/Const.GRID),
			cy		: Std.int(sy/Const.GRID),
		}
	}

	override function unregister() {
		super.unregister();

		for(e in Entity.ALL)
			e.destroy();
		while( Entity.GC.length>0 )
			Entity.GC[0].unregister();

		fx.destroy();
		sdm.destroy();
		drag = null;
		buffer.destroy();
		tiles.destroy();
		city.destroy();
	}



	override function render() {
		super.render();
		fx.update();
		buffer.update();
	}

	function onNewDay() {
		new ui.Notification("Day "+day,true);
		delayer.add( function() new ui.Notification("6:"+irnd(10,59)+"am", 0x9BA8B7), 1000 );
		var usedShelters = [];
		for(e in en.Hero.ALL)
			if( e.cell.type==C_Shelter ) {
				usedShelters.remove(e.cell);
				usedShelters.push(e.cell);
			}

		for(c in usedShelters)  {
			c.useCount++;
			if( c.useCount>=2 )
				c.depleted = true;
		}

		city.attach();
	}

	function bombShake() {
		shake = rnd(0.2, 1);
		tw.create(shake, 0, rnd(500,2000));
	}

	function bombing() {
		day++;
		cd.set("bombing", Const.seconds(6));
		cd.onComplete("bombing", onNewDay);
	}



	override function update() {
		super.update();

		cm.update();

		if( locked )
			return;

		Key.update();

		for(e in Entity.ALL)
			e.update();
		while( Entity.GC.length>0 )
			Entity.GC[0].unregister();


		if( drag!=null ) {
			var m = getMouse();
			if( !drag.active && Lib.distanceSqr(m.gx, m.gy, drag.x, drag.y)>=12*12 )
				drag.active = true;

			if( drag.active ) {
				viewport.stopTweens();
				viewport.x -= (m.gx-drag.x)/Const.UPSCALE;
				viewport.y -= (m.gy-drag.y)/Const.UPSCALE;
				drag.x = m.gx;
				drag.y = m.gy;
			}
		}

		if( !cd.has("bombingDelay") ) {
			cd.set("bombingDelay", Const.seconds(60));
			bombing();
		}

		if( curHero!=null && curHero.destroyAsked )
			curHero = null;

		if( curHero==null )
			for( h in en.Hero.ALL )
				if( !h.destroyAsked ) {
					curHero = h;
					break;
				}

		if( curHero!=null ) {
			select.visible = true;
			select.x = Std.int(curHero.xx);
			select.y = Std.int(curHero.yy);
			select.alpha = Math.sin(time*0.4)*0.4 + 0.6;
		}
		else
			select.visible = false;

		if( cd.has("bombing") ) {
			if( !cd.has("explosion") ) {
				cd.set("explosion", irnd(0, 3));
				var pt = viewport.randomPoint();
				if( !cd.hasSet("bfx",12) )
					Sfx.playOne([ SBANK.bomb1, SBANK.bomb2, SBANK.bomb3 ], 1);
				fx.explosion(pt.x, pt.y);
				bombShake();
				for(e in en.Hero.ALL)
					if( !e.cell.canProtect() && ( Lib.distanceSqr(pt.x, pt.y, e.xx, e.yy)<=50*50 || !viewport.onScreen(e.xx,e.yy) ) )
						e.die("was killed by the bombing!", true);
						//e.die("died!");
			}
			if( time%20==0 )
				fx.plane();
		}

		var c = cd.get("bombingDelay");
		var max = cd.getInitialValue("bombingDelay");
		if( c<=Const.seconds(20) )
			nightFilter.alpha = 1-c/Const.seconds(20);
		else if( c>=max-Const.seconds(10) )
			nightFilter.alpha = (c-(max-Const.seconds(10)))/Const.seconds(10);

		if( c<=Const.seconds(15) ) {
			if( time%30==0 ) {
				for(cx in 0...city.mwid)
					for(cy in 0...city.mhei)
						if( city.getCell(cx,cy).canProtect() )
							fx.bleepShelter(cx,cy);
			}

			if( !cd.hasSet("bwarning", Const.seconds(30)) ) {
				fx.plane();
				SBANK.siren(0.5);
				new ui.Notification("Warning, bombing in 15 seconds!", true);
			}
			if( time%40==0 )
				fx.plane();
		}

		if( shake>0 ) {
			root.x = Math.cos(time*0.1)*shake*0.5;
			root.y = Math.cos(time*4)*shake*8 + rnd(0,1,true);
		}
		else
			root.x = root.y = 0;


		if( !cd.has("gameover") && Lambda.count(en.Hero.ALL)==0 ) {
			cd.set("gameover", 99999);
			delayer.add( function() {
				new Intro();
				destroy();
			},1500);
		}

		viewport.update();
	}

}
