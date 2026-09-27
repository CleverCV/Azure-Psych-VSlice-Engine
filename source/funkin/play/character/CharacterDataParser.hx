package funkin.play.character;

import objects.Character;

class CharacterDataParser
{
    public static function fetchCharacter(id:String):Character
    {
        if (id == null || id == "")
            return null;

        var character = new Character(0, 0, id);

        return character;
    }
}