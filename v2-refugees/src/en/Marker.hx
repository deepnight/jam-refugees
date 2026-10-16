package en;

import Const;

class Marker extends Entity {
	public function new(x,y) {
		super(x,y);

		setLayer(Const.DP_MARKER);
		autoCenter = false;

		switch( cell.type ) {
			case C_Loot : spr.set("marker", 0);
			case C_Shelter : spr.set("marker", 1);
			case C_Garage : spr.set("marker", 2);
			case C_TrainEngine :
				spr.set("marker", 3);
				yr = 0.3;
			default :
		}
	}

	override function update() {
		super.update();
		if( cell.depleted )
			destroy();

		//spr.alpha = 0.5 + 0.3*Math.cos(Game.ME.time*0.25);
	}

}