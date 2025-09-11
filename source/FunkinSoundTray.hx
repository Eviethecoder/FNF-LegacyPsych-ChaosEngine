package ;

import flixel.system.ui.FlxSoundTray;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.tweens.FlxEase;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import flixel.math.FlxMath;
import Assets;

/**
 *  Extends the default flixel soundtray, but with some art
 *  and lil polish!
 *
 *  Gets added to the game in Main.hx, right after FlxGame is new'd
 *  since it's a Sprite rather than Flixel related object
 */
class FunkinSoundTray extends FlxSoundTray
{
  var graphicScale:Float = 0.30;
  var lerpYPos:Float = 0;
  var alphaTarget:Float = 0;
  var bg:Bitmap;

  var volumeMaxSound:String;

  public function new()
  {
    // calls super, then removes all children to add our own
    // graphics
    super();
    removeChildren();

    bg = new Bitmap(Assets.getBitmapData(Paths.vsliceimage("soundtray/volumebox")));
    bg.scaleX = graphicScale;
    bg.scaleY = graphicScale;
    bg.smoothing = true;
    addChild(bg);

    y = -height;
    visible = false;



    // clear the bars array entirely, it was initialized
    // in the super class
    _bars = [];

    // 1...11 due to how block named the assets,
    // we are trying to get assets bars_1-10
    for (i in 1...11)
    {
      var bar:Bitmap = new Bitmap(Assets.getBitmapData(Paths.vsliceimage("soundtray/bars_" + i)));
       bar.x = 6;
      bar.y = 11;
      bar.scaleX = graphicScale;
      bar.scaleY = graphicScale;
      bar.smoothing = true;
      addChild(bar);
      _bars.push(bar);
    }

    y = -height;
    screenCenter();

    volumeUpSound = Paths.vslicesound("soundtray/volumeUp");
    volumeDownSound = Paths.vslicesound("soundtray/volumeDown");
    volumeMaxSound = Paths.vslicesound("soundtray/volumeMax");

    trace("Custom tray added!");
  }

  override public function update(MS:Float):Void
  {
    y = FlxMath.lerp(y, lerpYPos, 0.1);
    alpha = FlxMath.lerp(alpha, alphaTarget, 0.25);

    var shouldHide = (FlxG.sound.muted == false && FlxG.sound.volume > 0);

    // Animate sound tray thing
    if (_timer > 0)
    {
      if (shouldHide) _timer -= (MS / 1000);
      alphaTarget = 1;
    }
    else if (y >= -height)
    {
      lerpYPos = -height - 10;
      alphaTarget = 0;
    }

    if (y <= -height)
    {
      visible = false;
      active = false;

      #if FLX_SAVE
      // Save sound preferences
      if (FlxG.save.isBound)
      {
        FlxG.save.data.mute = FlxG.sound.muted;
        FlxG.save.data.volume = FlxG.sound.volume;
        FlxG.save.flush();
      }
      #end
    }
  }

  /**
   * Makes the little volume tray slide out.
   *
   * @param	up Whether the volume is increasing.
   */
  override public function show(up:Bool = false):Void
  {
    _timer = 1;
    lerpYPos = 0;
    visible = true;
    active = true;
    var globalVolume:Int = Math.round(FlxG.sound.volume * 10);

    if (FlxG.sound.muted || FlxG.sound.volume == 0)
    {
      globalVolume = 0;
    }

    if (!silent)
    {
      var sound = up ? volumeUpSound : volumeDownSound;

      if (globalVolume == 10) sound = volumeMaxSound;

      if (sound != null) FlxG.sound.load(sound).play();
    }

    for (i in 0..._bars.length)
    {
      if (i < globalVolume)
      {
        _bars[i].visible==true;
      }
      else
      {
        _bars[i].visible==false;
      }
    }
  }
 
  /**
	 * Shows the volume animation for the desired settings
	 * @param   volume    The volume, 1.0 is full volume
	 * @param   sound     The sound to play, if any
	 * @param   duration  How long the tray will show
	 * @param   label     The test label to display
	 */
	override public function showAnim(volume:Float, ?sound:FlxSoundAsset, duration = 1.0, label = "VOLUME")
	{
		if (sound != null)
			FlxG.sound.play(FlxG.assets.getSoundAddExt(sound));
		
		_timer = 1;
		lerpYPos = 0;
		visible = true;
		active = true;

		_label.text = label;
    final numBars = Math.round(volume * 10);
		updateSize();
    for (i in 0..._bars.length)
			_bars[i].visible = i < numBars ? true : false;
	}
  override function updateSize()
	{
		if (_label.textWidth + 10 > _bg.width)
			_label.width = _label.textWidth + 10;
			
		_bg.width = _label.textWidth + 10 > _minWidth ? _label.textWidth + 10 : _minWidth;
		
		_label.width = _bg.width;
		
		
		
		
		screenCenter();
	}
}
