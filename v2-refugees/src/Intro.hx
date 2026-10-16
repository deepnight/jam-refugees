import mt.deepnight.Lib;
import mt.deepnight.Buffer;
import mt.deepnight.mui.*;
import mt.deepnight.slb.*;
import mt.flash.Sfx;
import mt.MLib;
import mt.flash.Key;
import flash.display.*;
import Const;

@:bitmap("assets/logo.png") class GfxLogo extends flash.display.BitmapData {}

class Intro extends mt.deepnight.FProcess {
	var cm				: mt.deepnight.Cinematic;
	var buffer			: Buffer;
	var mask			: Sprite;
	var logo			: Bitmap;

	public function new() {
		super();

		if( Game.MUSIC!=null )
			Game.MUSIC.tweenVolume(0, 1500);

		cm = new mt.deepnight.Cinematic(Const.FPS);

		buffer = new Buffer(MLib.ceil(w()/Const.UPSCALE),MLib.ceil(h()/Const.UPSCALE), Const.UPSCALE, false, 0x130610);
		root.addChild(buffer.render);
		buffer.setTexture( Buffer.makeMosaic2(Const.UPSCALE), 0.2, true );

		logo = new flash.display.Bitmap( new GfxLogo(0,0) );
		buffer.addChild(logo);
		logo.y = buffer.height-logo.height;

		mask = new flash.display.Sprite();
		buffer.addChild(mask);
		mask.graphics.beginFill(0x0, 1);
		mask.graphics.drawRect(0,0,buffer.width,buffer.height);

		tw.create(mask.alpha, 0, 700);

		root.addEventListener( flash.events.MouseEvent.CLICK, skip1 );
	}

	function createField(p, y, str, ?col) {
		var tf = Game.createField(str, col);
		p.addChild(tf);
		tf.y = y;
		tf.width = 170;
		tf.multiline = tf.wordWrap = true;
		tf.height = tf.textHeight+5;
		return tf;
	}

	function skip1(_) {
		root.removeEventListener( flash.events.MouseEvent.CLICK, skip1 );

		tw.create(mask.alpha, 0.7, 500);

		var desc = new Sprite();
		buffer.addChild(desc);
		desc.alpha = 0;
		var y = 0.;
		var tf = createField(desc, y, "\"Refugees\"");
		y+=tf.height;

		var tf = createField(desc, y, "This game was created in 48h by Sebastien Benard (DEEPNIGHT.NET) for the charitable jam Desert Bus.");
		y+=tf.height;

		var tf = createField(desc, y, "If you like it, please donate here: http://english.secourspopulaire.fr");
		y+=tf.height;

		var tf = createField(desc, y, "Music credit: \"Epiq\" by Boerd (facebook.com/boerdmusic)");

		desc.x = Std.int(buffer.width*0.5 - desc.width*0.5);
		desc.y = Std.int(buffer.height*0.5 - desc.height*0.5);

		tw.create(desc.alpha, 1, 500);

		function skip(_) {
			root.removeEventListener( flash.events.MouseEvent.CLICK, skip);

			tw.create(desc.alpha, 0, 1000);
			tw.create(mask.alpha, 1, 1000).onEnd = function() {
				new Game();
				destroy();
			}

		}

		root.addEventListener( flash.events.MouseEvent.CLICK, skip);
	}

	override function unregister() {
		super.unregister();
		cm.destroy();
		buffer.destroy();
		logo.bitmapData.dispose();
		logo.bitmapData = null;
	}

	override function update() {
		super.update();
		cm.update();
		buffer.update();
	}
}