package chorus.backend.scripting.scriptevents;

import chorus.backend.save.Rating;
import flixel.FlxBasic;
import chorus.backend.scripting.Scripthandler;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import chorus.backend.save.Rating;
import chorus.objects.game.Note;

// this is modified from v slice directly support the official release of the game
enum abstract ScriptEventType(String) from String to String
{
	/**
	 * Called when the relevant object is created.
	 * Keep in mind that the constructor may be called before the object is needed,
	 * for the purposes of caching data or otherwise.
	 *
	 * This event is not cancelable.
	 */
	public var PRE_CREATE = 'PRECREATE';

	/**
	 * Called when the relevant object is created.
	 * Keep in mind that the constructor may be called before the object is needed,
	 * for the purposes of caching data or otherwise.
	 *
	 * This event is not cancelable.
	 */
	public var CREATE_POST = 'CREATE_POST';

	/**
	 * Called when the relevant object is fully created and ready to be used.
	 * This assumes all data is loaded and ready to go.
	 *
	 * This event is not cancelable.
	 */
	public var STATE_CREATE = 'STATE_CREATE';

	/**
	 * Called when the relevant object is destroyed.
	 * This should perform relevant cleanup to ensure good performance.
	 *
	 * This event is not cancelable.
	 */
	public var DESTROY = 'DESTROY';

	/**
	 * Called during the update function.
	 * This is called every frame, so be careful!
	 *
	 * This event is not cancelable.
	 */
	public var UPDATE = 'UPDATE';

	/**
	 * Called when the player moves to pause the game.
	 *
	 * This event IS cancelable! Canceling the event will prevent the game from pausing.
	 */
	public var PAUSE = 'PAUSE';

	/**
	 * Called when the player moves to unpause the game while paused.
	 *
	 * This event IS cancelable! Canceling the event will prevent the game from resuming.
	 */
	public var RESUME = 'RESUME';

	/**
	 * Called once per beat . This happens 4 times per measure.
	 *
	 * This event IS cancelable! Canceling this event will prevent the beat hit from processing.
	 */
	public var BEAT_HIT = 'SONG_BEAT_HIT';

	/**
	 * Called once per step . This happens 16 times per measure.
	 *
	 * This event IS cancelable! Canceling this event will prevent the step hit from processing.
	 */
	public var STEP_HIT = 'SONG_STEP_HIT';

	/**
	 * Called when a character hits a note.
	 * Important information such as judgement/timing, note data, player/opponent, etc. are all provided.
	 *
	 * This event IS cancelable! Canceling this event prevents the note from being hit,
	 *   and will likely result in a miss later.
	 */
	public var NOTE_HIT = 'NOTE_HIT';

	/**
	 * Called when a character misses a note.
	 * Important information such as note data, player/opponent, etc. are all provided.
	 *
	 * This event IS cancelable! Canceling this event prevents the note from being considered missed,
	 *   avoiding a combo break and lost health.
	 */
	public var NOTE_MISS = 'NOTE_MISS';

	/**
	 * Called when a character lets go of a hold note.
	 * Important information such as note data, player/opponent, etc. are all provided.
	 *
	 * This event IS cancelable! Canceling this event prevents the hold from being considered dropped,
	 *   avoiding a combo break, lost health.
	 */
	public var NOTE_HOLD_DROP = 'NOTE_HOLD_DROP';

	/**
	 * Called when a character presses a note when there was none there, causing them to lose health.
	 * Important information such as direction pressed, etc. are all provided.
	 *
	 * This event IS cancelable! Canceling this event prevents the note from being considered missed,
	 *   avoiding lost health/score and preventing the miss animation.
	 */
	public var NOTE_GHOST_MISS = 'NOTE_GHOST_MISS';

	/**
	 * Called when a song event is reached in the chart.
	 *
	 * This event IS cancelable! Cancelling this event prevents the event from being triggered,
	 *   thus blocking its normal functionality.
	 */
	public var SONG_EVENT = 'SONG_EVENT';

