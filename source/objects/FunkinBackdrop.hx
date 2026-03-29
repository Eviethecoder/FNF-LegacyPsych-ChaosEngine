package objects;

import flixel.util.FlxAxes;
import Character.AnimArray;
import flixel.addons.display.FlxBackdrop;

class FunkinBackdrop extends FlxBackdrop
{
	private var idleAnim:String;
	private var idleNameList:Array<String> = ['idle', 'dance', 'bop', 'resting', 'rest'];

	public function new(?path:String,?repeatAxes:FlxAxes = FlxAxes.XY,spacingX:Float = 0,spacingY:Float = 0,?animations:Array<AnimArray> = null)
	{
		super(Paths.image(path),0,0);

		this.repeatAxes = repeatAxes;
		trace("FunkinBackdrop repeatAxes: " + repeatAxes);

		if (animations != null && animations.length > 0) {
			frames = Paths.getSparrowAtlas(path);

			for (anim in animations) {
				animation.addByPrefix(anim.name, anim.anim, anim.fps, anim.loop);
				for (name in idleNameList) {
					if (name == anim.name) {
						idleAnim = anim.name;
						break;
					}
				}
				if (idleAnim != null) {
					animation.play(idleAnim);
				}
			}
		}

	}


	public override function dance(?forceplay:Bool = false) {
		super.dance();
		if (idleAnim != null) {
			animation.play(idleAnim, forceplay);
		}
	}
}
