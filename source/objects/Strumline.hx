package objects;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import Section.SwagSection;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxSort;
import editors.ChartingState;
import Song.ChartNoteData;

using StringTools;

/**
 * Represents a single lane of the game (player or opponent).
 * Owns its 4 strum arrows, its note queue, and handles note spawning,
 * movement and killing independently. PlayState creates two instances of
 * this class and wires up the hit/miss callbacks.
 */
class Strumline extends FlxSpriteGroup
{
	// ─── public fields ───────────────────────────────────────────────────────

	/** The 4 receptor / strum-arrow sprites for this lane. */
	public var strumNotes:FlxTypedSpriteGroup<StrumNote>;

	/**
	 * Active notes that are currently on screen.
	 * This is the same FlxTypedGroup that was added to PlayState.noteGroup,
	 * so rendering still goes through the existing camera layers.
	 */
	public var notes:FlxTypedSpriteGroup<Note>;

	/** Notes waiting to appear on screen, sorted ascending by strumTime. */
	public var unspawnNotes:Array<Note> = [];

	/** Whether this strumline belongs to the player (true) or opponent (false). */
	public var isPlayer:Bool;

	/** Current scroll speed for this lane. */
	public var songSpeed(default, set):Float = 1;

	/** How far ahead (in ms) to pre-spawn notes. */
	public var spawnTime:Float = 2000;

	/** Notes older than noteKillOffset past their strumTime are destroyed. */
	public var noteKillOffset:Float = 350;

	/** When true the CPU plays this strumline automatically. */
	public var cpuControlled:Bool = false;

	// ─── callbacks (assigned by PlayState) ───────────────────────────────────

	/** Called when a note should be hit (player good-hit or cpu/opponent auto-hit). */
	public var onNoteHit:Note->Void = null;

	/** Called when a player note was missed (ran off screen without being hit). */
	public var onNoteMiss:Note->Void = null;

	/**
	 * Backward-compatible script callback hook.
	 * Hit handling is now owned by Strumline; this callback is optional.
	 */
	public var onNoteProcessed:Note->Void = null;

	// ─── private ─────────────────────────────────────────────────────────────
	var _strumY:Float = 10;

	// ─────────────────────────────────────────────────────────────────────────
	public var charlist:Array<Character> = [];

	/**
	 * @param x          Horizontal position of the lane (usually 0 – arrows set their own x).
	 * @param strumY     Vertical position used when spawning the strum arrows.
	 * @param isPlayer   True for the player lane, false for the opponent lane.
	 * @param noteGroup  The FlxTypedGroup<Note> owned by PlayState that notes are
	 *                   inserted into so they're drawn in the correct layer order.
	 */
	public function new(x:Float = 0, strumY:Float = 50, isPlayer:Bool = false)
	{
		super(x, strumY);
		this.isPlayer = isPlayer;
		this._strumY = strumY;

		strumNotes = new FlxTypedSpriteGroup<StrumNote>();

		notes = new FlxTypedSpriteGroup<Note>();
		add(strumNotes);
		add(notes);
	}

