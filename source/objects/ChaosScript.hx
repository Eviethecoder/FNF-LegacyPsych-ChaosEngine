package objects;

import insanity.Script;
import insanity.Environment;
import insanity.backend.Exception;
import insanity.backend.Parser;
import insanity.backend.Interp;
import insanity.backend.Expr;

class ChaosScript extends Script
{
	public var parentObject:Dynamic = null;

	public function new(string:String, name:String = 'hscript', ?environment:Environment, ?parentObject:Dynamic):Void
	{
		super(string, name, environment);
		this.parentObject = parentObject;

		if (this.parentObject != null)
		{
			variables.set('this', this.parentObject);
		}
	}

	public override function setDefaults():Void
	{
		this.interp.setDefaults();
		variables.set('interp', interp);
		variables.set('Path', Paths);
		variables.set("stage", objects.Stage.instance);
		variables.set("Consolehandler", debug.Consolehandler);
		variables.set('FlxColor', HaxeScript.Flxcolorscript);

		if (parentObject != null)
		{
			variables.set('parent', parentObject);
			variables.set('this', parentObject);
		}
	}
}
