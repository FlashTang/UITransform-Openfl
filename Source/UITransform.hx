package;

import openfl.utils.Object;
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

enum IntersectAlign {
    //假设 p1在p2左边，并且，p1在p2的下方
    TOP_LEFT;
    BOTTOM_RIGHT;
    TOP_LEFT_AND_BOTTOM_RIGHT;
    UNDEFINED;
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
    private var md_moment_2segs_intersectants:Array<Bool>;
    private var task:GrabTask;
    private var current_grab:GrabPoint;
    private var scale_base_points:Array<Point>;
    private var old_scale_dis_yz:Float;
    private var old_scale_dis_yz_x:Float;
    private var old_scale_dis_yz_y:Float;
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

        base = new GrabPoint(GrabType.Circle,new Point(12,12),0x0000ff,0x000000,1);
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
            var grab:GrabPoint = e.currentTarget;
            md_moment_rad = getRotationRad();
            md_moment_pvt = getPivot();
           
            var is____2d = grab.id == 0 || grab.id == 2 || grab.id == 6 || grab.id == 8 ;
            md_moment_2segs_intersectants = segs_intersectant(new Point(_parent.mouseX,_parent.mouseY),grab,is____2d);
       
            scale_base_points = getScaleBasdPoint(new Point(_parent.mouseX,_parent.mouseY),grab,is____2d);
            var a:Float = Math.NaN;
            var b:Float = Math.NaN;
            
            if(is____2d){
                a = scale_base_points[1].x - _parent.mouseX;
                b = scale_base_points[1].y - _parent.mouseY;
                var a2 = scale_base_points[0].x - _parent.mouseX;
                var b2 = scale_base_points[0].y - _parent.mouseY;
                old_scale_dis_yz_y = Math.sqrt(a * a + b * b); 
                old_scale_dis_yz_x = Math.sqrt(a2 * a2 + b2 * b2); 
            }
            else{
                a = scale_base_points[0].x - _parent.mouseX;
                b = scale_base_points[0].y - _parent.mouseY;
            }
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
                var is_2d = grab.id == 0 || grab.id == 2 || grab.id == 6 || grab.id == 8 ;

                scale_base_points = getScaleBasdPoint(new Point(_parent.mouseX,_parent.mouseY),grab,is_2d);
               
