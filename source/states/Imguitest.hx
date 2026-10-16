package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import imgui.ImGui;
import debug.Consolehandler;

class Imguitest extends ImguiState
{
	var bg:FlxSprite;
	var showWindow:Bool = true;
	var charwindow:Bool = false;
	var characterIndex:Int = 0;
	var characterItems:Array<String> = ["Dad", "Bf", "Gf"];
	var hideBg:Bool = false;
	var charbuttonpressed:Bool = false;
	var speed:cpp.Float32 = 1.0;
	var tint:Array<cpp.Float32> = [0.64, 0.09, 0.6];
	var enabled:Bool = true;
	var checked:Bool = false;
	var selectedRadio:Int = 0;
	var integerValue:Int = 25;
	var dragValue:Int = 10;
	var floatValue:cpp.Float32 = 0.5;
	var angleValue:cpp.Float32 = 0.75;
	var color4:Array<cpp.Float32> = [0.2, 0.65, 0.95, 1.0];
	var comboIndex:Int = 0;
	var listIndex:Int = 0;
	var selectedItem:Bool = false;
	var progress:cpp.Float32 = 0.65;
	var showDemoWindow:Bool = false;
	var clicks:Int = 0;
	var comboItems:Array<String> = ["First", "Second", "Third"];
	var plotValues:Array<cpp.Float32> = [0.1, 0.35, 0.2, 0.75, 0.5, 0.9, 0.65];

	override function create():Void
	{
		super.create();
		ImGui.styleColorsDark();
		var colors = ImGui.getStyle().colors;
		colors[ImGuiCol.WindowBg] = ImVec4.create(0.16, 0.02, 0.02, 1.0);
		colors[ImGuiCol.ChildBg] = ImVec4.create(0.12, 0.02, 0.02, 1.0);
		colors[ImGuiCol.PopupBg] = ImVec4.create(0.18, 0.02, 0.02, 0.98);
		colors[ImGuiCol.FrameBg] = ImVec4.create(0.35, 0.04, 0.04, 1.0);
		colors[ImGuiCol.FrameBgHovered] = ImVec4.create(0.55, 0.06, 0.06, 1.0);
		colors[ImGuiCol.FrameBgActive] = ImVec4.create(0.68, 0.08, 0.08, 1.0);
		colors[ImGuiCol.TitleBg] = ImVec4.create(0.24, 0.02, 0.02, 1.0);
		colors[ImGuiCol.TitleBgActive] = ImVec4.create(0.48, 0.03, 0.03, 1.0);
		colors[ImGuiCol.MenuBarBg] = ImVec4.create(0.24, 0.02, 0.02, 1.0);
		colors[ImGuiCol.ScrollbarGrab] = ImVec4.create(0.48, 0.04, 0.04, 1.0);
		colors[ImGuiCol.ScrollbarGrabHovered] = ImVec4.create(0.65, 0.06, 0.06, 1.0);
		colors[ImGuiCol.ScrollbarGrabActive] = ImVec4.create(0.78, 0.08, 0.08, 1.0);
		colors[ImGuiCol.CheckMark] = ImVec4.create(1.0, 0.24, 0.24, 1.0);
		colors[ImGuiCol.SliderGrab] = ImVec4.create(0.85, 0.08, 0.08, 1.0);
		colors[ImGuiCol.SliderGrabActive] = ImVec4.create(1.0, 0.18, 0.18, 1.0);
		colors[ImGuiCol.Button] = ImVec4.create(0.55, 0.04, 0.04, 1.0);
		colors[ImGuiCol.ButtonHovered] = ImVec4.create(0.78, 0.06, 0.06, 1.0);
		colors[ImGuiCol.ButtonActive] = ImVec4.create(0.92, 0.08, 0.08, 1.0);
		colors[ImGuiCol.Header] = ImVec4.create(0.5, 0.04, 0.04, 1.0);
		colors[ImGuiCol.HeaderHovered] = ImVec4.create(0.72, 0.06, 0.06, 1.0);
		colors[ImGuiCol.HeaderActive] = ImVec4.create(0.86, 0.08, 0.08, 1.0);
		colors[ImGuiCol.Tab] = ImVec4.create(0.36, 0.03, 0.03, 1.0);
		colors[ImGuiCol.TabHovered] = ImVec4.create(0.72, 0.06, 0.06, 1.0);
		colors[ImGuiCol.TabActive] = ImVec4.create(0.55, 0.04, 0.04, 1.0);
		colors[ImGuiCol.TabUnfocused] = ImVec4.create(0.24, 0.02, 0.02, 1.0);
		colors[ImGuiCol.TabUnfocusedActive] = ImVec4.create(0.38, 0.03, 0.03, 1.0);
		bg = new FlxSprite(-80).loadGraphic(Paths.image('ebotmenuBG-invert'));
		bg.scrollFactor.set(0, 0);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.color = 0xFFA4179A;
		bg.antialiasing = ClientPrefs.data.globalAntialiasing;
		add(bg);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isImGuiReady())
			return;

