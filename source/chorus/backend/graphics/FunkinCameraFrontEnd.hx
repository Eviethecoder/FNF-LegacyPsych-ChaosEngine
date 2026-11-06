package graphics;

import flixel.FlxCamera;
import flixel.system.frontEnds.CameraFrontEnd;
import objects.FunkinCamera;

/**
 * A `CameraFrontEnd` override that uses `FunkinCamera`!
 */
@:nullSafety
class FunkinCameraFrontEnd extends CameraFrontEnd
{
  public override function reset(?newCamera:FlxCamera):Void
  {
    super.reset(newCamera ?? new FunkinCamera());
  }
}
