import mt.deepnight.Lib;
import mt.deepnight.Buffer;
import mt.deepnight.mui.*;
import mt.deepnight.slb.*;
import mt.MLib;
import flash.display.*;
import Const;

@:bitmap("assets/tiles.png") class GfxTiles extends flash.display.BitmapData {}

class Game extends mt.deepnight.FProcess { //}
	public static var ME : Game;

	public var dm			: mt.flash.DepthManager;
	public var fx			: Fx;

	public var deck			: Array<Card>;
	public var cur			: Card;

	var cm					: mt.deepnight.Cinematic;

	public var tiles		: BLib;


	public function new() {
		super();
		ME = this;

		deck = [];

		cm = new mt.deepnight.Cinematic();
		dm = new mt.flash.DepthManager(root);

		var bg = new flash.display.Sprite();
		dm.add(bg, Const.DP_BG);
		bg.graphics.beginFill(0x0);
		bg.graphics.drawRect(0,0,w(),h());

		tiles = new mt.deepnight.slb.BLib( new GfxTiles(0,0) );
		tiles.slice("cardFront", 0,0,200,260);
		tiles.slice("cardBack", 200,0,200,260);
		tiles.initBdGroups();

		fx = new Fx();

		initDeck();
		drawCard();
	}

	public function createField(str:Dynamic, ?col=0xFFFFFF) {
		var tf = new flash.text.TextField();

		var f = new flash.text.TextFormat("def", 16, col);
		f.leading = -3;
		tf.setTextFormat(f);
		tf.defaultTextFormat = f;

		tf.selectable = tf.mouseEnabled = false;
		tf.multiline = tf.wordWrap = false;
		tf.embedFonts = true;
		tf.text = Std.string(str);

		return tf;
	}

	function initDeck() {
		deck = [];

		addCardsToDeck( CardData.getByTag("start") );
		addCardsToDeck( CardData.getByTag("startChoice") );

		//for(c in db) {
			//if( c.hasTag("start") || c.hasTag("startChoice") )
				//deck.push( new Card(c) );
		//}
//
		//deck = Lib.shuffle(deck, Std.random);
		//deck.sort( function(a,b) return a.data.hasTag("start")?-1:1 );
	}

	function refreshDeck() {
		var i = 0;
		for( c in deck ) {
			dm.under(c.wrapper);
			c.slideTo(Const.DECK_X+i*10, Const.DECK_Y+i*2);
			i++;
		}
	}


	public function next() {
		cur.discard();
		delayer.add( drawCard, 200 );
	}


	public function drawCard() {
		cur = deck.shift();
		cur.draw();

		for(e in cur.data.effects)
			applyEffect(e);

		//for(a in cur.actions) {
			//win.button(a.desc, function() {
				//for(e in a.effects)
					//applyEffect(e);
				//next();
			//});
		//}
//
		//if( cur.actions.length==0 )
			//win.button("Continue", next);
	}

	inline function sign(v:Float) return v>0?'+$v' : Std.string(v);

	public function applyEffect(e:Effect) {
		var red = 0xFF4D00;
		var green = 0x80FF00;
		switch( e ) {
			case E_Stamina(n) :
				new ui.Notification('${sign(n)} stamina', n>0?green:red);

			case E_Rsc(n) :
				new ui.Notification('${sign(n)} scrap', n>0?green:red);

			case E_Def(n) :
				new ui.Notification('${sign(n)} defense', n>0?green:red);

			case E_AddCards(t, max) :
				var cards = CardData.getByTag(t);
				cards = Lib.shuffle(cards,Std.random);
				if( max<cards.length )
					cards.splice(0, cards.length-max);

				addCardsToDeck(cards);

				new ui.Notification("+"+cards.length+" consequence cards");
		}
	}

	public function addCardsToDeck(cardsData:Array<CardData>) {
		var newCards = [];
		for( d in cardsData ) {
			var nc = new Card(d);
			newCards.push(nc);
			deck.insert(Std.random(deck.length), nc);
		}
		refreshDeck();

		newCards.reverse();
		var i = 0;
		for( c in newCards ) {
			c.insertIntoDeck(i*300);
			i++;
		}

	}

	override function update() {
		super.update();
		cm.update();

		for(c in Card.ALL)
			if( !c.destroyAsked )
				c.update();
		while( Card.GC.length>0 )
			Card.GC[0].unregister();
	}

	override function render() {
		super.render();
		fx.update();
		Component.updateAll();
	}
}
