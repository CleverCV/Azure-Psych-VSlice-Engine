package objects;

/** Personaje controlado por el jugador. */
class Player extends Character
{
	public function new(x:Float = 0, y:Float = 0, id:String)
	{
		super(x, y, id);
		// El jugador se muestra mirando al rival, situado a la izquierda del stage.
		flipX = true;
	}

	override public function playAnim(name:String, force:Bool = false):Void
	{
		super.playAnim(name, force);
		flipX = true;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		// FlxAnimationController puede restaurar el flip del atlas al cambiar
		// de frame; reaplicarlo aquí garantiza la orientación del jugador.
		flipX = true;
	}
}
