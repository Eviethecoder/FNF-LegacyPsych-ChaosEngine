package;

import haxe.Rest; 
import flixel.FlxCamera; 
import openfl.geom.Rectangle;
import flixel.FlxSprite; 
import flixel.FlxG; 
import flixel.text.FlxText;
import lime.app.Application;
import lime.ui.WindowAttributes;
import flixel.FlxState;
import PlayState;
import hscript.Interp;
import hscript.Macro;
import flixel.util.FlxColor;
import flixel.addons.display.FlxBackdrop;
import hscript.Parser;
import flixel.tweens.FlxTween;
import openfl.display.BlendMode;
import flixel.tweens.FlxEase;
import scriptobjects.*;


using StringTools;


//curently this is just me and NoclueBros hscript interpreter -kuru
class HaxeScript {
    public var interpreter:Interp;
	public static var imports:Array<{original:String, alias:String}> = [];
    public var parser:Parser;
    public var onError:(Dynamic, String, String)->Void = null;
    public var filePath:String = '';
    
 
    
    @:noCompletion public var obj:Dynamic; 

    public static function FromFile(path:String, obj:Dynamic, ?runautocreate:Bool= true):HaxeScript { 
        var script:HaxeScript = null;
        try{ 
            script = new HaxeScript(sys.io.File.getContent(path), obj,runautocreate);
            script.filePath = path;
        } 
        catch(e) {
            throw e; 
        }
      
        return script;
    }

    public function new(code:String, obj:Dynamic,runautocreate:Bool) {

        
        var processed = preprocess(code, imports);
		

	
        var parser = new Parser();
    

        this.obj = obj;
        parser.resumeErrors = true;
        parser.allowTypes = true;

		var expr = parser.parseString(processed);
		interpreter = new Interp();


         
        __default_stuff(this);
        interpreter.execute(expr);
        if(runautocreate){
            this.runFunction('onCreate', []);
        }
        
    }

    public function runFunction(id:String, params:Array<Dynamic>):Dynamic {  
        var func:Dynamic = get(id);

        if(func == null) 
            return null;
        
        var result:Dynamic = null;
        
        try{  
            result = Reflect.callMethod(null, func, params);
        }
        catch(e:Dynamic) {
            if(onError != null) {
                onError(e, id, filePath);
            }
        }

        return result;
    }
    

    public function get(id:String):Dynamic {   
        return interpreter.variables[id];
    }


	

static function preprocess(script:String, imports:Array<{original:String, alias:String}>):String {
    var lines = script.split("\n");
    var out = new Array<String>();

    for (l in lines) {
        var trimmed = l.trim();
        if (StringTools.startsWith(trimmed, "import ")) {
            var classname = trimmed.substr(7).split(";")[0].trim();

            // Check for alias
            var alias:String = null;
            var original:String = null;

            if (classname.indexOf(" as ") != -1) {
                var parts = classname.split(" as ");
                original = parts[0].trim();
                alias = parts[1].trim();
            } else {
                original = classname;
                // Default alias is last part of class path
                alias = classname.split(".").pop();
            }

            imports.push({ original: original, alias: alias });

        } else {
            out.push(l);
        }
    }

    return out.join("\n");
}



	static function registerImports(script:HaxeScript, imports:Array<{ original:String, alias:String }>) {
		for (imp in imports) {
			var classname = imp.original;
			var alias = imp.alias;

			var cls = Type.resolveClass(classname);

			if (cls == null) {
				trace('Warning: could not resolve class $classname');
			} else {
				// Bind using the alias (custom name or last path segment)
				adddvar(script, alias, cls);
			}
		}
	}


