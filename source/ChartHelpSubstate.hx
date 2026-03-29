package editors;

import flixel.FlxG;
import flixel.FlxSprite;
import MusicBeatSubstate;
import flixel.ui.FlxButton;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;



class ChartHelpSubstate extends MusicBeatSubstate
{
	var textBox:FlxSprite;
    var textexample:FlxText;  
    var bPos:FlxPoint;
	public function new()
	{
		super();

		textBox = new FlxSprite().makeGraphic(Std.int(5), Std.int(5),FlxColor.BLUE);
	
		textBox.screenCenter();
		textBox.scrollFactor.set();
		textBox.alpha = 0;
		
		
		bPos = FlxPoint.get(textBox.x, textBox.y);
		

        add(textBox);
        var textexample:FlxText = new FlxText(0, 0, 0, 'test', 16);
        textexample.screenCenter();
        textexample.alpha = 0;
        
        add(textexample);
        var closebutton:FlxButton = new FlxButton(textexample.x -100, textexample.y -100, "close", function()
		{
			close();
            
		});
        
        add(closebutton);
        FlxTween.tween(textBox, {x: 0, y: 0, alpha: 1}, 0.75, {ease: FlxEase.quartOut});
        FlxTween.tween(textBox.scale, {x: 200 }, 0.3, {ease: FlxEase.quadOut});
        FlxTween.tween(textBox.scale, {y: 200 }, 0.3, {ease: FlxEase.quadOut,  startDelay: 0.15, onComplete: function(tween:FlxTween){
             textexample.x = textBox.getMidpoint().x;
             textexample.y = textBox.getMidpoint().y;
             closebutton.x = textBox.getMidpoint().x;
             closebutton.y = textBox.getMidpoint().y;
              FlxTween.tween(textexample, {alpha: 1 }, 0.2, {ease: FlxEase.quadOut});
              FlxTween.tween(closebutton, {alpha: 1 }, 0.2, {ease: FlxEase.quadOut});

        }});
	}
    override function close():Void
	{
		super.close();
		
	}

	override function update(elapsed:Float)
	{
		// placeholder update logic; keeps beat handling from parent
        if(textexample !=null){
            FlxG.watch.addQuick('x', textexample.x);
            FlxG.watch.addQuick('y', textexample.y);

        }
        
		super.update(elapsed);
	}
}