		bg.visible = !hideBg;
		bg.color = FlxColor.fromRGBFloat(tint[0], tint[1], tint[2]);
		bg.angle += speed * elapsed * 10;
	}

	override public function drawImGui():Void
	{
		if (ImGui.beginMainMenuBar())
		{
			if (ImGui.beginMenu("Character Window", true))
			{
				if (ImGui.menuItem("Show character window", "", charwindow, true))
					charwindow = !charwindow;
				ImGui.endMenu();
			}
			if (ImGui.beginMenu("Demo", true))
			{
				if (ImGui.menuItem("Show demo window", "", showDemoWindow, true))
					showDemoWindow = !showDemoWindow;
				ImGui.endMenu();
			}
			if (ImGui.beginMenu("Chorus Demo", true))
			{
				if (ImGui.menuItem("Show Chorus demo window", "", showWindow, true))
					showWindow = !showWindow;
				ImGui.endMenu();
			}
			ImGui.endMainMenuBar();
		}

		if (charwindow)
		{
			var charWindowVisible = ImGui.begin("Chorus Char Window", charwindow);
			if (charWindowVisible)
			{
				ImGui.textUnformatted("A character window.");
				if (ImGui.beginTabBar("Character Window Tabs", 0))
				{
					if (ImGui.beginTabItem("Character Base"))
					{
						if (ImGui.beginCombo("Characters", characterItems[characterIndex], 0))
						{
							for (i in 0...characterItems.length)
							{
								var isSelected = characterIndex == i;
								if (ImGui.selectable(characterItems[i], isSelected, 0, ImVec2.create()))
									characterIndex = i;
							}
							ImGui.endCombo();
							ImGui.sameLine();
						}
						if (ImGui.button("Reload Character"))
							Consolehandler.print("Reload Character button pressed");
						ImGui.sameLine();
						if (ImGui.button("Load Template"))
							Consolehandler.print("Load Template button pressed");
						if (ImGui.radioButton("Flip Y", charbuttonpressed))
						{
							charbuttonpressed = !charbuttonpressed;
							Consolehandler.print("Flip Y button value: " + charbuttonpressed);
						}
						ImGui.endTabItem();
					}
					ImGui.endTabBar();
				}
			}
			ImGui.end();
		}

		if (showDemoWindow)
			ImGui.showDemoWindow(showDemoWindow);

		if (showWindow)
		{
			var demoWindowVisible = ImGui.begin("Chorus Demo", showWindow);
			if (demoWindowVisible)
			{
				ImGui.textUnformatted("A showcase of the widgets exposed by linc_imgui.");
				ImGui.separator();

				if (ImGui.beginTabBar("WidgetGalleryTabs", 0))
				{
					if (ImGui.beginTabItem("Basics"))
					{
						drawBasicWidgets();
						ImGui.endTabItem();
					}
					if (ImGui.beginTabItem("Inputs"))
					{
						drawInputWidgets();
						ImGui.endTabItem();
					}
					if (ImGui.beginTabItem("Layout"))
					{
						drawLayoutWidgets();
						ImGui.endTabItem();
					}
					if (ImGui.beginTabItem("Trees & Tables"))
					{
						drawTreeAndTableWidgets();
						ImGui.endTabItem();
					}
					if (ImGui.beginTabItem("Popups"))
					{
						drawPopupWidgets();
						ImGui.endTabItem();
					}
					ImGui.endTabBar();
				}
			}
			ImGui.end();
		}
	}

	function drawBasicWidgets():Void
	{
		ImGui.textUnformatted("Text, labels, and status");
		ImGui.textUnformatted("Regular text");
		ImGui.bullet();
		ImGui.sameLine();
		ImGui.textUnformatted("Bullet text");
		ImGui.textUnformatted("Label: Value shown beside a label");

		ImGui.separator();
		ImGui.textUnformatted("Buttons and selection");
		if (ImGui.button("Button"))
			clicks++;
		ImGui.sameLine();
		if (ImGui.smallButton("Small button"))
			clicks++;
		ImGui.sameLine();
		if (ImGui.arrowButton("Arrow button", 1))
			clicks++;
		ImGui.sameLine();
		ImGui.textUnformatted("Clicks: " + clicks);

		ImGui.checkbox("Enabled", enabled);
		ImGui.checkbox("Hide background", hideBg);
		for (i in 0...3)
		{
			if (ImGui.radioButton("Option " + (i + 1), selectedRadio == i))
				selectedRadio = i;
			if (i < 2)
				ImGui.sameLine();
		}
		if (ImGui.selectable("Selectable row", selectedItem, 0, ImVec2.create()))
			selectedItem = !selectedItem;
		ImGui.progressBar(progress, ImVec2.create(), "Progress");
		if (ImGui.button("Advance progress"))
			progress = progress >= 1.0 ? 0.0 : progress + 0.1;
	}

	function drawInputWidgets():Void
	{
		ImGui.textUnformatted("Numeric inputs");
		ImGui.inputInt("Integer input", integerValue);
		ImGui.sliderInt("Integer slider", integerValue, 0, 100);
		ImGui.dragInt("Integer drag", dragValue, 0.5, 0, 100);
		ImGui.inputFloat("Float input", floatValue);
		ImGui.sliderFloat("Float slider", floatValue, 0.0, 1.0);
		ImGui.dragFloat("Float drag", speed, 0.1, 0.0, 10.0);
		ImGui.sliderAngle("Angle slider", angleValue, -180.0, 180.0);

		ImGui.separator();
		ImGui.textUnformatted("Color editors");
		ImGui.colorEdit3("RGB color", tint);
		ImGui.colorEdit4("RGBA color", color4);
		ImGui.colorPicker3("Color picker", tint, 0);

		ImGui.separator();
		ImGui.textUnformatted("Combo and list selection");
		if (ImGui.beginCombo("Combo", comboItems[comboIndex], 0))
		{
			for (i in 0...comboItems.length)
			{
				var isSelected = comboIndex == i;
				if (ImGui.selectable(comboItems[i], isSelected, 0, ImVec2.create()))
					comboIndex = i;
			}
			ImGui.endCombo();
		}
		ImGui.textUnformatted("List selection");
		for (i in 0...comboItems.length)
		{
			var isSelected = listIndex == i;
			if (ImGui.selectable(comboItems[i], isSelected, 0, ImVec2.create()))
				listIndex = i;
		}
	}

	function drawLayoutWidgets():Void
	{
		ImGui.textUnformatted("Layout helpers");
		ImGui.textUnformatted("Same-line placement:");
		ImGui.button("First", ImVec2.create());
		ImGui.sameLine();
		ImGui.button("Next", ImVec2.create());

		ImGui.separator();
		ImGui.textUnformatted("Groups and spacing");
		ImGui.beginGroup();
		ImGui.button("Grouped button");
		ImGui.textUnformatted("Grouped caption");
		ImGui.endGroup();
		ImGui.spacing();
		ImGui.dummy(ImVec2.create());

		ImGui.separator();
		ImGui.textUnformatted("Child region");
		if (ImGui.beginChild("Scrollable child", ImVec2.create(), true, 0))
		{
			for (i in 0...8)
				ImGui.textUnformatted("Child item " + (i + 1));
		}
		ImGui.endChild();

		ImGui.separator();
		ImGui.checkbox("Hide background", hideBg);
		ImGui.sliderFloat("Spin speed", speed, 0.0, 10.0);
		ImGui.colorEdit3("Background tint", tint);
	}

	function drawTreeAndTableWidgets():Void
	{
		ImGui.textUnformatted("Tree nodes and collapsing headers");
		if (ImGui.treeNode("Parent node"))
		{
			ImGui.textUnformatted("Nested item");
			if (ImGui.treeNode("Nested node"))
			{
				ImGui.textUnformatted("Tree content");
				ImGui.treePop();
			}
			ImGui.treePop();
		}
		if (ImGui.collapsingHeader("Collapsing header", 0))
			ImGui.textUnformatted("Header content is visible.");

		ImGui.separator();
		ImGui.textUnformatted("Table");
		if (ImGui.beginTable("Widget table", 3, 1920, ImVec2.create(), 0.0))
		{
			ImGui.tableSetupColumn("Name");
			ImGui.tableSetupColumn("Type");
			ImGui.tableSetupColumn("Value");
			ImGui.tableHeadersRow();
			ImGui.tableNextRow(0, 0.0);
			ImGui.tableNextColumn();
			ImGui.textUnformatted("Spin speed");
			ImGui.tableNextColumn();
			ImGui.textUnformatted("Float");
			ImGui.tableNextColumn();
			ImGui.textUnformatted(Std.string(speed));
			ImGui.tableNextRow(0, 0.0);
			ImGui.tableNextColumn();
			ImGui.textUnformatted("Click count");
			ImGui.tableNextColumn();
			ImGui.textUnformatted("Integer");
			ImGui.tableNextColumn();
			ImGui.textUnformatted(Std.string(clicks));
			ImGui.endTable();
		}
	}

	function drawPopupWidgets():Void
	{
		ImGui.textUnformatted("Popups, menus, and tooltips");
		if (ImGui.button("Open popup"))
			ImGui.openPopup("Example popup", 0);
		if (ImGui.beginPopup("Example popup", 0))
		{
			ImGui.textUnformatted("Popup content");
			if (ImGui.menuItem("Close popup", "", false, true))
				ImGui.closeCurrentPopup();
			ImGui.endPopup();
		}

		ImGui.button("Hover for tooltip");
		if (ImGui.isItemHovered(0))
		{
			ImGui.beginTooltip();
			ImGui.textUnformatted("This tooltip is attached to the button.");
			ImGui.endTooltip();
		}

		if (ImGui.beginPopupContextItem("Context popup", 1))
		{
			ImGui.textUnformatted("Right-click popup");
			ImGui.endPopup();
		}
	}
}