    public static function __default_stuff(script:HaxeScript):Void {   
       
         script.interpreter.variables["Cool"] = {
            'SkipFunction': function(value = null){ 
                return {'__fn': 'skip', '__value': value};
            }
        }; 

        registerImports(script,imports);		
        adddvar(script,"controls",function(){ return Controls;});
        adddvar(script,"this", script.obj);
		adddvar(script, "FlxGroup", flixel.group.FlxGroup);
        adddvar(script, "Std", Std);
        adddvar(script,"FlxG", FlxG);
        adddvar(script,"FlxSprite", flixel.FlxSprite);
        adddvar(script,"Paths", Paths);
        adddvar(script,"FlxRuntimeShader", flixel.addons.display.FlxRuntimeShader);
        adddvar(script,"Note", Note);
        adddvar(script,"ClientPrefs", ClientPrefs);
        adddvar(script,"easeFromString", getFlxEaseByString);
		adddvar(script,"FlxSpriteGroup", flixel.group.FlxSpriteGroup);
        adddvar(script,"colorFromString", FlxColor.fromString);
        adddvar(script,"praseIntfromString",  function(number:String) {
            
            return Std.parseInt(number);
            
        });
        adddvar(script,"praseFloatfromString",  function(number:String) {
            
            return Std.parseFloat(number);
            
        });
        adddvar(script,"PlayState", PlayState.instance);
        adddvar(script,"BGSprite", BGSprite);
        adddvar(script,"Math", Math);
		adddvar(script,"ScriptedSubState", ScriptableMusicBeatSubState);
        adddvar(script, 'persistantvariables', ScriptedStatehandler.persistantvariables);

        adddvar(script,"FlxBackdrop",FlxBackdrop);
        //Tween shit, but for strums.. this shit isnt  static in lua shit so we just adding it here so we can easily use it
		adddvar(script, "noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

        adddvar(script, "ScriptedFunkinSprite",  ScriptedFunkinSprite);

        adddvar(script, "switchscriptedstate",  function(name:String){
            MusicBeatState.switchscriptedstate(name);
        });
        adddvar(script, "switchState",  function(name:FlxState){
            MusicBeatState.switchState(name);
        });
        adddvar(script,'BlendMode',{
			SUBTRACT: BlendMode.SUBTRACT,
			ADD: BlendMode.ADD,
			MULTIPLY: BlendMode.MULTIPLY,
			ALPHA: BlendMode.ALPHA,
			DARKEN: BlendMode.DARKEN,
			DIFFERENCE: BlendMode.DIFFERENCE,
			INVERT: BlendMode.INVERT,
			HARDLIGHT: BlendMode.HARDLIGHT,
			LIGHTEN: BlendMode.LIGHTEN,
			OVERLAY: BlendMode.OVERLAY,
			SHADER: BlendMode.SHADER,
			SCREEN: BlendMode.SCREEN
		});
		adddvar(script, "noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if(note < 0) note = 0;
			var danote:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(danote != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(danote, {y: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		adddvar(script,'FlxColor',Flxcolorscript);
		adddvar(script, "noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		adddvar(script, "noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
    } 

    public static function shouldSkip(f:Dynamic) {
        return f != null && f.__fn == 'skip';
    }

    public static function getFlxEaseByString(?ease:String = '') {
		return switch(ease.toLowerCase().trim()) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
			case _: return FlxEase.linear;
		}
	}


    static function cancelTween(tag:String) {
		if(PlayState.instance.modchartTweens.exists(tag)) {
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
	}

    //its funny that you can tell when this is just ported here

    public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic):Any
	{
		var variablelist:Array<String> = variable.split('[');
		if(variablelist.length > 1)
		{
            //ithink
			var curvalue:Dynamic = null;
			if(PlayState.instance.variables.exists(variablelist[0]))
			{
				var retVal:Dynamic = PlayState.instance.variables.get(variablelist[0]);
				if(retVal != null)
					curvalue = retVal;
			}
			else
				curvalue = Reflect.getProperty(instance, variablelist[0]);

			for (i in 1...variablelist.length)
			{
				var leNum:Dynamic = variablelist[i].substr(0, variablelist[i].length - 1);
				if(i >= variablelist.length-1) //Last array
					curvalue[leNum] = value;
				else //Anything else
					curvalue = curvalue[leNum];
			}
			return curvalue;
		}
		
			
		if(PlayState.instance.variables.exists(variable))
		{
			PlayState.instance.variables.set(variable, value);
			return true;
		}

		Reflect.setProperty(instance, variable, value);
		return true;
	}
    public static function getPropertyLoopThingWhatever(killMe:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool=true):Dynamic
	{
		var coverMeInPiss:Dynamic = getObjectDirectly(killMe[0], checkForTextsToo);
		var end = killMe.length;
		if(getProperty)end=killMe.length-1;

		for (i in 1...end) {
			coverMeInPiss = getVarInArray(coverMeInPiss, killMe[i]);
		}
		return coverMeInPiss;
	}
    public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic
	{
		var coverMeInPiss:Dynamic = PlayState.instance.getLuaObject(objectName, checkForTextsToo);
		if(coverMeInPiss==null)
			coverMeInPiss = getVarInArray(getInstance(), objectName);

		return coverMeInPiss;
	}
    public static function getVarInArray(instance:Dynamic, variable:String):Any
	{
		var shit:Array<String> = variable.split('[');
		if(shit.length > 1)
		{
			var blah:Dynamic = null;
			if(PlayState.instance.variables.exists(shit[0]))
			{
				var retVal:Dynamic = PlayState.instance.variables.get(shit[0]);
				if(retVal != null)
					blah = retVal;
			}
			else
				blah = Reflect.getProperty(instance, shit[0]);

			for (i in 1...shit.length)
			{
				var leNum:Dynamic = shit[i].substr(0, shit[i].length - 1);
				blah = blah[leNum];
			}
			return blah;
		}

		if(PlayState.instance.variables.exists(variable))
		{
			var retVal:Dynamic = PlayState.instance.variables.get(variable);
			if(retVal != null)
				return retVal;
		}

		return Reflect.getProperty(instance, variable);
	}
    public static inline function getInstance()
	{
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}


    public static function adddvar(script:HaxeScript, name:String, object:Dynamic){
        script.interpreter.variables[name] = object;
    }
} 

class ModchartSprite extends FlxSprite
{
	public var wasAdded:Bool = false;
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	//public var isInFront:Bool = false;

	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		antialiasing = ClientPrefs.data.globalAntialiasing;
	}
}

class ModchartText extends FlxText
{
	public var wasAdded:Bool = false;
	public function new(x:Float, y:Float, text:String, width:Float)
	{
		super(x, y, width, text, 16);
		setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		cameras = [PlayState.instance.camHUD];
		scrollFactor.set();
		borderSize = 2;
	}
}

//flxcolor passthrough
class Flxcolorscript {
	public static var BLACK:Int = FlxColor.BLACK;
	public static var BLUE:Int = FlxColor.BLUE;
	public static var CYAN:Int = FlxColor.CYAN;
	public static var GRAY:Int = FlxColor.GRAY;
	public static var GREEN:Int = FlxColor.GREEN;
	public static var LIME:Int = FlxColor.LIME;
	public static var MAGENTA:Int = FlxColor.MAGENTA;
	public static var ORANGE:Int = FlxColor.ORANGE;
	public static var PINK:Int = FlxColor.PINK;
	public static var PURPLE:Int = FlxColor.PURPLE;
	public static var RED:Int = FlxColor.RED;
	public static var TRANSPARENT:Int = FlxColor.TRANSPARENT;
	public static var WHITE:Int = FlxColor.WHITE;
	public static var YELLOW:Int = FlxColor.YELLOW;

	public static function fromCMYK(cyan:Float,magenta:Float,yellow:Float,black:Float,alpha:Float = 1):Int return FlxColor.fromCMYK(cyan,magenta,yellow,black,alpha);
	public static function fromHSB(hue:Float,saturation:Float,brightness:Float,alpha:Float = 1):Int return FlxColor.fromHSB(hue,saturation,brightness,alpha);
	public static function fromInt(num:Int):Int return cast FlxColor.fromInt(num);
	public static function fromRGBFloat(red:Float,green:Float,blue:Float,alpha:Float = 1):Int return FlxColor.fromRGBFloat(red,green,blue,alpha);
	public static function fromRGB(red:Int,green:Int,blue:Int,alpha:Int = 255):Int return FlxColor.fromRGB(red,green,blue,alpha);
	public static function getHSBColorWheel(alpha:Int = 255):Array<Int> return cast FlxColor.getHSBColorWheel(alpha);
	public static function gradient(color1:FlxColor, color2:FlxColor, steps:Int, ?ease:Float->Float):Array<Int> return FlxColor.gradient(color1,color2,steps,ease);
	public static function interpolate(color1:FlxColor, color2:FlxColor, factor:Float = 0.5):Int return FlxColor.interpolate(color1,color2,factor);
	public static function fromString(string:String):Int return FlxColor.fromString(string);
}