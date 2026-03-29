package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import flixel.util.FlxColor;

using StringTools;

class StrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	private var ispixel:Bool = false;
	public var sustainSplash:SustainSplash;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	
	private var player:Int;
	var isPlayer:Bool;
	var arr:Array<Dynamic>;
	
	public var useRGBShader:Bool = true;
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(x:Float, y:Float, leData:Int, player:Int) {

		isPlayer = false;
		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData,isPlayer));
		rgbShader.enabled = false;
		switch(player)
		{
			case 0:
				isPlayer = false;
			case 1:
				isPlayer = true;

		}
		arr = PlayState.instance.hud.hudData.getNoteskinrgb(isPlayer)[leData];
		noteData = leData;
		this.player = player;

		if(leData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		this.noteData = leData;
		super(x, y);



		
		var skin:String = 'Huds/Noteskins/NOTE_assets';
		if(PlayState.instance !=null && PlayState.instance.hud.bars.noteskin != null){
			var playerbool:Bool = false;
			if(player == 1){
				playerbool = true;
			}
			skin = PlayState.instance.hud.hudData.getNoteskin(playerbool);
		}
		else{
			skin = 'Huds/Noteskins/NOTE_assets';
		}
		texture = skin; //Load texture and anims

		sustainSplash = new SustainSplash(this);

		scrollFactor.set();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		frames = Paths.getSparrowAtlas(texture);
		animation.addByPrefix('green', 'arrowUP');
		animation.addByPrefix('blue', 'arrowDOWN');
		animation.addByPrefix('purple', 'arrowLEFT');
		animation.addByPrefix('red', 'arrowRIGHT');

		antialiasing = ClientPrefs.data.globalAntialiasing;
		setGraphicSize(Std.int(width * 0.7));

		switch (Math.abs(noteData) % 4)
		{
			case 0:
				animation.addByPrefix('static', 'arrowLEFT');
				animation.addByPrefix('pressed', 'left press', 24, false);
				animation.addByPrefix('confirm', 'left confirm', 24, false);
			case 1:
				animation.addByPrefix('static', 'arrowDOWN');
				animation.addByPrefix('pressed', 'down press', 24, false);
				animation.addByPrefix('confirm', 'down confirm', 24, false);
			case 2:
				animation.addByPrefix('static', 'arrowUP');
				animation.addByPrefix('pressed', 'up press', 24, false);
				animation.addByPrefix('confirm', 'up confirm', 24, false);
			case 3:
				animation.addByPrefix('static', 'arrowRIGHT');
				animation.addByPrefix('pressed', 'right press', 24, false);
				animation.addByPrefix('confirm', 'right confirm', 24, false);
		}
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
		ID = noteData;
		
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		
		if(animation.curAnim.name == 'confirm' && !ispixel) {
			centerOrigin();
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
	
		if(animation.curAnim.name == 'confirm' ) {
			centerOrigin();
		}
		if(useRGBShader) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}
}

class SustainSplash extends FlxSprite {
	public var rgbShader:RGBShaderReference;
	public var strum:StrumNote;
	override public function new(strum:StrumNote) {
		super();
		this.strum = strum;

		@:privateAccess
		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(strum.noteData, strum.isPlayer));

		frames = Paths.getSparrowAtlas("sustain_cover");
		animation.addByPrefix('cover', 'sustain cover pre0', 24, false);
		animation.addByPrefix('splash', 'sustain cover end0', 24, false);
		animation.addByPrefix('loop', 'sustain cover0', 24);
		animation.play("loop");
		updateHitbox();
		visible = false;
		antialiasing = ClientPrefs.data.globalAntialiasing;

		scale.set(strum.scale.x / 0.7, strum.scale.y / 0.7);
		updateHitbox();
	}

	public var updatedThisFrame:Bool = false;

	public inline function show() {
		updatedThisFrame = true;
		visible = true;
		if (animation.curAnim.name != "loop") {
			animation.play("cover");
			center();
		}
	}
	public inline function hide(miss:Bool = false) {
		if (animation.curAnim.name == "splash") return;

		updatedThisFrame = true;
		if (miss) visible = false;
		if (animation.curAnim.name != "splash") {
			animation.play("splash");
			center();
		}
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		updatedThisFrame = false;

		if (animation.curAnim.finished) {
			if (animation.curAnim.name == "cover") animation.play("loop");
			if (animation.curAnim.name == "splash") visible = false;
		}
		
		//if (animation.curAnim.name != "splash") center();
		//updateHitbox();
		center();
	}

	public function center() {
		centerOffsets();
		x = strum.x + (strum.width/2) - (width/2);
		y = strum.y + (strum.height/2) - (height/2);
	}
}
