package funkin.play;

class GameOverSubState
{
    public static var instance:GameOverSubState;

    public var mustNotExit:Bool = false;

    public function new()
    {
        instance = this;
    }

    public function add(object:Dynamic):Void
    {
    }

    public static function playBlueBalledSFX():Void
    {
    }
}