package funkin.audio;

import flixel.FlxG;
import flixel.sound.FlxSound;

/**
 * Compatibilidad básica con funkin.audio.FunkinSound.
 */
class FunkinSound
{
	public static function playOnce(
		path:String,
		volume:Float = 1.0
	):FlxSound
	{
		return FlxG.sound.play(path, volume);
	}
}