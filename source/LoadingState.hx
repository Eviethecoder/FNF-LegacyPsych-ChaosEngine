package;

import data.StageData;
import flixel.FlxG;
import flixel.FlxSprite;
import objects.FunkinMemory;

class LoadingState extends MusicBeatState
{
	public var stateToLoad:MusicBeatState;
	public var stopMusic:Bool;
	public var loadingamount:Float = 0;
	public var loaadingpercent:Float = 0; // not a percent

	public static var stagedata:StageFile;

	public function new(dastate:MusicBeatState = null, stopmusic:Bool = false) // add loading paramaters for non playstate preloading if we need to
	{
		super();
		this.stateToLoad = dastate;
		this.stopMusic = stopmusic;
	}

	override public function create()
	{
		super.create();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xffc01b1b;
		bg.scale.y = FlxG.height / (bg.height);
		bg.scale.x = FlxG.width / (bg.width);
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		bg.scrollFactor.set(0, 0);
		trace('loading state created:' + Type.getClassName(Type.getClass(stateToLoad)) + ' is the class name of the state we are loading');
		add(bg);

		if (Type.getClassName(Type.getClass(stateToLoad)) == "PlayState")
		{
			initpreload();
		}
		else
		{
			switchstate(stopMusic);
		}
	}

	function switchstate(stopMusic:Bool)
	{
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
		MusicBeatState.switchState(stateToLoad);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (loaadingpercent == loadingamount)
		{
			if (controls.ACCEPT)
			{
				switchstate(stopMusic);
			}
		}
	}

	function initpreload()
	{
		FunkinMemory.clearUnusedMemory();
		var directory:String = '';
		stagedata = StageData.getStageFile(PlayState.SONG.stage);
		if (stagedata.directory != '')
		{
			trace('stage has directory: ' + stagedata.directory);
			directory = stagedata.directory;
		}
		loadingamount = stagedata.props.length;
		for (i in 0...stagedata.props.length)
		{
			var prop = stagedata.props[i];
			if (prop.PropType != "ColorSprite")
			{
				Paths.returnGraphic(Paths.vsliceimage(directory + '/' + prop.path));
			}
			loaadingpercent++;
		}
	}

	public static function forcereloadstagedata()
	{
		stagedata = StageData.getStageFile(PlayState.SONG.stage);
	}
}
