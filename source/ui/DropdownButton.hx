package ui;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import flixel.math.FlxPoint;
import objects.Cursor;


class DropdownButton extends FlxButton {
    public function new(X:Float, Y:Float, Label:String, OnClick:Void->Void) {
        super(X, Y, Label, OnClick);
        makeGraphic(120, 22, FlxColor.fromRGB(68, 62, 62));
        label.setFormat(null, 12, FlxColor.WHITE, "left");
        label.x += 5;
        onOver.callback = overlap;
        onOut.callback = onleave;
    }

    function overlap(){
        Cursor.set_cursorMode(Pointer);
    }
    function onleave(){
        Cursor.set_cursorMode(Default);
    }
}
