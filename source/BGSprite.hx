package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import objects.FunkinSprite;
import objects.FunkinMemory;
import Character.AnimArray as AnimArray;

class BGSprite extends FunkinSprite
{
	private var idleAnim:String;
	
	private var idlenamelist:Array<String> = ['idle', 'dance', 'bop', 'resting', 'rest'];

	public function new(image:String,x:Float = 0,y:Float = 0,scrollX:Float = 1,scrollY:Float = 1,animations:Array<AnimArray> = null, velocity:Array<Float> = null) {
		super(x, y);

		if (animations != null && animations.length > 0) {
			frames = Paths.getSparrowAtlas(image);

			for (anim in animations) {
				animation.addByPrefix(anim.name, anim.anim, anim.fps, anim.loop);
				for (name in idlenamelist) {
					if (name == anim.name) {
						idleAnim = anim.name;
						break;
					}
				}
				if (idleAnim != null) {
					animation.play(idleAnim);
				}
			}
		} else {
			if (image != null) {
				loadGraphic(FunkinMemory.returnGraphic(Paths.vsliceimage(image)));
			}
			active = false;
		}
		if (velocity != null ){
			this.velocity.set(velocity[0], velocity[1]);
			trace('the velocity is ' + this.velocity);
		}

		scrollFactor.set(scrollX, scrollY);
		antialiasing = ClientPrefs.data.globalAntialiasing;
	}

	public override function dance(?forceplay:Bool = false) {
		super.dance();
		if (idleAnim != null) {
			animation.play(idleAnim, forceplay);
		}
	}
}
