package;
import openfl.display.Sprite;
import openfl.Lib;
import openfl.geom.Rectangle;
import openfl.events.MouseEvent;
import openfl.geom.Matrix;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import openfl.display.DisplayObject;
import openfl.geom.Point;
import com.akifox.transform.Transformation;

class UITransform extends Transformation{

    private var _parent:DisplayObject;
    private static var grabsAdded:Bool;
    private static var grabsCreated:Bool;
    private static var grabs:Array<GrabPoint>;
    private var pivotOffset:Point = new Point();
    public static var aligns:Array<Point> = [
        //[x,x,x]
        //[x,o,x]
        //[x,x,x]
		new Point(-1,-1),new Point(0,-1),new Point(1,-1),
		new Point(-1,0),new Point(0,0),new Point(1,0),
		new Point(-1,1),new Point(0,1),new Point(1,1)
	];

    // public function new(matrix:Matrix=null,width:Float=0,height:Float=0,?pivot:Point=null) {
    //     super(matrix,width,height,pivot);
    // }
    
    public override function bind(target:DisplayObject) {
        super.bind(target);
        
        createGrabPoints();
        if(target.parent != null){
            addGrabsToParent(target.parent);
            _parent = target.parent;
        }else{
            target.addEventListener(Event.ADDED_TO_STAGE,ATSHandler);
        }
        this.addEventListener(Transformation.TRANSFORM, _onTransform);

        target.addEventListener(MouseEvent.MOUSE_DOWN,targetMouseDownHandler);

        updateGrabsPosition();
    }
    private var targetOffset:Point;
    private var currenrDraggingTarget:DisplayObject;
    private var currentSelected:DisplayObject;
    private function targetMouseDownHandler(e:MouseEvent) {
        var __pivot = this.getPivot();
        pivotOffset.x = _target.parent.mouseX -  __pivot.x;
        pivotOffset.y = _target.parent.mouseY -  __pivot.y;
        var tar:DisplayObject = e.currentTarget;
        currenrDraggingTarget = e.currentTarget;
        currentSelected = e.currentTarget;
     
        targetOffset = new Point(getTranslationX() - tar.parent.mouseX,getTranslationY() - tar.parent.mouseY);
        tar.stage.removeEventListener(MouseEvent.MOUSE_MOVE,targetStageHandler);
        tar.stage.addEventListener(MouseEvent.MOUSE_MOVE,targetStageHandler);
        tar.stage.removeEventListener(MouseEvent.MOUSE_UP,targetStageHandler);
        tar.stage.addEventListener(MouseEvent.MOUSE_UP,targetStageHandler);
        updateGrabsPosition();
    }

    private function targetStageHandler(e:MouseEvent) {
        var tar:DisplayObject = e.currentTarget;
        
        if(e.type == MouseEvent.MOUSE_UP){
            tar.stage.removeEventListener(MouseEvent.MOUSE_MOVE,targetStageHandler);
            tar.stage.removeEventListener(MouseEvent.MOUSE_UP,targetStageHandler);
            currenrDraggingTarget = null;
        }
        else if(e.type == MouseEvent.MOUSE_MOVE){

            setTranslationX(_target.parent.mouseX + targetOffset.x);
            setTranslationY(_target.parent.mouseY + targetOffset.y);

            updateGrabsPosition();
        }
    }
    var n = 0;
    private function updateGrabsPosition(except:Array<Int> = null,updatePivot:Bool = true){
        var _r = getRotationRad();
        var pvt:Point = getPivot();
        setRotationRad(0);
        setGrabsPositionWhenRI0();
        setRotationRad(_r);
    
        var distances:Array<Float> = [];
        
        for (index => grab in grabs) {
            if(index != 4){
                var a = grab.x - pvt.x;
                var b = grab.y - pvt.y;
                distances.push(Math.sqrt(a * a + b * b));
            }
            else {
                distances.push(0);
            }
        }
        
        for (i => dis in distances) {
            var _180_DIV_PI:Float = 180 / Math.PI;
            if(i != 4){
                var grab = grabs[i];
                var r:Float = Math.atan2(grab.y - pvt.y,grab.x - pvt.x);
                r+=_r;
                grab.x = pvt.x + Math.cos(r) * dis;
                grab.y = pvt.y + Math.sin(r) * dis;
                grab.rotation = _r * _180_DIV_PI;
            }
            
        }
        if(updatePivot){
             this.setPivot(new Point(_target.parent.mouseX - pivotOffset.x,_target.parent.mouseY - pivotOffset.y));
        }

    }

