package funkin.play.components;

import flixel.FlxSprite;

class HealthIcon extends FlxSprite
{
    public var characterId:String = "";

    public function new(id:String = "")
    {
        super();
        characterId = id;
    }

    public function setCharacter(id:String):Void
    {
        characterId = id;
    }
}