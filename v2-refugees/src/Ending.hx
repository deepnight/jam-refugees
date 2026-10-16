import mt.deepnight.Lib;
import mt.deepnight.Buffer;
import mt.deepnight.mui.*;
import mt.deepnight.slb.*;
import mt.flash.Sfx;
import mt.MLib;
import mt.flash.Key;
import flash.display.*;
import Const;

class Ending extends mt.deepnight.FProcess {
	var cm				: mt.deepnight.Cinematic;
	var buffer			: Buffer;
	public var tiles	: BLib;
	var lineY			: Float;
	var allowClick		: Bool;

	public function new(dad,mum,kid) {
		super();

		lineY = 120;
		allowClick = false;

		cm = new mt.deepnight.Cinematic(Const.FPS);
		buffer = new Buffer(MLib.ceil(w()/Const.UPSCALE),MLib.ceil(h()/Const.UPSCALE), Const.UPSCALE, false, 0x0);
		root.addChild(buffer.render);
		buffer.setTexture( Buffer.makeMosaic2(Const.UPSCALE), 0.2, true );

		tiles = new mt.deepnight.slb.BLib( new Game.GfxTiles(0,0) );
		tiles.slice("cadre", 224,112,16*5,16*4);
		tiles.slice("people", 224,176,16,32, 3);
		tiles.initBdGroups();

		root.addEventListener( flash.events.MouseEvent.CLICK, function(_) skip() );

		var s = tiles.get("cadre");
		buffer.addChild(s);
		s.x = Std.int(buffer.width*0.5-s.width*0.5) + 10;
		s.y = Std.int(50);

		var smum = tiles.get("people",0);
		s.addChild(smum);
		smum.setCenter(0.5,1);
		smum.x = 22;
		smum.y = 55;
		smum.filters = [ new flash.filters.DropShadowFilter(4,0, 0x0,0.3, 0,0) ];

		var sdad = tiles.get("people",1);
		s.addChild(sdad);
		sdad.setCenter(0.5,1);
		sdad.x = 40;
		sdad.y = 55;
		sdad.filters = [ new flash.filters.DropShadowFilter(2,0, 0x0,0.3, 0,0) ];

		var skid = tiles.get("people",2);
		s.addChild(skid);
		skid.setCenter(0.5,1);
		skid.x = 35;
		skid.y = 55;
		skid.filters = [ new flash.filters.DropShadowFilter(2,0, 0x0,0.3, 0,0) ];

		var mask = new flash.display.Sprite();
		buffer.addChild(mask);
		mask.graphics.beginFill(0x0, 1);
		mask.graphics.drawRect(0,0,buffer.width,buffer.height);

		var n = 0;
		if( mum ) n++;
		if( dad ) n++;
		if( kid ) n++;

		cm.create({
			tw.create(mask.alpha, 0, 2000);
			3000;
			if( !mum )
				tw.create(smum.alpha, 0, 2000);
			if( !dad )
				tw.create(sdad.alpha, 0, 2000);
			if( !kid )
				tw.create(skid.alpha, 0, 2000);
			2000;
			if( !mum || !dad || !kid ) {
				if( n==1 ) {
					txt("My family has ceased to exist.")> end;
					txt("War took me EVERYTHING.") > end;
					txt("You couldn't help us.") > end;
				}
				else {
					txt("Our family as a whole ceased to exist.") > end;
					txt("Life must go on, but there won't be any rest for us.") > end;
				}
			}
			else {
				txt("You saved us all!") > end;
				txt("We survived this war,") > end;
				txt("but not everyone was this lucky.") > end;
			}
			1000;
			lineY+=20;
			allowClick = true;
			txt("Thank you for playing.") > end;
			txt("Please visit DEEPNIGHT.NET")  >end;
		});
	}

	function txt(str) {
		var tf = Game.createField(str);
		buffer.addChild(tf);
		tf.width = buffer.width;
		tf.alpha = 0;
		tf.x = Std.int(buffer.width*0.5-tf.textWidth*0.5);
		tf.y = lineY;
		tw.create(tf.alpha, 1);
		delayer.add( function() cm.signal(), 1500 );
		lineY+=tf.textHeight+5;
	}

	function skip() {
		if( allowClick && !cd.hasSet("skip",999999) ) {
			new Intro();
			destroy();
		}
	}

	override function update() {
		super.update();
		cm.update();
		buffer.update();
	}
}