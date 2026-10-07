package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import shaders.RGBPalette;
import utility.NoteSkinHelper;
import Character.AnimArray;
import shaders.RGBPalette.RGBShaderReference;
import flixel.util.FlxColor;

using StringTools;

class StrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	public var animOffsets:Null<Map<String, Array<Dynamic>>>;

	private var noteData:Int = 0;
	private var ispixel:Bool = false;

	public var sustainSplash:SustainSplash;
	public var direction:Float = 90; // plan on doing scroll directions soon -bb
	public var downScroll:Bool = false; // plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;

	private var player:Int;
	var isPlayer:Bool;
	var arr:Array<Int>;

	public var useRGBShader:Bool = true;
	public var texture(default, set):String = null;

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int)
	{
		isPlayer = false;
		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end
		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData, isPlayer));
		rgbShader.enabled = false;
		switch (player)
		{
			case 0:
				isPlayer = false;
			case 1:
				isPlayer = true;
		}
		arr = NoteSkinHelper.getNoteskinRgb(isPlayer)[leData];
		noteData = leData;
		this.player = player;

		if (leData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		this.noteData = leData;
		super(x, y);

		var skin:String = NoteSkinHelper.getNoteskinFrames(isPlayer);
		texture = skin; // Load texture and anims

		sustainSplash = new SustainSplash(this);

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if (animation.curAnim != null)
			lastAnim = animation.curAnim.name;
		var strumlineData = NoteSkinHelper.getStrumlineData();
		frames = Paths.getSparrowAtlas(texture);

		if (strumlineData != null)
		{
			switch (Math.abs(noteData) % 4)
			{
				case 0:
					addAnimation(strumlineData.leftstatic, 'static');
					addAnimation(strumlineData.leftpressed, 'pressed');
					addAnimation(strumlineData.leftconfirm, 'confirm');
				case 1:
					addAnimation(strumlineData.downstatic, 'static');
					addAnimation(strumlineData.downpressed, 'pressed');
					addAnimation(strumlineData.downconfirm, 'confirm');
				case 2:
					addAnimation(strumlineData.upstatic, 'static');
					addAnimation(strumlineData.uppressed, 'pressed');
					addAnimation(strumlineData.upconfirm, 'confirm');
				case 3:
					addAnimation(strumlineData.rightstatic, 'static');
					addAnimation(strumlineData.rightpressed, 'pressed');
					addAnimation(strumlineData.rightconfirm, 'confirm');
			}
		}

		antialiasing = ClientPrefs.data.globalAntialiasing;
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();

		if (lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	function addAnimation(data:AnimArray, animnameoveride:String = null):Void
	{
		if (data == null)
			return;

		var animationName:String = animnameoveride != null ? animnameoveride : data.anim;
		if (data.indices != null && data.indices.length > 0)
			animation.addByIndices(animationName, data.name, data.indices, '', data.fps, data.loop);
		else
			animation.addByPrefix(animationName, data.name, data.fps, data.loop);

		if (data.offsets != null && data.offsets.length > 1)
			addOffset(animationName, data.offsets);
	}

	public function postAddedToGroup()
	{
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
	}

	public function addOffset(name:String,
			offsets:Array<Float>) // we need to edit this, but make sure if their is no extra offsets then it defaults to 0, 0 instead of null, which causes errors
	{
		if (offsets == null)
			offsets = [0, 0];

		animOffsets[name] = offsets;
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}

		if (animation.curAnim.name == 'confirm' && !ispixel)
		{
			centerOrigin();
		}

		super.update(elapsed);
	}

	/**
	 * Helper function that adjusts the offset automatically to center the bounding box within the graphic.  modified to add our offsets we add to the total
	 *
	 * @param   AdjustPosition   Adjusts the actual X and Y position just once to match the offset change.
	 */
	public function centerAnimationOffsets(animname:String = '', AdjustPosition:Bool = false):Void
	{
		offset.x = (frameWidth - width) * 0.5;
		offset.y = (frameHeight - height) * 0.5;
		if (animname != '')
		{
			var daOffset = animOffsets.get(animname);
			var x:Float = 0;
			var y:Float = 0;
			if (daOffset != null && daOffset.length > 1)
			{
				x += daOffset[0];
				y += daOffset[1];
				offset.x += x;
				offset.y += y;
			}
		}
		if (AdjustPosition)
		{
			x += offset.x + x;
			y += offset.y + y;
		}
	}

	public function playAnim(anim:String, ?force:Bool = false)
	{
		animation.play(anim, force);
		centerAnimationOffsets(anim);

		centerOrigin();

		if (animation.curAnim.name == 'confirm')
		{
			centerOrigin();
		}
		if (useRGBShader)
			rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}
}

class SustainSplash extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var strum:StrumNote;

	override public function new(strum:StrumNote)
	{
		super();
		this.strum = strum;

		@:privateAccess
		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(strum.noteData, strum.isPlayer));

		frames = Paths.getSparrowAtlas("sustain_cover");
		animation.addByPrefix('cover', 'sustain cover pre0', 24, false);
		animation.addByPrefix('splash', 'sustain cover end0', 24, false);
		animation.addByPrefix('loop', 'sustain cover0', 24);
		animation.play("loop");
		updateHitbox();
		visible = false;
		antialiasing = ClientPrefs.data.globalAntialiasing;

		scale.set(strum.scale.x / 0.7, strum.scale.y / 0.7);
		updateHitbox();
	}

	public var updatedThisFrame:Bool = false;

	public inline function show()
	{
		updatedThisFrame = true;
		visible = true;
		if (animation.curAnim.name != "loop")
		{
			animation.play("cover");
			center();
		}
	}

	public inline function hide(miss:Bool = false)
	{
		if (animation.curAnim.name == "splash")
			return;

		updatedThisFrame = true;
		if (miss)
			visible = false;
		if (animation.curAnim.name != "splash")
		{
			animation.play("splash");
			center();
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		updatedThisFrame = false;

		if (animation.curAnim.finished)
		{
			if (animation.curAnim.name == "cover")
				animation.play("loop");
			if (animation.curAnim.name == "splash")
				visible = false;
		}

		// if (animation.curAnim.name != "splash") center();
		// updateHitbox();
		center();
	}

	public function center()
	{
		centerOffsets();
		x = strum.x + (strum.width / 2) - (width / 2);
		y = strum.y + (strum.height / 2) - (height / 2);
	}
}
