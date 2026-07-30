package debug;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.ui.Keyboard;
import debug.ConsoleLogType;
import openfl.Lib;

class ConsoleUI extends Sprite
{
	var log:TextField;
	var input:TextField;
	var autoFollow:Bool = true;

	public function new()
	{
		super();

		// background
		graphics.beginFill(0x000000, 0.8);
		graphics.drawRect(0, 0, 800, 250);
		graphics.endFill();

		var format = new TextFormat("_sans", 14, 0xFFFFFF);

		log = new TextField();
		log.defaultTextFormat = format;
		log.width = 790;
		log.height = 200;
		log.x = 5;
		log.y = 5;
		log.multiline = true;
		log.wordWrap = true;
		log.mouseWheelEnabled = true;
		log.selectable = true;
		log.addEventListener(MouseEvent.MOUSE_WHEEL, onLogWheel);

		addChild(log);
	}

	function onLogWheel(e:MouseEvent)
	{
		var next = log.scrollV - e.delta;
		if (next < 1)
			next = 1;
		if (next > log.maxScrollV)
			next = log.maxScrollV;
		log.scrollV = Std.int(next);

		autoFollow = (log.scrollV >= log.maxScrollV - 1);
	}

	public function setFocus(toggle:Bool)
	{
		if (toggle)
			Lib.current.stage.focus = input;
		else
			Lib.current.stage.focus = null;
	}

	public function print(text:String, type:ConsoleLogType = NORMAL)
	{
		var badgeHtml = "";
		var textColor = "#FFFFFF";

		switch (type)
		{
			case NORMAL:
				badgeHtml = "";
				textColor = "#FFFFFF";

			case WARNING:
				badgeHtml = '<font color="#FFFF44"><b> WARN: </b></font>';
				textColor = "#FFFFFF";

			case ERROR:
				badgeHtml = '<font color="#FF4444"><b> ERROR: </b></font>';
				textColor = "#FF2222";
		}

		this.log.htmlText += badgeHtml + '<font color="$textColor">' + escapeHtml(text) + '</font><br>';

		if (autoFollow)
			this.log.scrollV = this.log.maxScrollV;
	}

	public function printFromClass(className:String, text:String, color:Int, type:ConsoleLogType = NORMAL)
	{
		var prefix = "";
		var classColor = StringTools.hex(color, 6);
		var textColor = 0xFFFFFF;
		var classIsBold = false;

		switch (type)
		{
			case NORMAL:
				prefix = "";
				classColor = StringTools.hex(color, 6);
				textColor = 0xFFFFFF;

			case WARNING:
				prefix = "WARN: ";
				classColor = "FFFF44";
				textColor = 0xFFFFFF;
				classIsBold = true;

			case ERROR:
				prefix = "ERROR: ";
				classColor = "FF4444";
				textColor = 0xFF0000;
				classIsBold = true;
		}

		var safeClass = escapeHtml(className + ' ' +  prefix);
		var classLabel = '■ ' + safeClass;
		if (classIsBold)
			classLabel = '<b>' + classLabel + '</b>';
		var box = '<font color="#' + classColor + '">' + classLabel + '</font>';
		var safeText = escapeHtml( text);
		var body = '<font color="#' + StringTools.hex(textColor, 6) + '">' + safeText + '</font><br>';
		this.log.htmlText += box + body;

		if (autoFollow)
			this.log.scrollV = this.log.maxScrollV;
	}

	function escapeHtml(text:String):String
	{
		return StringTools.htmlEscape(Std.string(text), true);
	}
}
