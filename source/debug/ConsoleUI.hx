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
		var prefix = "";
		var color = 0xFFFFFF;

		switch (type)
		{
			case NORMAL:
				prefix = "";
				color = 0xFFFFFF;

			case WARNING:
				prefix = "[WARN] ";
				color = 0xFFFF44;

			case ERROR:
				prefix = "[ERROR] ";
				color = 0xFF4444;
		}

		// apply color formatting
		this.log.htmlText += '<font color="#' + StringTools.hex(color, 6) + '">' + prefix + text + '</font><br>';

		if (autoFollow)
			this.log.scrollV = this.log.maxScrollV;
	}
}
