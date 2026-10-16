import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;
import mt.deepnight.slb.*;
import mt.deepnight.Lib;
import mt.deepnight.Color;
import mt.MLib;
import Const;

class Cell {
	public var cx		: Int;
	public var cy		: Int;
	public var type		: CellType;
	public var depleted	: Bool;
	public var useCount	: Int;

	public function new(x,y) {
		cx = x;
		cy = y;
		type = C_Road;
		useCount = 0;
		depleted = false;
	}

	public inline function collides() {
		return switch( type ) {
			case C_Shelter, C_Building, C_Loot, C_Garage, C_Train, C_TrainEngine : true;
			case C_Park, C_Road, C_Rail : false;
		}
	}

	public function canProtect() {
		return type==C_Shelter && !depleted;
	}
}



class City extends mt.deepnight.FProcess {
	static var FOG_SCALE = 12;

	public var map			: Array<Array<Cell>>;
	public var bg			: flash.display.Bitmap;

	public var mwid			: Int;
	public var mhei			: Int;

	public var pwid			: Int;
	public var phei			: Int;
	public var pf			: mt.deepnight.PathFinder;

	public var dark			: BSprite;
	public var fog			: Bitmap;
	public var fogMap		: Array<Array<Bool>>;

	public var rseed		: mt.Rand;
	public var fireSpots	: Array<{cx:Int, cy:Int}>;

	public function new() {
		super();

		rseed = new mt.Rand(0);
		Game.ME.sdm.add(root, Const.DP_BG);

		bg = new flash.display.Bitmap();
		root.addChild(bg);

		fireSpots = [];

		parse();
		initPf();
		attach();

		fogMap = [];
		for( cx in 0...mwid ) {
			fogMap[cx] = [];
			for( cy in 0...mhei )
				fogMap[cx][cy] = false;
		}

		fog = new flash.display.Bitmap( new flash.display.BitmapData(MLib.ceil(pwid/FOG_SCALE), MLib.ceil(phei/FOG_SCALE), true, 0x0) );
		Game.ME.sdm.add(fog, Const.DP_FOG);
		fog.scaleX = fog.scaleY = FOG_SCALE;
		fog.filters = [
			new flash.filters.BlurFilter(16,16,2),
		];
		fog.bitmapData.fillRect(fog.bitmapData.rect, Color.addAlphaF(0x430C0C));
		#if debug
		fog.visible = false;
		#end

		dark = Game.ME.tiles.get("dark");
		Game.ME.buffer.dm.add(dark, Const.DP_FOG);
		dark.width = Game.ME.buffer.width;
		dark.height = Game.ME.buffer.height;
	}

	function parse() {
		var source = Game.ME.tiles.getBitmapData("level");

		map = [];
		mwid = source.width;
		mhei = source.height;
		pwid = mwid*Const.GRID;
		phei = mhei*Const.GRID;

		bg.bitmapData = new flash.display.BitmapData(pwid,phei, true, 0x0);

		for(cx in 0...mwid) {
			map[cx] = [];
			for(cy in 0...mhei) {
				var c = new Cell(cx,cy);
				map[cx][cy] = c;
				var p = source.getPixel(cx,cy);
				c.type = switch( p ) {
					case 0x0 : C_Road;
					case 0xffffff : C_Building;
					case 0x0000FF : C_Shelter;
					case 0x00FF00 : C_Park;
					case 0xff9c00 : C_Loot;
					case 0xff0000 : Game.ME.trainCounter++; C_Garage;
					case 0x7d7d7d : C_Rail;
					case 0x9e9e9e : C_Train;
					case 0xFF00FF : C_TrainEngine;
					default : trace('unknown color at $cx,$cy'); C_Building;
				}
			}
		}

		source.dispose();
		source = null;
	}


	public function revealFogCell(cx,cy) {
		if( !isValid(cx,cy) )
			return;

		if( !fogMap[cx][cy] ) {
			var g = Const.GRID/FOG_SCALE;
			fog.bitmapData.fillRect( new flash.geom.Rectangle(cx*g, cy*g, g,g), 0x0 );
		}
	}

	public function revealFogBox(cx,cy) {
		if( !fogMap[cx][cy] ) {
			var g = Const.GRID/FOG_SCALE;
			fog.bitmapData.fillRect( new flash.geom.Rectangle((cx-1)*g, (cy-1)*g, g*3,g*3), 0x0 );
		}
	}


	function initPf() {
		pf = new mt.deepnight.PathFinder(mwid, mhei);
		for(cx in 0...mwid)
			for(cy in 0...mhei) {
				var c = getCell(cx,cy);
				pf.setCollision(cx,cy, c.collides());
			}


	}


