package events;

import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import PlayState;
import flixel.FlxBasic;
import utility.Scripthandler;
import flixel.math.FlxPoint;
import HaxeScript;
import objects.FunkinSprite;

using StringTools;

@:keep
class CameraMovement extends BaseEvent
{
	public static var cameraTwn:FlxTween;

	public function new(name:String)
	{
		super();
		eventName = 'Camera Movement';
	}

	public override function triggerEvent():Void
	{
		var focous:String = '';

		var prop:FunkinSprite = null;
		var propoffsets:Array<Float> = [];

		var time:Float = handletimelogic(grabeventFloat('Timing'));

		switch (grabeventString('Focus'))
		{
			case 'Dad':
				prop = PlayState.instance.stage.getCharacter('dad');
				propoffsets = [150, -100];
				propoffsets[0] += (grabeventFloat('Offset x') + PlayState.instance.stage.getCharacter('dad').cameraPosition[0]);
				propoffsets[1] += (grabeventFloat('Offset y') + PlayState.instance.stage.getCharacter('dad').cameraPosition[1]);
				focous = 'dad';

			case 'GF':
				prop = PlayState.instance.stage.getCharacter('gf');
				propoffsets = [-100, -100];
				propoffsets[0] += (grabeventFloat('Offset x') + PlayState.instance.stage.getCharacter('gf').cameraPosition[0]);
				propoffsets[1] += (grabeventFloat('Offset y') + PlayState.instance.stage.getCharacter('gf').cameraPosition[1]);
				focous = 'GF';

			case 'BF':
				prop = PlayState.instance.stage.getCharacter('bf');
				propoffsets = [-100, -100];
				propoffsets[0] += (grabeventFloat('Offset x') + PlayState.instance.stage.getCharacter('bf').cameraPosition[0]);
				propoffsets[1] += (grabeventFloat('Offset y') + PlayState.instance.stage.getCharacter('bf').cameraPosition[1]);
				focous = 'BF';
			case 'Prop':
				prop = PlayState.instance.stage.grabProp(grabeventString('focusprop'));
				propoffsets = [0, 0];
				propoffsets[0] += (grabeventFloat('Offset x'));
				propoffsets[1] += (grabeventFloat('Offset y'));
				focous = grabeventString('focusprop');
				if (prop == null)
				{
					trace('no character found, looking for prop with name: ' + grabeventString('focusprop') + ' Canceling camera movement event');
					return;
				}
		}
		var easingtype:String = grabeventString('Easing');
		easingtype += grabeventString('inout');

		tweencamera(prop, propoffsets, time, easingtype);
	}

	public function snapCam(focusoffset:Array<Float>)
	{
		PlayState.instance.camFollow.set(focusoffset[0], focusoffset[1]);
		PlayState.instance.camFollowPos.setPosition(focusoffset[0], focusoffset[1]);
		FlxG.camera.focusOn(PlayState.instance.camFollowPos.getPosition());
	}

	function tweencamera(prop:FunkinSprite, propoffsets:Array<Float>, time:Float, ease:String)
	{
		if (time == 0)
		{
			snapCam([prop.getMidpoint().x + propoffsets[0], prop.getMidpoint().y + propoffsets[1]]);
			return;
		}

		// Disable camera following for the duration of the tween.
		@:nullSafety(Off)
		FlxG.camera.target = null;
		PlayState.instance.camFollowPos.setPosition(prop.getMidpoint().x + propoffsets[0], prop.getMidpoint().y + propoffsets[1]);
		var followPos:FlxPoint = PlayState.instance.camFollowPos.getPosition() - FlxPoint.weak(FlxG.camera.width * 0.5, FlxG.camera.height * 0.5);
		cameraTwn = FlxTween.tween(FlxG.camera.scroll, {
			x: followPos.x,
			y: followPos.y
		}, time, {
			ease: HaxeScript.getFlxEaseByString(ease),
			onComplete: function(twn:FlxTween)
			{
				cameraTwn = null;
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
