package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.text.FlxText;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxBasic;

class MusicBeatState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;
	private var debugGroup:FlxTypedGroup<DebugText>;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	public var controls(get, never):Controls;

	public static var camBeat:FlxCamera;

	public function new( ){
		super();
		debugGroup = new FlxTypedGroup<DebugText>();
		
		add(debugGroup);

	}

	inline function get_controls():Controls
		return Controls.instance;

	override function create() {
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if(!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		trace(Type.getClassName(Type.getClass(this)));
		FlxTransitionableState.skipNextTransOut = false;
		
		
		
	}

	override function update(elapsed:Float)
	{
		//everyStep();
		if (FlxG.keys.justPressed.F5) {
			ScriptedStatehandler.reListStates();
			FlxG.resetState();
		}
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
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

	public static function switchscriptedstate(nextState:String) {
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		
		if(!FlxTransitionableState.skipNextTransIn) {
			leState.openSubState(new CustomFadeTransition(0.6, false));
			
		
			CustomFadeTransition.finishCallback = function() {
				ScriptedStatehandler.curselectedstate = nextState;
				FlxG.switchState(new ScriptableMusicBeatState(nextState));
			};
				//trace('changed state');
			
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		ScriptedStatehandler.curselectedstate = nextState;
		FlxG.switchState(new ScriptableMusicBeatState(nextState));
		
		
	}

	public static function switchState(nextState:FlxState) {
		// Custom made Trans in

		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		var statepass:FlxState = nextState;
		var foundstate:Bool = false;
		var doogstate:Bool = false;
		
		if(!FlxTransitionableState.skipNextTransIn) {
			leState.openSubState(new CustomFadeTransition(0.6, false));
			if(nextState == FlxG.state) {
				CustomFadeTransition.finishCallback = function() {
					FlxG.resetState();
				};
				//trace('resetted');
			} else {
				CustomFadeTransition.finishCallback = function() {
					detectscriiptedstates(statepass);
				};
				//trace('changed state');
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		detectscriiptedstates(statepass);
		
		
	}

	public static function detectscriiptedstates(nextState:FlxState){
		var classname:String = Type.getClassName(Type.getClass(nextState));
		for (i in 0... ScriptedStatehandler.states.length){
			trace(ScriptedStatehandler.states[i] + 'compared to ' +classname);
			if (ScriptedStatehandler.states[i] == classname){
				
				ScriptedStatehandler.curselectedstate = ScriptedStatehandler.states[i];
				FlxG.switchState(new ScriptableMusicBeatState(classname));
				return;
			}
		}
		FlxG.switchState(nextState);

	}
	public static function resetState() {
		var curState:Dynamic = FlxG.state;
		if(!FlxTransitionableState.skipNextTransIn) {
			curState.openSubState(new CustomFadeTransition(0.6, false));
			CustomFadeTransition.finishCallback = function() {
					trace('resetstate');
				};
				FlxG.resetState();
			
				
		}
	
	}
	public static function getState():MusicBeatState {
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
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

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}

class DebugText extends FlxText
{
	private var disableTime:Float = 6;
	public var parentGroup:FlxTypedGroup<DebugText>;
	public function new(text:String, parentGroup:FlxTypedGroup<DebugText>, color:FlxColor) {
		this.parentGroup = parentGroup;
		super(10, 10, 0, text, 16);
		setFormat(Paths.font("vcr.ttf"), 20, color, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scrollFactor.set();
		borderSize = 1;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		disableTime -= elapsed;
		if(disableTime < 0) disableTime = 0;
		if(disableTime < 1) alpha = disableTime;
	}
}
