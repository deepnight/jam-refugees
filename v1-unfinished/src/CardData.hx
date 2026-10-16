import Const;

class CardData {
	public static var ALL : Array<CardData> = loadDb();

	public var bad		: Bool;
	public var desc		: String;
	public var tags		: Map<String,Bool>;
	public var actions	: Array<Action>;
	public var effects	: Array<Effect>;

	public function new() {
		desc = "???";
		bad = false;
		actions = [];
		effects = [];
		tags = new Map();
	}

	public function toString() return desc.substr(0,20);

	public function hasTag(t:String) return tags.exists(t.toLowerCase());

	public function getTags() {
		var a = [];
		for(k in tags.keys())
			a.push(k);
		return a;
	}


	public static function loadDb() : Array<CardData> {
		var db : Array<CardData> = [];
		var raw = haxe.Resource.getString("db");
		var xml = Xml.parse(raw);
		var doc = new haxe.xml.Fast(xml);
		for( cn in doc.nodes.c ) {
			var c = new CardData();
			db.push(c);

			c.desc = StringTools.trim(cn.innerHTML.split("<")[0]);
			c.bad = cn.has.bad && cn.att.bad=="1";
			var tags = cn.att.t.split(",").map( function(t) return StringTools.trim(t).toLowerCase() );
			for(t in tags)
				c.tags.set(t, true);

			for(en in cn.nodes.e) {
				for(e in parseEffects(en.innerHTML))
					c.effects.push(e);
			}

			for(an in cn.nodes.a) {
				var a = new Action();
				c.actions.push(a);
				a.desc = an.att.desc;
				for(e in parseEffects(an.innerHTML))
					a.effects.push(e);
			}
		}
		return db;
	}

	static function parseEffects(raw:String) {
		if( StringTools.trim(raw).length==0 )
			return [];

		var effects = [];
		for(raw in raw.split(",")) {
			var raw = StringTools.replace(raw, ")", "");
			var l = raw.split("(");
			var params = l[1].split(":");
			var vStr = params[0];
			var vInt = Std.parseInt(vStr);
			switch( StringTools.trim(l[0]) ) {
				case "" :
				case "stamina" : effects.push( E_Stamina(vInt) );
				case "rsc" : effects.push( E_Rsc(vInt) );
				case "def" : effects.push( E_Def(vInt) );
				case "add" :
					effects.push( E_AddCards(vStr, params.length==1 ? 999 : Std.parseInt(params[1])) );
				default : trace("ERROR: unknown effect "+l);
			}
		}
		return effects;
	}


	public static function getByTag(t) return ALL.filter( function(c) return c.hasTag(t) );

}