	/**
	 * Called when the song starts. This occurs as the countdown ends and the instrumental begin.
	 *
	 * This event is not cancelable.
	 */
	public var SONG_START = 'SONG_START';

	/**
	 * Called when the song ends. This happens as the instrumental end.
	 *
	 * This event IS cancelable! Canceling this event will prevent the song from ending.
	 * - The song will not end until you call PlayState.instance.endSong() later.
	 * - Note that calling endSong() will trigger this event again, so be sure to add logic to ignore it.
	 */
	public var SONG_END = 'SONG_END';

	/**
	 * Called when the countdown begins. This occurs before the song starts.
	 *
	 * This event IS cancelable! Canceling this event will prevent the countdown from starting.
	 * - The song will not start until you call Countdown.performCountdown() later.
	 * - Note that calling performCountdown() will trigger this event again, so be sure to add logic to ignore it.
	 */
	public var COUNTDOWN_START = 'COUNTDOWN_START';

	/**
	 * Called when a step of the countdown happens.
	 * Includes information about what step of the countdown was hit.
	 *
	 * This event IS cancelable! Canceling this event will pause the countdown.
	 * - The countdown will not resume until you call PlayState.resumeCountdown().
	 */
	public var COUNTDOWN_STEP = 'COUNTDOWN_STEP';

	/**
	 * Called when the countdown is done but just before the song starts.
	 *
	 * This event is not cancelable.
	 */
	public var COUNTDOWN_END = 'COUNTDOWN_END';

	/**
	 * Called before the game over screen triggers and the death animation plays.
	 *
	 * This event IS cancelable! Canceling this event will prevent the game from transitioning to the game over screen.
	 */
	public var GAME_OVER = 'GAME_OVER';

	/**
	 * Called after the player presses a key to restart the game.
	 * This can happen from the pause menu or the game over screen.
	 *
	 * This event IS cancelable! Canceling this event will prevent the song from restarting.
	 */
	public var SONG_RETRY = 'SONG_RETRY';

	/**
	 * Called when the player pushes down any key on the keyboard.
	 *
	 * This event is not cancelable.
	 */
	public var KEY_DOWN = 'KEY_DOWN';

	/**
	 * Called when the player releases a key on the keyboard.
	 *
	 * This event is not cancelable.
	 */
	public var KEY_UP = 'KEY_UP';

	/**
	 * Called when the game is about to switch the current FlxState.
	 *
	 * This event IS cancelable! Canceling this event will prevent the state from changing.
	 */
	public var STATE_CHANGE_BEGIN = 'STATE_CHANGE_BEGIN';

	/**
	 * Called when the game has finished switching the current FlxState.
	 *
	 * This event is not cancelable.
	 */
	public var STATE_CHANGE_END = 'STATE_CHANGE_END';

	/**
	 * Called when the game is about to open a new FlxSubState.
	 *
	 * This event IS cancelable! Canceling this event will prevent the substate from opening.
	 */
	public var SUBSTATE_OPEN_BEGIN = 'SUBSTATE_OPEN_BEGIN';

	/**
	 * Called when the game has finished opening a new FlxSubState.
	 *
	 * This event is not cancelable.
	 */
	public var SUBSTATE_OPEN_END = 'SUBSTATE_OPEN_END';

	/**
	 * Called when the game is about to close the current FlxSubState.
	 *
	 * This event IS cancelable! Canceling this event will prevent the substate from closing.
	 */
	public var SUBSTATE_CLOSE_BEGIN = 'SUBSTATE_CLOSE_BEGIN';

	/**
	 * Called when the game has finished closing the current FlxSubState.
	 *
	 * This event is not cancelable.
	 */
	public var SUBSTATE_CLOSE_END = 'SUBSTATE_CLOSE_END';

	/**
	 * Called when the game regains focus.
	 *
	 * This event is not cancelable.
	 */
	public var FOCUS_GAINED = 'FOCUS_GAINED';

