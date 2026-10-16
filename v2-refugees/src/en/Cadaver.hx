package en;

import Const;

class Cadaver extends Entity {
	public function new(e:en.Hero) {
		super(e.cx,e.cy);

		xr = e.xr;
		yr = e.yr;
		updateCoords();

		var blood = Game.ME.tiles.get("heroBlood");
		Game.ME.sdm.add(blood, Const.DP_BG);
		blood.setCenter(0.5,0.5);
		blood.x = xx;
		blood.y = yy;

		setLayer(Const.DP_BG);

		spr.set("heroNoArrow", switch( e.type ) {
			case Dad : 0;
			case Mum : 1;
			case Kid : 2;
		});
		spr.setCenter(0.5,1);
		autoCenter = false;

		spr.rotation = 90*(Std.random(2)*2-1);

	}

	override function update() {
		super.update();
		if( cell.depleted )
			destroy();
	}

}