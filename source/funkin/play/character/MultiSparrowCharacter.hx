package funkin.play.character;

import objects.Character;

/**
 * Compatibilidad con MultiSparrowCharacter de Funkin.
 *
 * Internamente utiliza nuestro Character.
 */
class MultiSparrowCharacter extends Character
{
	public function new(id:String)
	{
		super(0, 0, id);
	}

	public function playSingAnimation(
		name:String,
		?holdTimer:Float = 0
	):Void
	{
		playAnim(name, true);
	}

	public function getDeathQuote():Null<String>
	{
		return null;
	}
}