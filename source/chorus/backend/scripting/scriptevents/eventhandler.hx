package chorus.backend.scripting.scriptevents;

import flixel.util.FlxDestroyUtil.IFlxDestroyable;

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
	public var CREATE = 'CREATE';

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
	 * Called when a note comes on screen and starts approaching the strumline.
	 *
	 * This event is not cancelable.
	 */
	public var NOTE_INCOMING = 'NOTE_INCOMING';

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
	 * Called when the game has finished loading the notes from JSON.
	 * This allows modders to mutate the notes before they are used in the song.
	 *
	 * This event is not cancelable.
	 */
	public var SONG_LOADED = 'SONG_LOADED';

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

class BasicEvent
{
	/**
	 * The type associated with the event.
	 */
	public var type(default, null):ScriptEventType;

	/* this will tell the game whether it is cancelable, set this to false to prevent canceling in scripts */
	var iscancleable:Bool = true;

	/* this will tell the game whether the event has been canceled */
	var cancled:Bool = false;

	function new(eventtype:ScriptEventType, cancleable:Bool)
	{
		type = eventtype;
		iscancleable = cancleable;
	}

	function toString():String
	{
		return 'Event(type=' + type + ', iscancleable=' + iscancleable + ', cancled=' + cancled + ')';
	}
}

typedef SustainInfo =
{
	public var sustainLength:Int;
	public var isSustain:Bool;
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
	public var note:Int;

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

	/** the change in health caused by this note hit **/
	public var healthchange:Float;

	function new(eventtype:ScriptEventType, cancleable:Bool, note:Note, doesNotesplash:Bool = false)
	{
		super(eventtype, cancleable);
		this.note = note;
		this.isspecial = this.note.special;
		this.sustainInfo = {sustainLength: this.note.sustainLength, isSustain: this.note.isSustain};
		this.doesNotesplash = doesNotesplash;
		this.blockHit = this.note.blockHit;
		this.healthchange = this.note.healthchange;
	}
}

class EventHandler implements IFlxDestroyable
{
	public function new()
	{
	}

	public function destroy():Void
	{
	}
}
