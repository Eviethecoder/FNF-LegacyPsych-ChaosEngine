package chorus.backend.scripting;

import chorus.backend.assets.Paths;
import chorus.backend.debug.Consolehandler;
import chorus.backend.utils.MathUtil;
import chorus.objects.stages.Stage;

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
		variables.set('MathUtil', MathUtil);
		variables.set('Path', Paths);
		variables.set("stage", Stage.instance);
		variables.set("Consolehandler", Consolehandler);
		variables.set('FlxColor', HaxeScript.Flxcolorscript);
		variables.set('window', lime.app.Application.current.window);
		variables.set('print', function(v:HaxeScript.AnyValue):Void
		{
			Consolehandler.print(v);
		});
		variables.set('warn', function(v:HaxeScript.AnyValue):Void
		{
			Consolehandler.warn(v);
		});
		variables.set('error', function(v:HaxeScript.AnyValue):Void
		{
			Consolehandler.error(v);
		});

		if (parentObject != null)
		{
			variables.set('parent', parentObject);
			variables.set('this', parentObject);
		}
	}
}
