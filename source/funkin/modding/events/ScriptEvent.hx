package funkin.modding.events;

class ScriptEvent
{
    public var cancelled:Bool = false;

    public function new()
    {
    }

    public function cancel():Void
    {
        cancelled = true;
    }
}