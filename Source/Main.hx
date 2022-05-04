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


class RotatePoint extends Sprite{

    public var size:Float;
    public function new(fillColor:Int,size:Float,_alpha = 0.5) {
        super();
        this.size = size;
        graphics.beginFill(fillColor,_alpha);
        graphics.drawCircle(0,0,size);
        graphics.endFill();
    }
    
}