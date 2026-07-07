package objects;

import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import openfl.filters.BitmapFilter;


// a flxcamera class with features for ease of use/ older functions like setFilter
class FunkinCamera extends FlxCamera {
	public function new(x:Float=0, y:Float=0, width:Int=0, height:Int=0, ?zoom:Float=1) {
		super(x, y, width, height);
		
	}

  

	/**
	 * Sets the filter array to be applied to the camera.
	 */
	public function setFilters(filters:Array<BitmapFilter>):Void
	{
		this.filters = filters;
	}

	

	
}

