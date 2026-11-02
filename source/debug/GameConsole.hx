package debug;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import imgui.ImGui;
import objects.FlxImGui;
import imgui.TextBuffer;

using StringTools;

typedef LogLine =
{
	text:String,
	color:Int
}

var commandlist:Map<String, Dynamic>;

class GameConsole extends FlxBasic
{
	public static var instance(default, null):GameConsole;

	static inline var INPUT_SIZE:Int = 256;

	static inline var MAX_LINES:Int = 1000;

	static var scrollToBottom:Bool = false;

	static var lines:Array<LogLine> = [{text: "Type 'help' for commands.", color: 0xFFFFFFFF}];

	public var toggleKey:FlxKey;

	var gui:Int = -1;
	var input:TextBuffer = new TextBuffer(INPUT_SIZE);

	var refocusInput:Bool = false;
	var originalTrace:Dynamic->?haxe.PosInfos->Void;

	public static function init(toggleKey:FlxKey = FlxKey.GRAVEACCENT):GameConsole
	{
		if (instance == null)
		{
			instance = new GameConsole(toggleKey);
			FlxG.plugins.addPlugin(instance);
			setupCommands();
		}
		return instance;
	}

	static function setupCommands():Void
	{
		commandlist = new Map<String, Dynamic>();
		commandlist.set("help", function(args:Array<String>):Void
		{
			print("Available commands: " + [for (name in commandlist.keys()) name].join(", "));
		});
		commandlist.set("clear", function(args:Array<String>):Void
		{
			clear();
		});
		commandlist.set("error", function(args:Array<String>):Void
		{
			printError("This is a test error.");
		});
		commandlist.set("resetState", function(args:Array<String>):Void
		{
			print("Resetting state...", 0xFF21B61C);
			print("State reset initiated. with var " + args, 0xFFFFFFFF);
			FlxG.resetState();
		});
	}

	function new(toggleKey:FlxKey)
	{
		super();
		this.toggleKey = toggleKey;
		hookTraces();
	}

	override public function update(elapsed:Float):Void
	{
		if (FlxG.keys.checkStatus(toggleKey, JUST_PRESSED))
			toggle();

		if (gui >= 0)
			FlxImGui.newFrame(elapsed);
	}

	override public function destroy():Void
	{
		close();
		unhookTraces();
		if (instance == this)
			instance = null;
		super.destroy();
	}

	public function toggle():Void
	{
		if (gui < 0)
			open();
		else
			close();
	}

	public function open():Void
	{
		if (gui >= 0)
			return;

		var newGui = FlxImGui.register(drawConsole);
		if (!FlxImGui.isImGuiReady())
		{
			FlxImGui.unregister(newGui);
			return;
		}
		gui = newGui;
		refocusInput = true;
	}

	public function close():Void
	{
		if (gui < 0)
			return;

		FlxImGui.unregister(gui);
		gui = -1;
	}

	function hookTraces():Void
	{
		if (originalTrace != null)
			return;

		originalTrace = haxe.Log.trace;
		haxe.Log.trace = onTrace;
	}

	function unhookTraces():Void
	{
		if (originalTrace == null)
			return;

		haxe.Log.trace = originalTrace;
		originalTrace = null;
	}

	function onTrace(value:Dynamic, ?pos:haxe.PosInfos):Void
	{
		originalTrace(value, pos);

		var time = DateTools.format(Date.now(), "%H:%M:%S");
		var file = pos != null ? haxe.io.Path.withoutDirectory(pos.fileName) + ":" + pos.lineNumber : "?";

		var parts = [Std.string(value)];
		if (pos != null && pos.customParams != null)
			for (p in pos.customParams)
				parts.push(Std.string(p));

		print('[$time] [$file] ${parts.join(" ")}', 0xFFF3EF15);
	}

	public static function print(text:String, color:Int = 0xFFFFFFFF):Void
	{
		lines.push({text: text, color: color});
		while (lines.length > MAX_LINES)
			lines.shift();
		scrollToBottom = true;
	}

	public static function warn(text:String, ?pos:haxe.PosInfos):Void
	{
		print(formatMessage(text, pos), 0xFFFF44);
	}

	public static function error(text:String, ?pos:haxe.PosInfos):Void
	{
		print(formatMessage(text, pos), 0xFF6666FF);
	}

	static function formatMessage(text:String, ?pos:haxe.PosInfos):String
	{
		var location = pos != null ? pos.className : "?";
		return '$location: $text';
	}

	public static function printError(text:String):Void
	{
		var time = DateTools.format(Date.now(), "%H:%M:%S");
		print('[$time] [Error] ' + text, 0xFF6666FF);
	}

	public static function clear():Void
	{
		lines = [];
	}

	function drawConsole():Void
	{
		ImGui.setNextWindowSize(createVec2(520, 400), ImGuiCond.FirstUseEver);

		if (ImGui.begin("Game Console", null, 0))
		{
			drawToolbar();
			drawLog();
			drawInput();
		}
		ImGui.end();
	}

	function createVec2(x:Float, y:Float):ImVec2
	{
		var value = ImVec2.create();
		value.x = x;
		value.y = y;
		return value;
	}

	function drawToolbar():Void
	{
		if (ImGui.smallButton("Clear"))
			clear();
		ImGui.separator();
	}

	function drawLog():Void
	{
		var inputRowHeight = ImGui.getStyle().itemSpacing.y + ImGui.getFrameHeightWithSpacing();

		if (ImGui.beginChild("Log", createVec2(0, -inputRowHeight), false, ImGuiWindowFlags.HorizontalScrollbar))
		{
			for (line in lines)
				drawLogLine(line);

			if (scrollToBottom)
			{
				ImGui.setScrollHereY(1.0);
				scrollToBottom = false;
			}
		}
		ImGui.endChild();
		ImGui.separator();
	}

	function drawLogLine(line:LogLine):Void
	{
		// cant compile cause some bull with c, needs seperated
		var text:String = line.text;
		var color:Int = line.color;

		ImGui.pushStyleColor(ImGuiCol.Text, color);
		ImGui.textUnformatted(text, null);
		ImGui.popStyleColor(1);
	}

	function drawInput():Void
	{
		var submitted = ImGui.inputText("Input", input, input.length(), ImGuiInputTextFlags.EnterReturnsTrue, null, null);
		ImGui.sameLine();
		if (ImGui.smallButton("Run"))
		{
			var command = StringTools.trim(readInput());
			if (command != "")
				run(command);

			clearInput();
			refocusInput = true;
		}

		if (refocusInput)
		{
			ImGui.setKeyboardFocusHere(-1);
			refocusInput = false;
		}
	}

	function readInput():String
	{
		return input.toString().split(String.fromCharCode(0))[0];
	}

	function clearInput():Void
	{
		var chars:Array<cpp.Char> = cast input;
		for (i in 0...chars.length)
			chars[i] = 0;
	}

	function run(command:String):Void
	{
		print("> " + command,);

		try
		{
			var comandsplit = command.split(':');
			var commandName = comandsplit[0];
			var comandvars:Array<String> = comandsplit[1].split(',');
			trace(commandName);
			trace(comandvars);
			if (comandvars == null)
			{
				comandvars = [];
			}
			Reflect.callMethod(null, commandlist.get(commandName), [comandvars]);
		}
		catch (e:Dynamic)
		{
			printError('Error running command: $command try Running Help');
		}
	}
}
