class ChangeScrollSpeed extends BaseEvent
{
	public var songSpeedTween:FlxTween;
	public var songSpeedTween2:FlxTween;

	public function new(newSpeed:Float)
	{
		super();
	}

	override public function triggerEvent():Void
	{
		if (PlayState.instance.songSpeedType == "constant")
			return;
		var multiplier:Float = grabeventFloat('multiplyer');
		var time:Float = grabeventFloat('time');
		var strumlinetoscroll:Float = grabeventString('strumlinetoscroll');

		var newValue:Float = PlayState.instance.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * multiplier;

		if (val2 <= 0)
		{
			PlayState.instance.songSpeed = newValue;
		}
		else
		{
			dospeedtween(newValue, time, strumlinetoscroll);
		}
	}

	function dospeedtween(newValue:Float, time:Float, strumlinetoscroll:Float):Void
	{
		switch (strumlinetoscroll)
		{
			case "all":
				dospeedtween(newValue, time, "Player");
				dospeedtween(newValue, time, "Opponent");
			case "Player":
				songSpeedTween1 = FlxTween.tween(this, {PlayState.instance.playerStrumline.songSpeed: newValue}, time / PlayState.instance.playbackRate, {
					ease: FlxEase.linear,
					onComplete: function(twn:FlxTween)
					{
						songSpeedTween1 = null;
					}
				});
			case "Opponent":
				songSpeedTween2 = FlxTween.tween(this, {PlayState.instance.opponentStrumline.songSpeed: newValue}, time / PlayState.instance.playbackRate, {
					ease: FlxEase.linear,
					onComplete: function(twn:FlxTween)
					{
						songSpeedTween2 = null;
					}
				});
		}
	}
}
