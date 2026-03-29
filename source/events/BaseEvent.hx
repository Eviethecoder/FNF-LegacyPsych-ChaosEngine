package events;

import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import PlayState;
import flixel.FlxBasic;
import HaxeScript;

using StringTools;

typedef EventUnion = Union4<Int, Float, String, Bool>;
typedef EventSchematic = {
    var eventLogic:Array<EventData>;
}

typedef EventData = {
    var name:String;
    var title:String;
    var type:SongEventTypes;
    @:optional
    var list:Array<String>;
}

typedef Eventdata = {
    var name:String;
    var value:Array<EventUnion>;
}



class BaseEvent extends FlxBasic
{
    public var earlyTriggerTime:Float = 0;
    public var eventName:String = "";
    public var eventScript:HaxeScript;
    public function new(name:String)
    {
        super();
        eventName = name;
   

    }

    public function triggerEvent(data:EventData):Void
    {
       
    }

    public function precacheEvent():Void
    {
       
    }


    public function returneventschematic():EventSchematic
    {
        return null;
    }


}


/**
 * The available field types for a song event schema.
 */
enum abstract SongEventTypes(String) from String to String
{
  /**
   * The STRING type will display as a text field.
   */
  public var STRING = "string";

  /**
   * The INTEGER type will display as a text field that only accepts numbers.
   */
  public var INTEGER = "integer";

  /**
   * The FLOAT type will display as a text field that only accepts numbers.
   */
  public var FLOAT = "float";

  /**
   * The BOOL type will display as a checkbox.
   */
  public var BOOL = "bool";

  /**
   * The DropDown type will display as a dropdown.
   * Make sure to specify the `list` field in the schema.
   */
  public var DROPDOWN = "dropdown";


}
