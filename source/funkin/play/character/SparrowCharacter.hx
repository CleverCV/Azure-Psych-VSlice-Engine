package funkin.play.character;

import objects.Character;

class SparrowCharacter extends Character
{
    public var characterType:CharacterType = CharacterType.OTHER;
    public var holdTimer:Float = 0;

    public function new(id:String = "bf")
    {
        super(0, 0, id);
    }

    public function set_characterType(value:CharacterType):Void
    {
        characterType = value;
    }

    public function initHealthIcon(isOpponent:Bool = false):Void
    {
    }

    public function playSingAnimation(
        direction:String,
        force:Bool = true,
        suffix:String = ""
    ):Void
    {
        var anim = direction;

        if (suffix != null && suffix != "")
            anim += suffix;

        playAnim(anim, force);
    }
}