package shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;

class Outline extends FlxShader {
    public var enabled(default, set):Bool;
   public var color(default, set):FlxColor;
    public var bORDERWIDTH(default, set):Float;
    private var uEnabledID:Int;
    // GLSL code using the fragment source metadata
     @:glFragmentSource('
        #pragma header

uniform bool enbl;
uniform vec4 uColor; //like [1,1,1,0] BUT 0 BARELY DOES SHIT
uniform float BORDER_WIDTH;

void main() {
    vec4 color = texture2D(bitmap, openfl_TextureCoordv);

    if (!enbl) {
        gl_FragColor = color * openfl_Alphav;
        return;
    }

    float w = BORDER_WIDTH / openfl_TextureSize.x;
    float h = BORDER_WIDTH / openfl_TextureSize.y;

    if (color.a == 0.) {
        if (
            texture2D(bitmap, vec2(openfl_TextureCoordv.x + w, openfl_TextureCoordv.y)).a != 0
            || texture2D(bitmap, vec2(openfl_TextureCoordv.x - w, openfl_TextureCoordv.y)).a != 0.
            || texture2D(bitmap, vec2(openfl_TextureCoordv.x, openfl_TextureCoordv.y + h)).a != 0.
            || texture2D(bitmap, vec2(openfl_TextureCoordv.x, openfl_TextureCoordv.y - h)).a != 0.
        ) {
            gl_FragColor = vec4(uColor.rgb, uColor.a);
        } else {
            gl_FragColor = color * openfl_Alphav;
        }
    } else {
        gl_FragColor = color * openfl_Alphav;
    }
}')

    public function new() {
        super();

        enabled = true;
        color = FlxColor.WHITE;
        bORDERWIDTH = 1.5;
    }

    function set_color(col:FlxColor):FlxColor
  {
    color = col;
    uColor.value = [color.red / 255, color.green / 255, color.blue / 255, 1.0];

    return color;
  }
   function set_bORDERWIDTH(val:Float):Float
    {
        bORDERWIDTH = val;
        BORDER_WIDTH.value = [val];
        return val;
    }

     function set_enabled(val:Bool):Bool
    {
        enbl.value = [val];
        return val;
    }
    
}