	/**
	 * Called when the game loses focus.
	 *
	 * This event is not cancelable.
	 */
	public var FOCUS_LOST = 'FOCUS_LOST';

	/**
	 * Called when the game starts a conversation.
	 *
	 * This event is not cancelable.
	 */
	public var DIALOGUE_START = 'DIALOGUE_START';

	/**
	 * Called to display the next line of conversation.
	 *
	 * This event IS cancelable! Canceling this event will prevent the conversation from moving to the next line.
	 * - This event is called when the conversation starts, or when the user presses ACCEPT to advance the conversation.
	 */
	public var DIALOGUE_LINE = 'DIALOGUE_LINE';

	/**
	 * Called to skip scrolling the current line of conversation.
	 *
	 * This event IS cancelable! Canceling this event will prevent the conversation from skipping to the next line.
	 * - This event is called when the user presses ACCEPT to advance the conversation while it is already advancing.
	 */
	public var DIALOGUE_COMPLETE_LINE = 'DIALOGUE_COMPLETE_LINE';

	/**
	 * Called to skip the conversation.
	 *
	 * This event IS cancelable! Canceling this event will prevent the conversation from skipping.
	 */
	public var DIALOGUE_SKIP = 'DIALOGUE_SKIP';

	/**
	 * Called when the game ends a conversation.
	 *
	 * This event is not cancelable.
	 */
	public var DIALOGUE_END = 'DIALOGUE_END';

	public inline function toString():String
	{
		return this;
	}

	public inline function scriptFuncName():String
	{
		switch (this.toString())
		{
			default:
				return '';
			case 'SONG_STEP_HIT':
				return 'onStepHit';
			case 'SONG_BEAT_HIT':
				return 'onBeatHit';
			case 'NOTE_HIT':
				return 'onNoteHit';
			case 'NOTE_MISS':
				return 'onNoteMiss';
			case 'PRE_CREATE':
				return 'onPreCreate';
			case 'CREATE_POST':
				return 'onCreatePost';
		}
	}

	/**
	 * Allow for comparing `ScriptEventType` to `String`.
	 */
	@:op(A == B)
	static inline function equals(a:ScriptEventType, b:String):Bool
	{
		return (a : String) == b;
	}

	/**
	 * Allow for comparing `ScriptEventType` to `String`.
	 */
	@:op(A != B)
	static inline function notEquals(a:ScriptEventType, b:String):Bool
	{
		return (a : String) != b;
	}
}

class BasicEvent extends FlxBasic // curently also to be used with countdown end
{
	/**
	 * The type associated with the event.
	 */
	public var type(default, null):ScriptEventType;

	/* this will tell the game whether it is cancelable, set this to false to prevent canceling in scripts */
	public var iscancleable:Bool = true;

	/* this will tell the game whether the event has been canceled */
	public var cancled:Bool = false;

	public function new(eventtype:ScriptEventType, cancleable:Bool)
	{
		super();
	}

	public function resetEvent(eventtype:ScriptEventType, cancleable:Bool, ?data:Dynamic):Void
	{
		type = eventtype;
		iscancleable = cancleable;
		cancled = false;
	}

	public override function toString():String
	{
		return 'Event(type=' + type + ', iscancleable=' + iscancleable + ', cancled=' + cancled + ')';
	}
}

typedef SustainInfo =
{
	public var sustainLength:Float;
	public var isSustain:Bool;
}

class CountdownStartEvent extends BasicEvent
{
	/**
	 * Called when the countdown starts.
	 *
	 * This event IS cancelable! Canceling this event will prevent the countdown from starting.
	 */
	// when the song starts at, normaly should be 0
	public var startOnTime:Float;

	public function new(eventtype:ScriptEventType, cancleable:Bool, startOnTime:Float)
	{
		super(eventtype, cancleable);
		resetEvent(eventtype, cancleable, {startOnTime: startOnTime});
	}

