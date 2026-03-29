
package objects;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import objects.FunkinSprite;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import openfl.display.BitmapData;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.FlxCamera;
import openfl.system.System;
import flixel.util.FlxDestroyUtil;
import flixel.input.mouse.FlxMouseEvent;




class Button extends FunkinSprite { 
    var onclick:Void->Void;
    public function new(x:Float = 0, y:Float = 0, graphic:String, clickcallback:Void->Void,custompath:Bool = false) {
        super(x, y);

        switch(custompath){
            default:
                frames = Paths.getSparrowAtlas('menu/ui/$graphic');
            case true:
                frames = Paths.getSparrowAtlas(graphic);

        }
        animation.addByPrefix('Idle', 'Idle',8,true);
        animation.addByPrefix('Disabled', 'Disabled',8,true);
        onclick = clickcallback;
        FlxMouseEvent.add(this, onMouseDown, onMouseUp,);
    }
    function onMouseDown(sprite:FunkinSprite)
        {
            animation.play('Disabled');
             if (onclick != null)
                onclick();
        }

        function onMouseUp(sprite:FunkinSprite)
        {
            animation.play('Idle');
        }
}

