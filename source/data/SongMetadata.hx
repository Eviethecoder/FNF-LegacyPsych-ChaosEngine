package data;

typedef Metadata =
{
	var name:Null<String>;
	@:optional
	var Mixes:Null<Array<String>>;

	@:optional
	var color:Null<String>;

	@:optional
	var font:Null<Fontformat>;

	@:optional
	var renderdata:Null<RenderData>;

	@:optional
	var songitemdata:Null<SongItemData>;

	@:optional
	@:default(true)
	var dorendervibe:Null<Bool>;
}

typedef Fontformat =
{
	@:optional
	var font:Null<String>;

	@:optional
	var selectedcolor:Null<Int>;

	@:optional
	var deselectedcolor:Null<Int>;
}

typedef RenderData =
{
	@:optional
	var name:Null<String>;

	@:optional
	var rendergraphic:Null<String>;

	@:optional
	var animdata:Null<Array<Character.AnimArray>>;
}

typedef SongItemData =
{
	@:optional
	var itemgraphic:Null<String>;

	@:optional
	var animdata:Null<Array<Character.AnimArray>>;
}
