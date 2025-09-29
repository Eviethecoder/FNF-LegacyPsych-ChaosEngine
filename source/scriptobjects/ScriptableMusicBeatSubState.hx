package scriptobjects;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import MusicBeatSubstate;
import flixel.FlxCamera;
import flixel.FlxBasic;

class ScriptableMusicBeatSubState extends MusicBeatSubstate
{
	var script:HaxeScript ;
	public function new(Script:String,  ?additionalVars:Map<String, Dynamic>)
	{
		super();
		var filepath:String = '$Script.hx';

		if(!sys.FileSystem.exists(Paths.getPreloadPath(filepath))){
			filepath = 'states/' + ScriptedStatehandler.curselectedstate + '.hx';
			trace('game reset. detect if the curselected state is found');
		}

		if(sys.FileSystem.exists(Paths.getPreloadPath(filepath))){

			try{
				trace('script found!! '+ filepath );
				
				script = HaxeScript.HaxeScript.FromFile(Paths.getPreloadPath(filepath), this, false); 
				script.onError = this.hscriptError;

				
			}
			catch(e:Dynamic){  
				this.addTextToDebug("   ...  " + Std.string(e), FlxColor.fromRGB(240, 166, 38)); 
				this.addTextToDebug("[ ERROR ] Could not load state script " + Paths.getPreloadPath(filepath), FlxColor.RED);
				
			} 
		}
		else{
			trace('no script has been found for path:' + filepath +' in assets. checking modfolder');
			if(sys.FileSystem.exists(Paths.modFolders(filepath))){

			try{
				trace('script found!! '+ filepath );
				
				script = HaxeScript.HaxeScript.FromFile(Paths.modFolders(filepath), this, false); 
				script.onError = this.hscriptError;

				
			}
			catch(e:Dynamic){  
				this.addTextToDebug("   ...  " + Std.string(e), FlxColor.fromRGB(240, 166, 38)); 
				this.addTextToDebug("[ ERROR ] Could not load character script " + Paths.modFolders(filepath), FlxColor.RED);
				
			} 
			
			}
		}
		if (additionalVars != null){
				for (key in additionalVars.keys()){
					addvar(key,additionalVars.get(key));
				}
					
			}
			addvar('add',function(object:FlxBasic){
				add(object);
			});

		runScriptFunction('new',[]);
	
		


		
	}



	override function create() {
		runScriptFunction('create',[]);
	
		super.create();

		
	}

	override function update(elapsed:Float)
	{
		runScriptFunction('update',[elapsed]);
		super.update(elapsed);
	}

	

	override public function stepHit():Void
	{
		runScriptFunction('stepHit',[curStep]);
		if (curStep % 4 == 0)
			beatHit();
	}

	override public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
		runScriptFunction('beatHit',[this.curBeat]);
	}

	override function destroy()
		{
			runScriptFunction('destroy',[]);
			super.destroy();

		}

	

	 public function runScriptFunction(id:String, params:Array<Dynamic>):Dynamic {
		if(script == null) 
			return null;
 
		return script.runFunction(id, params);
	}
	
	
	 public function addvar(name:String, value:Dynamic) {
        if (script != null) {
            script.interpreter.variables[name] = value;
        }
    }
}
