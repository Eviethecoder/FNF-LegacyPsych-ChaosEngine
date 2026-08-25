package utility;

#if sys
import sys.FileSystem;
import sys.io.File;
#end
import haxe.Json;
import haxe.io.Path;
import Paths;
import debug.Consolehandler;
import events.CameraMovement;
import events.CameraZoom;
import events.BaseEvent;
import events.ScriptedEvent;
import events.BPMChange;
import events.CharacterChange;
import events.LyricEvent;
import events.PlayAnim;
import events.WaveyNotes;

using StringTools;

class EventHandler
{
	public static var eventmapping:Map<String, events.BaseEvent.EventSchematic> = [];

	public static var usedeventmap:Map<String, BaseEvent> = [];

	public static var eventList:Array<String> = ['none'];
	public static var usedEvents:Array<String> = [];

	static var hardcodedEvents:Array<String> = [
		'CameraMovement',
		'CameraZoom',
		'CharacterChange',
		'Lyrics',
		'BPMChange',
		'WaveyNotes',
		'PlayAnim'
	];

	public static function scanFolderRecursive(folder:String, onFile:String->Void):Void
	{
		#if !sys
		return;
		#end
		if (!FileSystem.exists(folder) || !FileSystem.isDirectory(folder))
			return;

		for (entry in FileSystem.readDirectory(folder))
		{
			var fullPath:String = Path.join([folder, entry]);

			if (FileSystem.isDirectory(fullPath))
				scanFolderRecursive(fullPath, onFile); // recurse into subfolder
			else
				onFile(fullPath); // handle file
		}
	}

	public static function clearEventData():Void
	{
		eventmapping = [];
		usedeventmap = [];
		eventList = ['none'];
	}

	public static function cleareventlist():Void
	{
		usedeventmap = [];
		usedEvents = [];
	}

	public static function setupeventdata(foldertolook:String, append:Bool = false):Void
	{
		if (!append)
			clearEventData();

		#if sys
		scanFolderRecursive(foldertolook, function(filePath:String)
		{
			if (!filePath.toLowerCase().endsWith('.json'))
				return;

			try
			{
				var jsonString:String = File.getContent(filePath);
				if (jsonString == null || jsonString.trim().length < 1)
					return;

				var eventData:events.BaseEvent.EventSchematic = Json.parse(jsonString);
				var eventName:String = Path.withoutExtension(Path.withoutDirectory(filePath));
				if (eventmapping.exists(eventName))
					return;

				eventmapping.set(eventName, eventData);
				eventList.push(eventName);
			}
			catch (e:Dynamic)
			{
				trace('Failed to load event json: ' + filePath + ' (' + Std.string(e) + ')');
			}
		});
		#end
	}

	public static function setupevents(eventnote:Note.EventNote):Void
	{
		var eventname:String = eventnote.event;
		if (!usedEvents.contains(eventname))
		{
			if (hardcodedEvents.contains(eventname))
			{
				var className:String = switch (eventname)
				{
					case 'Lyrics':
						'LyricEvent';
					case 'Wavey':
						'WaveyNotes';
					default:
						eventname;
				};
				var cls = Type.resolveClass('events.' + className);
				trace('making event: ' + eventname + ' looked for class: ' + cls);
				var event:BaseEvent = Type.createInstance(cls, []);
				trace(event);
				event.precacheEvent(eventnote);
				usedeventmap.set(eventname, event);
				trace(usedeventmap);
				usedEvents.push(eventname);
			}
			else
			{
				if (!usedEvents.contains(eventname))
				{
					var event:ScriptedEvent = new ScriptedEvent(eventname);
					debug.Consolehandler.print('event is:' + event);
					if (event != null)
					{
						event.precacheEvent(eventnote);
						usedeventmap.set(eventname, event);
						usedEvents.push(eventname);
					}
				}
				else
				{
					usedeventmap.get(eventname).precacheEvent(eventnote);
				}
			}
		}
		else
		{
			usedeventmap.get(eventname).precacheEvent(eventnote);
		}
	}

	public static function callEvent(eventname:String, eventvalues:Array<Note.Eventsvalue>):Void
	{
		var event:BaseEvent = usedeventmap.get(eventname);
		if (event != null)
		{
			event.eventData = eventvalues;
			event.triggerEvent();
		}
		else
		{
		}
	}

	public static function setupAllEventData():Void
	{
		clearEventData();

		#if sys
		setupeventdata(Paths.getPreloadPath('data/events'), true);

		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			setupeventdata(Paths.mods(Paths.currentModDirectory + '/data/events'), true);

		for (mod in Paths.getGlobalMods())
			setupeventdata(Paths.mods(mod + '/data/events'), true);

		setupeventdata(Paths.mods('data/events'), true);
		#end
	}
}
