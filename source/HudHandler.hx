package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import haxe.Json;
import haxe.format.JsonParser;
import Character.AnimArray as AnimArray;
import objects.Bar;


#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;


typedef Hudstyle = {
    var healthbar:BarInfo;
    var timeBar:BarInfo;
    @:optional
    var iconP1pos:Array<Float>;
    @:optional
    var iconP2pos:Array<Float>;
    @:optional
    var iconP2visible:Bool;
    @:optional
    var iconP1visible:Bool;
    @:optional
    var scorpos:Array<Float>;
    @:optional
    var noteskin:String;
    @:optional
    var falback:String;
    
}

typedef BarInfo = {
    @:optional
	var animations:Array<AnimArray>;
	var image:Array<String>;
	var scale:Float;
    var barStyle:String; 

	var position:Array<Float>;
    var barOffsets:Array<Float>;
	var no_antialiasing:Bool;
    
	

}



class HudHandler extends FlxGroup{
    public var bars:Hudstyle;
    public var healthBar:Bar;
    public var timebg:FlxSprite;
    public var bg:FlxSprite;
    public var spritegroup:FlxTypedGroup<FlxSprite>;
    public var timeBar:Bar;
    var json:Hudstyle;
    public var script:HaxeScript = null;
    public var iconp1overide:Array<Float>; 
    public var iconp1vis:Bool = true;
    public var iconp2overide:Array<Float>;
    public var scorposs:Array<Float> =[0,0];
    var hudscriptpath:String;
    var songname:String;
    public var timeTxt:FlxText;
    public var hasscript:Bool = false;
    public function new( json:String, hudname:String, songname:String) {
        super();
        setupjson(json);
        trace('hudname is: ' + hudname);
        hudscriptpath = 'hudstyles/' + hudname + '.hx';
        
        this.songname = Paths.formatToSongPath(songname);
        trace('song name is' +songname);
        barsetup();
    }

