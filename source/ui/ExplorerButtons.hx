package ui;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.input.mouse.FlxMouseEvent;
import flixel.ui.FlxButton;
import flixel.math.FlxPoint;
import objects.Cursor;




class ExplorerButtons extends FlxButton {
    public function new(X:Float, Y:Float, Label:String, OnClick:Void->Void) {
        super(X, Y, Label, OnClick);
        frames = Paths.getSparrowAtlas('editorui/button');
        animation.addByPrefix("idle", "NotSelect",1,false);
        animation.addByPrefix("pressed", "Select",1,false);
        label.setFormat(null, 12, FlxColor.WHITE, "center");
        FlxMouseEvent.add(this, onMouseDown, onMouseUp, onMouseOver, onMouseOut);
    }


    function onMouseOver(sprite:FlxButton){
        Cursor.set_cursorMode(Pointer);
        
    }

    function onMouseDown(sprite:FlxButton){
        animation.play("pressed");
    }

    function onMouseUp(sprite:FlxButton){
        Cursor.set_cursorMode(Default);
        animation.play("idle");
    }

    function onMouseOut(sprite:FlxButton){
        Cursor.set_cursorMode(Default);
        animation.play("idle");
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if (alpha == 0){
            return;
        }
        else{
            super.update(elapsed);
        }
       
    }
    
}
