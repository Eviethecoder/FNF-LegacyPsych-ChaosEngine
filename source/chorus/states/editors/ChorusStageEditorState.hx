package chorus.states.editors;

import flixel.FlxG;
import lime.ui.FileDialogFilter;
import imgui.ImGui;
import chorus.objects.misc.FlxImGui;
import imgui.BoolPointer;
import chorus.backend.base.MusicBeatState;
#if desktop
import lime.app.Application;
import lime.ui.FileDialog;
#end

class ChorusStageEditorState extends MusicBeatState
{
	var imgui:Int = -1;
	var isBeginningWindowOpen:Bool = true;
	var _savingDialog:Bool = false;
	var curStage:String = "";

	public function new()
	{
		FlxG.mouse.visible = true;
		super();
		imgui = FlxImGui.register(createWindows);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		FlxImGui.newFrame(elapsed);

		if (!FlxImGui.isImGuiReady())
			return;
	}

	public function createWindows():Void
	{
		if (isBeginningWindowOpen)
		{
			if (ImGui.begin("Stage Editor - Welcome", isBeginningWindowOpen, 2 | 4 | 32))
			{
				if (ImGui.button("Open from file test..."))
				{
					#if desktop
					if (_savingDialog)
						return;
					_savingDialog = true;
					FileDialog.openFile(Application.current.window, "Open from file...", function(path:Array<String>, _)
					{
						_savingDialog = false;
						FlxG.log.notice("File open success!!");
					}, [new FileDialogFilter("Chorus Stage File", "pcstg")], curStage + '.pcstg');
					#end
				}
			}
			ImGui.end();
		}
	}
}
