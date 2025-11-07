package ui;

import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import ui.ExplorerButtons;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import objects.Cursor;
import ui.Explorerbar.DropdownItem;
import flixel.math.FlxPoint;

class Window extends FlxSpriteGroup
{
    public var windowwidth:Float;
    public var windowheight:Float;
    var barHeight = 100;

    var bg:FlxSprite;
    var bar:FlxSprite;

    // Used for dragging
    var dragging:Bool = false;
    var dragOffset:FlxPoint;
    public var buttonSpacing:Float = 30;
    public var buttonStartX:Float = 220;
    public var buttonStartY:Float = 8;
    public var buttonYmod:Float = 0;
    public var buttons:Array<FlxButton> = [];

    public function new(title:String, message:String, width:Int = 200, height:Int = 400)
    {
        super();

        this.windowwidth = width;
        buttonStartX = windowwidth / 10;
        this.windowheight = height;
        

        bg = new FlxSprite(0, 0);
        bg.makeGraphic(width, height, FlxColor.BLACK);
        bg.alpha = 0.9;
        add(bg);

        bar = new FlxSprite(0, 0);
        bar.makeGraphic(width, Std.int(barHeight / 8), FlxColor.WHITE);
        bar.alpha = 0.9;
        bar.y = bg.y - bar.height;
        buttonStartY = bar.y + 50;
        add(bar);

        var titleText = new FlxText(0, 5, width, title);
        titleText.setFormat(null, 14, FlxColor.YELLOW, "center");
        add(titleText);

        var msgText = new FlxText(0, 30, width, message);
        msgText.setFormat(null, 12, FlxColor.WHITE, "center");
        add(msgText);

        var close = new WindowButtons(bar.width - 20, bar.y, "X", function() {
            alpha = 0;
        });
        close.setup([20, bar.height], FlxColor.RED);
        add(close);

        this.x = (FlxG.width - width) / 2;
        this.y = (FlxG.height - height) / 2;
    }

    override function update(elapsed:Float)
    {
        

        if (alpha == 0)
            return;
        else{
            super.update(elapsed);
        }

        var mousePos = FlxG.mouse.getWorldPosition();
        if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(bar))
        {
            dragging = true;
            dragOffset = new FlxPoint(mousePos.x - this.x, mousePos.y - this.y);
        }
        if (FlxG.mouse.justReleased)
        {
            dragging = false;
        }
        if (dragging)
        {
            this.x = mousePos.x - dragOffset.x;
            this.y = mousePos.y - dragOffset.y;
        }
    }

    
    /**
     * Adds a button to the bar.
     * @param dropdownItems Optional array of dropdown entries (label + onClick).
     */
    public function addButton( label:String,onClick:Void->Void):FlxButton {
  
        var xPos:Float = buttonStartX;
        var yPos:Float = buttonStartY + buttonYmod;
        for (btn in buttons) {
            xPos += btn.graphic.width; 
        }
        if(xPos >= this.windowwidth - 40) {
            xPos = buttonStartX;
            buttonYmod += 30;
        
          
        }
        var btn = new ExplorerButtons(xPos, 8, label, function() {
            onClick();
        });
        btn.scale.set(0.7,0.7);
        add(btn);
        buttons.push(btn);
        return btn;
    }
}

class WindowButtons extends FlxButton
{
    public function new(X:Float, Y:Float, Label:String, OnClick:Void->Void)
    {
        super(X, Y, Label, OnClick);
        label.setFormat(null, 7, FlxColor.WHITE, "center");
        onOver.callback = overlap;
        onOut.callback = onleave;
    }

    public function setup(size:Array<Float>, color:FlxColor)
    {
        makeGraphic(Std.int(size[0]), Std.int(size[1]), color);
    }

    function overlap()
    {
        Cursor.set_cursorMode(Pointer);
    }

    function onleave()
    {
        Cursor.set_cursorMode(Default);
    }
}
