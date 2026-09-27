package funkin.play.song;

import funkin.modding.events.ScriptEvent;

class Song
{
    public var id:String;

    public function new(id:String)
    {
        this.id = id;
    }

    public function onCreate(event:ScriptEvent):Void {}
    public function onCountdownStart(event:Dynamic):Void {}
    public function onSongRetry(event:ScriptEvent):Void {}
}