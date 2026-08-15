package objects;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import data.DialogueBoxutil;
import data.DialogueBoxutil.DialogueBoxData as BoxData;
import data.DialogueBoxutil.RGBArray as RGBArray;
import flixel.util.FlxColor;
import misc.FlxBitmapTextFactory;
import com.bitdecay.lucidtext.TypeOptions;
import com.bitdecay.lucidtext.TextGroup;
import com.bitdecay.lucidtext.TypingGroup;
import flixel.FlxG;

class DialogueBox extends FlxSpriteGroup
{
	var boxData:BoxData;

	var rgbvalues:RGBArray;

	public var mainbox:DialogueBoxSprite;

	public var text:TypingGroup;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		rgbvalues = {r: [255, 255, 255], g: [255, 255, 255], b: [255, 255, 255]};
		boxData = DialogueBoxutil.loadFromJson('DialogueBox/default');
		rgbvalues.r = boxData.basergb.r;
		rgbvalues.g = boxData.basergb.g;
		rgbvalues.b = boxData.basergb.b;
		setupDialogueBox();
	}

	public function setrgbdata(r:Array<Int>, g:Array<Int>, b:Array<Int>):Void
	{
		var red:Int = FlxColor.fromRGB(r[0], r[1], r[2]);
		var green:Int = FlxColor.fromRGB(g[0], g[1], g[2]);
		var blue:Int = FlxColor.fromRGB(b[0], b[1], b[2]);
		rgbvalues.r = r;
		rgbvalues.g = g;
		rgbvalues.b = b;

		mainbox.rgbshader.r = red;
		mainbox.rgbshader.g = green;
		mainbox.rgbshader.b = blue;
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		mainbox.playAnim(AnimName, Force, Reversed, Frame);
	}

	function setupDialogueBox()
	{
		mainbox = new DialogueBoxSprite(0, 0, boxData);
		add(mainbox);
		FlxBitmapTextFactory.defaultColor = FlxColor.BLACK;
		TextGroup.textMakerFunc = FlxBitmapTextFactory.makeSimple;
		var letterSound = FlxG.sound.load(Paths.sound('clickText'));
		var margins:Array<Float> = [14, 8, 8, 8];
		var options = new TypeOptions(null, null, margins);
		options.fontSize = 32;
		text = new TypingGroup(FlxRect.get(mainbox.x, mainbox.y, mainbox.width, mainbox.height),
			"<wave>Hello, this is a test of the dialogue box system!</wave>", options, -55);

		text.x = (mainbox.x) + boxData.textoffset[0];
		text.y = (mainbox.y + mainbox.height * 0.5) + boxData.textoffset[1];
		text.letterCallback = () ->
		{
			letterSound.stop();
			letterSound.play();
		};
		add(text);
	}
}
