package shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;

class AngleMask extends FlxShader
{
	public var extraColor(default, set):FlxColor = 0xFFFFFFFF;
	public var endangle(default, set):Array<Float> = [0, 0];

	function set_endangle(value:Array<Float>):Array<Float>
	{
		this.endangle = value;
		endPosition.value = value;
		return this.endangle;
	}

	function set_extraColor(value:FlxColor):FlxColor
	{
		extraTint.value = [value.redFloat, value.greenFloat, value.blueFloat];
		this.extraColor = value;

		return this.extraColor;
	}

	@:glFragmentSource('
    #pragma header

    uniform vec3 extraTint;

    uniform vec2 endPosition;
    vec2 hash22(vec2 p) {
      vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
      p3 += dot(p3, p3.yzx + 33.33);
      return fract((p3.xx + p3.yz) * p3.zy);
    }



    // ====== GAMMA CORRECTION ====== //
    // Helps with color mixing -- good to have by default in almost any shader
    // See https://www.shadertoy.com/view/lscSzl
    vec3 gamma(in vec3 color) {
      return pow(color, vec3(1.0 / 2.2));
    }

    vec4 mainPass(vec2 fragCoord)
  {
      vec4 base = flixel_texture2D(bitmap, fragCoord);


      vec2 uv = fragCoord.xy;


      vec2 start = vec2(0.5, 0.5);


      vec2 end = endPosition / openfl_TextureSize.xy;


      vec2 dir = end - start;


        float dirLen = length(dir);
        if (dirLen <= 0.00001)
          return base;


        vec2 nDir = dir / dirLen;


        vec2 rel = uv - start;

        float side = dot(rel, nDir);
        if (side >= 0.0)
          return base;
        return vec4(0.0);
  }

    vec4 antialias(vec2 fragCoord) {

      const float AA_STAGES = 2.0;

      const float AA_TOTAL_PASSES = AA_STAGES * AA_STAGES + 1.0;
      const float AA_JITTER = 0.5;

      // Run the shader multiple times with a random subpixel offset each time and average the results
      vec4 color = mainPass(fragCoord);
      for (float x = 0.0; x < AA_STAGES; x++)
      {
          for (float y = 0.0; y < AA_STAGES; y++)
          {
              vec2 offset = AA_JITTER * (2.0 * hash22(vec2(x, y)) - 1.0) / openfl_TextureSize.xy;
              color += mainPass(fragCoord + offset);
          }
      }
      return color / AA_TOTAL_PASSES;
    }

    void main() {
      vec4 col = antialias(openfl_TextureCoordv);
      col.xyz = col.xyz * extraTint.xyz;
      // col.xyz = gamma(col.xyz);
      gl_FragColor = col;
    }')
	public function new()
	{
		super();

		endPosition.value = [0, 0];
		extraTint.value = [1, 1, 1];
	}
}
