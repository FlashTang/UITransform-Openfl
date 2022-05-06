package;


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
			
			sprite.graphics.beginFill(0xff0000);
			sprite.graphics.drawRect(10,10,200,100);
			sprite.graphics.endFill();
			sprite.x = 300;
			sprite.y = 300;

			 
			addChild(sprite);
			var t:UITransform = UITransform.make(sprite);
			

		}
	}

	 

 

	

}