	public override function resetEvent(eventtype:ScriptEventType, cancleable:Bool, ?data:Dynamic):Void
	{
		super.resetEvent(eventtype, cancleable);
		startOnTime = (data != null && data.startOnTime != null) ? data.startOnTime : 0;
	}

	public override function toString():String
	{
		return 'CountdownStartEvent(type='
			+ type
			+ ', iscancleable='
			+ iscancleable
			+ ', cancled='
			+ cancled
			+ ', startOnTime='
			+ startOnTime
			+ ')';
	}
}

class BeatHitEvent extends BasicEvent
{
	/**
	 * Called when a beat is hit.
	 *
	 * This event IS cancelable! Canceling this event will prevent the beat from being registered.
	 */
	public var beat:Int;

	public function new(eventtype:ScriptEventType, cancleable:Bool, beat:Int)
	{
		super(eventtype, cancleable);
		resetEvent(eventtype, cancleable, {beat: beat});
	}

	public override function resetEvent(eventtype:ScriptEventType, cancleable:Bool, ?data:Dynamic):Void
	{
		super.resetEvent(eventtype, cancleable);
		beat = (data != null && data.beat != null) ? data.beat : 0;
	}

	public override function toString():String
	{
		return 'BeatHitEvent(type=' + type + ', iscancleable=' + iscancleable + ', cancled=' + cancled + ', beat=' + beat + ')';
	}
}

class StepHitEvent extends BasicEvent
{
	/**
	 * Called when a step is hit.
	 *
	 * This event IS cancelable! Canceling this event will prevent the step from being registered.
	 */
	public var step:Int;

	public function new(eventtype:ScriptEventType, cancleable:Bool, step:Int)
	{
		super(eventtype, cancleable);
		resetEvent(eventtype, cancleable, {step: step});
	}

	public override function resetEvent(eventtype:ScriptEventType, cancleable:Bool, ?data:Dynamic):Void
	{
		super.resetEvent(eventtype, cancleable);
		step = (data != null && data.step != null) ? data.step : 0;
	}

	public override function toString():String
	{
		return 'StepHitEvent(type=' + type + ', iscancleable=' + iscancleable + ', cancled=' + cancled + ', step=' + step + ')';
	}
}

class CountdownStepEvent extends BasicEvent
{
	/**
	 * Called when the countdown steps.
	 *
	 * This event IS cancelable! Canceling this event will prevent the countdown from progressing.
	 */
	// the current step of the countdown
	public var step:Int;

	public var soundtoplay:String;

	public var asset:String;

	public function new(eventtype:ScriptEventType, cancleable:Bool, step:Int, soundtoplay:String, asset:String)
	{
		super(eventtype, cancleable);
		resetEvent(eventtype, cancleable, {step: step, soundtoplay: soundtoplay, asset: asset});
	}

	public override function resetEvent(eventtype:ScriptEventType, cancleable:Bool, ?data:Dynamic):Void
	{
		super.resetEvent(eventtype, cancleable);
		step = (data != null && data.step != null) ? data.step : 0;
		soundtoplay = data != null ? data.soundtoplay : null;
		asset = data != null ? data.asset : null;
	}

	public override function toString():String
	{
		return 'CountdownStepEvent(type=' + type + ', iscancleable=' + iscancleable + ', cancled=' + cancled + ', step=' + step + ', soundtoplay='
			+ soundtoplay + ', asset=' + asset + ')';
	}
}

class NoteMissEvent extends BasicEvent
{
	/**
	 * Called when a note is missed.
	 *
	 * This event IS cancelable! Canceling this event will prevent the note miss being regestered.
	 */
	/**
	 * The note that was hit.
	 */
	public var note:Note;

	public var gfNote:Bool = false;

	/**
	 * Whether the note hit was of the special type.
	 */
	public var isspecial:Bool;

	/** holds relitive sustain information for the note **/
	public var sustainInfo:SustainInfo;

	/**
	 * Whether this note hit causes a note splash to display.
	 * Defaults to true only on "sick" notes.
	 */
	public var doesNotesplash:Bool = false;

