package events;

import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import PlayState;
import utility.Scripthandler;
import HaxeScript;

@:keep
class CameraZoom extends BaseEvent
{
	public static var zoomTwn:FlxTween;

	public function new(name:String)
	{
		super();
		eventName = 'Camera Zoom';
	}

	public override function triggerEvent():Void
	{
		var time:Float = handletimelogic(grabeventFloat('Timing'));

		var zoom:Float = grabeventFloat('Zoom');
		var easingtype:String = grabeventString('Easing');
		easingtype += grabeventString('inout');

		tweenZoom(zoom, time, easingtype);
	}

	function snapZoom(zoom:Float)
	{
		FlxG.camera.zoom = zoom;
	}

	function tweenZoom(targetZoom:Float, time:Float, ease:String)
	{
		var wasogzooming:Bool = PlayState.instance.camZooming;
		if (PlayState.instance.camZooming == true)
		{
			PlayState.instance.camZooming = false;
			PlayState.instance.defaultCamZoom = targetZoom;
		}
		if (time == 0)
		{
			snapZoom(targetZoom);
			return;
		}

		if (zoomTwn != null)
			zoomTwn.cancel();

		zoomTwn = FlxTween.tween(FlxG.camera, {zoom: targetZoom}, time, {
			ease: HaxeScript.getFlxEaseByString(ease),
			onComplete: function(twn:FlxTween)
			{
				zoomTwn = null;
				PlayState.instance.defaultCamZoom = targetZoom;
				if (wasogzooming == true)
				{
					PlayState.instance.camZooming = true;
				}
			}
		});
	}

	static function handletimelogic(offset:Float):Float
	{
		var step:Float = 0;
		switch (PlayState.instance.steptyype)
		{
			case 'step':
				step = Conductor.stepCrochet;
			case 'sec':
				return offset;
		}

		if (offset == 0)
			return 0;
		return step * offset / 1000;
	}
}
