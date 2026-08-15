package editors;

import objects.DialogueBox;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxColor;
import MusicBeatState;

class DialogueTextState extends MusicBeatState
{
	var dialogueBox:DialogueBox;

	public var randomtxt:Array<String> = [
		"<wave>Hello, this is a test of the dialogue box system!</wave>",
		"<faster><shake>Shake effect</shake></faster> <color rgb=0x3F10CD>Colored Text!!</color>",
		"<rainbow>Rainbow</rainbow> text",
		"Chud chud chud chud chud chud",
		"Text of <smaller>smaller size</smaller>",
		"Text of <bigger>bigger size</bigger>"
	];

	override function create()
	{
		super.create();
		var bgback:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('ebotmenuBG'));
		bgback.scrollFactor.set(0, 0);
		bgback.setGraphicSize(Std.int(bgback.width * 1.175));
		bgback.updateHitbox();
		bgback.screenCenter();
		bgback.color = 0xFFA4179A;
		bgback.antialiasing = ClientPrefs.data.globalAntialiasing;
		add(bgback);
		dialogueBox = new DialogueBox(0, 0);
		if (dialogueBox.mainbox != null)
		{
			dialogueBox.x = (FlxG.width - dialogueBox.mainbox.width) * 0.5;
			dialogueBox.y = (FlxG.height - dialogueBox.mainbox.height) * 0.5;
		}
		dialogueBox.playAnim('normalIdle');
		add(dialogueBox);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.switchState(new editors.MasterEditorMenu());
		}
		if (FlxG.keys.justPressed.A)
		{
			dialogueBox.text.loadText(randomtxt[FlxG.random.int(0, randomtxt.length - 1)]);
			dialogueBox.setrgbdata([FlxG.random.int(0, 255), FlxG.random.int(0, 255), FlxG.random.int(0, 255)],
				[FlxG.random.int(0, 255), FlxG.random.int(0, 255), FlxG.random.int(0, 255)],
				[FlxG.random.int(0, 255), FlxG.random.int(0, 255), FlxG.random.int(0, 255)]);
		}
	}
}
