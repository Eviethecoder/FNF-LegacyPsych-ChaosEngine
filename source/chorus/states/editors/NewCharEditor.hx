package chorus.states.editors;

import chorus.backend.base.MusicBeatState;

import chorus.backend.utils.Characterpreloader;
import chorus.backend.assets.Paths;
import chorus.objects.stages.Character;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.FlxG;
import imgui.ImGui;
import chorus.objects.misc.FlxImGui;
import flixel.FlxObject;
import chorus.backend.debug.Consolehandler;

class NewCharEditor extends MusicBeatState
{
	var imgui:Int = -1;
	var bg:FlxSprite;
	var character:Character;
	var ghostVisible:Bool = false;
	var ghost:Character;
	var charwindow:Bool = false;
	var characterIndex:Int = 0;
	var characterItems:Array<String> = [];
	var charbuttonpressed:Bool = false;
	var hideBg:Bool = false;
	var speed:cpp.Float32 = 1.0;
	var tint:Array<cpp.Float32> = [0.64, 0.09, 0.6];
	var selectedCharacter:Int = 0;
	var camFollow:FlxObject;

	override function create():Void
	{
		super.create();
		imgui = FlxImGui.register(drawImGui);

		bg = new FlxSprite(-80).loadGraphic(Paths.image('ebotmenuBG-invert'));
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = 0xFFA4179A;
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		add(bg);
		reloadCharacter(characterItems[0]);
		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);
		FlxG.camera.follow(camFollow);
		FlxG.camera.bgColor = 0xff45308b;
		for (key in utility.Characterpreloader.charmap.keys())
		{
			trace('the key is:' + key);
			characterItems.push(key);
		}
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		FlxImGui.newFrame(elapsed);
		if (FlxG.keys.justPressed.R)
		{
			FlxG.camera.zoom = 1;
		}

		if (FlxG.keys.pressed.E && FlxG.camera.zoom < 3)
		{
			FlxG.camera.zoom += elapsed * FlxG.camera.zoom;
			if (FlxG.camera.zoom > 3)
				FlxG.camera.zoom = 3;
		}
		if (FlxG.keys.pressed.Q && FlxG.camera.zoom > 0.1)
		{
			FlxG.camera.zoom -= elapsed * FlxG.camera.zoom;
			if (FlxG.camera.zoom < 0.1)
				FlxG.camera.zoom = 0.1;
		}

		if (FlxG.keys.justPressed.ESCAPE)
		{
			MusicBeatState.switchState(new editors.MasterEditorMenu());
		}

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
		{
			var addToCam:Float = 500 * elapsed;
			if (FlxG.keys.pressed.SHIFT)
				addToCam *= 4;

			if (FlxG.keys.pressed.I)
				camFollow.y -= addToCam;
			else if (FlxG.keys.pressed.K)
				camFollow.y += addToCam;

			if (FlxG.keys.pressed.J)
				camFollow.x -= addToCam;
			else if (FlxG.keys.pressed.L)
				camFollow.x += addToCam;
		}

		if (!FlxImGui.isImGuiReady())
			return;
	}

	function reloadCharacter(charName:String):Void
	{
		if (character != null)
		{
			character.destroy();
		}
		if (ghost != null)
		{
			ghost.destroy();
		}
		ghost = new Character(0, 0, charName, 'bf');
		add(ghost);
		ghost.screenCenter();
		ghost.alpha = 0;
		character = new Character(0, 0, charName, 'bf');
		add(character);
		character.screenCenter();
	}

	public function drawImGui():Void
	{
		if (ImGui.beginMainMenuBar())
		{
			if (ImGui.beginMenu("Character Window", true))
			{
				if (ImGui.menuItem("Show character window", "", charwindow, true))
					charwindow = !charwindow;
				ImGui.endMenu();
			}
			ImGui.endMainMenuBar();
		}

		if (!charwindow)
			return;

		var charWindowVisible = ImGui.begin("Chorus Char Window", charwindow);
		if (charWindowVisible)
		{
			ImGui.textUnformatted("A character window.");
			if (ImGui.beginTabBar("Character Window Tabs", 0))
			{
				if (ImGui.beginTabItem("Character Base"))
				{
					if (characterItems.length > 0 && ImGui.beginCombo("Characters", characterItems[characterIndex], 0))
					{
						for (i in 0...characterItems.length)
						{
							var isSelected = characterIndex == i;
							if (ImGui.selectable(characterItems[i], isSelected, 0, ImVec2.create()) && characterIndex != i)
							{
								characterIndex = i;

								selectedCharacter = i;
							}
						}
						ImGui.endCombo();
					}
					if (ImGui.button("Reload Character"))
					{
						reloadCharacter(characterItems[selectedCharacter]);
					}
					ImGui.sameLine();
					if (ImGui.button("Load Template"))
						Consolehandler.print("Load Template button pressed");
					if (ImGui.radioButton("Flip X", charbuttonpressed))
					{
						charbuttonpressed = !charbuttonpressed;
						character.flipX = charbuttonpressed;
					}
					ImGui.endTabItem();
				}

				if (ImGui.beginTabItem("Ghost"))
				{
					if (ImGui.radioButton("Show Ghost", charbuttonpressed))
					{
						charbuttonpressed = !charbuttonpressed;
						ghostVisible = charbuttonpressed;
						ghost.alpha = ghostVisible ? 0.5 : 0;
					}
					ImGui.endTabItem();
				}
				ImGui.endTabBar();
			}
		}
		ImGui.end();
	}

	override function destroy():Void
	{
		if (imgui >= 0)
		{
			FlxImGui.unregister(imgui);
			imgui = -1;
		}
		super.destroy();
	}
}
