package;

import motion.easing.Quad;
import motion.Actuate;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import openfl.filters.BlurFilter;
import openfl.filters.DropShadowFilter;
import openfl.geom.Point;
import openfl.media.Sound;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.Assets;
import openfl.Lib;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.ui.Mouse;

import akifox.debug.Performance;
import akifox.Utils;
import akifox.gui.TextFieldSmooth;
import akifox.Transformation;
import akifox.Points;

class Transform extends Sprite {

	var r:Sprite;

	var ox = 200;
	var oy = 200;
	var ow = 100;
	var oh = 100;

	var rp:Point;

	var pivot:Transformation;
	var bitmapData:BitmapData = Assets.getBitmapData ("graphics/test.png");
	
	public function new () {


		bitmapData = Assets.getBitmapData ("graphics/test.png");
		
		super();

		Mouse.hide();

		/*r = new Sprite();
		r.graphics.beginFill(0xFF0000,1);
		r.graphics.drawRect(0,0,ow,oh);
		r.graphics.endFill();*/

		var r = new Bitmap(bitmapData);
		r.smoothing = true;

		r.x = ox;
		r.y = oy;
		r.alpha = 0.5;

		addChild(r);

		pivot = new Transformation(r);
		pivot.setInternalPoint(Transformation.CENTER,Transformation.TOP);
		rp = pivot.getAbsolutePoint();

		Lib.current.stage.addEventListener(MouseEvent.MOUSE_MOVE, setrotationpoint);
		Lib.current.stage.addEventListener(MouseEvent.MOUSE_DOWN, this_onMouseDown);
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, onSpecialKeyDown);
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, onSpecialKeyUp);

		//kind of unit primitive testing
		/*pivot.setInternalPoint(2,2); // 0,0
		pivot.setTranslation(30,30); //30,30
		pivot.translate(100,30); //130,160
		pivot.setTranslation(100,50); //100,50
		pivot.translate(150); //250,50
		pivot.setInternalPoint(0,0); // 150,-50
		pivot.translate(0,200); //150,150
		trace(pivot.getAbsolutePoint()); //SHOULD BE 150,150*/
/*
		pivot.scaleX(2);
		trace('scalex 2,1->',pivot.getScaleX(),pivot.getScaleY());

		pivot.skewX(30);
		trace('skewx 30->',pivot.getSkewX());

		pivot.scaleX(2.3);
		trace('scalex 2.3,1->',pivot.getScaleX(),pivot.getScaleY());

		pivot.setRotation(65);
		trace('get/set',pivot.getRotation(),65);

		pivot.setRotation(73);
		trace('get/set',pivot.getRotation(),73);

		pivot.setRotation(0);
		trace('get/set',pivot.getRotation(),0);

		pivot.setRotation(185);
		trace('get/set',pivot.getRotation(),185);

		pivot.setRotation(20);
		trace('get/set',pivot.getRotation(),20);*/

		drawme();

	}


	// Event Handlers

	var mousedown:Point;
	var dragged:Bool=false;

	var angle:Float=0;
	var langle:Float=0;

	var skewing = false;
	var scaling = false;
	var rotating = false;
	var moving = false;

	var dCenterMousedown:Float;
	var center:Point;
	var currentscale:Float;
    var axisX:Point;
	var axisY:Point;


	private function this_onMouseDown (event:MouseEvent):Void {
		dragged = false;
		mousedown = new Point(Std.int(event.stageX),Std.int(event.stageY));
		center = pivot.getAbsolutePoint();
		currentscale = pivot.getScaleX();
		dCenterMousedown = Points.distance(mousedown,center);
		setAngle(false);
    	axisX = new Point(1, 0);        //vector for x - axis
    	axisY = new Point(0, 1);        //vector for y - axis

		stage_onMouseMove(event);

		stage.addEventListener (MouseEvent.MOUSE_MOVE, stage_onMouseMove);
		stage.addEventListener (MouseEvent.MOUSE_UP, stage_onMouseUp);

	}


	private function stage_onMouseMove (event:MouseEvent):Void {
		if (!dragged && (event.shiftKey || event.altKey || event.ctrlKey)) dragged = true;
		if (!dragged && Points.distance(mousedown,new Point(Std.int(event.stageX),Std.int(event.stageY))) > 5) dragged = true;
		if (dragged) {
			if (event.shiftKey || event.altKey || event.ctrlKey) {
				if (event.shiftKey) setAngle();
				if (event.altKey) setScale(event);
				if (event.ctrlKey) setSkew(event);
			} 
			else {
				moving = true;
				setPosition(event);
				//isometrize(event);
			}
		}

	}

	private function isometrize(event:MouseEvent) {
		var x:Float=event.stageX;
		var y:Float=event.stageY;
		var f1:Point = pivot.getAbsolutePoint();
		//f1.x>0 //front side
		axisX.setTo(x - f1.x, y - f1.y);  //determine orientation (but magnitude changed as well)
    	axisX.normalize(1);         //fix magnitude of vector with new orientation to 1 unit
    	pivot.setTo(axisX.x, axisX.y, axisY.x, axisY.y, 200, 200);
	}

