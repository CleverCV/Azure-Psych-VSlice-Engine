package funkin;

/**
 * Compatibilidad básica con funkin.Preferences.
 */
class Preferences
{
	public static var naughtyness:Bool = true;

	public static function get(key:String):Dynamic
	{
		switch (key)
		{
			case "naughtyness":
				return naughtyness;

			default:
				return null;
		}
	}
}