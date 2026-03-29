package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import shaders.RGBPalette;
import flixel.util.FlxColor;
import shaders.RGBPalette.RGBShaderReference;

typedef RGB = {
	r:Null<Int>,
	g:Null<Int>,
	b:Null<Int>
}

class NoteSplash extends FlxSprite
{
	
	private var idleAnim:String;
	public var rgbShader:RGBShaderReference;
	private var textureLoaded:String = null;
	public var rgbColor:Array<RGB> = null;
	var offsets:Array<Float>; 
	var alphaoveride:Float;
	

	public function new(x:Float = 0, y:Float = 0, ?notedata:Int = 0, note:Note = null) {
		super(x, y);


		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
		rgbShader = new RGBShaderReference(this, new RGBPalette());
		rgbShader.enabled = PlayState.instance.hud.bars.noteskin.usergbshader;
		alphaoveride = PlayState.instance.hud.bars.noteskin.alphaoveride;
		

		loadAnims(skin);
		

		

		setupsplash(x, y, notedata);
		antialiasing = ClientPrefs.data.globalAntialiasing;
	}

	public function setupsplash(x:Float, y:Float, note:Int = 0, texture:String = null, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0) {
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		alpha = 0.6;

		if(texture == null) {
			texture = 'noteSplashes';
			if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) texture = PlayState.SONG.splashSkin;
		}

		if(textureLoaded != texture) {
			loadAnims(texture);
		}
		offsets = PlayState.instance.hud.hudData.getnotesplashoffsets();
		offset.set(offsets[0], offsets[1]);

		var animNum:Int = FlxG.random.int(1, 2);
		animation.play('note' + note + '-' + animNum, true);
		if(animation.curAnim != null)animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
	}

	public function setupNoteSplash(x:Float, y:Float, noteData:Int = 0, note:Note = null, texture:String = null, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0) {
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		if(alphaoveride != 0.6){
			alpha = alphaoveride;
		}
		 else {
			alpha = 0.6;
		}

		if(texture == null) {
			texture = 'noteSplashes';
			if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) texture = PlayState.SONG.splashSkin;
		}

		if(textureLoaded != texture) {
			loadAnims(texture);
		}
	
		offset.set(offsets[0], offsets[1]);

		var animNum:Int = FlxG.random.int(1, 2);
		animation.play('note' + noteData + '-' + animNum, true);
		var tempShader:RGBPalette = null;
		if(animation.curAnim != null)animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
		if ((note == null || note.noteSplashData.useRGBShader) && (PlayState.SONG == null ))
			{
				tempShader = new RGBPalette();
				// If Note RGB is enabled:
				if ((note == null || !note.noteSplashData.useGlobalShader))
				{
					var colors = rgbColor;
					if (colors != null)
					{
						for (i in 0...colors.length)
						{
							if (i > 2) break;

							var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData + 3];
							
							var rgb = colors[i];
							if (rgb == null)
							{
								if (i == 0) tempShader.r = arr[0];
								else if (i == 1) tempShader.g = arr[1];
								else if (i == 2) tempShader.b = arr[2];
								continue;
							}

							var r:Null<Int> = rgb.r; 
							var g:Null<Int> = rgb.g;
							var b:Null<Int> = rgb.b;

							if (r == null || Math.isNaN(r) || r < 0) r = arr[0];
							if (g == null || Math.isNaN(g) || g < 0) g = arr[1];
							if (b == null || Math.isNaN(b) || b < 0) b = arr[2];

							var color:FlxColor = FlxColor.fromRGB(r, g, b);
							if (i == 0) tempShader.r = color;
							else if (i == 1) tempShader.g = color;
							else if (i == 2) tempShader.b = color;
						}
					}
					else tempShader = Note.initializeGlobalRGBShader(noteData, note != null ? note.mustPress : false);

					if (note != null)
					{
						if (note.noteSplashData.r != -1) tempShader.r = note.noteSplashData.r;
						if (note.noteSplashData.g != -1) tempShader.g = note.noteSplashData.g;
						if (note.noteSplashData.b != -1) tempShader.b = note.noteSplashData.b;
					}
				}
			}
			
			else tempShader = Note.initializeGlobalRGBShader(noteData, note != null ? note.mustPress : false);

			rgbShader.parent.copyValues(tempShader);
	}
	

	function loadAnims(skin:String) {
		frames = Paths.getSparrowAtlas(skin);
		for (i in 1...3) {
			animation.addByPrefix("note1-" + i, "splash", 24, false);
			animation.addByPrefix("note2-" + i,  "splash", 24, false);
			animation.addByPrefix("note0-" + i,  "splash", 24, false);
			animation.addByPrefix("note3-" + i,  "splash", 24, false);
		}
	}

	override function update(elapsed:Float) {
		if(animation.curAnim != null)if(animation.curAnim.finished) kill();

		super.update(elapsed);
	}
}

