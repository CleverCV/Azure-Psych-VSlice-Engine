package funkin.modding.module;

class Module
{
    public var id:String;

    public function new(id:String)
    {
        this.id = id;
    }

    public function scriptCall(name:String, args:Array<Dynamic>):Dynamic
    {
        return null;
    }

    public function onCreate(event:Dynamic):Void {}
    public function onSongLoaded(event:Dynamic):Void {}
    public function onSongRetry(event:Dynamic):Void {}
    public function onCountdownStart(event:Dynamic):Void {}
    public function onNoteHit(event:Dynamic):Void {}
}