package;

#if hxdiscord_rpc
import Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import sys.FileSystem;
import sys.io.File;

import flixel.tweens.FlxEase;

import openfl.Assets;
import haxe.Json;

using StringTools;

typedef Creditsjson = {
    var Catagorys:Array<Catagory>;
}

typedef Catagory = {
    var name:String;
    var people:Array<Creditpeople>;
}

typedef Creditpeople = {
    var name:String;
    var description:String;
    var icon:String; // GitHub username or asset name
    var link:String; // external profile
    var color:String; // hex color for background
}

class CreditsState extends MusicBeatState
{
    var curSelected:Int = -1;
    private var grpOptions:FlxTypedGroup<Alphabet>;
    private var iconArray:Array<AttachedSprite> = [];

    var bg:FlxSprite;
    var descText:FlxText;
    var intendedColor:Int;
    var colorTween:FlxTween;
    var descBox:AttachedSprite;

    var offsetThing:Float = -75;
    var quitting:Bool = false;
    var holdTime:Float = 0;

    var creditsData:Creditsjson;
    var people:Array<Creditpeople> = [];
    var categories:Array<String> = [];

    override function create()
    {
        #if desktop
        DiscordClient.changePresence("In the Menus", null);
        #end

        persistentUpdate = true;

        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        add(bg);
        bg.screenCenter();

        grpOptions = new FlxTypedGroup<Alphabet>();
        add(grpOptions);

        #if MODS_ALLOWED
        var path = Paths.mods("data/credits/credits.json");
        if (FileSystem.exists(path))
            creditsData = Json.parse(File.getContent(path));
        else
        #end
            creditsData = Json.parse(Assets.getText("assets/data/credits/credits.json"));

        // Flatten categories + people into lists
        for (cat in creditsData.Catagorys) {
            categories.push(cat.name);
            for (p in cat.people) {
                people.push(p);
            }
        }

        // Build UI
        var row = 0;
        for (cat in creditsData.Catagorys) {
			trace("Category: " + cat.name);
            // Category header
            var header = new Alphabet(FlxG.width / 2, 300, cat.name, true);
			header.isMenuItem = true; 
			header.isHeader = true;// headers are NOT selectable
            header.targetY = row;
            header.changeX = false;
            header.snapToPosition();
            header.alignment = CENTERED;
            grpOptions.add(header);
            row++;

            // Each person
            for (p in cat.people) {
                var optionText = new Alphabet(FlxG.width / 6, 300, p.name, false);
                optionText.isMenuItem = true;
                optionText.targetY = row;
                optionText.changeX = false;
                optionText.snapToPosition();
                grpOptions.add(optionText);

                // Icon: local asset or GitHub avatar
                var iconPath:String;
                if (Assets.exists(Paths.vsliceimage('credits/${p.icon}'))) {
                    iconPath = 'credits/${p.icon}';
                } else {
                    iconPath = 'https://avatars.githubusercontent.com/' + p.icon;
                }

                var icon = new Githubicon(iconPath); // NetSprite/AttachedSprite
                icon.sprTracker = optionText;
                icon.xAdd = optionText.width + 10;
                iconArray.push(icon);
                add(icon);

                if (curSelected == -1) curSelected = row;
                row++;
            }
        }

        // Description box
        descBox = new AttachedSprite();
        descBox.makeGraphic(1, 1, FlxColor.BLACK);
        descBox.xAdd = -10;
        descBox.yAdd = -10;
        descBox.alphaMult = 0.6;
        descBox.alpha = 0.6;
        add(descBox);
		trace("desk");
        descText = new FlxText(50, FlxG.height + offsetThing - 25, 1180, "", 32);
        descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
        descText.scrollFactor.set();
        descBox.sprTracker = descText;
        add(descText);

        // Initial background color
        var first = getCurrentPerson();
        if (first != null) {
            bg.color = CoolUtil.colorFromString(first.color);
            intendedColor = bg.color;
        }

        changeSelection();
		trace("create");
        super.create();
    }

    function getCurrentPerson():Creditpeople {
		if (curSelected < 0 || curSelected >= grpOptions.members.length) return null;
		var selectedItem = grpOptions.members[curSelected];
		if (selectedItem.isHeader) return null; // headers have no description

		// Map selection index to people array
		var peopleCount = 0;
		for (cat in creditsData.Catagorys) {
			for (p in cat.people) {
				if (peopleCount == curSelected - countHeadersBefore(curSelected)) return p;
				peopleCount++;
			}
		}
		return null;
}

	var moveTween:FlxTween = null;
    function changeSelection(change:Int = 0) {
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = grpOptions.members.length - 1;
			if (curSelected >= grpOptions.members.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));
		var bullShit:Int = 0;
        // Update menu item positions
		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}
       

        var person = getCurrentPerson();
        if (person != null) {
            var newColor = CoolUtil.colorFromString(person.color);
            if (newColor != intendedColor) {
                if (colorTween != null) colorTween.cancel();
                intendedColor = newColor;
                colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
                    onComplete: function(_) colorTween = null
                });
            }

            descText.text = person.description;
            descText.y = FlxG.height - descText.height + offsetThing - 60;
            descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
            var changeamount: Int = 1;
        
            if(moveTween != null) moveTween.cancel();
		    moveTween = FlxTween.tween(descText, {y : descText.y + 75}, 0.25, {ease: FlxEase.sineOut});
        }
    }

    override function update(elapsed:Float) {
        if (!quitting) {
            if (grpOptions.members.length > 1) {
                var shiftMult:Int = 1;
                if (FlxG.keys.pressed.SHIFT) shiftMult = 3;

                var upP = controls.UI_UP_P;
                var downP = controls.UI_DOWN_P;

                if (upP) {
                    changeSelection(-shiftMult);
                    holdTime = 0;
                }
                if (downP) {
                    changeSelection(shiftMult);
                    holdTime = 0;
                }

                if (controls.UI_DOWN || controls.UI_UP) {
                    var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
                    holdTime += elapsed;
                    var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

                    if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
                        changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
                    }
                }
            }
        }

        if (controls.ACCEPT) {
            var person = getCurrentPerson();
            if (person != null && person.link.length > 4)
                CoolUtil.browserLoad(person.link);
        }

        if (controls.BACK) {
            if (colorTween != null) colorTween.cancel();
            FlxG.sound.play(Paths.sound('cancelMenu'));
            quitting = true;
            MusicBeatState.switchState(new MainMenuState());
        }
		// ...existing code...
		for (i in 0...grpOptions.members.length) {
			var member = grpOptions.members[i];
			if (i == curSelected) {
				// Lerp x toward target (e.g., center)
				var targetX = FlxG.width / 2 - member.width / 2;
				member.x = FlxMath.lerp(member.x, targetX, 0.2);
			} else {
				if (member.isHeader == false){
					// Optionally, reset x for non-selected items
					var defaultX = FlxG.width / 6;
					member.x = FlxMath.lerp(member.x, defaultX, 0.2);
				} 
			}
		}

        super.update(elapsed);
    }
	// Update unselectableCheck:
	private function unselectableCheck(idx:Int):Bool {
		return (grpOptions.members[idx].isHeader);
	}
	// Helper to count headers before current selection
	private function countHeadersBefore(idx:Int):Int {
		var count = 0;
		for (i in 0...idx) {
			if (grpOptions.members[i].isHeader) count++;
		}
		return count;
	}
}