                if(!is_2d){
                    if(grab.id != 4) {
                        var a = scale_base_points[0].x - _parent.mouseX;
                        var b = scale_base_points[0].y - _parent.mouseY;
                        var now_scale_dis_yz = Math.sqrt(a * a + b * b); 
        
                        var now_height = now_scale_dis_yz * (old_size_before_scale.y/old_scale_dis_yz);
                        var now_scale_y = now_height / old_size_before_scale.y;

                        var now_width = now_scale_dis_yz * (old_size_before_scale.x/old_scale_dis_yz);
                        var now_scale_x = now_width / old_size_before_scale.x;

                        base.x = scale_base_points[0].x;
                        base.y = scale_base_points[0].y;

                        var now_intersectants:Array<Bool> = segs_intersectant(new Point(_parent.mouseX,_parent.mouseY),grab);
                        var flip_yz = md_moment_2segs_intersectants[0] != now_intersectants[0] ? -1 : 1;
                        if(grab.id == 3 || grab.id == 5){
                            setScaleX(now_scale_x * md_moment_scale.x * flip_yz);
                        }
                        else if(grab.id == 1 || grab.id == 7){
                            setScaleY(now_scale_y * md_moment_scale.y * flip_yz);
                        }
                        updateGrabsPosition(null,false);
                      
                    }
                
                }
                else { //那就是 0,2,6,8
                    if(grab.id != 4) {
                        var a1 = scale_base_points[0].x - _parent.mouseX;
                        var b1 = scale_base_points[0].y - _parent.mouseY;
                        var a2 = scale_base_points[1].x - _parent.mouseX;
                        var b2 = scale_base_points[1].y - _parent.mouseY;

                        var now_scale_dis_yz_x = Math.sqrt(a1 * a1 + b1 * b1);
                        var now_scale_dis_yz_y = Math.sqrt(a2 * a2 + b2 * b2);


                        var now_height = now_scale_dis_yz_y * (old_size_before_scale.y/old_scale_dis_yz_y);
                        var now_scale_y = now_height / old_size_before_scale.y;

                        var now_width = now_scale_dis_yz_x * (old_size_before_scale.x/old_scale_dis_yz_x);
                        var now_scale_x = now_width / old_size_before_scale.x;
                        var now_intersectants:Array<Bool> = segs_intersectant(new Point(_parent.mouseX,_parent.mouseY),grab,true);
                        var flip_yz_x = md_moment_2segs_intersectants[0] != now_intersectants[0] ? -1 : 1;
                        var flip_yz_y = md_moment_2segs_intersectants[1] != now_intersectants[1] ? -1 : 1;

                        setScaleX(now_scale_x * md_moment_scale.x * flip_yz_x);
                        setScaleY(now_scale_y * md_moment_scale.y * flip_yz_y);

                        updateGrabsPosition(null,false);
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

    //判断两条线段是否相交
    //https://stackoverflow.com/questions/9043805/test-if-two-lines-intersect-javascript-function
    function intersects(a,b,c,d,p,q,r,s):Bool {
        var det, gamma, lambda;
        det = (c - a) * (s - q) - (r - p) * (d - b);
        if (det == 0) {
            return false;
        } else {
        lambda = ((s - q) * (r - a) + (p - r) * (s - b)) / det;
        gamma = ((b - d) * (r - a) + (c - a) * (s - b)) / det;
            return (0 < lambda && lambda < 1) && (0 < gamma && gamma < 1);
        }
    };

    
 
    function getNormalLonglines(p1:Point,p2:Point,align:IntersectAlign):Object {
        var a_x:Float,a_y:Float,b_x:Float,b_y:Float;
        var c_x:Float,c_y:Float,d_x:Float,d_y:Float;
        var rad = md_moment_rad;
        if(align == IntersectAlign.TOP_LEFT){
            a_x = Math.cos(rad - Math.PI / 2) * 999999999 + p1.x;
            a_y = Math.sin(rad - Math.PI / 2) * 999999999 + p1.y;
            b_x = Math.cos(rad + Math.PI / 2) * 999999999 + p1.x;
            b_y = Math.sin(rad + Math.PI / 2) * 999999999 + p1.y;
    
            
            c_x = p2.x;
            c_y = p2.y;
            d_x = Math.cos(rad) * 999999999 + p2.x;
            d_y = Math.sin(rad) * 999999999 + p2.y;
        }
        else{
            a_x = Math.cos(rad) * 999999999 + p1.x;
            a_y = Math.sin(rad) * 999999999 + p1.y;
            b_x = Math.cos(rad - Math.PI) * 999999999 + p1.x;
            b_y = Math.sin(rad - Math.PI) * 999999999 + p1.y;
    
            c_x = p2.x;
            c_y = p2.y;
            d_x = Math.cos(rad + Math.PI/2) * 999999999 + p2.x;
            d_y = Math.sin(rad + Math.PI/2) * 999999999 + p2.y;
        }
        
        return {x1:a_x,y1:a_y,x2:b_x,y2:b_y,x3:c_x,y3:c_y,x4:d_x,y4:d_y};
    }
    function getAlign(grab:GrabPoint) :IntersectAlign{
        var align:IntersectAlign = IntersectAlign.UNDEFINED;
        for (i in [1,7]) {
            if(grab.id == i){
                align = IntersectAlign.BOTTOM_RIGHT;
                break;
            }
        }
        if(align == IntersectAlign.UNDEFINED){
            for (i in [3,5]) {
                if(grab.id == i){
                    align = IntersectAlign.TOP_LEFT;
                    break;
                }
            }
        }
        else{
            align = IntersectAlign.TOP_LEFT_AND_BOTTOM_RIGHT;
        }
        return align;
    }
    function getScaleBasdPoint(mousePoint:Point,grab:GrabPoint,is2D:Bool = false):Array<Point> {
        if(!is2D){
            var align = getAlign(grab);
            var obj:Object = getNormalLonglines(md_moment_pvt,mousePoint,align);
            return [line_intersect(obj.x1, obj.y1, obj.x2, obj.y2, obj.x3, obj.y3, obj.x4, obj.y4)];
        }
        else{
            var obj1:Object = getNormalLonglines(md_moment_pvt,mousePoint,IntersectAlign.TOP_LEFT);
            var obj2:Object = getNormalLonglines(md_moment_pvt,mousePoint,IntersectAlign.BOTTOM_RIGHT);
            return [
                line_intersect(obj1.x1, obj1.y1, obj1.x2, obj1.y2, obj1.x3, obj1.y3, obj1.x4, obj1.y4),
                line_intersect(obj2.x1, obj2.y1, obj2.x2, obj2.y2, obj2.x3, obj2.y3, obj2.x4, obj2.y4)
            ];
        }
    }
    function segs_intersectant(mousePoint:Point,grab:GrabPoint,two_dimension:Bool = false):Array<Bool> {
        var align = null;
        var auto:Object = null;
        var tl:Object = null,br:Object = null;
        if(!two_dimension){
            align = getAlign(grab);
            auto= getNormalLonglines(md_moment_pvt,mousePoint,align);
        }
        else{
            tl = getNormalLonglines(md_moment_pvt,mousePoint,IntersectAlign.TOP_LEFT);
            br = getNormalLonglines(md_moment_pvt,mousePoint,IntersectAlign.BOTTOM_RIGHT);
        }
        
        if(!two_dimension){
            return [intersects(auto.x1, auto.y1, auto.x2, auto.y2, auto.x3, auto.y3, auto.x4, auto.y4)];
        }
        else{
            return [intersects(tl.x1, tl.y1, tl.x2, tl.y2, tl.x3, tl.y3, tl.x4, tl.y4),
                intersects(br.x1, br.y1, br.x2, br.y2, br.x3, br.y3, br.x4, br.y4)];
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