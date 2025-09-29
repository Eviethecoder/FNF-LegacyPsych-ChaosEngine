package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import MusicBeatState.DebugText;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;
	private var debugGroup:FlxTypedGroup<DebugText>;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return Controls.instance;

	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();


		super.update(elapsed);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}
	public function addTextToDebug(text:String, color:FlxColor)
	{
		
		debugGroup.forEachAlive(function(spr:DebugText)
		{
			spr.y += 20;
		});

		if (debugGroup.members.length > 34)
		{
			var blah = debugGroup.members[34];
			blah.destroy();
			debugGroup.remove(blah);
		}
		debugGroup.insert(0, new DebugText(text, debugGroup, color));
	
	}

	public function hscriptError(e:Dynamic, funcName:String, fPath:String) { 
		addTextToDebug("   ...  " + Std.string(e), FlxColor.fromRGB(240, 166, 38));
		addTextToDebug("[ ERROR ] Could not run function " + funcName + " (script: "+fPath+") ", FlxColor.RED); 
		trace(e );
	}

	public function beatHit():Void
	{
		//do literally nothing dumbass
	}
}