	function set_songSpeed(value:Float):Float
	{
		if (PlayState.instance.generatedMusic)
		{
			var ratio:Float = value / songSpeed;
			// Resize notes in both strumlines; each strumline now owns its notes
			resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	// ─── Arrow generation ─────────────────────────────────────────────────────

	/**
	 * Spawns the 4 strum-arrow sprites, positions them, and applies the
	 * intro tween (if needed).  Mirrors the old PlayState.generateStaticArrows.
	 *
	 * @param isStoryMode    Skips the tween when true.
	 * @param skipTween      Skips the tween regardless of story mode.
	 */
	public function generateArrows(isStoryMode:Bool, skipTween:Bool):Void
	{
		var player:Int = isPlayer ? 1 : 0;

		for (i in 0...4)
		{
			var targetAlpha:Float = 1;
			if (!isPlayer)
			{
				if (!ClientPrefs.data.opponentStrums)
					targetAlpha = 0;
				else if (ClientPrefs.data.middleScroll)
					targetAlpha = 0.35;
			}

			// Base X – will be adjusted for middle-scroll opponent below
			var baseX:Float = ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;

			var babyArrow:StrumNote = new StrumNote(baseX, _strumY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;

			if (!isPlayer && ClientPrefs.data.middleScroll)
			{
				babyArrow.x += 310;
				if (i > 1) // Up and Right columns
					babyArrow.x += FlxG.width / 2 + 25;
			}

			if (!isStoryMode && !skipTween)
			{
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
				babyArrow.alpha = targetAlpha;

			strumNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	// ─── Note generation ──────────────────────────────────────────────────────

	/**
	 * Parses all song sections, keeps only the notes that belong to *this*
	 * strumline, builds Note + sustain objects, and sorts them into
	 * unspawnNotes.  Also registers note types in the supplied map.
	 *
	 * @param sections       The SONG.notes array (all sections).
	 * @param speed          Scroll speed for this lane.
	 * @param noteTypeMap    Map<String,Bool> for preloading note-type scripts.
	 */
	public function generateNotes(sections:Array<SwagSection>, noteTypeMap:Map<String, Bool>):Void
	{
		var noteDatas:Array<ChartNoteData> = [];

		for (section in sections)
		{
			for (i in 0...section.sectionNotes.length)
			{
				final songNotes:Array<Dynamic> = section.sectionNotes[i];

				if (songNotes[1] < 0)
					continue;

				var gottaHitNote:Bool = section.mustHitSection;
				if (songNotes[1] > 3)
					gottaHitNote = !section.mustHitSection;

				// Only keep notes that belong to this lane
				if (gottaHitNote != isPlayer)
					continue;

				final leNoteData:ChartNoteData = {
					time: songNotes[0],
					id: Std.int(songNotes[1] % 4),
					sLen: songNotes[2],
					strumLine: gottaHitNote ? 1 : 0,
					isGfNote: (section.gfSection && (songNotes[1] < 4)),
					type: songNotes[3]
				};

				if (!Std.isOfType(songNotes[3], String))
					leNoteData.type = ChartingState.noteTypeList[songNotes[3]];

				// Remove ghost jacks (duplicate notes in the same step)
				if (i != 0)
				{
					for (evilNoteData in noteDatas)
					{
						if (evilNoteData.id == leNoteData.id && Math.abs(evilNoteData.time - leNoteData.time) < 1.0)
						{
							evilNoteData.dispose();
							noteDatas.remove(evilNoteData);
						}
					}
				}

				noteDatas.push(leNoteData);
			}
		}

		// Build Note objects
		for (note in noteDatas)
		{
			var oldNote:Note = unspawnNotes.length > 0 ? unspawnNotes[unspawnNotes.length - 1] : null;

			var swagNote:Note = new Note(note.time, note.id, oldNote, isPlayer);
			swagNote.sustainLength = note.sLen;
			swagNote.gfNote = note.isGfNote;
			swagNote.noteType = note.type;
			swagNote.scrollFactor.set();
			swagNote.songSpeed = songSpeed;

			unspawnNotes.push(swagNote);

			// Sustain notes
			var floorSus:Int = Math.floor(swagNote.sustainLength / Conductor.stepCrochet);
			if (floorSus > 0)
			{
				for (susNote in 0...floorSus + 1)
				{
					oldNote = unspawnNotes[unspawnNotes.length - 1];
					var sustainNote:Note = new Note(note.time
						+ (Conductor.stepCrochet * susNote)
						+ (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), note.id, oldNote,
						isPlayer, true);

					// Opponent sustains use oppsongSpeed for timing offset
					if (!isPlayer)
					{
						var ps:PlayState = PlayState.instance;
						sustainNote.strumTime = note.time + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2));
					}

					sustainNote.gfNote = note.isGfNote;
					sustainNote.noteType = swagNote.noteType;
					sustainNote.scrollFactor.set();
					swagNote.tail.push(sustainNote);
					sustainNote.parent = swagNote;
					unspawnNotes.push(sustainNote);

					_applyNoteXOffset(sustainNote, note.id);
				}
			}

			_applyNoteXOffset(swagNote, note.id);

			if (noteTypeMap != null && !noteTypeMap.exists(swagNote.noteType))
				noteTypeMap.set(swagNote.noteType, true);
		}

		unspawnNotes.sort(function(a:Note, b:Note):Int
		{
			return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
		});
	}

	/** Apply the horizontal offset that puts notes over the correct side of the screen. */
	inline function _applyNoteXOffset(note:Note, noteId:Int):Void
	{
		if (isPlayer)
			note.x += FlxG.width / 2;
		else if (ClientPrefs.data.middleScroll)
		{
			note.x += 310;
			if (noteId > 1)
				note.x += FlxG.width / 2 + 25;
		}
	}

	// ─── Speed helpers ────────────────────────────────────────────────────────

	/** Called when PlayState.songSpeed changes so existing notes resize. */
	public function resizeByRatio(ratio:Float):Void
	{
		for (note in notes)
			note.resizeByRatio(ratio);
		for (note in unspawnNotes)
			note.resizeByRatio(ratio);
	}

	// ─── Cleanup helpers ─────────────────────────────────────────────────────

	/** Invalidate all notes at or before `time` (used by startOnTime / seek). */
	public function clearNotesBefore(time:Float):Void
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				PlayState.instance.invalidateNote(daNote);
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0)
		{
			var daNote:Note = notes.members[i];
			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				PlayState.instance.invalidateNote(daNote);
			}
			--i;
		}
	}

	/** Destroy every active/unspawned note in this strumline. */
	public function killAllNotes():Void
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;
			PlayState.instance.invalidateNote(daNote);
		}
		unspawnNotes = [];
	}

	// ─── Update ───────────────────────────────────────────────────────────────

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		_spawnNotes();

		if (!PlayState.instance.startedCountdown)
			return;

		_updateNotePositions();
		_resetSustainSplashes();
	}

	/** Move notes from unspawnNotes into the live notes group when they're close enough. */
	function _spawnNotes():Void
	{
		if (unspawnNotes[0] == null)
			return;

		var time:Float = spawnTime;
		if (songSpeed < 1)
			time /= songSpeed;
		if (unspawnNotes[0].multSpeed < 1)
			time /= unspawnNotes[0].multSpeed;

		while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
		{
			var dunceNote:Note = unspawnNotes[0];
			notes.insert(0, dunceNote);
			dunceNote.spawned = true;

			// Fire the script hook directly – no external callback needed
			var ps = PlayState.instance;
			if (ps != null)
				ps.setFunctionOnScripts('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote]);

			unspawnNotes.splice(0, 1);
		}
	}

	/** Move every live note to its correct screen position and handle hits/misses. */
	function _updateNotePositions():Void
	{
		var ps:PlayState = PlayState.instance;
		var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
		var sustainSetting:Int = ps.sustainSplashSetting;

		notes.forEachAlive(function(daNote:Note)
		{
			if (daNote.noteData < 0 || daNote.noteData >= strumNotes.members.length)
				return;

			var strum:StrumNote = strumNotes.members[daNote.noteData];
			if (strum == null)
				return;

			var strumX:Float = strum.x + daNote.offsetX;
			var strumY:Float = strum.y + daNote.offsetY;
			var strumAngle:Float = strum.angle + daNote.offsetAngle;
			var strumDirection:Float = strum.direction;
			var strumAlpha:Float = strum.alpha * daNote.multAlpha;
			var strumScroll:Bool = strum.downScroll;

			// Distance calculation (signed: positive = below strum, negative = above)
			var scrolledSpeed:Float = songSpeed;
			var dist:Float = 0.45 * (Conductor.songPosition - daNote.strumTime) * scrolledSpeed * daNote.multSpeed;
			daNote.distance = strumScroll ? dist : -dist;

			var angleDir:Float = strumDirection * Math.PI / 180;

			if (daNote.copyAngle)
				daNote.angle = strumDirection - 90 + strumAngle;
			if (daNote.copyAlpha)
				daNote.alpha = strumAlpha;
			if (daNote.copyX)
				daNote.x = strumX + Math.cos(angleDir) * daNote.distance;
			if (daNote.copyY)
			{
				daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

				if (strumScroll && daNote.isSustainNote)
				{
					if (StringTools.endsWith(daNote.animation.curAnim.name, 'end'))
					{
						daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * scrolledSpeed + (46 * (scrolledSpeed - 1));
						daNote.y -= 46 * (1 - (fakeCrochet / 600)) * scrolledSpeed;
						if (ps.stage.isPixelStage)
							daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
						else
							daNote.y -= 19;
					}
					daNote.y += (Note.swagWidth / 2) - (60.5 * (scrolledSpeed - 1));
					daNote.y += 27.5 * ((PlayState.SONG.bpm / 100) - 1) * (scrolledSpeed - 1);
				}
			}

			// ── Hit triggers ──────────────────────────────────────────────────

			// Opponent auto-hit – handle strum/note visuals here; callback handles cam/char/vocals/scripts
			if (!isPlayer && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
			{
				daNote.hitByOpponent = true;
				// Play strum confirm animation
				var time:Float = 0.15;
				if (daNote.isSustainNote
					&& daNote.animation.curAnim != null
					&& !StringTools.endsWith(daNote.animation.curAnim.name, 'end'))
					time += 0.15;
				strum.playAnim('confirm', true);
				strum.resetAnim = time;
				// Notify PlayState (now handled in Strumline)
				hitNote(daNote);
				// Invalidate non-sustain note
				if (!daNote.isSustainNote)
					invalidateNote(daNote);
			}

			// CPU / botplay player auto-hit
			if (isPlayer && cpuControlled && !daNote.blockHit && daNote.canBeHit)
			{
				if (daNote.isSustainNote)
				{
					if (daNote.canBeHit)
						hitNote(daNote);
				}
				else if (daNote.strumTime <= Conductor.songPosition)
				{
					hitNote(daNote);
				}
			}

			// ── Sustain visuals ───────────────────────────────────────────────

			if (daNote.isSustainNote && strum.sustainReduce)
				daNote.clipToStrumNote(strum);

			if (sustainSetting > 0 && daNote.isSustainNote && daNote.wasGoodHit && !strum.sustainSplash.updatedThisFrame)
			{
				if (StringTools.endsWith(daNote.animation.curAnim.name, "holdend"))
				{
					if (Conductor.songPosition >= daNote.strumTime)
						strum.sustainSplash.hide(!isPlayer || sustainSetting == 1);
				}
				else
					strum.sustainSplash.show();
			}

			// ── Kill late notes ───────────────────────────────────────────────

			if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
			{
				if (isPlayer && !cpuControlled && !daNote.ignoreNote && !ps.endingSong && (daNote.tooLate || !daNote.wasGoodHit))
				{
					if (onNoteMiss != null)
						onNoteMiss(daNote);
				}

				daNote.active = false;
				daNote.visible = false;
				ps.invalidateNote(daNote);
			}
		});
	}

	/** Reset every sustain-splash that wasn't touched this frame. */
	function _resetSustainSplashes():Void
	{
		if (PlayState.instance.sustainSplashSetting <= 0)
			return;
		for (strum in strumNotes.members)
		{
			if (!strum.sustainSplash.updatedThisFrame)
				strum.sustainSplash.hide(true);
		}
	}

	// ─── Public hit helpers ───────────────────────────────────────────────────

	/**
	 * Play the strum confirm animation for a given note column.
	 * Called by PlayState.goodNoteHit so strum logic stays here.
	 * For CPU/botplay lanes resetAnim is set so the arrow returns to static
	 * automatically; for human-input lanes it stays in confirm until next frame.
	 */
	public function confirmStrum(noteData:Int, isSustainNote:Bool):Void
	{
		var strum = strumNotes.members[Std.int(Math.abs(noteData))];
		if (strum == null)
			return;
		strum.playAnim('confirm', true);
		if (cpuControlled)
		{
			var time:Float = 0.15;
			if (isSustainNote && strum.animation.curAnim != null && !StringTools.endsWith(strum.animation.curAnim.name, 'end'))
				time += 0.15;
			strum.resetAnim = time;
		}
	}

	/**
	 * Handles note-hit logic for this lane.
	 * - Player lane: score/rating/health/animations and note invalidation.
	 * - Opponent lane: camera/character/vocals hooks and script callback.
	 */
	public function hitNote(note:Note):Void
	{
		if (isPlayer)
			_playerGoodNoteHit(note);
		else
			_opponentNoteHit(note);

		if (onNoteProcessed != null)
			onNoteProcessed(note);
	}

	function _opponentNoteHit(note:Note):Void
	{
		var ps:PlayState = PlayState.instance;
		if (ps == null)
			return;

		ps.setFunctionOnScripts('opponentNoteHit', [note]);
		if (Paths.formatToSongPath(PlayState.SONG.song) != 'tutorial')
			ps.camZooming = true;

		if (note.noteType == 'Hey!' && ps.stage.dad.animOffsets.exists('hey'))
		{
			ps.stage.dad.playAnim('hey', true);
			ps.stage.dad.specialAnim = true;
			ps.stage.dad.heyTimer = 0.6;
		}

		var animToPlay:String = ps.getSingAnimationByData(note.noteData);
		for (character in charlist)
		{
			if (character != null)
			{
				if (character.charactertype == 'dad')
				{
					character.playSingAnim(note, animToPlay, true);
					character.holdTimer = 0;
				}
			}
		}

		ps.vocals.set_dadVolume(1);
	}

	function _playerGoodNoteHit(note:Note):Void
	{
		var ps:PlayState = PlayState.instance;
		if (ps == null)
			return;

		if (note.wasGoodHit)
			return;
		if (cpuControlled && note.ignoreNote)
			return;

		var leData:Int = Math.round(Math.abs(note.noteData));
		ps.setFunctionOnScripts('goodNoteHit', [note]);

		note.wasGoodHit = true;
		if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);

		if (note.hitCausesMiss)
		{
			ps.noteMiss(note);
			if (!note.noteSplashDisabled && !note.isSustainNote)
				ps.spawnNoteSplashOnNote(note);

			if (!note.isSustainNote)
				invalidateNote(note);
			return;
		}

		var animToPlay:String = ps.getSingAnimationByData(leData) + note.animSuffix;
		if (note.gfNote)
		{
			if (ps.stage.gf != null)
			{
				ps.stage.gf.playSingAnim(note, animToPlay, true);
				ps.stage.gf.holdTimer = 0;
			}
		}
		else
		{
			for (character in charlist)
			{
				if (character != null)
				{
					if (character.charactertype == 'bf')
					{
						character.playSingAnim(note, animToPlay, true);
						character.holdTimer = 0;
					}
					if (note.noteType == 'Hey!')
					{
						if (character.animOffsets.exists('hey'))
						{
							character.playAnim('hey', true);
							character.specialAnim = true;
							character.heyTimer = 0.6;
						}
					}
				}
			}
			if (ps.stage.gf != null && ps.stage.gf.animOffsets.exists('cheer'))
			{
				ps.stage.gf.playAnim('cheer', true);
				ps.stage.gf.specialAnim = true;
				ps.stage.gf.heyTimer = 0.6;
			}
		}

		confirmStrum(note.noteData, note.isSustainNote);
		ps.vocals.unmutePlayer();

		if (!note.isSustainNote)
		{
			ps.combo += 1;
			if (ps.combo > 9999)
				ps.combo = 9999;
			ps.popUpScore(note);
			ps.health += note.hitHealth * ps.healthGain;
			invalidateNote(note);
		}
	}

	/**
	 * Remove any duplicate live notes that match daNote's data/time.
	 * Called by PlayState.noteMiss to clean up ghost jacks.
	 */
	public function removeDupeNotes(daNote:Note):Void
	{
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note
				&& daNote.noteData == note.noteData
				&& daNote.isSustainNote == note.isSustainNote
				&& Math.abs(daNote.strumTime - note.strumTime) < 1)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
	}

	/**
	 * Kill and remove a note from this lane's live notes group.
	 * PlayState.invalidateNote delegates here based on mustPress.
	 */
	public function invalidateNote(note:Note):Void
	{
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}
}
