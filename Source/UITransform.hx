package;

import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.Lib;
import openfl.geom.Rectangle;
import openfl.events.MouseEvent;
import openfl.geom.Matrix;
import openfl.display.DisplayObjectContainer;
import openfl.display.DisplayObject;
import openfl.geom.Point;
import com.akifox.transform.Transformation;

enum GrabTask{
    ROTATE;
    ZOOM;
}
enum GrabType {
	Circle;
	Rect;
}

class UITransform extends Transformation{

    
    private static var grabsAdded:Bool;
    private static var grabsCreated:Bool;
    private static var grabs:Array<GrabPoint>;
    private var _parent:DisplayObjectContainer;
    private var pivotOffset:Point = new Point();
    private var line:Sprite;
    private var base:GrabPoint;
    private var targetOffset:Point;
    private var grab_mouse_offset:Point;
    private var start_r:Float;
    private var md_moment_rad:Float;
    private var md_moment_pvt:Point;
    private var md_moment_scale:Point;
    private var task:GrabTask;
    private var current_grab:GrabPoint;
    private var scale_base_point:Point;
    private var old_scale_dis_yz:Float;
    private var old_size_before_scale:Point;
    public static var aligns:Array<Point> = [
        //[x,x,x]
        //[x,o,x]
        //[x,x,x]
		new Point(-1,-1),new Point(0,-1),new Point(1,-1),
		new Point(-1,0),new Point(0,0),new Point(1,0),
		new Point(-1,1),new Point(0,1),new Point(1,1)
	];
    
    public override function bind(target:DisplayObject) {
        super.bind(target);
        createGrabPoints(); 
        _parent = target.parent;
        addGrabsToParent(target.parent);
        
        target.addEventListener(MouseEvent.MOUSE_DOWN,targetMouseDownHandler);

        base = new GrabPoint(GrabType.Circle,new Point(14,14),0xff0000,0x000000,1);
        line = new Sprite();
        _parent.addChild(base);
        _parent.addChild(line);

        updateGrabsPosition();
        drawLines();
    }
    
