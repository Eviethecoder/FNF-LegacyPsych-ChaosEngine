package;

import openfl.display.Loader;
import openfl.net.URLRequest;
import openfl.events.Event;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.display.Shape;
import openfl.geom.Point;
import openfl.display.PixelSnapping;

using StringTools;

class Githubicon extends AttachedSprite
{
    var bmp:Bitmap;
    public function new(?fileOrUrl:String = null, ?anim:String = null, ?library:String = null, ?loop:Bool = false)
    {
        super(null, anim, library, loop);
        scrollFactor.set();

        if(fileOrUrl != null)
        {
            if(fileOrUrl.startsWith("http"))
            {
                loadFromUrl(fileOrUrl);
            }
            else
            {
                loadGraphic(Paths.image(fileOrUrl));
                
            }
        }
    }

    private function loadFromUrl(url:String):Void
    {
        var loader = new Loader();
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event) {
            var bmp:Bitmap = cast(loader.content, Bitmap);
                //made me wana kill myself ngl
            // Resize the bitmap to 150x150
            var resizedData = new openfl.display.BitmapData(150, 150, true, 0x00000000);
            resizedData.draw(bmp, new openfl.geom.Matrix(150 / bmp.width, 0, 0, 150 / bmp.height));

            pixels = resizedData;
            makeSpherical();
            dirty = true;
        });
        loader.load(new URLRequest(url));
    }
    private function makeSpherical():Void
    {
        if (pixels == null) return;

        // Create the circular mask as BitmapData
        var maskData = new BitmapData(150, 150, true, 0x00000000);
        var shape = new Shape();
        shape.graphics.beginFill(0xFFFFFF);
        shape.graphics.drawCircle(75, 75, 75);
        shape.graphics.endFill();
        maskData.draw(shape);

        // Apply the mask to the original pixels using copyPixels
        var clipped = new BitmapData(150, 150, true, 0x00000000);
        clipped.copyPixels(pixels, pixels.rect, new Point(0,0), maskData, new Point(0,0), true);

        pixels = clipped;
        dirty = true;
    }
}