	override function unregister() {
		super.unregister();
		rseed = null;

		bg.bitmapData.dispose();
		bg.bitmapData = null;
		bg = null;

		map = null;
	}

	public function getClosestNear(fx,fy, tx,ty) : {cx:Int, cy:Int} {
		var pts = [];
		pts.push({ cx:tx-1, cy:ty, d:9999 });
		pts.push({ cx:tx+1, cy:ty, d:9999 });
		pts.push({ cx:tx, cy:ty-1, d:9999 });
		pts.push({ cx:tx, cy:ty+1, d:9999 });
		for( pt in pts ) {
			if( pt.cx==fx && pt.cy==fy )
				pt.d = 0;
			else {
				var p = getPath(fx,fy, pt.cx, pt.cy);
				if( p.length!=0 )
					pt.d = p.length;
			}
		}
		pts.sort( function(a,b) return Reflect.compare(a.d, b.d) );
		return pts[0].d<9999 ? { cx:pts[0].cx, cy:pts[0].cy } : null;
	}

	//public function getDist(x,y, tx,ty) {
		//var p = getPath(x,y,tx,ty);
	//}

	public inline function getPath(x,y, tx,ty) {
		var p = pf.getPath({x:x, y:y}, {x:tx, y:ty}).copy();
		return p;
		//return pf.smooth(p);
	}

	public function sightCheck(fx,fy, tx,ty) {
		return mt.deepnight.Bresenham.checkThinLine(fx,fy, tx,ty, function(x,y) {
			return !hasCollision(x,y);
		});
	}

	inline function isValid(cx,cy) {
		return cx>=0 && cx<mwid && cy>=0 && cy<mhei;
	}

	public inline function getCell(cx,cy) {
		return !isValid(cx,cy) ? null : map[cx][cy];
	}

	public function hasCollision(cx,cy) {
		return getCell(cx,cy)==null || getCell(cx,cy).collides();
	}

	public function has(cx,cy, t:CellType) {
		return getCell(cx,cy)!=null && getCell(cx,cy).type==t;
	}

