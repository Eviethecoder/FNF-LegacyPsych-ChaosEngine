package utility;

interface FunkinInterface
{
	public function onBeat(beat:Int):Void;
	public function onStep(step:Int):Void;
	public function onPause():Void;
	public function onResume():Void;
}
