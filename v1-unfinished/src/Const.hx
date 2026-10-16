class Const { //}
	public static var UPSCALE = 2;
	public static var FPS = 30;
	public static inline function seconds(v:Float) return mt.MLib.round(v*FPS);

	private static var uniq = 0;
	public static var DP_BG = uniq++;
	public static var DP_CARD = uniq++;
	public static var DP_FX = uniq++;
	public static var DP_INTERF = uniq++;

	public static var CARD_X = 300;
	public static var CARD_Y = 300;
	public static var DECK_X = 850;
	public static var DECK_Y = 400;

}


enum Effect {
	E_Stamina(n:Int);
	E_Rsc(n:Int);
	E_Def(n:Int);
	E_AddCards(tag:String, max:Int);
}

