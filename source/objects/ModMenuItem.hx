package objects;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import openfl.display.BitmapData;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import AttachedSprite;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.FlxCamera;
import openfl.system.System;
import sys.io.File;
import sys.FileSystem;
import flixel.group.FlxSpriteGroup;



class ModMenuItem extends FlxSpriteGroup {
    public var dlcinfo:ModsMenuState.ModMetadata;
    public var icon:FunkinSprite;
    public var description:FlxText;
    public var name:FlxText;
    public var base:FunkinSprite;
    public var verified:FunkinSprite;
    public var vernum:FunkinSprite;
    public var enabled:Bool = true;
    public var enable:Button;
    public var enabletxt:FlxText;

   public function new(dlc:ModsMenuState.ModMetadata, startEnabled:Bool = true)
    {
        super();
        dlcinfo = dlc;
        enabled = startEnabled;



        base = new FunkinSprite(0, 0);
        base.frames = Paths.getSparrowAtlas('menus/dlc/Box');
        base.animation.addByPrefix('Idle', 'Idle', 8, true);
        base.animation.addByPrefix('Disabled', 'Disabled', 8, true);
        base.animation.play('Idle');
        add(base);

        icon = new FunkinSprite();
        add(icon);

        var iconPath = Paths.mods(dlcinfo.folder + '/pack.png');

        if (FileSystem.exists(iconPath)) {
            icon.loadGraphic(BitmapData.fromFile(iconPath), true, 150, 150);
        } else {
            icon.loadGraphic(Paths.image('menus/dlc/placeholder'), true, 150, 150);
        }

        var bmp = icon.graphic.bitmap;
        var totalFrames = Std.int(bmp.width / 150) * Std.int(bmp.height / 150);

        if (totalFrames > 1) {
            icon.animation.add("icon", [for (i in 0...totalFrames) i], 10, true);
            icon.animation.play("icon");
        }
        description = new FlxText(12, FlxG.height - 44, 0, dlcinfo.description, 12);
		description.scrollFactor.set();
		description.setFormat(Paths.font("sonic-cd-menu-font.TTF"), 45, 0x2c2626, LEFT);
        description.x = icon.x + 200;
        description.y = icon.y + 70;
		add(description);
        name = new FlxText(12, FlxG.height - 44, 0, dlcinfo.name, 12);
		name.scrollFactor.set();
		name.setFormat(Paths.font("sonic-cd-menu-font.TTF"), 65, 0x2c2626, LEFT);
        name.x = description.x;
        name.y = description.y - 68;
		add(name);
        enable = new Button(740,40,'menus/dlc/DisableEnable',toggleenable.bind(),true);
        add(enable);
        enabletxt = new FlxText(12, FlxG.height - 44, 0, 'enabled', 12);
		enabletxt.scrollFactor.set();
        enabletxt.color = 0x00FF00;
		enabletxt.setFormat(Paths.font("sonic-cd-menu-font.TTF"), 65, 0x2c2626, LEFT);
        enabletxt.x = enable.x + 80;
        enabletxt.y = enable.y;
		add(enabletxt);
        refreshState();
    }

    public function refreshState()
    {
        if (this.enabled){
            base.animation.play("Idle");
            enabletxt.color = 0x00FF00;
            enabletxt.text = 'ENABLED';
        }
        else{
            base.animation.play("Disabled");
            enabletxt.color = 0xFF0000;
            enabletxt.text = 'DISABLED';
        }
    }


    function toggleenable():Void{
        this.enabled = !this.enabled;
        refreshState();
    }
}