	/** whether this note blocks a hit**/
	public var blockHit:Bool = false;

	public var hitCausesMiss:Bool = false;

	public var noteType:String;

	public var animSuffix:String = "";

	/** the change in health caused by this note hit **/
	public var healthchange:Float;

	public function new(eventtype:ScriptEventType, cancleable:Bool, note:Note, doesNotesplash:Bool = false)
	{
		super(eventtype, cancleable);
		resetEvent(eventtype, cancleable, {note: note, doesNotesplash: doesNotesplash});
	}

	public function setNote(note:Note, doesNotesplash:Bool = false):Void
	{
		this.note = note;
		this.gfNote = this.note.gfNote;
		this.isspecial = this.note.special;
		this.sustainInfo = {sustainLength: this.note.sustainLength, isSustain: this.note.isSustainNote};
		this.doesNotesplash = doesNotesplash;
		this.blockHit = this.note.blockHit;
		this.gfNote = this.note.gfNote;
		this.animSuffix = this.note.animSuffix;
		this.healthchange = this.note.missHealth;
		this.hitCausesMiss = this.note.hitCausesMiss;
		this.noteType = this.note.noteType;
	}

	public override function resetEvent(eventtype:ScriptEventType, cancleable:Bool, ?data:Dynamic):Void
	{
		super.resetEvent(eventtype, cancleable);
		note = null;
		isspecial = false;
		sustainInfo = null;
		doesNotesplash = false;
		blockHit = false;
		gfNote = false;
		hitCausesMiss = false;
		noteType = null;
		animSuffix = "";
		healthchange = 0;
		if (data != null && data.note != null)
			setNote(data.note, data.doesNotesplash == true);
	}

	public override function toString():String
	{
		return 'NoteMissEvent(type=' + type + ', iscancleable=' + iscancleable + ', cancled=' + cancled + ', note=' + note + ', isspecial=' + isspecial
			+ ', sustainInfo=' + Std.string(sustainInfo) + ', doesNotesplash=' + doesNotesplash + ', blockHit=' + blockHit + ', healthchange=' + healthchange
			+ ')';
	}
}

class NoteHitEvent extends BasicEvent
{
	/**
	 * Called when a note is hit.
	 *
	 * This event IS cancelable! Canceling this event will prevent the note hit from being registered.
	 */
	/**
	 * The note that was hit.
	 */
	public var note:Note;

	public var gfNote:Bool = false;

	/**
	 * Whether the note hit was of the special type.
	 */
	public var isspecial:Bool;

	/** holds relitive sustain information for the note **/
	public var sustainInfo:SustainInfo;

	/**
	 * Whether this note hit causes a note splash to display.
	 * Defaults to true only on "sick" notes.
	 */
	public var doesNotesplash:Bool = false;

	/** whether this note blocks a hit**/
	public var blockHit:Bool = false;

	public var hitCausesMiss:Bool = false;

	public var noteType:String;

	public var animSuffix:String = "";

	/** the change in health caused by this note hit **/
	public var healthchange:Float;

	public var ranking(default, null):Rating;

	public function new(eventtype:ScriptEventType, cancleable:Bool, note:Note, doesNotesplash:Bool = false)
	{
		super(eventtype, cancleable);
		// resetEvent(eventtype, cancleable, {note: note, doesNotesplash: doesNotesplash});
	}

	public function setNote(note:Note, doesNotesplash:Bool = false):Void
	{
		this.note = note;
		this.gfNote = this.note.gfNote;
		this.isspecial = this.note.special;
		this.sustainInfo = {sustainLength: this.note.sustainLength, isSustain: this.note.isSustainNote};
		this.doesNotesplash = doesNotesplash;
		this.blockHit = this.note.blockHit;
		this.animSuffix = this.note.animSuffix;
		this.healthchange = this.note.hitHealth;
		this.hitCausesMiss = this.note.hitCausesMiss;
		this.noteType = this.note.noteType;
	}

