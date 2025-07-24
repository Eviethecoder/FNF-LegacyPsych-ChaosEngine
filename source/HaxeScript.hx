package;

import haxe.Rest; 
import flixel.FlxCamera; 
import openfl.geom.Rectangle;
import flixel.FlxSprite; 
import flixel.FlxG; 
import lime.app.Application;
import lime.ui.WindowAttributes;
import PlayState;
import hscript.Interp;
import hscript.Macro;
import flixel.util.FlxColor;
import hscript.Parser;
import psychlua.LuaUtils;
import flixel.tweens.FlxTween;


//curently this is just me and NoclueBros hscript interpreter -kuru
class HaxeScript {
    public var interpreter:Interp;
    public var parser:Parser;
    public var onError:(Dynamic, String, String)->Void = null;
    public var filePath:String = '';
    
    @:noCompletion public var obj:Dynamic; 

    public static function FromFile(path:String, obj:Dynamic):HaxeScript { 
        var script:HaxeScript = null;
        try{ 
            script = new HaxeScript(sys.io.File.getContent(path), obj);
            script.filePath = path;
        } 
        catch(e) {
            throw e; 
        }
        return script;
    }

    public function new(code:String, obj:Dynamic) {
        interpreter = new Interp();
        parser = new Parser();

        this.obj = obj;
        parser.resumeErrors = true;
        parser.allowTypes = true;
         
        __default_stuff(this);
        interpreter.execute(parser.parseString(code));
        this.runFunction('onCreate', []);
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

        adddvar(script,"this", script.obj);
        adddvar(script,"FlxG", FlxG);
        adddvar(script,"FlxSprite", flixel.FlxSprite);
        adddvar(script,"Paths", Paths);
        adddvar(script,"FlxRuntimeShader", flixel.addons.display.FlxRuntimeShader);
        adddvar(script,"Note", Note);
        adddvar(script,"ClientPrefs", ClientPrefs);
        adddvar(script,"easeFromString", LuaUtils.getFlxEaseByString);
        adddvar(script,"colorFromString", FlxColor.fromString);
        adddvar(script,"praseIntfromString",  function(number:String) {
            
            return Std.parseInt(number);
            
        });
        adddvar(script,"praseFloatfromString",  function(number:String) {
            
            return Std.parseFloat(number);
            
        });
        adddvar(script,"PlayState", PlayState.instance);
        adddvar(script,"BGSprite", BGSprite);

        //Tween shit, but for strums.. this shit isnt  static in lua shit so we just adding it here so we can easily use it
		adddvar(script, "noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if(note < 0) note = 0;
			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(testicle != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		adddvar(script, "noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String) {
			cancelTween(tag);
			if(note < 0) note = 0;
			var danote:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if(danote != null) {
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(danote, {y: value}, duration, {ease: LuaUtils.getFlxEaseByString(ease),
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
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
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
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration, {ease: LuaUtils.getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween) {
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
    } 

    public static function shouldSkip(f:Dynamic) {
        return f != null && f.__fn == 'skip';
    }


    static function cancelTween(tag:String) {
		if(PlayState.instance.modchartTweens.exists(tag)) {
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
	}

    public static function adddvar(script:HaxeScript, name:String, object:Dynamic){
        script.interpreter.variables[name] = object;
    }
} 