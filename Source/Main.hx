package;


import openfl.display.DisplayObject;
import openfl.geom.Point;
import openfl.events.MouseEvent;
import openfl.utils.Assets;
import openfl.display.Bitmap;
import openfl.display.Sprite;

class Main extends Sprite
{
  
	public function new(){
		super();
		stage.frameRate = 60;
		stage.color = 0x888888;
        createSprites();
	}

	private function createSprites() {
		for(i in 0...1){
			var sprite:Sprite = new Sprite();
			var bm:Bitmap = new Bitmap(Assets.getBitmapData("assets/adobe-ninja.png"),null,true);
			sprite.addChild(bm);
			sprite.x = 300;
			sprite.y = 300;
			addChild(sprite);
			UITransform.make(sprite).setRotationRad(10);

		}
	}

 

	

}
