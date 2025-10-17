package objects;

import flixel.addons.effects.FlxSkewedSprite;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import openfl.display.BitmapData;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.FlxCamera;
import openfl.system.System;

class FunkinSprite extends FlxSkewedSprite {
    public function new(x:Float = 0, y:Float = 0) {
        super(x, y);
        // Initialization code here
        this.animation.finishCallback = this.onAnimationFinished;
    }


    //this all is a glorified v-slice port for use here. with some changes to make it acscessable to any sprite class
    public function getCurrentAnimation():String
	{
	  if (this.animation == null || this.animation.curAnim == null) return "";
	  return this.animation.curAnim.name;
	}

    public function isAnimationFinished():Bool
{
        // Check that animation exists and has a valid 'finished' field
        if (this.animation != null) {
            return this.animation.finished;
        }
        else{
            return false;
        }
}

        /**
     * Ensure scale is applied when cloning a sprite.R
     * The default `clone()` method acts kinda weird TBH.
     * @return A clone of this sprite.
     */

        /**
     * Called when an animation finishes.
     * @param name The name of the animation that just finished.
     */
    public function onAnimationFinished(name:String)
    {
        // left blank for classes to add their own functionality
    
    }
    public override function clone():FunkinSprite
    {
        
        var result = new FunkinSprite(this.x, this.y);
        result.frames = this.frames;
        result.scale.set(this.scale.x, this.scale.y);
        result.updateHitbox();

        return result;
    }

    @:access(flixel.FlxCamera)
    override function getBoundingBox(camera:FlxCamera):FlxRect
    {
        getScreenPosition(_point, camera);

        _rect.set(_point.x, _point.y, width, height);
        _rect = camera.transformRect(_rect);

        if (isPixelPerfectRender(camera))
        {
        _rect.width = _rect.width / this.scale.x;
        _rect.height = _rect.height / this.scale.y;
        _rect.x = _rect.x / this.scale.x;
        _rect.y = _rect.y / this.scale.y;
        _rect.floor();
        _rect.x = _rect.x * this.scale.x;
        _rect.y = _rect.y * this.scale.y;
        _rect.width = _rect.width * this.scale.x;
        _rect.height = _rect.height * this.scale.y;
        }

        return _rect;
    }

    /**
     * Returns the screen position of this object.
     *
     * @param   result  Optional arg for the returning point
     * @param   camera  The desired "screen" coordinate space. If `null`, `FlxG.camera` is used.
     * @return  The screen position of this object.
     */
    public override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
    {
        if (result == null) result = FlxPoint.get();

        if (camera == null) camera = FlxG.camera;

        result.set(x, y);
        if (pixelPerfectPosition)
        {
        _rect.width = _rect.width / this.scale.x;
        _rect.height = _rect.height / this.scale.y;
        _rect.x = _rect.x / this.scale.x;
        _rect.y = _rect.y / this.scale.y;
        _rect.round();
        _rect.x = _rect.x * this.scale.x;
        _rect.y = _rect.y * this.scale.y;
        _rect.width = _rect.width * this.scale.x;
        _rect.height = _rect.height * this.scale.y;
        }

        return result.subtract(camera.scroll.x * scrollFactor.x, camera.scroll.y * scrollFactor.y);
    }

    override function drawSimple(camera:FlxCamera):Void
    {
        getScreenPosition(_point, camera).subtractPoint(offset);
        if (isPixelPerfectRender(camera))
        {
        _point.x = _point.x / this.scale.x;
        _point.y = _point.y / this.scale.y;
        _point.round();

        _point.x = _point.x * this.scale.x;
        _point.y = _point.y * this.scale.y;
        }

        _point.copyToFlash(_flashPoint);
        camera.copyPixels(_frame, framePixels, _flashRect, _flashPoint, colorTransform, blend, antialiasing);
    }

    override function drawComplex(camera:FlxCamera):Void
    {
        _frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
        _matrix.translate(-origin.x, -origin.y);
        _matrix.scale(scale.x, scale.y);

        if (bakedRotationAngle <= 0)
        {
        updateTrig();

        if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
        }

        getScreenPosition(_point, camera).subtractPoint(offset);
        _point.add(origin.x, origin.y);
        _matrix.translate(_point.x, _point.y);

        if (isPixelPerfectRender(camera))
        {
        _matrix.tx = Math.round(_matrix.tx / this.scale.x) * this.scale.x;
        _matrix.ty = Math.round(_matrix.ty / this.scale.y) * this.scale.y;
        }

        camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
    }

    public override function destroy():Void
    {
        
        frames = null;
        // Cancel all tweens so they don't continue to run on a destroyed sprite.
        // This prevents crashes.
        FlxTween.cancelTweensOf(this);
        super.destroy();
    }
}
