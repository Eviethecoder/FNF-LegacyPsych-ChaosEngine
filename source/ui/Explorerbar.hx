package ui;

import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.ui.FlxButton;
import flixel.math.FlxPoint;
import ui.DropdownButton;
import ui.ExplorerButtons;
import objects.Cursor;

typedef DropdownItem = {
    var label:String;
    var onClick:Void->Void;
};

class Explorerbar extends FlxSpriteGroup {
    public var bg:FlxSprite;
    public var titleText:FlxText;
    public var buttons:Array<FlxButton> = [];
    public var dropdowns:Map<String, FlxSpriteGroup> = new Map();
    public var buttonSpacing:Float = 30;
    public var buttonStartX:Float = 220;

    public function new(X:Float = 0, Y:Float = 0, ?title:String = "File Explorer") {
        super(X, Y);
        makeBar(title);
    }

    function makeBar(title:String):Void {
        bg = new FlxSprite(0, 0).loadGraphic(Paths.image('editorui/Bar'));
        add(bg);

        titleText = new FlxText(10, 10, 200, title);
        titleText.setFormat(null, 20, FlxColor.WHITE, "left");
        add(titleText);
    }

    /**
     * Adds a button to the bar.
     * @param dropdownItems Optional array of dropdown entries (label + onClick).
     */
    public function addButton( label:String,onClick:Void->Void,?dropdownItems:Array<DropdownItem>):FlxButton {
  
        var xPos:Float = buttonStartX;
        for (btn in buttons) {
            xPos += btn.graphic.width; 
        }
        var btn = new ExplorerButtons(xPos, 8, label, function() {
            onClick();
            if (dropdownItems != null)
                toggleDropdown(label, dropdownItems, xPos,8); 
        });
        add(btn);
        buttons.push(btn);
        return btn;
    }

    /**
     * Creates or toggles a dropdown menu under a button with clickable options.
     */
    function toggleDropdown(label:String, items:Array<DropdownItem>, xPos:Float, yPos):Void {
        closeAllDropdowns();

        var dropGroup = new FlxSpriteGroup();
        var itemHeight = 22;
        var bgHeight = itemHeight * items.length;

        // Background
        var bg = new FlxSprite(xPos, 40 ).makeGraphic(120, bgHeight, FlxColor.fromRGB(68, 62, 62));
        dropGroup.add(bg);

        for (i in 0...items.length) {
            var item = items[i];
            var itemY = 40 + i * itemHeight;

            var optionBtn = new DropdownButton(xPos, itemY, item.label, function() {
            closeAllDropdowns();
            item.onClick();
            });

            dropGroup.add(optionBtn);
            dropGroup.y += (bg.height/8);
        }

        dropdowns.set(label, dropGroup);
        add(dropGroup);
}




    public function closeAllDropdowns():Void {
        for (group in dropdowns)
            remove(group, true);
        dropdowns.clear();
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

         var inside = false;
         for (btn in buttons){
                if (FlxG.mouse.overlaps(btn)){
                    if (FlxG.mouse.justPressed) {
                        inside = true;
                      }
                }
                }

            for (group in dropdowns){
                if (FlxG.mouse.overlaps(group)){
                    if (FlxG.mouse.justPressed) {
                        inside = true;
                      }
                    
                }
            }
            if (FlxG.mouse.justPressed && !inside)
                closeAllDropdowns();
        
    }
}
