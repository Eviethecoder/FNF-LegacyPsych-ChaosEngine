package events;

class BPMChange extends BaseEvent
{
	public var newBpm:Float = 0;

	public function new()
	{
		super();
		eventName = "BPMChange";
	}

	override public function triggerEvent():Void
	{
		var newBpmValue = grabeventFloat("NewBpm");
		Conductor.bpm = newBpmValue;
	}
}