//http://code.tutsplus.com/tutorials/understanding-affine-transformations-with-matrix-mathematics--active-10884
/*private function keyUp(e:KeyboardEvent):void {
if (e.keyCode == Keyboard.LEFT) {
    velo = delta_negative.transformPoint(velo)
}
else if (e.keyCode == Keyboard.RIGHT) {
    velo = delta_positive.transformPoint(velo)
}
if (e.keyCode == Keyboard.UP) {
    axisY = delta_negative.transformPoint(axisY)
}
else if (e.keyCode == Keyboard.DOWN) {
    axisY = delta_positive.transformPoint(axisY)
}
}*/

	private function setPosition(event:MouseEvent) {
		var x:Float=event.stageX;
		var y:Float=event.stageY;
		pivot.setTranslation(x,y);
	}

	private function setAngle(?rotate:Bool=true) {
		var pt:Point = pivot.getAbsolutePoint();
		var aa:Point = Points.clone(rp);
		aa.x-=pt.x;
		aa.y-=pt.y;
		angle = Math.atan2(aa.x, aa.y);
		if (rotate) pivot.rotate(-(angle-langle)/Transformation.DEG2RAD);
		langle=angle;
		trace('get',pivot.getRotation());
	}

	private function setScale(event:MouseEvent) {
		var dNowCenter = Points.distance(center,new Point(Std.int(event.stageX),Std.int(event.stageY)));
		pivot.setScale(dNowCenter/dCenterMousedown*currentscale);
		trace('set/get',dNowCenter/dCenterMousedown*currentscale,pivot.getScaleX());
	}

	private function setSkew(event:MouseEvent) {
/*		var dNowMousedownXY = new Point(Std.int(event.stageX)-mousedown.x,Std.int(event.stageY)-mousedown.y);
		var xs = ((dNowMousedownXY.x/dCenterMousedown));
		var ys = ((dNowMousedownXY.y/dCenterMousedown));*/

		var xs = (Std.int(event.stageX)-Lib.current.stage.stageWidth/2)/(Lib.current.stage.stageWidth/2);
		var ys = (Std.int(event.stageY)-Lib.current.stage.stageHeight/2)/(Lib.current.stage.stageHeight/2);

		pivot.setSkewX(xs*50);
		pivot.setSkewY(ys*50);
		trace('get/set',pivot.getSkewY(),ys*50);
	}


	private function stage_onMouseUp (event:MouseEvent):Void {
		if (!dragged) {
			//click
			setpivot(event);
		}
		dragged = false;

		skewing = false;
		scaling = false;
		rotating = false;
		moving = false;

		stage.removeEventListener (MouseEvent.MOUSE_MOVE, stage_onMouseMove);
		stage.removeEventListener (MouseEvent.MOUSE_UP, stage_onMouseUp);
		drawme();

	}

	private function drawme(){
		var pt:Point = pivot.getAbsolutePoint();

		graphics.clear();

		//pivot point
		graphics.beginFill(0x00FF00,1);
		graphics.drawCircle(pt.x,pt.y,5);
		graphics.endFill();

		//rotation point
		graphics.beginFill(((dragged)?0xFF0000:0x0000FF),1);
		graphics.drawCircle(rp.x,rp.y,5);
		graphics.endFill();

		//transformed rect
		//graphics.lineStyle(2, 0x0000FF, .5, false);
		//graphics.drawRect(r.x,r.y,r.width,r.height);

		//original rect
		graphics.lineStyle(2, 0xFF00FF, .5, false);
		graphics.drawRect(ox,oy,ow,oh);

		//var radius = Points.distance(pt,new Point(r.x,r.y));

		if (rotating || scaling) {
			graphics.lineStyle(2, 0x00FF00, .5, false);
			graphics.moveTo(pt.x,pt.y);
			graphics.lineTo(rp.x,rp.y);
		}

		if (rotating) {
			graphics.lineStyle(2, 0x00FF00, .5, false);
			//graphics.drawCircle(pt.x,pt.y,radius);
		}

		if (skewing) {
			graphics.lineStyle(2, 0x0000FF, .5, false);
			graphics.moveTo(0,Std.int(Lib.current.stage.stageWidth/2));
			graphics.lineTo(Std.int(Lib.current.stage.stageWidth),Std.int(Lib.current.stage.stageWidth/2));
			graphics.moveTo(Std.int(Lib.current.stage.stageHeight/2),0);
			graphics.lineTo(Std.int(Lib.current.stage.stageHeight/2),Std.int(Lib.current.stage.stageHeight));
		}

	}

	private function setpivot (event:MouseEvent):Void {
		pivot.setAbsolutePoint(Std.int(event.stageX),Std.int(event.stageY));
		drawme();
	}

	private function setrotationpoint (event:MouseEvent):Void {
		rp = new Point(Std.int(event.stageX),Std.int(event.stageY));
		drawme();
	}

	private function onSpecialKeyDown(event:KeyboardEvent):Void {
		
		switch (event.keyCode) {
			
			case Keyboard.SHIFT: rotating = true;
			case Keyboard.CONTROL: skewing = true;
			case Keyboard.ALTERNATE: scaling = true;
			
		}
		drawme();
	}

	private function onSpecialKeyUp(event:KeyboardEvent):Void {
		
		switch (event.keyCode) {
			case Keyboard.SHIFT: rotating = false;
			case Keyboard.CONTROL: skewing = false;
			case Keyboard.ALTERNATE: scaling = false;
		}
		drawme();
	}

	private function onKeyUp(event:KeyboardEvent):Void {
		if (dragged) return;
		
		switch (event.keyCode) {
			case Keyboard.RIGHT: pivot.rotate(-15);
			case Keyboard.LEFT: pivot.rotate(15);
			case Keyboard.SPACE: pivot.identity();
			case Keyboard.NUMBER_1: pivot.setInternalPoint(0,0);
			case Keyboard.NUMBER_2: pivot.setInternalPoint(0,1);
			case Keyboard.NUMBER_3: pivot.setInternalPoint(0,2);
			case Keyboard.NUMBER_4: pivot.setInternalPoint(1,0);
			case Keyboard.NUMBER_5: pivot.setInternalPoint(1,1);
			case Keyboard.NUMBER_6: pivot.setInternalPoint(1,2);
			case Keyboard.NUMBER_7: pivot.setInternalPoint(2,0);
			case Keyboard.NUMBER_8: pivot.setInternalPoint(2,1);
			case Keyboard.NUMBER_9: pivot.setInternalPoint(2,2);
			
		}
	}
	
}
