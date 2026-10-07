package events;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import PlayState;
import HaxeScript;
import objects.Strumline;

@:keep
class ChangeScrollSpeed extends BaseEvent
{
	public static var playerSpeedTween:FlxTween;
	public static var opponentSpeedTween:FlxTween;

	public function new(?name:String)
	{
		super();
		eventName = 'ChangeScrollSpeed';
	}

	override public function triggerEvent():Void
	{
		var game:PlayState = PlayState.instance;
		if (game.songSpeedType == "constant")
			return;

		var multiplier:Float = grabeventFloat('Scroll modifier');
		if (multiplier == 0)
			multiplier = 1;
		var time:Float = handletimelogic(grabeventFloat('Timing'));
		var target:String = grabeventString('Strumline to modify');
		var easing:String = grabeventString('Easing') + grabeventString('inout');

		var newValue:Float = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * multiplier;

		switch (target)
		{
			case 'Player':
				playerSpeedTween = changeSpeed(game.playerStrumline, playerSpeedTween, newValue, time, easing);
			case 'Opponent':
				opponentSpeedTween = changeSpeed(game.opponentStrumline, opponentSpeedTween, newValue, time, easing);
			default:
				playerSpeedTween = changeSpeed(game.playerStrumline, playerSpeedTween, newValue, time, easing);
				opponentSpeedTween = changeSpeed(game.opponentStrumline, opponentSpeedTween, newValue, time, easing);
		}
	}

	function changeSpeed(strumline:Strumline, oldTween:FlxTween, newValue:Float, time:Float, easing:String):FlxTween
	{
		if (oldTween != null)
			oldTween.cancel();

		if (time <= 0)
		{
			strumline.songSpeed = newValue;
			return null;
		}

		return FlxTween.tween(strumline, {songSpeed: newValue}, time / PlayState.instance.playbackRate, {
			ease: HaxeScript.getFlxEaseByString(easing),
			onComplete: function(twn:FlxTween)
			{
				if (playerSpeedTween == twn)
					playerSpeedTween = null;
				if (opponentSpeedTween == twn)
					opponentSpeedTween = null;
			}
		});
	}

	static function handletimelogic(offset:Float):Float
	{
		if (offset == 0)
			return 0;
		return switch (PlayState.instance.steptyype)
		{
			case 'step': Conductor.stepCrochet * offset / 1000;
			default: offset;
		}
	}
}
