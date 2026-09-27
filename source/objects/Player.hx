package objects;

/** Personaje controlado por el jugador. */
class Player extends Character
{
	public function new(
		x:Float = 0,
		y:Float = 0,
		id:String
	)
	{
		super(x, y, id);
	}
}