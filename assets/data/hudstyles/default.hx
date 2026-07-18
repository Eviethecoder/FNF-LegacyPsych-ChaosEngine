import objects.FunkinSprite;
import flixel.FlxG;
import ClientPrefs;

var barbg:FunkinSprite;

function gethealthbargraphics(index:Int):String
{
	if (index == 0)
	{
		return null;
	}
}

function onCreatePost()
{
	PlayState.instance.iconP2.iconPosOffset[1] += -10;
	PlayState.instance.iconP1.iconPosOffset[1] += -10;
	if (!ClientPrefs.data.downScroll)
	{
		PlayState.instance.scoreTxt.y -= 130;
	}
	else
	{
		this.timeTxt.y -= 20;
		this.timeTxt.x += 5;
	}
}

function BarCreatePost()
{
	barbg = new FunkinSprite(0, 0);
	barbg.loadGraphic(Path.image('Huds/hudbgs/Hudbg'));
	barbg.screenCenter();
	barbg.scale.set(FlxG.width / barbg.width, FlxG.height / barbg.height);
	this.insert(this.members.indexOf(this.healthBar), barbg);
	this.healthBar.scale.x = (FlxG.width / barbg.width) + 0.01;
	this.healthBar.scale.y = (FlxG.height / barbg.height) + 0.03;
	this.healthBar.barWidth = 766;
	this.healthBar.barHeight = 134;
	this.healthBar.barOffset.set(1, 1);
	this.bg.visible = false;
	if (ClientPrefs.data.downScroll)
	{
		barbg.flipY = true;
		this.healthBar.y -= 23;
	}

	Consolehandler.print('BarCreatePost ran');
}
