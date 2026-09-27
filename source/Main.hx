package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.system.scaleModes.RatioScaleMode;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();

		scripting.PolymodTest.run();

		var gameWidth:Int = 1280;
		var gameHeight:Int = 720;

		var game = new FlxGame(gameWidth, gameHeight, MainMenu, 60, 60, true);
		addChild(game);

		#if mobile
		FlxG.scaleMode = new RatioScaleMode();
		#end
	}
}