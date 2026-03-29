package objects;

import HaxeScript.AnyValue;
import objects.FunkinSprite;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import utility.Scripthandler;
import openfl.display.BlendMode;
import objects.FunkinBackdrop;
import flixel.util.FlxAxes;
import data.StageData;
import HaxeScript;
import Note;
import Character;

using StringTools;

class Stage extends FlxBasic{

	public var gfSpeed:Int = 1;
	public var charposmap: Map<String, Array<Float>> = [];
	public var stageGroup:FlxTypedGroup<FunkinSprite>;
    public var stagescript:HaxeScript;
	var stageData:StageFile;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;
	public var foundprop:Bool = false;
	public var isPixelStage:Bool = false;
	public static var instance:Stage;


	private var player1Char:String;
	private var player2Char:String;
	private var gfChar:String;


	public var gf:Character = null;
	public var curStage:String;
	public var boyfriend:Character = null;
	public var dad:Character = null;
	



    public function new(curStage:String, Player1Char:String, Player2Char:String, gfChar:String)
	{
		super();
		this.player1Char = Player1Char;
		this.player2Char = Player2Char;
		this.gfChar = gfChar;
		this.curStage = curStage;
		instance = this;
        setupstagejson();

        
		
	}


	


    function setupscript(){
        var hxFile:String = 'data/stages/' + curStage + '.hx';
		trace('the hxfile is' + hxFile);
        Scripthandler.setupScripts(hxFile, this);
		stagescript = Scripthandler.setupScripts(hxFile, this, true);
		trace('the stagescript is' + stagescript);
	


    }
	/**
   * You can use this function in FlxTypedGroup.sort() to sort FlxObjects by their z-index values.
   * The value defaults to 0, but by assigning it you can easily rearrange objects as desired.
   *
   * @param order Either `FlxSort.ASCENDING` or `FlxSort.DESCENDING`
   * @param a The first FlxObject to compare.
   * @param b The second FlxObject to compare.
   * @return 1 if `a` has a higher z-index, -1 if `b` has a higher z-index.
   */
  public static inline function byZIndex(order:Int, a:FunkinSprite, b:FunkinSprite):Int
  {
    if (a == null || b == null) return 0;
    return FlxSort.byValues(order, a.zIndex, b.zIndex);
  }

	function setupstagejson(){
        stageData = StageData.getStageFile(curStage);
		
		trace('STAGE DATA:' + stageData);
		setupscript();
		if(HaxeScript.isInPlayState()){
			PlayState.instance.defaultCamZoom = stageData.defaultZoom;
		}
		isPixelStage = stageData.isPixelStage;

		stageGroup = new FlxTypedGroup<FunkinSprite>();
		add(stageGroup);
		trace('adding CHARACTERS');
		
		for (name in Reflect.fields(stageData.characters))
		{
			trace('adding character: ' + name);
			addcharacter(Reflect.field(stageData.characters, name), name);
		}
		trace('adding props');

		addprops(stageData.props);
		Scripthandler.dispatchevent('postPropCreation',[]);
		stageGroup.sort(byZIndex, FlxSort.ASCENDING);
        
    }

	public function forcesort(){
		stageGroup.sort(byZIndex, FlxSort.ASCENDING);
	}

	public function handlecamerafocus(){
		var focus:String = stageData.camera_focus;
		var char:Character = getCharacter(focus);
		var offsets:Array<Float> = [0,0];
		if(focus == 'dad' || focus == 'boyfriend' || focus == 'girlfriend'){
			trace('focusing camera on character: ' + focus);
			var char:Character = getCharacter(focus);
			switch(focus){
				case 'dad':
					offsets = [150, -100];
				case 'boyfriend' , 'girlfriend':
					offsets = [-100, -100];
			}
					
			PlayState.instance.snapCamFollowToPos(char.getMidpoint().x + char.cameraPosition[0] + offsets[0], char.getMidpoint().y + char.cameraPosition[1] + offsets[1]);

		}
		else {
			var prop:FunkinSprite = grabProp(focus);
			if (prop != null){
				PlayState.instance.snapCamFollowToPos(prop.getMidpoint().x , prop.getMidpoint().y );
				trace('focusing camera on prop: ' + focus);
			} else {
				trace('could not find camera focus target: ' + focus);
			}
		}
	}
	public function addBehindchar(type:String, object:FunkinSprite){
		var char = getCharacter(type);
		var index = char.zIndex -1;
		stageGroup.insert(index,object);
		stageGroup.sort(byZIndex, FlxSort.ASCENDING);
	}