    private function setGrabsPositionWhenRI0() {
        
        var bbox:Rectangle = _target.getBounds(grabs[4].parent);
        var halfWid:Float = bbox.width / 2;
        var halfHei:Float = bbox.height / 2;
        var center:Point = new Point(bbox.x + halfWid, bbox.y + halfHei);
        for (index => grab in grabs) {
            if(index == 4){
                continue;
            }
            grab.x = center.x + aligns[index].x * halfWid;
            grab.y = center.y + aligns[index].y * halfHei;
        }

    }
 
   

    public override function setPivot(point:Point) {
        super.setPivot(point);
        grabs[4].x = point.x;
        grabs[4].y = point.y;
    }
    private function getTargetSize():Point {
        var ori_r = _target.rotation;
        var size:Point = new Point(_target.width,_target.height);
        _target.rotation = ori_r;
        return size;
    }
    
    private function _onTransform(event:Event) {
        
    }
    private function ATSHandler(e:Event) {
        _parent = cast(e.currentTarget,DisplayObject).parent;
        addGrabsToParent(cast(e.currentTarget,DisplayObject).parent);
    }

    private function addGrabsToParent(par:DisplayObjectContainer) {
        for (grab in grabs) {
            par.addChild(grab);
        }
    }

    private inline function createGrabPoints() {
        if(grabsCreated) {
            return;
        }

        grabs = [];
        for (i in 0...9){
            var type:GrabType = i == 4 ? GrabType.Circle : GrabType.Rect;
            var fillColor:Int = i == 4 ? 0xffffff : 0x000000;
            var lineColor:Int = i == 4 ? 0x000000 : 0xffffff;
            var grab:GrabPoint = new GrabPoint(type,new Point(12,12),fillColor,lineColor,1);
            grab.id = i;
            grab.addRotatePoint();
            grabs.push(grab);
            grab.addEventListener(MouseEvent.MOUSE_DOWN,grabHandler);
             
        }
        grabsCreated = true;

        grabs[4].addEventListener(MouseEvent.MOUSE_DOWN,grab4MouseDownHandler);
    }
    private var grab_mouse_offset:Point;
    private function grab4MouseDownHandler(e:MouseEvent) {
        var grab:GrabPoint = e.currentTarget;
        grab_mouse_offset = new Point(grab.x - grab.parent.mouseX,grab.y - grab.parent.mouseY);
        Lib.current.stage.removeEventListener(MouseEvent.MOUSE_MOVE,stageMouseHandlerForGrab4);
        Lib.current.stage.removeEventListener(MouseEvent.MOUSE_UP,stageMouseHandlerForGrab4);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE,stageMouseHandlerForGrab4);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP,stageMouseHandlerForGrab4);
        
    }
    
    private function stageMouseHandlerForGrab4(e:MouseEvent) {
        if(e.type == MouseEvent.MOUSE_MOVE){
            var grab:GrabPoint = grabs[4];
            var p = new Point(grab.parent.mouseX + grab_mouse_offset.x,grab.parent.mouseY + grab_mouse_offset.y);
            setPivot(p);
        }
        else if(e.type == MouseEvent.MOUSE_UP){
            Lib.current.stage.removeEventListener(MouseEvent.MOUSE_MOVE,stageMouseHandlerForGrab4);
            Lib.current.stage.removeEventListener(MouseEvent.MOUSE_UP,stageMouseHandlerForGrab4);
        }
    }
    var start_r_point:Point;
    var start_r:Float;
    var _pvt_for_rotate_temp:Point;
    var _old_r_for_rotate_temp:Float;
    private function grabHandler(e:MouseEvent) {
       if(e.target is RotatePoint){
            
            _old_r_for_rotate_temp = getRotationRad();
            var __pivot:Point = getPivot();
            _pvt_for_rotate_temp = __pivot;
            trace(_parent);
            start_r_point = new Point(_parent.mouseX,_parent.mouseY);
            start_r = Math.atan2(start_r_point.y - __pivot.y,start_r_point.x - __pivot.x);
            Lib.current.stage.removeEventListener(MouseEvent.MOUSE_MOVE,stageMouseMoveHandlerForGrabs);
            Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE,stageMouseMoveHandlerForGrabs);
            Lib.current.stage.removeEventListener(MouseEvent.MOUSE_UP,stageMouseMoveHandlerForGrabs);
            Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP,stageMouseMoveHandlerForGrabs);
            
       }
       else{

       }
    }

    private function stageMouseMoveHandlerForGrabs(e:MouseEvent){
        if(e.type == MouseEvent.MOUSE_MOVE){
        
            var current_r_point = new Point(_parent.mouseX,_parent.mouseY);
            var current_r:Float = Math.atan2(current_r_point.y - _pvt_for_rotate_temp.y,current_r_point.x - _pvt_for_rotate_temp.x);
            var rotated_r = current_r - start_r;
            trace(_old_r_for_rotate_temp + rotated_r);
            setRotationRad(_old_r_for_rotate_temp + rotated_r);
            updateGrabsPosition(null,false);

        }else if(e.type == MouseEvent.MOUSE_UP){
            Lib.current.stage.removeEventListener(MouseEvent.MOUSE_MOVE,stageMouseMoveHandlerForGrabs);
            Lib.current.stage.removeEventListener(MouseEvent.MOUSE_UP,stageMouseMoveHandlerForGrabs);
        }
        
    }
    public static function make(object:DisplayObject):UITransform{
        var uit:UITransform = new UITransform(new openfl.geom.Matrix(1,0,0,1,object.x,object.y));
		uit.bind(object);
        var b:Rectangle = object.getBounds(object.parent);
        uit.setPivot(new Point(b.x + b.width / 2,b.y+b.height / 2));
        return uit;
    }

}


