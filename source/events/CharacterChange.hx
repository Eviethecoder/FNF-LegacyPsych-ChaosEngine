package events;

import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import PlayState;
import utility.Scripthandler;
import debug.Consolehandler;
import flixel.graphics.frames.FlxFramesCollection;
import HaxeScript;

@:keep
typedef CharacterchangeData =
{
	var chartype:String;
	var charactername:String;
}

class CharacterChange extends BaseEvent
{
	public var charmap:Map<CharacterchangeData, Character> = new Map<CharacterchangeData, Character>();

	public function new(name:String)
	{
		super();
		eventName = 'Character Change';
	}

	public override function triggerEvent():Void
	{
		var char = grabeventString('characterJson');
		var type = grabeventString('CharToChange');
		var charinfo:CharacterchangeData = {chartype: type, charactername: char};
		var oldChar:Character = PlayState.instance.stage.getCharacter('gf');
		var newChar:Character = charmap.get(charinfo);
		var x = oldChar.x;
		var y = oldChar.y;
		var zindex = oldChar.zIndex;
		oldChar.alpha = 0.000001;
		PlayState.instance.stage.stageGroup.remove(oldChar);
		var prevalpha = PlayState.instance.stage.getCharacter('dad').alpha;
		oldChar.alpha = 0.00001;
		oldChar.kill();
		oldChar = newChar;
		oldChar.revive();
		oldChar.alpha = prevalpha;
		PlayState.instance.stage.stageGroup.add(oldChar);
	}

	public function loadcharacter(type:String, newCharacter:String)
	{
		var charinfo:CharacterchangeData = {chartype: type, charactername: newCharacter};
		var char:Dynamic;
		switch (type)
		{
			case 'BF':
				char = PlayState.instance.stage.getCharacter('boyfriend');
			case 'DAD':
				char = PlayState.instance.stage.getCharacter('dad');
			case 'GF':
				char = PlayState.instance.stage.getCharacter('gf');
			default:
				Consolehandler.warn('Invalid character type for Character Change event: ' + type + '. Valid types are: BF, DAD, GF, Returning BF');
				char = PlayState.instance.stage.getCharacter('boyfriend');
		}

		var newchar:Character = new Character(0, 0, newCharacter, true);
		newchar.x = char.x;
		newchar.y = char.y;
		newchar.zIndex = char.zIndex;
		charmap.set(charinfo, newchar);
		newchar.alpha = 0.00001;
	}

	public override function precacheEvent(precachdata:Note.EventNote):Void
	{
	}
}
