package ui;

import flixel.addons.ui.FlxUICheckBox;
import flixel.FlxG;
import flixel.util.FlxColor;



class CheckBox extends FlxUICheckBox
{
    public function new(X:Float = 0, Y:Float = 0,  ?Label:String, ?LabelW:Int = 100, ?color:Array<FlxColor>, ?Params:Array<Dynamic>, ?Callback:Void->Void)
	{
		super(X, Y, Paths.image('editorui/checkBox'), Paths.image('editorui/checkbox-check'), Label, LabelW, Params, Callback);
        this.scale.set(0.7,0.7);

        if(color != null)
        {
            if(color.length >= 0)
            {
                this.box.color = color[0];
            }
            if(color.length >= 1)
            {
                this.mark.color = color[1];
            }
        }
        else{
            this.box.color = 0x1e1b1b;
        }

    }

}