enum GrabType {
	Circle;
	Rect;
}
 
class GrabPoint extends Sprite{

	public var id:Int = -1;
    public var _extents:Point;
	public function new(type:GrabType,extents:Point,color:Int,lineColor:Int,_alpha:Float) {
		super();
        _extents = extents;
		graphics.lineStyle(2,lineColor);
		graphics.beginFill(color,_alpha);
		if(type == GrabType.Circle){
			graphics.drawEllipse(-extents.x / 2,-extents.y / 2,extents.x,extents.y);
		}
		else if(type == GrabType.Rect){
			graphics.drawRect(-extents.x / 2,-extents.y / 2,extents.x,extents.y);
		}
		graphics.endFill();
	}

    public  function addRotatePoint() {
        var rp:RotatePoint = new RotatePoint(0x000000,20);
        if(id == 0){
            rp.x = -_extents.x - rp.size / 2;
            rp.y = -_extents.y - rp.size / 2;
        }
        else if(id == 2){
            rp.x = _extents.x + rp.size / 2;
            rp.y = -_extents.y - rp.size / 2;
        }
        else if(id == 6){
            rp.x = -_extents.x - rp.size / 2;
            rp.y = _extents.y + rp.size / 2;
        }
        else if(id == 8){
            rp.x = _extents.x +rp.size / 2;
            rp.y = _extents.y + rp.size / 2;
        }
        for (i in [0,2,6,8]) {
            if(i == id){
                addChild(rp);
                break;
            }
        }
        
    }
 
}

class RotatePoint extends Sprite{
    public var size:Float;
    public function new(fillColor:Int,size:Float) {
        super();
        this.size = size;
        graphics.beginFill(fillColor);
        graphics.drawCircle(0,0,size);
        graphics.endFill();
    }
    
}