	public function getCharacter(type:String):Character{
		switch(type){
			case 'dad':
				return dad;
			case 'boyfriend':
				return boyfriend;
			case 'girlfriend':
				return gf;
			default:
				FlxG.log.warn('Character type not found: ' + type + ' RETURNING NULL' );
				return null;
		}
	}
	
	public function grabProp(name:String):FunkinSprite{
		for (prop in stageGroup.members)
		{
		
			if (prop.id == name)
			{
				return prop;
			}
		}
		return null;
	}

	function addprops(props:Array<PropData>){
		for (prop in props)
		{
			trace('adding prop: ' + prop.name);
			switch(prop.PropType)
			{
				case 'ColorSprite':
					var bgSprite:FunkinSprite = new FunkinSprite(0,0);
					bgSprite.id = prop.name;
					bgSprite.zIndex = prop.zIndex;
					bgSprite.alpha = prop.alpha;
					bgSprite.makeGraphic(Std.int(prop.scale[0]), Std.int(prop.scale[1]), FlxColor.fromString(prop.path));
					bgSprite.velocity.set(prop.velocity[0], prop.velocity[1]); 
					bgSprite.angle = prop.angle;
					if(prop.blend != 'nan' ){
						bgSprite.blend = getBlendmodeFromString(prop.blend);

					}
					Scripthandler.dispatchevent('Prop Creation',[bgSprite]);
					stageGroup.add(bgSprite);

				case 'BGSprite':
					trace('the prop path is ' + stageData.directory+ '/' + prop.path);
					var bgSprite:BGSprite = new BGSprite(stageData.directory+ '/' + prop.path, prop.position[0], prop.position[1], prop.scroll[0], prop.scroll[1], prop.animations);
					bgSprite.id = prop.name;
					bgSprite.zIndex = prop.zIndex;
					bgSprite.alpha = prop.alpha;
					bgSprite.scale.set(prop.scale[0], prop.scale[1]);
					bgSprite.velocity.set(prop.velocity[0], prop.velocity[1]); 
					bgSprite.angle = prop.angle;
					if(prop.blend != 'nan' ){
						bgSprite.blend = getBlendmodeFromString(prop.blend);

					}
					Scripthandler.dispatchevent('Prop Creation',[bgSprite]);
					stageGroup.add(bgSprite);
				case 'FunkinBackdrop':
					var axsis:FlxAxes = FlxAxes.XY;
					trace('the prop repeat axes is ' + prop.repeatAxes.toLowerCase());
					switch(prop.repeatAxes.toLowerCase())
					{
						case 'x':
							axsis = FlxAxes.X;
						case 'y':
							axsis = FlxAxes.Y;
						case 'xy':
							axsis = FlxAxes.XY;
						case 'none':
							axsis = FlxAxes.NONE;
						default:
							axsis = FlxAxes.NONE;
					}
					var bgSprite:FunkinBackdrop = new FunkinBackdrop(stageData.directory+ '/' + prop.path, axsis, prop.spacing[0], prop.spacing[1], prop.animations);

					trace(bgSprite.repeatAxes + ' is the repeat axes compared to ' + prop.repeatAxes);
					bgSprite.x = prop.position[0];
					bgSprite.y = prop.position[1];
					bgSprite.id = prop.name;
					bgSprite.velocity.set(prop.velocity[0], prop.velocity[1]); 
					bgSprite.zIndex = prop.zIndex;
					bgSprite.alpha = prop.alpha;
					bgSprite.scale.set(prop.scale[0], prop.scale[1]);
					bgSprite.angle = prop.angle;
					if(prop.blend != 'nan' ){
						trace('the prop blend mode is ' + prop.blend);
						bgSprite.blend = getBlendmodeFromString(prop.blend);
					}
					Scripthandler.dispatchevent('Prop Creation',[bgSprite]);
					stageGroup.add(bgSprite);
				// You can add more prop types here
		}

	}
}

function functionfromscripts(name:String, params:Array<HaxeScript.AnyValue>){
	stagescript.runFunction(name, params);
	}
 
function getBlendmodeFromString(blend:String){
	trace('looking for blend mode: ' + blend);
	switch(blend.toLowerCase()){
		case 'subtract':
			return BlendMode.SUBTRACT;
		case 'add':
			return BlendMode.ADD;
		case 'multiply':
			return BlendMode.MULTIPLY;
		case 'alpha':
			return BlendMode.ALPHA;
		case 'darken':
				return BlendMode.DARKEN;
		case 'difference':
			return BlendMode.DIFFERENCE;
		case 'invert':
				return BlendMode.INVERT;
		case 'hardlight':
				return BlendMode.HARDLIGHT;
		case 'lighten':
				return BlendMode.LIGHTEN;
		case 'overlay':
				return BlendMode.OVERLAY;
		case 'shader':
				return BlendMode.SHADER;
		case 'screen':
				return BlendMode.SCREEN;
		}
		trace('couldnt find blendmode: ' + blend);
		return BlendMode.ADD;
	}
 

	

	

