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
import flixel.FlxBasic;
import PlayState;
import flixel.FlxCamera;
import hscript.Interp;
import hscript.Macro;
import flixel.util.FlxColor;
import flixel.addons.display.FlxBackdrop;
import hscript.Parser;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import openfl.display.BlendMode;
import flixel.tweens.FlxEase;
import scriptobjects.*;


using StringTools;


//curently this is just me and NoclueBros hscript interpreter -kuru
class HaxeScript {
    public var interpreter:Interp;
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
        interpreter = new Interp();
        parser = new Parser();

        this.obj = obj;
        parser.resumeErrors = true;
        parser.allowTypes = true;
         
        __default_stuff(this);
        interpreter.execute(parser.parseString(code));
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

    public static function __default_stuff(script:HaxeScript):Void {   
       
         script.interpreter.variables["Cool"] = {
            'SkipFunction': function(value = null){ 
                return {'__fn': 'skip', '__value': value};
            }
        }; 

        adddvar(script,"import", function(path:String, id:Null<String> = null) {
            var cls:Dynamic = Type.resolveClass(path);
            if(cls == null) {
                Sys.println("[ Warning ] class " + path + " could not be resolved!");
                return;
            }

            if(id != null) 
                adddvar(script, id, cls);
            else {
                var className:String = path.substring(path.lastIndexOf('.') + 1, path.length);
                //Sys.println("[ Hscript ] importing class " + className);
                adddvar(script, className, cls);
            }
        });
		
        adddvar(script,"controls",function(){ return Controls;});
        adddvar(script,"this", script.obj);
		adddvar(script,"ScriptedFlxGroup", ScriptedFlxGroup);
		
        adddvar(script, "Std", Std);
        adddvar(script,"FlxG", FlxG);
        adddvar(script,"FlxSprite", flixel.FlxSprite);
        adddvar(script,"Paths", Paths);
        adddvar(script,"FlxRuntimeShader", flixel.addons.display.FlxRuntimeShader);
        adddvar(script,"Note", Note);
        adddvar(script,"ClientPrefs", ClientPrefs);
        adddvar(script,"easeFromString", getFlxEaseByString);
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

        adddvar(script, "ScriptedFlxSprite",  ScriptedFlxSprite);

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

class ScriptedFlxGroup {
    public var group:FlxTypedGroup<Dynamic>;

    public function new(maxsize:Int = 0) {
        group = new FlxTypedGroup<Dynamic>(maxsize);
    }

    public function addtogroup(obj:FlxBasic) {
        group.add(obj);
    }

    public function removefromgroup(obj:FlxBasic, splice:Bool = false) {
        group.remove(obj, splice);
    }

    public function clear() {
        group.clear();
    }

    public function length():Int {
        return group.length;
    }

    public function getmembers():Array<Dynamic> {
        return group.members;
    }

    public function get(index:Int):Dynamic {
        return group.members[index];
    }

	 public function setcam(cam:FlxCamera){
       group.cameras = [cam];
    }

    public function exists(obj:FlxBasic):Bool {
        return group.members.indexOf(obj) != -1;
    }

	public function addtostate(playstate:Bool){
		
		if(playstate){
			PlayState.instance.add(group);
		}
		else{
			FlxG.state.add(group);
		}
	}
}
