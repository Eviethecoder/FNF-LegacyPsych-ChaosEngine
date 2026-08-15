package objects;

import Character.AnimArray;
import data.DialogueBoxutil.DialogueBoxData as BoxData;
import shaders.RGBPalette;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;

class DialogueBoxSprite extends FunkinSprite
{
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public var animationsArray:Array<AnimArray> = [];
	public var spriteType:String = 'sparrow'; // for future proofing
	public var boxData:BoxData;
	public var rgbshader:RGBPalette;

	public function new(x:Float = 0, y:Float = 0, boxData:BoxData)
	{
		super(x, y);
		this.boxData = boxData;
		rgbshader = new RGBPalette();
		rgbshader.r = FlxColor.fromRGB(boxData.basergb.r[0], boxData.basergb.r[1], boxData.basergb.r[2]);
		rgbshader.g = FlxColor.fromRGB(boxData.basergb.g[0], boxData.basergb.g[1], boxData.basergb.g[2]);
		rgbshader.b = FlxColor.fromRGB(boxData.basergb.b[0], boxData.basergb.b[1], boxData.basergb.b[2]);
		this.shader = rgbshader.shader;
		setupSprite();
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);
	}

	function setupSprite():Void
	{
		if (boxData == null)
		{
			return;
		}
		var theFrames:FlxAtlasFrames;
		var loadedExtraFrames:Map<String, Bool> = [];

		theFrames = Paths.getSparrowAtlas('Huds/Dialogue/boxes/' + boxData.sprite);

		loadedExtraFrames.set('Huds/Dialogue/boxes/' + boxData.sprite, true);

		if (boxData.animationdata != null)
		{
			for (animData in boxData.animationdata)
			{
				if (!loadedExtraFrames.exists(animData.frames))
					continue;

				theFrames.addAtlas(Paths.getSparrowAtlas(animData.frames));
				loadedExtraFrames.set(animData.frames, true);
			}
		}
		frames = theFrames;

		animationsArray = boxData.animationdata;
		if (animationsArray == null || animationsArray.length < 1)
		{
			return;
		}

		for (anims in animationsArray)
		{
			var animAnim:String = '' + anims.anim;
			var animName:String = '' + anims.name;
			var animFps:Int = anims.fps;
			var animLoop:Bool = !!anims.loop;
			var animIndices:Array<Int> = anims.indices;

			switch (spriteType)
			{
				case 'packer' | 'sparrow' | 'texture':
					if (animIndices != null && animIndices.length > 0)
					{
						animation.addByIndices(animAnim, animName, animIndices, '', animFps, animLoop, false, false);
					}
					else
					{
						animation.addByPrefix(animAnim, animName, animFps, animLoop);
					}
			}

			if (anims.offsets != null && anims.offsets.length > 1)
			{
				addOffset(anims.anim, anims.offsets);
			}
		}
	}

	public function addOffset(name:String, offsets:Array<Float>):Void
	{
		if (offsets == null)
		{
			offsets = [0, 0];
		}

		animOffsets[name] = offsets;
	}
}
