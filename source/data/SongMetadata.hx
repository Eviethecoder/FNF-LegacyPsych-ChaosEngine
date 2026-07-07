package data;

typedef Metadata =
{
	@:optional
	var Mixes:Array<String>;
	@:optional
	var color:String;
	@:optional
	var font:Fontformat;
	var renderdata:RenderData;
	var songitemdata:SongItemData;
}

typedef Fontformat =
{
	var font:String;
	var selectedcolor:Int;
	var deselectedcolor:Int;
}

typedef RenderData =
{
	var name:String;
	@:default(true)
	var dorendervibe:Bool;
	var rendergraphic:String;
	@:optional
	var animdata:Array<Character.AnimArray>;
}

typedef SongItemData =
{
	var itemgraphic:String;
	@:optional
	var animdata:Array<Character.AnimArray>;
}
