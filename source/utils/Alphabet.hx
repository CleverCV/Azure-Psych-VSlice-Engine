package utils;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;

class Alphabet extends FlxSpriteGroup
{
    public var text(default, set):String = "";
    
    private var _textWidth:Float = 0;
    private var _textSize:Float = 1.0;
    private var _isBold:Bool = false;

    public function new(x:Float, y:Float, text:String = "", isBold:Bool = false, textSize:Float = 1.0)
    {
        super(x, y);
        this._isBold = isBold;
        this._textSize = textSize;
        this.text = text;
    }

    private function set_text(newText:String):String
    {
        if (text == newText && members.length > 0) return text;
        
        text = newText;
        clearAlphabet();

        var startX:Float = 0;
        var startY:Float = 0;
        var spaceWidth:Float = 28 * _textSize;
        var rowHeight:Float = 70 * _textSize;

        for (i in 0...text.length)
        {
            var char:String = text.charAt(i);

            // Control de salto de línea
            if (char == "\n")
            {
                startX = 0;
                startY += rowHeight;
                continue;
            }

            // Control de espacio
            if (char == " ")
            {
                startX += spaceWidth;
                continue;
            }

            var letter:AlphaCharacter = new AlphaCharacter(startX, startY, char, _isBold);
            letter.scale.set(_textSize, _textSize);
            letter.updateHitbox();
            add(letter);

            // Avanzar cursor para la siguiente letra con un pequeño espacio
            startX += letter.width + (4 * _textSize);
        }

        _textWidth = startX;
        return text;
    }

    private function clearAlphabet():Void
    {
        while (members.length > 0)
        {
            var obj = members.shift();
            if (obj != null) obj.destroy();
        }
    }
}

class AlphaCharacter extends FlxSprite
{

    // Mapeo de caracteres especiales a nombres seguros en el XML
    private static var _charMap:Map<String, String> = [
        "á" => "á",
        "é" => "é",
        "í" => "í",
        "ó" => "ó",
        "ú" => "ú",
        "ñ" => "ñ"
    ];

    public function new(x:Float, y:Float, char:String, isBold:Bool = false)
    {
        super(x, y);
        
        // Build / retrieve the atlas when this glyph is created.  Keeping a
        // static FlxAtlasFrames reference can retain an invalid graphic after
        // a state has been destroyed, which made every Freeplay glyph invisible
        // on returning from a song.
        frames = FlxAtlasFrames.fromSparrow(
            'assets/shared/images/alphabet.png',
            'assets/shared/images/alphabet.xml'
        );

        var animType:String = "normal";
        if (isBold)
        {
            animType = "bold";
        }
        else if (char != char.toLowerCase())
        {
            animType = "uppercase";
        }

        else if (char != char.toUpperCase())
        {
            animType = "lowercase";
        }

        var charKey:String = _charMap.exists(char) ? _charMap.get(char) : char;
        charKey = char.toLowerCase();

        // The glyph names finish with "10000", but that number is part of the
        // exported name (not an animation frame index). `addByPrefix` attempts
        // to parse it as a frame number and fills the log every time Freeplay
        // rebuilds its labels. Select this exact atlas frame instead.
        var animName:String = charKey + " " + animType + " instance 10000";
        animation.addByNames('idle', [animName], 24, true);
        animation.play('idle');
        
        if (animation.curAnim == null)
        {
            visible = false;
        }
    }
}
