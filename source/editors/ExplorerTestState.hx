package editors;


import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import ui.Explorerbar;
import ui.Window;
import ui.CheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.text.FlxText;
import flixel.addons.ui.FlxUICheckBox;
import objects.Cursor;

class ExplorerTestState extends MusicBeatState {
    var bar:Explorerbar;
    var infoText:FlxText;
    var testwindow:Window;

    override public function create():Void {
        super.create();
        Cursor.show();

        // Background (like a window backdrop)
        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF9FA931;
		add(bg);

        testwindow = new Window("Confirm Action", "Are you sure you want to continue?", 200, 500);
        testwindow.alpha = 0;
        add(testwindow);

        testwindow.addButton("TEST", function() {
            FlxG.log.add("TEST clicked!");
        });

        bar = new Explorerbar();

        bar.addButton("New Chart", function() {
            FlxG.log.add("New Chart clicked!");
        });

        bar.addButton("NoteMenus", function() {
            FlxG.log.add("NoteMenu placeholder!");
        });
        bar.addButton("Charting Window", function() {
            FlxG.log.add("Created new folder!");
        });

        bar.addButton("NoteMenus", function() {
            FlxG.log.add("Delete clicked!");
        });

         bar.addButton("OtherMenus", function() {
           
        }, [
            { label: "TestWindow", onClick: windowtest },
            { label: "Events", onClick: () -> FlxG.log.add("Icons view") },
            { label: "List", onClick: () -> FlxG.log.add("List view") }
        ]);

        var check_player = new CheckBox(10, 60, "Playable Character", 100);
        check_player.screenCenter();
        add(bar);
        add(check_player);


        // Example text area (pretend this is file content)
        infoText = new FlxText(20, 60, 400, "Click the toolbar buttons above.\nLogs will appear in the console.");
        infoText.setFormat(null, 14, FlxColor.RED);
        add(infoText);

      
    }

    function windowtest():Void {
        switch(testwindow.alpha) {
            case 0:
                testwindow.alpha = 1;
            case 1:
                testwindow.alpha = 0;
        }
    }
    function onViewIcons():Void {
        FlxG.log.add("Switched to Icons view.");
    }
    function onViewList():Void {
        FlxG.log.add("Switched to List view.");
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

    }
}