	public function characterBopper(beat:Int)
	{
		if (gf != null
			&& beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
			&& gf.animation.curAnim != null
			&& !gf.animation.curAnim.name.startsWith("sing")
			&& !gf.stunned)
			gf.dance();
		if (beat % boyfriend.danceEveryNumBeats == 0
			&& boyfriend.animation.curAnim != null
			&& !boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.stunned)
			boyfriend.dance();
		if (beat % dad.danceEveryNumBeats == 0
			&& dad.animation.curAnim != null
			&& !dad.animation.curAnim.name.startsWith('sing')
			&& !dad.stunned)
			dad.dance();


			for (prop in stageGroup.members)
			{
				if (!Std.is(prop, Character))
				{
					prop.dance();
				}
			}

		Scripthandler.dispatchevent('PropDance',[beat]);
	}
	
   
	public function resetchars(type:String, tochange:String)  //used in editor only, will have change event use this soon
	{
		var oldChar:Character = getCharacter(type);
		if (oldChar == null) return;

	
		var x = oldChar.x;
		var y = oldChar.y;
		var zindex = oldChar.zIndex;
		stageGroup.remove(oldChar, true);
		var newChar = new Character(x, y, tochange, type, type == 'boyfriend');
		var chararray:Array<Float> = charposmap.get(type);
		newChar.x = chararray[0] - newChar.characterOrigin.x;
      	newChar.y = chararray[1] - newChar.characterOrigin.y;
		newChar.zIndex = zindex;
		switch(type){
			case 'dad': 
				dad = newChar;
				stageGroup.add (dad);
			case 'boyfriend': 
				boyfriend = newChar;
				stageGroup.add (boyfriend);
			case 'girlfriend': 
				gf = newChar;
				stageGroup.add (gf);
		}

    	stageGroup.sort(byZIndex, FlxSort.ASCENDING);
}


	
    public function addcharacter(chardata:CharacterData, char:String = 'other'){
        switch(char){

            case 'dad':
				trace('adding dad');
				charposmap.set('dad', [chardata.position[0], chardata.position[1]]);
                dad = new Character(chardata.position[0], chardata.position[1], player2Char,char);
				dad.x = chardata.position[0] - dad.characterOrigin.x;
      			dad.y = chardata.position[1] - dad.characterOrigin.y;
				charextradata(dad, chardata);

		        startCharacterPos(dad, true);
               
            case 'boyfriend':
				trace('adding boyfriend');
				charposmap.set('boyfriend', [chardata.position[0], chardata.position[1]]);
                boyfriend = new Character(chardata.position[0], chardata.position[1], player1Char,char,true);
				boyfriend.x = chardata.position[0] - boyfriend.characterOrigin.x;
      			boyfriend.y = chardata.position[1] - boyfriend.characterOrigin.y;
				charextradata(boyfriend, chardata);
				startCharacterPos(boyfriend);
				
		
		  

             
            case 'girlfriend':
				trace('adding gf');
				charposmap.set('girlfriend', [chardata.position[0], chardata.position[1]]);
				GF_X = chardata.position[0];
				GF_Y = chardata.position[1];
                if (!stageData.hide_girlfriend)
                    {
                        gf = new Character(chardata.position[0], chardata.position[1], gfChar,char);
						gf.x = chardata.position[0] - gf.characterOrigin.x;
      					gf.y = chardata.position[1] - gf.characterOrigin.y;
						
                        startCharacterPos(gf);
						charextradata(gf, chardata);
						startCharacterPos(gf);
                    }
	}
}
	function charextradata(charobject:Character, chardata:CharacterData){
		charobject.zIndex = chardata.zIndex;
		charobject.angle = chardata.angle;
		charobject.alpha = chardata.alpha;
		charobject.scrollFactor.set(chardata.scroll[0], chardata.scroll[1]);
		stageGroup.add(charobject);
		Scripthandler.dispatchevent('CharacterCreation',[charobject.charactertype, charobject, chardata]);
	}


	 
	public function startCharacterPos(char:Character, gfCheck:Bool = false)
	{
		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
			gf.alpha = 0;
		}
	}


public function add(obj:FlxBasic){
    FlxG.state.add(obj);
}

override function destroy(){
	Scripthandler.dispatchevent('destroy',[]);
    super.destroy();
}

    
}