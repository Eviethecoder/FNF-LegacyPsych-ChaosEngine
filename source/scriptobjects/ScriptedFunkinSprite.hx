package scriptobjects;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import objects.FunkinSprite;
import HaxeScript;


class ScriptedFunkinSprite extends FunkinSprite {
    public var scriptpath:String;
    public var script:HaxeScript;
    public var hasscript:Bool;  
    public function new(x:Float = 0, y:Float = 0, dascriptPath:String) {
        super(x, y);
        this.scriptpath = dascriptPath;
        detectscript();

    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);
        runScriptFunction('update', [elapsed]);
    }

    override public function draw():Void {
        super.draw();
        runScriptFunction('draw', []);
    }

    override public function kill():Void {
        super.kill();
        runScriptFunction('kill', []);
    }

    override public function revive():Void {
        super.revive();
        runScriptFunction('revive', []);
    }

    override public function destroy():Void {
        super.destroy();
        runScriptFunction('destroy', []);
    }

    override public function updateHitbox():Void {
        super.updateHitbox();
        runScriptFunction('updateHitbox', []);
    }

    override public function set_clipRect(rect:flixel.math.FlxRect):flixel.math.FlxRect {
        runScriptFunction('set_clipRect', [rect]);
        return super.set_clipRect(rect);
    }


    public function detectscript(){
         if(sys.FileSystem.exists(Paths.getPreloadPath(scriptpath)) && PlayState.instance!=null ){

			try{
				trace('script found!! '+ scriptpath );
				#if !macro
				script = HaxeScript.HaxeScript.FromFile(Paths.getPreloadPath(scriptpath), this); 
				script.onError = PlayState.instance.hscriptError;
				hasscript = true;
				#end 
			}
			catch(e:Dynamic){  
                if(PlayState.instance !=null){
                    PlayState.instance.addTextToDebug("   ...  " + Std.string(e), FlxColor.fromRGB(240, 166, 38)); 
				    PlayState.instance.addTextToDebug("[ ERROR ] Could not load Sprite script " + Paths.getPreloadPath(scriptpath), FlxColor.RED);

                }
                else{
                   trace(e);
                }
				
				hasscript = false;  
			} 
		}
		else{
			hasscript = false;  
			trace('no script has been found for path:' + scriptpath );
		}

    }
    public function runScriptFunction(id:String, params:Array<Dynamic>):Dynamic {
		if(script == null) 
			return null;
 
		return script.runFunction(id, params);
	}
	
    public function callFunctionWithScripts(name:String,  params:Array<String>){
		if(hasscript){
			script.runFunction(name, params);
		}
		else{
			
		}

	}
	
	 public function addvar(name:String, value:Dynamic) {
        if (script != null) {
            script.interpreter.variables[name] = value;
        }
    }
}