	public override function resetEvent(eventtype:ScriptEventType, cancleable:Bool, ?data:Dynamic):Void
	{
		super.resetEvent(eventtype, cancleable);

		this.ranking = data.ranking;
		healthchange = 0;
		if (data.note != null)
			setNote(data.note, data.doesNotesplash == true);
	}

	public override function toString():String
	{
		return 'NoteHitEvent(type=' + type + ', iscancleable=' + iscancleable + ', cancled=' + cancled + ', note=' + note + ', isspecial=' + isspecial
			+ ', sustainInfo=' + Std.string(sustainInfo) + ', doesNotesplash=' + doesNotesplash + ', blockHit=' + blockHit + ', healthchange=' + healthchange
			+ ')';
	}
}

class EventDispatcher
{
	static public var dispatcherMap:Map<String, BasicEvent> = new Map<String, BasicEvent>();

	static public function setupeventmap():Void
	{
		// yes, their are better ways, will i do them, no. - past kuru
		dispatcherMap.set(ScriptEventType.PRE_CREATE.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.STATE_CREATE.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.DESTROY.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.UPDATE.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.PAUSE.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.RESUME.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.BEAT_HIT.toString(), new BeatHitEvent(null, false, 0));
		dispatcherMap.set(ScriptEventType.STEP_HIT.toString(), new StepHitEvent(null, false, 0));
		dispatcherMap.set(ScriptEventType.NOTE_HIT.toString(), new NoteHitEvent(null, false, null));
		dispatcherMap.set(ScriptEventType.NOTE_MISS.toString(), new NoteMissEvent(null, false, null));
		dispatcherMap.set(ScriptEventType.NOTE_HOLD_DROP.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.NOTE_GHOST_MISS.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.SONG_EVENT.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.SONG_START.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.SONG_END.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.COUNTDOWN_START.toString(), new CountdownStartEvent(null, false, 0));
		dispatcherMap.set(ScriptEventType.COUNTDOWN_STEP.toString(), new CountdownStepEvent(null, false, 0, null, null));
		dispatcherMap.set(ScriptEventType.COUNTDOWN_END.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.GAME_OVER.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.SONG_RETRY.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.KEY_DOWN.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.KEY_UP.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.STATE_CHANGE_BEGIN.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.STATE_CHANGE_END.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.SUBSTATE_OPEN_BEGIN.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.SUBSTATE_OPEN_END.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.SUBSTATE_CLOSE_BEGIN.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.SUBSTATE_CLOSE_END.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.FOCUS_GAINED.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.FOCUS_LOST.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.DIALOGUE_START.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.DIALOGUE_LINE.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.DIALOGUE_COMPLETE_LINE.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.DIALOGUE_SKIP.toString(), new BasicEvent(null, false));
		dispatcherMap.set(ScriptEventType.DIALOGUE_END.toString(), new BasicEvent(null, false));
	}

	static public function dispatchEvent(eventtype:ScriptEventType, cancleable:Bool, data:Dynamic):Dynamic
	{
		// this needs to also have support for auto calling scripts BEFORE the event is dispatched
		var event:BasicEvent = dispatcherMap.get(eventtype.toString());
		event.resetEvent(eventtype, cancleable, data);

		var ingame:Bool = chorus.backend.scripting.HaxeScript.isInPlayState();

		switch (ingame)
		{
		}

		/*
			switch (eventtype.toString())
			{
				default:
					// script calls, adding custom logic will go in its own case blocks for each event type
			}
			// add actual script call handling here, if needed
		 */
		if (eventtype.scriptFuncName() != '')
		{
			Scripthandler.dispatchevent(eventtype.scriptFuncName(), [event]); // once modules are added make these run both gamescripts AND modules
		}

		return event;
	}

	static public function resetMap():Void
	{
		for (event in dispatcherMap)
			event.destroy();
		dispatcherMap.clear();
		setupeventmap();
	}
}