    private function drawLines(){
        line.parent.addChild(line);
        line.graphics.clear();
        line.graphics.lineStyle(1,0x000000);
        line.graphics.moveTo(grabs[0].x,grabs[0].y);
        line.graphics.lineTo(grabs[2].x,grabs[2].y);
        line.graphics.lineTo(grabs[8].x,grabs[8].y);
        line.graphics.lineTo(grabs[6].x,grabs[6].y);
        line.graphics.lineTo(grabs[0].x,grabs[0].y);

        for (i => grab in grabs) {
            if(grab.parent != null){
                grab.parent.addChild(grab);
            }
        }
    }
  
  
    private function targetMouseDownHandler(e:MouseEvent) {
        var __pivot = this.getPivot();
        pivotOffset.x = _target.parent.mouseX -  __pivot.x;
        pivotOffset.y = _target.parent.mouseY -  __pivot.y;
        var tar:DisplayObject = e.currentTarget;
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
        }
        else if(e.type == MouseEvent.MOUSE_MOVE){

            setTranslationX(_target.parent.mouseX + targetOffset.x);
            setTranslationY(_target.parent.mouseY + targetOffset.y);

            updateGrabsPosition();

            drawLines();
        }
    }
 
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

    private function addGrabsToParent(par:DisplayObjectContainer) {
        for (grab in grabs) {
            par.addChild(grab);
        }
    }

    private inline function createGrabPoints() {
        if(grabsCreated)
            return;
         
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
    
    private function grabHandler(e:MouseEvent) {
        md_moment_pvt = getPivot();
        md_moment_rad = getRotationRad();
       if(e.target is RotatePoint){
            task = GrabTask.ROTATE;
           
             
            start_r = Math.atan2(_parent.mouseY - md_moment_pvt.y,_parent.mouseX - md_moment_pvt.x);
       }
       else{
            md_moment_rad = getRotationRad();
            md_moment_pvt = getPivot();
            var grab:GrabPoint = e.currentTarget;
            scale_base_point = getScaleBasdPoint(new Point(_parent.mouseX,_parent.mouseY),grab);
            var a = scale_base_point.x - _parent.mouseX;
            var b = scale_base_point.y - _parent.mouseY;
            old_scale_dis_yz = Math.sqrt(a * a + b * b); 
            current_grab = grab;
            task = GrabTask.ZOOM;
            md_moment_scale = new Point(getScaleX(),getScaleY());
            var o_r = getRotationRad();
            setRotationRad(0);
            old_size_before_scale = new Point(_target.width,_target.height);
            
            setRotationRad(o_r);
            updateGrabsPosition(null,false);
       }
       drawLines();
        Lib.current.stage.removeEventListener(MouseEvent.MOUSE_MOVE,stageMouseMoveHandlerForGrabs);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE,stageMouseMoveHandlerForGrabs);
        Lib.current.stage.removeEventListener(MouseEvent.MOUSE_UP,stageMouseMoveHandlerForGrabs);
        Lib.current.stage.addEventListener(MouseEvent.MOUSE_UP,stageMouseMoveHandlerForGrabs);
    }

    private function stageMouseMoveHandlerForGrabs(e:MouseEvent){
      
        if(e.type == MouseEvent.MOUSE_MOVE){

            if(task == GrabTask.ROTATE){
                var current_r_point = new Point(_parent.mouseX,_parent.mouseY);
                var current_r:Float = Math.atan2(current_r_point.y - md_moment_pvt.y,current_r_point.x - md_moment_pvt.x);
                var rotated_r = current_r - start_r;
                setRotationRad(md_moment_rad + rotated_r);
                updateGrabsPosition(null,false);

            }
            else if(task == GrabTask.ZOOM){
                var grab:GrabPoint = current_grab;
                
                for (id in [1,3,5,7,  0,2,8,6]) {
                    if(id == grab.id) {
                        scale_base_point = getScaleBasdPoint(new Point(_parent.mouseX,_parent.mouseY),grab);
                        
                        var a = scale_base_point.x - _parent.mouseX;
                        var b = scale_base_point.y - _parent.mouseY;
                        var now_scale_dis_yz = Math.sqrt(a * a + b * b); 
                        
                        var now_height = now_scale_dis_yz * (old_size_before_scale.y/old_scale_dis_yz);
                        var now_scale_y = now_height / old_size_before_scale.y;

                        var now_width = now_scale_dis_yz * (old_size_before_scale.x/old_scale_dis_yz);
                        var now_scale_x = now_width / old_size_before_scale.x;

                        base.x = scale_base_point.x;
                        base.y = scale_base_point.y;


                        if(id == 3 || id == 5){
                            setScaleX(now_scale_x * md_moment_scale.x);
                        }
                        else if(id == 1 || id == 7){
                            setScaleY(now_scale_y * md_moment_scale.y);
                        }
                        else {
                            setScaleX(now_scale_x * md_moment_scale.x);
                            setScaleY(now_scale_y * md_moment_scale.y);
                        }
                        
                        updateGrabsPosition(null,false);

                        break;
                    }
                }

            }   
            drawLines();
        }
        else if(e.type == MouseEvent.MOUSE_UP){
            Lib.current.stage.removeEventListener(MouseEvent.MOUSE_MOVE,stageMouseMoveHandlerForGrabs);
            Lib.current.stage.removeEventListener(MouseEvent.MOUSE_UP,stageMouseMoveHandlerForGrabs);
        }
        
    }
    
    function line_intersect(x1:Float, y1:Float, 
                            x2:Float, y2:Float, 
                            x3:Float, y3:Float, 
                            x4:Float, y4:Float):Point{
        var ua:Float, ub:Float, denom:Float = (y4 - y3)*(x2 - x1) - (x4 - x3)*(y2 - y1);
        ua = ((x4 - x3)*(y1 - y3) - (y4 - y3)*(x1 - x3))/denom;
        ub = ((x2 - x1)*(y1 - y3) - (y2 - y1)*(x1 - x3))/denom;
        return new Point(x1 + ua * (x2 - x1),y1 + ua * (y2 - y1));
    }

    function getScaleBasdPoint(mousePoint:Point,grab:GrabPoint):Point {
        var x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, x4:Float, y4:Float;
        x1 = y1 = x2 = y2 = x3 = y3 = x4 = y4 = 0;
        var bigNum:Float = 9999999999;
        var rad:Float = md_moment_rad;
        x1 = mousePoint.x; y1 = mousePoint.y;
       
        var pvt_p2_x:Float = 0,pvt_p2_y:Float = 0;
        if(grab.id == 1 || grab.id == 7){
            
            x2 = Math.cos(rad + Math.PI / 2) * bigNum + x1;
            y2 = Math.sin(rad + Math.PI / 2) * bigNum + y1;

            x3 = Math.cos(rad - Math.PI) * bigNum + md_moment_pvt.x;  
            y3 = Math.sin(rad - Math.PI) * bigNum + md_moment_pvt.y;

            pvt_p2_x = Math.cos(rad) * bigNum + md_moment_pvt.x;
            pvt_p2_y = Math.sin(rad) * bigNum + md_moment_pvt.y;
        }
        else if(grab.id == 3 || grab.id == 5){
            x2 = Math.cos(rad) * bigNum + x1;
            y2 = Math.sin(rad) * bigNum + y1;

            x3 = Math.cos(rad - Math.PI / 2) * bigNum + md_moment_pvt.x;  
            y3 = Math.sin(rad - Math.PI / 2) * bigNum + md_moment_pvt.y;

            pvt_p2_x = Math.cos(rad + Math.PI / 2) * bigNum + md_moment_pvt.x;
            pvt_p2_y = Math.sin(rad + Math.PI /2) * bigNum + md_moment_pvt.y;
        }

        x4 = pvt_p2_x;
        y4 = pvt_p2_y;

        //trace(x1 ,y1 , x2 , y2 , x3 , y3 , x4 , y4 );
        return line_intersect(x1, y1, x2, y2, x3, y3, x4, y4);
    }
    
    public static function make(object:DisplayObject):UITransform{
        var uit:UITransform = new UITransform(new openfl.geom.Matrix(1,0,0,1,object.x,object.y));
		uit.bind(object);
        var b:Rectangle = object.getBounds(object.parent);
        uit.setPivot(new Point(b.x + b.width / 2,b.y+b.height / 2));
        return uit;
    }
    
}
 
class GrabPoint extends Sprite{

	public var id:Int = -1;
    public var _extents:Point;
	public function new(type:GrabType,extents:Point,color:Int,lineColor:Int,_alpha:Float) {
		super();
        _extents = extents;
		graphics.lineStyle(1,lineColor);
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