    public function barsetup(){

        detectscript();
        if (json == null) {
            trace("No JSON data found for HudHandler.");
            return;
        }
        else{
            var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
            timeTxt = new FlxText(42 + (FlxG.width / 2) - 248, 19, 400, "", 32);
            timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            timeTxt.scrollFactor.set();
            timeTxt.alpha = 0;
            timeTxt.borderSize = 2;
            timeTxt.visible = showTime;
            if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;
            if(ClientPrefs.data.timeBarType == 'Song Name') timeTxt.text = songname;
            if(bars.healthbar.barStyle == 'png'){
                
                
                healthBar = new Bar(-200, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11),bars.healthbar.barStyle, gethealthbargraphics(1), function() return PlayState.instance.health, 0, 2);
                healthBar.leftToRight = false;
                healthBar.scrollFactor.set();
                healthBar.x += bars.healthbar.barOffsets[0];
                healthBar.y += bars.healthbar.barOffsets[1];
                healthBar.scale.set(bars.healthbar.scale, bars.healthbar.scale);
                healthBar.visible = !ClientPrefs.data.hideHud;
                healthBar.alpha = ClientPrefs.data.healthBarAlpha;
                bg = new FlxSprite().loadGraphic(Paths.image(gethealthbargraphics(0)));
			    bg.antialiasing = true;
                bg.scale.set(bars.healthbar.scale, bars.healthbar.scale);
                bg.x = healthBar.x + bars.healthbar.position[0];
                bg.y =  healthBar.y + bars.healthbar.position[1];
                trace(bg);
                reloadHealthBarColors();
                add(healthBar);
                add(bg);
               
                
            }
            else{
                
                healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11),bars.healthbar.barStyle, gethealthbargraphics(0), function() return PlayState.instance.health, 0, 2);
                healthBar.screenCenter(X);
                healthBar.leftToRight = false;
                healthBar.scrollFactor.set();
                healthBar.visible = !ClientPrefs.data.hideHud;
                healthBar.alpha = ClientPrefs.data.healthBarAlpha;
                reloadHealthBarColors();
                add(healthBar);


                
            }

            if(bars.timeBar.barStyle == 'png'){
                timebg = new FlxSprite().loadGraphic(Paths.image(gettimebargraphics(0)));
			    timebg.antialiasing = true;
                timebg.scale.set(bars.timeBar.scale, bars.timeBar.scale);
                timebg.x = timeBar.x + bars.timeBar.position[0];
                timebg.y =  timeBar.y + bars.timeBar.position[1];
                trace(timebg);
                

                timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4),bars.timeBar.barStyle, gettimebargraphics(1), function() return 0, 0, 1);
                timeBar.scrollFactor.set();
                timeBar.screenCenter(X);
                timeBar.alpha = 0;
                timeBar.x += bars.timeBar.barOffsets[0];
                timeBar.y += bars.timeBar.barOffsets[1];
                timeBar.visible = showTime;
                add(timeBar);
                add(timebg);
            }
            else{
                
                timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4),bars.timeBar.barStyle, gettimebargraphics(0), function() return 0, 0, 1);
                timeBar.scrollFactor.set();
                timeBar.screenCenter(X);
                timeBar.alpha = 0;
                timeBar.x += bars.timeBar.barOffsets[0];
                timeBar.y += bars.timeBar.barOffsets[1];
                timeBar.visible = showTime;
                timeBar.setColors(FlxColor.WHITE,FlxColor.BLACK);
                add(timeBar);

            }
            if (ClientPrefs.data.timeBarType == 'Song Name')
            {
                timeTxt.size = 24;
                timeTxt.y += 3;
            }
            spritegroup = new FlxTypedGroup<FlxSprite>();
            runScriptFunction('BarCreatePost', []);
            add(spritegroup);
            spritegroup.cameras = [PlayState.instance.camHUD];
        }
    }

    public function setupjson(location:String){
        var path:String;
        if(sys.FileSystem.exists(Paths.hudjson(location))){
            path = Paths.hudjson(location);
            trace('loading hud json from: ' + path);
            
    
        }
        else if(sys.FileSystem.exists(Paths.modshudJson(location))){
            path = Paths.modshudJson(location);
            trace('loading hud json from: ' + path);
        }
        else{
            trace('no hud json found at: ' + location);
            return;
        }
       
        json = cast Json.parse(File.getContent(path));
        trace ('json healthbar is : ' + json.healthbar);
        trace ('json timeBar is : ' + json.timeBar);
        bars = json;
        if (bars.iconP1pos != null) {
            iconp1overide = bars.iconP1pos;
        }
        if (bars.iconP2pos != null) {
            iconp2overide = bars.iconP2pos;
            trace('iconp2overide is: ' + iconp2overide);
        }
        if (bars.iconP1visible != null) {
            iconp1vis = bars.iconP1visible;
        }
        if (bars.scorpos != null) {
            scorposs = bars.scorpos;
        }
        if(bars.noteskin == null){
            bars.noteskin = 'NOTE_assets';
        }

    }

    public function updatehealth(health:Float){
        if(healthBar != null){
            healthBar.valueFunction = function() return health;
            healthBar.updateBar();
        }
        runScriptFunction('updatehealth', [health]);
    }

    public function gethealthbargraphics(barnum:Int):String {
    if (script != null) {
        trace('Running script function getbargraphics with bar number: ' + barnum);

        // Grab the function from the script
        var func = script.interpreter.variables.get("gethealthbargraphics");

        if (func != null) {
            var bargraphics:String = cast Reflect.callMethod(null, func, [barnum]);
            trace('bargraphics is: ' + bargraphics);

            if (bargraphics != null) {
                return bargraphics;
            } else {
                trace('Script returned null, falling back to JSON image.');
                return bars.healthbar.image[barnum];
            }
        } else {
            trace('Script function getbargraphics not found, using fallback.');
            return bars.healthbar.image[barnum];
        }
    } else {
        // No script loaded, use fallback
        return bars.healthbar.image[barnum];
    }
}
public function getNoteskin(player:Bool):String {
    if (script != null) {
        

        // Grab the function from the script
        var func = script.interpreter.variables.get("getNoteskin");

        if (func != null) {
            var noteskin:String = cast Reflect.callMethod(null, func, [player]);
           

            if (noteskin != null) {
                return noteskin;
            } else {
             
                return bars.noteskin;
            }
        } 
        else {
           
            
            return bars.noteskin;
        }
    } else {
        // No script loaded, use fallback
        return bars.noteskin;
    }
}
public function gettimebargraphics(barnum:Int):String {
    if (script != null) {
        trace('Running script function getbargraphics with bar number: ' + barnum);

        // Grab the function from the script
        var func = script.interpreter.variables.get("gettimebargraphics");

        if (func != null) {
            var bargraphics:String = cast Reflect.callMethod(null, func, [barnum]);
            trace('bargraphics is: ' + bargraphics);

            if (bargraphics != null) {
                return bargraphics;
            } else {
                trace('Script returned null, falling back to JSON image.');
                return bars.timeBar.image[barnum];
            }
        } else {
            trace('Script function getbargraphics not found, using fallback.');
            return bars.timeBar.image[barnum];
        }
    } 
    else {
        // No script loaded, use fallback
        return bars.healthbar.image[barnum];
    }
}

      

    public function geticonP1Pos(arraynum:Int):Float {
    // If JSON has iconP1pos
    if (bars.iconP1pos != null) {
        // Try script override first
        if (script != null) {
            var func = script.interpreter.variables.get("geticonP1Pos");

            if (func != null) {
                var pos:Dynamic = cast Reflect.callMethod(null, func, [arraynum]);
                
                if (pos != null) {
                    return pos; // Script returned valid value
                } else {
                    trace('Script returned null, falling back to JSON iconP1pos.');
                    return bars.iconP1pos[arraynum];
                }
            } else {
                trace('Script function geticonP1Pos not found, falling back to JSON.');
                return bars.iconP1pos[arraynum];
            }
        } else {
            trace('No script loaded, using JSON iconP1pos.');
            return bars.iconP1pos[arraynum];
        }

        // Fallback to JSON value
        return bars.iconP1pos[arraynum];
    } 
    else {
        // JSON also missing, fallback to default
        var defaultPos:Array<Float> = [0, 0];
        return defaultPos[arraynum];
    }
}

    public function geticonP2Pos(arraynum:Int):Float {
    // If JSON has iconP1pos
    if (bars.iconP2pos != null) {
        // Try script override first
        if (script != null) {
            var func = script.interpreter.variables.get("geticonP2Pos");

            if (func != null) {
                //dynamic to avoid compile issues
                var pos:Dynamic = cast Reflect.callMethod(null, func, [arraynum]);
                
                if (pos != null) {
                    return pos; // Script returned valid value
                } else {
                    trace('Script returned null, falling back to JSON iconP1pos.');
                    return bars.iconP2pos[arraynum];
                }
            } else {
                trace('Script function geticonP1Pos not found, falling back to JSON.');
                return bars.iconP2pos[arraynum];
            }
        } else {
            trace('No script loaded, using JSON iconP1pos.');
            return bars.iconP2pos[arraynum];
        }

        // Fallback to JSON value
        return bars.iconP2pos[arraynum];
    } 
    else {
        // JSON also missing, fallback to default
        var defaultPos:Array<Float> = [0, 0];
        return defaultPos[arraynum];
    }
}
    public function updateTime(time:Float){
        if(timeBar != null){
            timeBar.valueFunction = function() return time;
            timeBar.updateBar();
           
        }
        runScriptFunction('updateTime', [time]);
    }

    override function update(elapsed:Float)
	{
		
		super.update(elapsed);
        runScriptFunction('update', [elapsed]);

    }

    public function addvar(name:String, value:Dynamic) {
        if (script != null) {
            script.interpreter.variables[name] = value;
        }
    }

    public function runScriptFunction(id:String, params:Array<Dynamic>):Dynamic {
		if(script == null) 
			return null;
 
		return script.runFunction(id, params);
	}

    public function detectscript(){
         if(sys.FileSystem.exists(Paths.getPreloadPath(hudscriptpath)) && PlayState.instance!=null ){

			try{
				trace('script found!! '+ hudscriptpath );
				#if !macro
				script = HaxeScript.HaxeScript.FromFile(Paths.getPreloadPath(hudscriptpath), this); 
				script.onError = PlayState.instance.hscriptError;
				hasscript = true;
                
				#end 
			}
			catch(e:Dynamic){  
				PlayState.instance.addTextToDebug("   ...  " + Std.string(e), FlxColor.fromRGB(240, 166, 38)); 
				PlayState.instance.addTextToDebug("[ ERROR ] Could not load Hud script " + Paths.getPreloadPath(hudscriptpath), FlxColor.RED);
				hasscript = false;  
			} 
		}
		else if(sys.FileSystem.exists(Paths.modFolders(hudscriptpath)) && PlayState.instance!=null ){

			try{
				trace('script found!! '+ hudscriptpath );
				#if !macro
				script = HaxeScript.HaxeScript.FromFile(Paths.modFolders(hudscriptpath), this); 
				script.onError = PlayState.instance.hscriptError;
				hasscript = true;
				#end 
			}
			catch(e:Dynamic){  
				PlayState.instance.addTextToDebug("   ...  " + Std.string(e), FlxColor.fromRGB(240, 166, 38)); 
				PlayState.instance.addTextToDebug("[ ERROR ] Could not load Hud script " + Paths.getPreloadPath(hudscriptpath), FlxColor.RED);
				hasscript = false;  
			} 
		}
        else{
            trace('no script found at: ' + hudscriptpath);
            hasscript = false;
        }

    }


    public function reloadHealthBarColors()
	{
		healthBar.setColors(FlxColor.fromRGB(PlayState.instance.dad.healthColorArray[0], PlayState.instance.dad.healthColorArray[1], PlayState.instance.dad.healthColorArray[2]),
			FlxColor.fromRGB(PlayState.instance.boyfriend.healthColorArray[0], PlayState.instance.boyfriend.healthColorArray[1], PlayState.instance.boyfriend.healthColorArray[2]));

		healthBar.updateBar();
	}

}

