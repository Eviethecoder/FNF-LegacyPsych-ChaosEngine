package;

import Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var cameraevents:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	var arrowSkin:String;
	var hudSkin:String;
	var splashSkin:String;
	var validScore:Bool;
}


//// "what"?
//// a typedef with default values, basically. @crowplexus
@:structInit class ChartNoteData {
	public var time: Null<Float> = null;
	public var id: Null<Int> = null;
	public var type: Null<String> = null;
	public var strumLine: Null<Int> = null;
	public var isGfNote: Null<Bool> = null;
	public var sLen: Null<Float> = null;

	public function dispose() {
		// will be cleared by the GC later
		time = null;
		id = null;
		type = null;
		strumLine = null;
		isGfNote = null;
		sLen = null;
	}
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var cameraevents:Array<Dynamic>;

	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var hudSkin:String;
	public var splashSkin:String;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	private static function onLoadJson(songJson:Dynamic) // Convert old charts to newest format
	{
		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}
		if(songJson.hudSkin == null) songJson.hudSkin = 'default';

		if(songJson.events == null)
		{
			songJson.events = [];
			
		}
		if (songJson.cameraevents == null)
		{
			songJson.cameraevents = [];

			// for (secNum in 0...songJson.notes.length)
			// {
			// 	var sec:SwagSection = songJson.notes[secNum];
			// 	if (sec.sectionNotes == null) continue;

			// 	var i:Int = 0;
			// 	var notes:Array<Dynamic> = sec.sectionNotes;
			// 	var len:Int = notes.length;

			// 	while (i < len)
			// 	{
			// 		var note:Array<Dynamic> = notes[i];

			// 		// Check for camera events marked with a special ID (-999 or another flag)
			// 		if (note[1] == -2) // you can customize this
			// 		{
			// 			songJson.cameraevents.push([note[0], [[note[2], note[3], note[4]]]]);
			// 			notes.remove(note);
			// 			len = notes.length;
			// 		}
			// 		else i++;
			// 	}
			// }
		}
	}

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = null;
		var foldertocheck:String;
		if (folder == null){
			foldertocheck = 'songs/default';
		}
		else{
			foldertocheck = folder;
		}

		var formattedFolder:String = Paths.formatToSongPath(foldertocheck);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		trace('formattedFolder:' + formattedFolder);
		trace('formattedSong:' + formattedSong);
		trace('pathslocation:' + Paths.json(formattedFolder + '/' + formattedSong).trim());
		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsJson(formattedFolder + '/' + formattedSong);
		if(FileSystem.exists(moddyFile)) {
			rawJson = File.getContent(moddyFile).trim();
		}
		#end

		if(rawJson == null) {
			#if sys
			trace('loading songs from datafolder');
			rawJson = File.getContent(Paths.json(formattedFolder + '/' + formattedSong)).trim();

			#else
			rawJson = Assets.getText(Paths.json(formattedFolder + '/' + formattedSong)).trim();
			#end
		}

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		var songJson:Dynamic = parseJSONshit(rawJson);
		if(jsonInput != 'events'|| jsonInput != 'cameraevents') data.StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		return swagShit;
	}
}
