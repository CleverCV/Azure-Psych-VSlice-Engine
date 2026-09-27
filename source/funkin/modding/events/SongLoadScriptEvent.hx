package funkin.modding.events;

class SongLoadScriptEvent extends ScriptEvent
{
    public var events:Array<Dynamic>;

    public function new(?events:Array<Dynamic>)
    {
        super();
        this.events = events != null ? events : [];
    }
}