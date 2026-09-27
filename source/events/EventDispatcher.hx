package events;

import flixel.util.FlxColor;
import objects.Character;

class EventDispatcher
{
	public static function dispatch(
		event:EngineEvent,
		state:Dynamic
	):Bool
	{
		if (
			event == null ||
			event.name == null ||
			state == null
		)
			return false;

		var name =
			normalize(event.name);

		switch (name)
		{
			case "focuscamera", "focus camera":
				return focusCamera(event, state);

			case "playanimation", "play animation":
				return playAnimation(event, state);

			case "setcamerazoom", "set camera zoom":
				return setCameraZoom(event, state);

			case "addcamerazoom", "add camera zoom":
				return addCameraZoom(event, state);

			case "setcharacterflip", "set character flip":
				return setCharacterFlip(event, state);

			case "setcharactervisible", "set character visible":
				return setCharacterVisible(event, state);

			case "setcharacteralpha", "set character alpha":
				return setCharacterAlpha(event, state);

			case "setcharacterposition", "set character position":
				return setCharacterPosition(event, state);

			case "cameraflash", "camera flash":
				return cameraFlash(event, state);

			default:
				return false;
		}
	}

	static function focusCamera(
		event:EngineEvent,
		state:Dynamic
	):Bool
	{
		var target =
			event.field("char", null);

		if (target == null)
			target = event.field("character", null);

		if (target == null)
			target = event.value1;

		var role =
			Std.string(target).toLowerCase();

		if (
			role == "0" ||
			role == "bf" ||
			role == "player"
		)
		{
			if (state.player != null)
			{
				state.focusCamera(
					state.player,
					"bf"
				);

				return true;
			}
		}

		if (
			role == "1" ||
			role == "dad" ||
			role == "opponent"
		)
		{
			if (state.enemy != null)
			{
				state.focusCamera(
					state.enemy,
					"dad"
				);

				return true;
			}
		}

		return false;
	}

	static function playAnimation(
		event:EngineEvent,
		state:Dynamic
	):Bool
	{
		var target =
			event.field("char", null);

		if (target == null)
			target =
				event.field(
					"character",
					null
				);

		var animation =
			event.field("anim", null);

		if (animation == null)
			animation =
				event.field(
					"animation",
					null
				);

		/*
		 * V-Slice:
		 *
		 * {
		 *   "char": "0",
		 *   "anim": "hey",
		 *   "force": true
		 * }
		 */

		if (
			animation == null &&
			event.value1 != null &&
			Reflect.hasField(
				event.value1,
				"animation"
			)
		)
		{
			animation =
				Reflect.field(
					event.value1,
					"animation"
				);
		}

		/*
		 * Psych:
		 *
		 * value1 = character
		 * value2 = animation
		 */

		if (
			target == null &&
			event.value1 != null &&
			!Std.isOfType(
				event.value1,
				Bool
			)
		)
		{
			target = event.value1;
		}

		if (
			animation == null &&
			event.value2 != null
		)
		{
			animation = event.value2;
		}

		if (target == null)
			target = "bf";

		if (animation == null)
			animation = "idle";

		var force =
			event.boolValue(
				event.field(
					"force",
					true
				),
				true
			);

		var role =
			Std.string(
				target
			).toLowerCase();

		var character:Character = null;

		if (
			role == "0" ||
			role == "bf" ||
			role == "player"
		)
		{
			character = state.player;
		}
		else if (
			role == "1" ||
			role == "dad" ||
			role == "opponent"
		)
		{
			character = state.enemy;
		}
		else
		{
			if (
				state.player != null &&
				state.player.characterId ==
					Std.string(target)
			)
			{
				character = state.player;
			}

			if (
				state.enemy != null &&
				state.enemy.characterId ==
					Std.string(target)
			)
			{
				character = state.enemy;
			}
		}

		if (character == null)
			return false;

		character.playAnim(
			Std.string(animation),
			force
		);

		return true;
	}

	static function setCameraZoom(
		event:EngineEvent,
		state:Dynamic
	):Bool
	{
		var zoom =
			event.floatValue(
				event.field(
					"zoom",
					event.value1
				),
				state.camGame.zoom
			);

		state.camGame.zoom = zoom;

		return true;
	}

