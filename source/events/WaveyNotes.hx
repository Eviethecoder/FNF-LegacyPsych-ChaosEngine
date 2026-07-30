package events;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxTween.FlxTweenType;
import PlayState;
import objects.Strumline;
import flixel.FlxG;
import Note;

class WaveyNotes extends BaseEvent
{
	// Per-note tween map — each live note owns exactly one looping tween
	var noteTweenMap:Map<Note, FlxTween> = new Map();

	var randomness:Bool;
	var waveActive:Bool = false;

	// Cached wave params used by update() when assigning tweens to newly-spawned notes
	var _amplitude:Float = 10;
	var _phaseRadians:Float = 0;
	var _cycleSeconds:Float = 1;
	var _laneOffsets:Map<Strumline, Int> = new Map();

	public function new()
	{
		super();
		eventName = 'WaveyNotes';
	}

	override public function triggerEvent():Void
	{
		var disabled:Bool = grabeventBool('Disabled');
		if (disabled)
		{
			stopWave(true);
			return;
		}

		var amplitude:Float = grabeventFloat('Amplitude');
		if (amplitude == 0)
			amplitude = 10;

		debug.Consolehandler.print('amplitude: ' + amplitude);
		var speed:Float = grabeventFloat('Speed');
		if (speed <= 0)
			speed = 5;

		var phaseOffset:Float = grabeventFloat('PhaseOffset');
		if (phaseOffset == 0)
			phaseOffset = 20;

		randomness = grabeventBool('Add Randomness');

		var target:String = grabeventString('Target');
		if (target == null || target.length == 0)
			target = 'Both';

		startWave(target, amplitude, speed, phaseOffset);
	}

	function startWave(target:String, amplitude:Float, speed:Float, phaseOffset:Float):Void
	{
		stopWave(true);

		var targetLower:String = target.toLowerCase();
		var applyPlayer:Bool = (targetLower == 'both' || targetLower == 'all' || targetLower == 'player' || targetLower == 'bf');
		var applyOpponent:Bool = (targetLower == 'both' || targetLower == 'all' || targetLower == 'opponent' || targetLower == 'dad');

		if (!applyPlayer && !applyOpponent)
		{
			applyPlayer = true;
			applyOpponent = true;
		}

		var ps:PlayState = PlayState.instance;
		if (ps == null)
			return;

		_amplitude = amplitude;
		_phaseRadians = phaseOffset * Math.PI / 180;
		_cycleSeconds = Math.max(0.05, 1 / speed);

		_laneOffsets = new Map();
		if (applyOpponent)
			_laneOffsets.set(ps.opponentStrumline, 0);
		if (applyPlayer)
			_laneOffsets.set(ps.playerStrumline, 4);

		waveActive = true;
		// Add self to PlayState so update() is called every frame
		ps.add(this);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!waveActive)
			return;

		// Assign a fresh tween to any note that just became alive and has none yet
		for (strumline in _laneOffsets.keys())
		{
			var laneOffset:Int = _laneOffsets.get(strumline);
			for (daNote in strumline.notes.members)
			{
				if (daNote == null || !daNote.alive)
					continue;
				if (noteTweenMap.exists(daNote))
					continue;

				var note:Note = daNote;
				var lo:Int = laneOffset;
				// Offset the tween start so notes at different song positions begin at different wave phases
				var startDelay:Float = ((note.strumTime * 0.001) * 1.5) % _cycleSeconds;
				var tween:FlxTween = FlxTween.num(0, Math.PI * 2, _cycleSeconds, {type: FlxTweenType.LOOPING, startDelay: startDelay}, function(v:Float)
				{
					if (note == null || !note.alive)
						return;
					var phase:Float = (note.noteData + lo) * _phaseRadians;
					var finalAmplitude:Float = _amplitude;
					if (randomness)
						finalAmplitude += FlxG.random.int(10, 25);
					note.directionMod = Math.sin(v + phase) * finalAmplitude;
				});
				noteTweenMap.set(note, tween);
			}
		}

		// Clean up tweens for notes that have died/been recycled
		var deadNotes:Array<Note> = [];
		for (note in noteTweenMap.keys())
		{
			if (note == null || !note.alive)
				deadNotes.push(note);
		}
		for (note in deadNotes)
		{
			var tween:FlxTween = noteTweenMap.get(note);
			if (tween != null)
				tween.cancel();
			noteTweenMap.remove(note);
		}
	}

	function stopWave(resetDirectionMod:Bool):Void
	{
		waveActive = false;

		for (tween in noteTweenMap)
		{
			if (tween != null)
				tween.cancel();
		}
		noteTweenMap.clear();
		_laneOffsets = new Map();

		var ps:PlayState = PlayState.instance;
		if (ps != null)
			ps.remove(this); // unregister from update loop

		if (!resetDirectionMod)
			return;

		if (ps == null)
			return;

		for (daNote in ps.opponentStrumline.notes.members)
		{
			if (daNote != null)
				daNote.directionMod = 0;
		}

		for (daNote in ps.playerStrumline.notes.members)
		{
			if (daNote != null)
				daNote.directionMod = 0;
		}
	}
}
