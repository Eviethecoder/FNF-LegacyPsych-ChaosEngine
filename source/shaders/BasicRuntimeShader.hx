package shaders;

import flixel.addons.display.FlxRuntimeShader;
import openfl.display.BitmapData;

class BasicRuntimeShader extends FlxRuntimeShader {
    public var time(default, set):Float = 0;

    public function new(fragmentSource:String = null) {
        super(fragmentSource, null);
    }

    function set_time(value:Float):Float {
        this.setFloat('uTime', value);
        return time = value;
    }

    public function setBitmap(name:String, bmp:BitmapData):Void {
        this.setBitmapData(name, bmp);
    }

    public function update(elapsed:Float):Void {
        time += elapsed;
        set_time(time);
    }
}
