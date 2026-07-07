package editors;

#if desktop
import Discord.DiscordClient;
#end
import backend.ui.PsychUIBox;
import backend.ui.PsychUIButton;
import backend.ui.PsychUICheckBox;
import backend.ui.PsychUIDropDownMenu;
import backend.ui.PsychUIEventHandler.PsychUIEvent;
import backend.ui.PsychUIInputText;
import backend.ui.PsychUINumericStepper;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class ExampleEditorState extends MusicBeatState implements PsychUIEvent
{
	var preview:FlxSprite;
	var infoText:FlxText;
	var uiBox:PsychUIBox;
	var uiGroup:FlxSpriteGroup;

	var labelInput:PsychUIInputText;
	var scaleStepper:PsychUINumericStepper;
	var angleStepper:PsychUINumericStepper;
	var colorDropDown:PsychUIDropDownMenu;
	var autoRotateCheck:PsychUICheckBox;
	var autoRotate:Bool = false;

	override function create()
	{
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xffc01b1b;
		bg.scale.y = FlxG.height / (bg.height);
		bg.scale.x = FlxG.width / (bg.width);
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		bg.scrollFactor.set(0, 0);
		add(bg);

		preview = new FlxSprite().makeGraphic(160, 160, FlxColor.CYAN);
		preview.screenCenter();
		preview.offset.set();
		add(preview);

		uiBox = new PsychUIBox(20, 80, 360, 300, ['PsychUI Demo']);
		uiBox.scrollFactor.set();
		uiBox.selectedName = 'PsychUI Demo';
		add(uiBox);

		buildDemoUI();

		infoText = new FlxText(12, 12, FlxG.width - 24,
			'EXAMPLE EDITOR (PSYCH UI DEMO)\n'
			+ 'UI panel shows: Input, Steppers, Dropdown, Checkbox, Buttons\n'
			+ 'Arrow Keys: Move preview\n'
			+ 'ESC: Return to Editor Menu', 20);
		infoText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoText.borderSize = 1;
		add(infoText);

		#if desktop
		DiscordClient.changePresence("Example Editor", "Template / sandbox state");
		#end

		super.create();
	}

	function buildDemoUI():Void
	{
		uiGroup = new FlxSpriteGroup();

		labelInput = new PsychUIInputText(15, 35, 170, 'PsychUI Demo', 8);
		scaleStepper = new PsychUINumericStepper(15, 90, 0.1, 1, 0.2, 4, 1);
		angleStepper = new PsychUINumericStepper(115, 90, 5, 0, -360, 360, 0);

		colorDropDown = new PsychUIDropDownMenu(15, 145, ['Cyan', 'Red', 'Green', 'Blue', 'White'], function(id:Int, selected:String)
		{
			switch (selected)
			{
				case 'Red': preview.color = FlxColor.RED;
				case 'Green': preview.color = FlxColor.GREEN;
				case 'Blue': preview.color = FlxColor.BLUE;
				case 'White': preview.color = FlxColor.WHITE;
				default: preview.color = FlxColor.CYAN;
			}
		}, 130);

		autoRotateCheck = new PsychUICheckBox(15, 190, 'Auto Rotate', 120);
		autoRotateCheck.checked = false;
		autoRotateCheck.onClick = function()
		{
			autoRotate = autoRotateCheck.checked;
		};

		var resetButton:PsychUIButton = new PsychUIButton(15, 230, 'Reset', function()
		{
			preview.screenCenter();
			preview.angle = 0;
			preview.scale.set(1, 1);
			scaleStepper.value = 1;
			angleStepper.value = 0;
			colorDropDown.selectedLabel = 'Cyan';
			preview.color = FlxColor.CYAN;
		}, 70, 20);

		var applyLabelButton:PsychUIButton = new PsychUIButton(95, 230, 'Apply Label', function()
		{
			infoText.text = 'EXAMPLE EDITOR (PSYCH UI DEMO)\nLabel: ' + labelInput.text
				+ '\nUI panel shows: Input, Steppers, Dropdown, Checkbox, Buttons\n'
				+ 'Arrow Keys: Move preview\nESC: Return to Editor Menu';
		}, 90, 20);

		uiGroup.add(new FlxText(labelInput.x, labelInput.y - 18, 0, 'Label text:'));
		uiGroup.add(new FlxText(scaleStepper.x, scaleStepper.y - 18, 0, 'Scale / Angle:'));
		uiGroup.add(new FlxText(colorDropDown.x, colorDropDown.y - 18, 0, 'Color:'));
		uiGroup.add(labelInput);
		uiGroup.add(scaleStepper);
		uiGroup.add(angleStepper);
		uiGroup.add(colorDropDown);
		uiGroup.add(autoRotateCheck);
		uiGroup.add(resetButton);
		uiGroup.add(applyLabelButton);

		var tab = uiBox.getTab('PsychUI Demo');
		if (tab != null) tab.menu = uiGroup;
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == PsychUINumericStepper.CHANGE_EVENT && (sender is PsychUINumericStepper))
		{
			if (sender == scaleStepper)
			{
				preview.scale.set(scaleStepper.value, scaleStepper.value);
			}
			else if (sender == angleStepper)
			{
				preview.angle = angleStepper.value;
			}
		}
	}

	public function UIEvent(id:String, sender:Dynamic):Void
	{
		getEvent(id, sender, null, null);
	}

	override function update(elapsed:Float)
	{
		var moveSpeed:Float = 350 * elapsed;
		if(FlxG.keys.pressed.SHIFT) moveSpeed *= 2;

		if (FlxG.keys.pressed.LEFT) preview.x -= moveSpeed;
		if (FlxG.keys.pressed.RIGHT) preview.x += moveSpeed;
		if (FlxG.keys.pressed.UP) preview.y -= moveSpeed;
		if (FlxG.keys.pressed.DOWN) preview.y += moveSpeed;

		if (autoRotate)
		{
			preview.angle += 90 * elapsed;
			angleStepper.value = preview.angle;
		}

		if (FlxG.keys.justPressed.R)
		{
			preview.screenCenter();
			preview.angle = 0;
			preview.scale.set(1, 1);
			scaleStepper.value = 1;
			angleStepper.value = 0;
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			MusicBeatState.switchState(new MasterEditorMenu());
			return;
		}

		super.update(elapsed);
	}
}
