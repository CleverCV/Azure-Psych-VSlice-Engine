package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class Note extends FlxSprite
{
    public var strumTime:Float = 0;
    public var noteData:Int = 0; 
    public var mustHit:Bool = false; 

	// --- VARIABLES NUEVAS PARA SUSTAINS ---
	public var isSustainNote:Bool = false;
	public var parentNote:Note = null;
	public var sustainLength:Float = 0;
	public var wasPressed:Bool = false;

	public function new(strumTime:Float, noteData:Int, mustHit:Bool, isSustainNote:Bool = false, isLastSustain:Bool = false, customFrames:FlxAtlasFrames = null)
    {
        super();
        this.strumTime = strumTime;
        this.noteData = noteData;
        this.mustHit = mustHit;
		this.isSustainNote = isSustainNote;

		frames = customFrames != null ? customFrames : FlxAtlasFrames.fromSparrow(
            "assets/shared/images/notes/NOTE_assets.png", 
            "assets/shared/images/notes/NOTE_assets.xml"
        );

		animation.addByPrefix('purpleScroll', 'purple0');
		animation.addByPrefix('blueScroll', 'blue0');
		animation.addByPrefix('greenScroll', 'green0');
		animation.addByPrefix('redScroll', 'red0');       

		animation.addByPrefix('purplehold', 'purple hold piece');
		animation.addByPrefix('purpleholdend', 'purple hold end');
		animation.addByPrefix('bluehold', 'blue hold piece');
		animation.addByPrefix('blueholdend', 'blue hold end');
		animation.addByPrefix('greenhold', 'green hold piece');
		animation.addByPrefix('greenholdend', 'green hold end');
		animation.addByPrefix('redhold', 'red hold piece');
		animation.addByPrefix('redholdend', 'red hold end');

		var colorNames:Array<String> = ['purple', 'blue', 'green', 'red'];
		var color:String = colorNames[noteData];

		if (isSustainNote)
		{
			if (isLastSustain)
			{
				animation.play(color + 'holdend');
			}
			else
			{
				animation.play(color + 'hold');
			}

			alpha = 0.6;
		}
		else
		{
			switch (noteData)
			{
				case 0:
					animation.play('purpleScroll');
				case 1:
					animation.play('blueScroll');
				case 2:
					animation.play('greenScroll');
				case 3:
					animation.play('redScroll');
			}
        }

		if (isSustainNote)
		{
			scale.set(0.7, 0.7);
			updateHitbox();
		}
		else
		{
			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();
		}
        
        antialiasing = true;
    }
}
