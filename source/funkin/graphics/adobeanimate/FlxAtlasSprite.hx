package funkin.graphics.adobeanimate;

import flixel.FlxSprite;

class FlxAtlasSprite extends FlxSprite
{
    public var zIndex:Int = 0;

    public function new(x:Float, y:Float, path:String)
    {
        super(x, y);
    }

    public function playAnimation(name:String):Void
    {
    }
}