	static function addCameraZoom(
		event:EngineEvent,
		state:Dynamic
	):Bool
	{
		var amount =
			event.floatValue(
				event.field(
					"zoom",
					event.value1
				),
				0
			);

		state.camGame.zoom += amount;

		return true;
	}

	static function setCharacterFlip(
		event:EngineEvent,
		state:Dynamic
	):Bool
	{
		var character =
			resolveCharacter(
				event,
				state
			);

		if (character == null)
			return false;

		character.flipX =
			event.boolValue(
				event.field(
					"flipX",
					event.value2 != null
						? event.value2
						: event.value1
				),
				character.flipX
			);

		return true;
	}

	static function setCharacterVisible(
		event:EngineEvent,
		state:Dynamic
	):Bool
	{
		var character =
			resolveCharacter(
				event,
				state
			);

		if (character == null)
			return false;

		character.visible =
			event.boolValue(
				event.field(
					"visible",
					event.value2 != null
						? event.value2
						: event.value1
				),
				character.visible
			);

		return true;
	}

	static function setCharacterAlpha(
		event:EngineEvent,
		state:Dynamic
	):Bool
	{
		var character =
			resolveCharacter(
				event,
				state
			);

		if (character == null)
			return false;

		character.alpha =
			event.floatValue(
				event.field(
					"alpha",
					event.value2 != null
						? event.value2
						: event.value1
				),
				character.alpha
			);

		return true;
	}

	static function setCharacterPosition(
		event:EngineEvent,
		state:Dynamic
	):Bool
	{
		var character =
			resolveCharacter(
				event,
				state
			);

		if (character == null)
			return false;

		var x =
			event.field("x", null);

		var y =
			event.field("y", null);

		if (
			x == null &&
			Std.isOfType(
				event.value1,
				Array
			)
		)
		{
			var values:Array<Dynamic> =
				cast event.value1;

			if (values.length > 0)
				x = values[0];

			if (values.length > 1)
				y = values[1];
		}

		if (
			x == null &&
			event.value1 != null
		)
		{
			x = event.value1;
		}

		if (
			y == null &&
			event.value2 != null
		)
		{
			y = event.value2;
		}

		character.x =
			event.floatValue(
				x,
				character.x
			);

		character.y =
			event.floatValue(
				y,
				character.y
			);

		return true;
	}

	static function cameraFlash(
		event:EngineEvent,
		state:Dynamic
	):Bool
	{
		var duration =
			event.floatValue(
				event.field(
					"duration",
					event.value2
				),
				0.5
			);

		var color =
			event.field(
				"color",
				event.value1
			);

		state.camGame.flash(
			parseColor(color),
			duration
		);

		return true;
	}

	static function resolveCharacter(
		event:EngineEvent,
		state:Dynamic
	):Null<Character>
	{
		var target =
			event.field(
				"char",
				null
			);

		if (target == null)
			target =
				event.field(
					"character",
					null
				);

		if (target == null)
			target = event.value1;

		if (target == null)
			target = "bf";

		var role =
			Std.string(
				target
			).toLowerCase();

		if (
			role == "0" ||
			role == "bf" ||
			role == "player"
		)
			return state.player;

		if (
			role == "1" ||
			role == "dad" ||
			role == "opponent"
		)
			return state.enemy;

		if (
			state.player != null &&
			state.player.characterId ==
				Std.string(target)
		)
			return state.player;

		if (
			state.enemy != null &&
			state.enemy.characterId ==
				Std.string(target)
		)
			return state.enemy;

		return null;
	}

	static function parseColor(
		value:Dynamic
	):FlxColor
	{
		if (value == null)
			return FlxColor.WHITE;

		var text =
			Std.string(value);

		if (text.charAt(0) == "#")
			text = text.substr(1);

		if (text.length == 6)
			text = "FF" + text;

		var parsed =
			Std.parseInt(
				"0x" + text
			);

		return parsed == null
			? FlxColor.WHITE
			: parsed;
	}

static function normalize(
	value:String
):String
{
	return StringTools.trim(
		value
			.toLowerCase()
			.split("_")
			.join(" ")
			.split("-")
			.join(" ")
	);
    }
}