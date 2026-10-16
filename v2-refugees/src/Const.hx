class Const { //}
	public static var UPSCALE = 3;
	public static var FPS = 30;
	public static var GRID = 16;
	public static inline function seconds(v:Float) return mt.MLib.round(v*FPS);

	private static var uniq = 0;
	public static var DP_BG = uniq++;
	public static var DP_FX_BG = uniq++;
	public static var DP_MARKER = uniq++;
	public static var DP_HERO = uniq++;
	public static var DP_NIGHT = uniq++;
	public static var DP_FX = uniq++;
	public static var DP_FOG = uniq++;
	public static var DP_INTERF = uniq++;

}


enum CellType {
	C_Road;
	C_Park;
	C_Building;
	C_Loot;
	C_Shelter;
	C_Garage;
	C_Rail;
	C_Train;
	C_TrainEngine;
}

enum HeroType {
	Dad;
	Mum;
	Kid;
}

enum HeroAction {
	A_None;
	A_EnterBuilding(cx:Int,cy:Int);
}

enum Item {
	I_Food;
	I_Engine;
}