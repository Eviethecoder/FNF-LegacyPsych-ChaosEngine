package debug;

import flixel.FlxBasic;
import flixel.FlxG;

class ConsolePlugin extends FlxBasic
{
	public static var instance:ConsolePlugin;

	public var ui:ConsoleUI;
	public var isvis:Bool = false;

	public function new()
	{
		super();
		instance = this;

		ui = new ConsoleUI();
		FlxG.stage.addChild(ui);
		ui.visible = false;
	}

	public function togglevisible(?force:Bool)
	{
		if (force != null)
		{
			isvis = force;
		}
		else
		{
			isvis = !isvis;
		}
		ui.visible = isvis;
		FlxG.mouse.visible = isvis;
		ui.setFocus(isvis);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// Toggle console
		if (FlxG.keys.justPressed.GRAVEACCENT)
		{
			togglevisible();
		}
	}
}
