package;

import flixel.FlxG;
import flixel.FlxState;
import parsers.PsychParser;
import parsers.VSliceParser;
import states.PsychPlayState;
import states.VSlicePlayState;

class PlayState extends FlxState
{
    public static var currentSong:String = "tutorial";
    public static var chartType:String = "psych"; 

    override public function create():Void
    {
        super.create();

        if (chartType == "vslice")
        {
            trace("Cargando Chart de V-Slice...");
			var parsedData = VSliceParser.parseChart(currentSong);
			FlxG.switchState(() -> new VSlicePlayState(parsedData));
        }
        else
        {
            trace("Cargando Chart de Psych Engine...");
            var parsedData = PsychParser.parseChart(currentSong);
            FlxG.switchState(new PsychPlayState(parsedData));
        }
    }
}