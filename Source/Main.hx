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

			sprite.graphics.beginFill(0x00ff00);
			sprite.graphics.moveTo(20,40);
			sprite.graphics.lineTo(100,100);
			sprite.graphics.lineTo(50,20);
			sprite.graphics.lineTo(20,20);
			sprite.graphics.endFill();

			sprite.x = 300;
			sprite.y = 300;

			 
			addChild(sprite);
			var t:UITransform = UITransform.make(sprite);
			

		}
	}

	 

 

	

}