	public function attach() {
		var tiles = Game.ME.tiles;
		rseed.initSeed(1);
		fireSpots = [];

		var bg = bg.bitmapData;
		bg.fillRect(bg.rect, 0);
		var build = bg.clone();
		var bshadow = bg.clone();
		var road = bg.clone();
		var park = bg.clone();

		//var colors = [ 0x9A4743, 0x9D7E40, 0x82655B ];
		var colors = [ 0x9A4743 ];
		for(cx in 0...mwid)
			for(cy in 0...mhei) {
				var x = cx*Const.GRID;
				var y = cy*Const.GRID;
				var c = getCell(cx,cy);

				// Trees
				if( !c.collides() ) {
					if( hasCollision(cx,cy-1) ) {
						var n = rseed.irange(0,3);
						for(i in 0...n)
							tiles.drawIntoBitmapRandom(build, x+Const.GRID*0.5-n*4*0.5 + i*5, y+rseed.irange(0,1), "tree", rseed.random, 0.5,0.5);
					}
				}

				switch( c.type ) {
					case C_Building :
						var k = "building";
						if( getCell(cx,cy+1)!=null && getCell(cx,cy+1).collides() )
							k = "roof";
						var bd = tiles.getBitmapData(k, tiles.getRandomFrame(k,rseed.random));
						var bmp = new flash.display.Bitmap(bd);
						var r = rseed.range(0.3, 0.5);
						bd.applyFilter(bd, bd.rect, pt0, Color.getColorizeFilter(colors[rseed.random(colors.length)], r, 1-r));
						bmp.x = x;
						bmp.y = y;
						build.draw(bmp, bmp.transform.matrix);
						if( !hasCollision(cx-1,cy) || !hasCollision(cx+1,cy) || !hasCollision(cx,cy+1) )
							if( rseed.random(100)<5 )
								fireSpots.push({cx:cx,cy:cy});

					case C_Shelter :
						tiles.drawIntoBitmapRandom(bg, x,y, "roadBase", rseed.random);
						if( c.depleted ) {
							fireSpots.push({cx:cx,cy:cy});
							tiles.drawIntoBitmap(build, x,y, "brokenShelter");
						}
						else
							tiles.drawIntoBitmap(build, x,y, "shelter");

					case C_Loot :
						tiles.drawIntoBitmapRandom(bg, x,y, "roadBase", rseed.random);
						tiles.drawIntoBitmapRandom(build, x,y, "loot", rseed.random);

					case C_Rail :
						tiles.drawIntoBitmapRandom(bg, x,y, "roadBase", rseed.random);
						tiles.drawIntoBitmapRandom(bg, x,y, "rail", rseed.random);

					case C_Train :
						tiles.drawIntoBitmapRandom(bg, x,y, "roadBase", rseed.random);
						tiles.drawIntoBitmap(bg, x,y, "wagon", 0);

					case C_TrainEngine :
						tiles.drawIntoBitmapRandom(bg, x,y, "roadBase", rseed.random);
						tiles.drawIntoBitmap(bg, x,y, "wagon", 1);

					case C_Garage :
						tiles.drawIntoBitmapRandom(bg, x,y, "roadBase", rseed.random);
						tiles.drawIntoBitmapRandom(build, x,y, "tool", rseed.random);

					case C_Road : tiles.drawIntoBitmapRandom(bg, x,y, "roadBase", rseed.random);
					case C_Park : tiles.drawIntoBitmapRandom(park, x,y, "park", rseed.random);
				}

				if( !c.collides() ) {
					// Roads
					if( c.type==C_Road ) {
						if( has(cx-1, cy, C_Road) )
							tiles.drawIntoBitmap(road, x,y, "road", 3);
						if( has(cx+1, cy, C_Road) )
							tiles.drawIntoBitmap(road, x,y, "road", 2);
						if( has(cx, cy-1, C_Road) )
							tiles.drawIntoBitmap(road, x,y, "road", 0);
						if( has(cx, cy+1, C_Road) )
							tiles.drawIntoBitmap(road, x,y, "road", 1);
					}
				}

				// Building shadows
				if( !c.collides() && !has(cx,cy-1,C_Train) && !has(cx,cy-1,C_TrainEngine) && !has(cx-1,cy,C_Train) && !has(cx-1,cy-1,C_Train) ) {
					if( hasCollision(cx-1,cy) )
						if( hasCollision(cx-1, cy-1) )
							tiles.drawIntoBitmap(bshadow, x,y, "bshadow", 1);
						else
							tiles.drawIntoBitmap(bshadow, x,y, "bshadow", 3);

					if( hasCollision(cx,cy-1) )
						if( hasCollision(cx-1,cy-1) )
							tiles.drawIntoBitmap(bshadow, x,y, "bshadow", 0);
						else
							tiles.drawIntoBitmap(bshadow, x,y, "bshadow", 2);

					if( hasCollision(cx-1,cy-1) )
						tiles.drawIntoBitmap(bshadow, x,y, "bshadow", 4);
				}
			}

		build.applyFilter(build, build.rect, pt0, new flash.filters.GlowFilter(0xFFFFFF,0.2, 2,2,10, 1, true));
		build.applyFilter(build, build.rect, pt0, new flash.filters.GlowFilter(0x0,0.1, 2,2,10));
		build.applyFilter(build, build.rect, pt0, new flash.filters.DropShadowFilter(2,-90, 0x0a001a,0.9, 0,5,1, 1, true));

		bg.applyFilter(bg, bg.rect, pt0, new flash.filters.GlowFilter(0x0,0.5, 16,16,1,1,true));

		road.applyFilter(road, road.rect, pt0, new flash.filters.GlowFilter(0xffffff,0.1, 2,2,10, 1,true));

		park.applyFilter(park, park.rect, pt0, new flash.filters.GlowFilter(0x0,0.2, 8,8,20, 1,true));
		park.applyFilter(park, park.rect, pt0, new flash.filters.GlowFilter(0x0,0.2, 2,2,20, 1,true));

		bg.copyPixels(road, road.rect, pt0, true);
		bg.copyPixels(park, park.rect, pt0, true);
		bg.draw(bshadow, new flash.geom.ColorTransform(1,1,1, 0.5));
		bg.copyPixels(build, build.rect, pt0, true);

		// Dirt
		var bmp = new flash.display.Bitmap( tiles.getBitmapData("dirt") );
		var ct = new flash.geom.ColorTransform(1,1,1,0);
		for(i in 0...60) {
			bmp.x = rseed.range(0,pwid-bmp.width);
			bmp.y = rseed.range(0,phei-bmp.height);
			bmp.scaleX = bmp.scaleY = rseed.range(0.5,3);
			bmp.rotation = rseed.range(0,360);
			ct.alphaMultiplier = rseed.range(0.2, 0.5);
			bg.draw(bmp, bmp.transform.matrix, ct);
		}

		road.dispose();
		road = null;

		bshadow.dispose();
		bshadow = null;

		build.dispose();
		build = null;

		park.dispose();
		park = null;
	}

	override function update() {
		super.update();
		if( time%2==0  ) {
			var g = Game.ME;
			for(pt in fireSpots) {
				var x = (pt.cx+0.5)*Const.GRID;
				var y = (pt.cy+0.5)*Const.GRID;
				if( g.viewport.onScreen(x,y) )
					Fx.ME.fire(x, y);
			}
		}
	}
}

