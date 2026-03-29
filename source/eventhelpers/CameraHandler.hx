package eventhelpers;

import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import objects.FunkinSprite;
import PlayState;
import Character;

using StringTools;

class CameraHandler
{
	static public var cameraTwn:FlxTween;
	static public var zoomTwn:FlxTween;
	static public var ogzoom:Float = 0;
	static public var steptyype:String = 'ms';


	static public function handlestepreset():Void
	{
		steptyype = 'ms';
	}

	static public function handelcameramovement(value1:String, value2:String)
	{
		var focous:String = '';
		var character:Character = null;
		var offsets:Array<Float> = [];
		var ease:String = '';
		var prop:FunkinSprite = null;
		var characteroffsets:Array<Float> = [];
		var valuearray:Array<String> = value1.split(',');
		var valuearray2:Array<String> = value2.split(',');
		var time:Float = 4;

		if (valuearray.length > 0 && valuearray[0] != null)
		{
			switch (valuearray[0].toLowerCase().trim())
			{
				case 'dad', 'd', 'opponent':
					character = PlayState.instance.stage.dad;
					characteroffsets = [150, -100];
					focous = 'dad';

				case 'bf', 'boyfriend', 'player':
					character = PlayState.instance.stage.boyfriend;
					characteroffsets = [-100, -100];
					focous = 'boyfriend';

				case 'gf', 'girlfriend':
					character = PlayState.instance.stage.gf;
					characteroffsets = [-100, -100];
					focous = 'girlfriend';

				default:
					trace('no character found, looking for prop with name: ' + valuearray[0]);
					prop = PlayState.instance.stage.grabProp(valuearray[0]);
					focous = valuearray[0];
					if( prop == null){
						trace('no prop found with name: ' + valuearray[0] + ' defaulting to dad');
						character = PlayState.instance.stage.dad;
						characteroffsets = [150, -100];
						focous = 'dad';
					}
			}
		}
		else
		{
			trace('WARNING!!! EVENT NOT USED PROPERLY, VALUE 1 MUST BE IN THIS ORDER CHARACTER, CAMOFFSET. STOPPING EVENT.');
			return;
		}

		for (i in 1...3)
		{
			if (valuearray.length > i)
			{
				var parsed:Float = Std.parseFloat(valuearray[i]);
				if (!Math.isNaN(parsed))
					offsets.push(parsed);
				else
					offsets.push(0);
			}
			else
				offsets.push(0);
		}

		
		if (valuearray2.length > 0)
		{
			var first:String = valuearray2[0];
			var firstFloat:Float = Std.parseFloat(first);
			if (Math.isNaN(firstFloat))
				ease = first;
			else
			{
				trace('No value 2 easing. defaulting to linear. doing time code instead');
				time = cameratime(firstFloat);
				ease = 'linear';
			}
		}

		if (valuearray2.length > 1)
		{
			var second:Float = Std.parseFloat(valuearray2[1]);
			if (!Math.isNaN(second))
				time = cameratime(second);
			else
			{
				trace('No value 2 timing. defaulting to 4');
				ease = 'linear';
			}
		}

		
		if (cameraTwn != null)
		{
			cameraTwn.cancel();
			cameraTwn = null;
		}

		PlayState.instance.setFunctionOnScripts('onMoveCamera', [focous]);
		if(character == null){
			cameraTwn = FlxTween.tween(
			PlayState.instance.camFollow,
			{
				x: prop.getMidpoint().x + offsets[0],
				y: prop.getMidpoint().y + offsets[1]
			},
			time,
			{
				ease: HaxeScript.getFlxEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					cameraTwn = null;
				}
			}
		);
		}
		else{
			cameraTwn = FlxTween.tween(
			PlayState.instance.camFollow,
			{
				x: character.getMidpoint().x + characteroffsets[0] + character.cameraPosition[0] + offsets[0],
				y: character.getMidpoint().y + characteroffsets[1] + character.cameraPosition[1]  + offsets[1]
			},
			time,
			{
				ease: HaxeScript.getFlxEaseByString(ease),
				onComplete: function(twn:FlxTween)
				{
					cameraTwn = null;
				}
			}
		);
	}

		}
		



	static public function cameratween(value1:String, value2:String,camZooming:Bool ){


		var valuearray:Array<String>  = value2.split(',');
		var ease:String = 'linear';
		var time:Float = 4;
		var zoom:Float = 0;
		if(ogzoom == 0){
			ogzoom = PlayState.instance.defaultCamZoom;
		}
		else{
			if (ogzoom != PlayState.instance.defaultCamZoom){
				ogzoom = PlayState.instance.defaultCamZoom;
			}
		}
		if(value1 != ''){
			ease = value1;
		}

		if(valuearray[0] != null){
			time = Std.parseFloat(valuearray[0]);
		}
		if(valuearray[1] != null){
			zoom = Std.parseFloat(valuearray[1]);
		}
		else{
			zoom = ogzoom;
		}

		if (zoomTwn != null)
		{
			zoomTwn.cancel();
			zoomTwn = null;
		}
		
		trace('camzooming: ' + camZooming);
		if(time == 0){
			switch(camZooming){
				case true:
					PlayState.instance.defaultCamZoom = zoom;
					FlxG.camera.zoom = zoom;
				case false:
					FlxG.camera.zoom = zoom;
			}
			
		}
		switch(camZooming){
			case true:
				zoomTwn = FlxTween.tween(PlayState.instance, {defaultCamZoom: zoom},cameratime(time), {ease: HaxeScript.getFlxEaseByString(ease),onComplete: function(twn:FlxTween)
						{
							zoomTwn = null;
						}}); //woaaaah});


			case false:
				zoomTwn = FlxTween.tween(FlxG.camera, {zoom: zoom},cameratime(time), {ease: HaxeScript.getFlxEaseByString(ease),onComplete: function(twn:FlxTween)
						{
							zoomTwn = null;
						}}); //woaaaah});
		}

	}

	static public function snapCamFollowToPos(value1:String, value2:String, camZooming:Bool)
	{
		var valuearray:Array<String> = value1.split(',');

		var focus:String = valuearray[0];  //dad, bf, gf, or prop name. will work with anything that has a midpoint function and is on the stage
		var object:Dynamic;
		var offsets:Array<Float> = [0, 0];
		var zoomvalue:Float;
		if(Math.isNaN(Std.parseFloat(value2))){
			zoomvalue = PlayState.instance.defaultCamZoom;
		}
		else{
			zoomvalue = Std.parseFloat(value2);
		}

		switch(focus.toLowerCase().trim())
		{
			default:
				trace('no character found, looking for prop with name: ' + focus);
				object = PlayState.instance.stage.grabProp(focus);
				if( object == null){
					trace('no prop found with name: ' + focus + ' defaulting to dad');
					object = PlayState.instance.stage.dad;
					if(Reflect.field(object, 'cameraPosition')){
						offsets = [object.getMidpoint().x + object.cameraPosition[0] + 150, object.getMidpoint().y + object.cameraPosition[1] - 100];
					}
					else{
						offsets = [150, -100];
					}
					offsets = [150, -100];
				}
			case  'd' | 'dad' | 'opponent' |'g' | 'gf' | 'girlfriend':
				
				if(focus.toLowerCase().trim() == 'g' || focus.toLowerCase().trim() == 'gf' || focus.toLowerCase().trim() == 'girlfriend'){
					object = PlayState.instance.stage.gf;
				}
				else{
					object = PlayState.instance.stage.dad;
				}
				offsets = [object.getMidpoint().x + object.cameraPosition[0] + 150, object.getMidpoint().y + object.cameraPosition[1] - 100];
				
					

			case 'bf', 'boyfriend', 'player':
				object = PlayState.instance.stage.boyfriend;
					offsets = [object.getMidpoint().x + object.cameraPosition[0] -100, object.getMidpoint().y + object.cameraPosition[1] - 100];


		}
		if(valuearray[1] != null){
			var parsed:Float = Std.parseFloat(valuearray[1]);
			if (!Math.isNaN(parsed))
				offsets[0] + parsed;
		}
		if(valuearray[2] != null){
			var parsed:Float = Std.parseFloat(valuearray[2]);
			if (!Math.isNaN(parsed))
				offsets[1] + parsed;
		}
		
		snapCam(offsets, zoomvalue, camZooming);

	}

	static public function snapCam(focusoffset:Array<Float>, zoom:Float, camZooming:Bool)
	{
		PlayState.instance.camFollow.set(focusoffset[0], focusoffset[1]);
		PlayState.instance.camFollowPos.setPosition(focusoffset[0], focusoffset[1]);
		switch(camZooming){
				case true:
					PlayState.instance.defaultCamZoom = zoom;
					FlxG.camera.zoom = zoom;
				case false:
					FlxG.camera.zoom = zoom;
			}
	}
	static function cameratime(offset:Float):Float
	{
		var step:Float = 0;
		switch(steptyype){
			case 'ms':
				step = Conductor.stepCrochet;
			case 'sec':
				step = Conductor.stepLength;
		}
		return step * offset / 1000;
	}
}
