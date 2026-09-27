package events;

/**
 * Normaliza eventos de V-Slice y Psych Engine.
 */
class EventParser
{
	public static function parse(value:Dynamic):Array<EngineEvent>
	{
		var result:Array<EngineEvent> = [];

		if (value == null)
			return result;

		/*
		 * Psych clásico:
		 *
		 * [
		 *   1000,
		 *   [
		 *     ["PlayAnimation", "bf", "hey"]
		 *   ]
		 * ]
		 */
		if (Std.isOfType(value, Array))
		{
			var array:Array<Dynamic> = cast value;

			if (
				array.length >= 2 &&
				isNumber(array[0]) &&
				Std.isOfType(array[1], Array)
			)
			{
				var time = toFloat(array[0]);
				var entries:Array<Dynamic> = cast array[1];

				for (entry in entries)
				{
					if (Std.isOfType(entry, Array))
					{
						var event:Array<Dynamic> = cast entry;

						if (event.length > 0)
						{
							result.push(
								new EngineEvent(
									time,
									Std.string(event[0]),
									event.length > 1 ? event[1] : null,
									event.length > 2 ? event[2] : null,
									value
								)
							);
						}
					}
					else if (entry != null)
					{
						for (parsed in parse(entry))
							result.push(parsed);
					}
				}

				return result;
			}

			for (entry in array)
			{
				for (parsed in parse(entry))
					result.push(parsed);
			}

			return result;
		}

		/*
		 * V-Slice:
		 *
		 * {
		 *   "t": 1000,
		 *   "e": "PlayAnimation",
		 *   "v": {
		 *     "char": "0",
		 *     "anim": "hey",
		 *     "force": true
		 *   }
		 * }
		 *
		 * Psych:
		 *
		 * {
		 *   "time": 1000,
		 *   "name": "PlayAnimation",
		 *   "value1": "bf",
		 *   "value2": "hey"
		 * }
		 */

		var hasName =
			Reflect.hasField(value, "name") ||
			Reflect.hasField(value, "e") ||
			Reflect.hasField(value, "event");

		if (!hasName)
			return result;

		var time = firstNumber(
			value,
			["t", "time", "timestamp"],
			0
		);

		var name = firstString(
			value,
			["e", "name", "event"],
			""
		);

		if (name.length == 0)
			return result;

		var v:Dynamic =
			Reflect.hasField(value, "v")
				? Reflect.field(value, "v")
				: null;

		var value1:Dynamic =
			Reflect.hasField(value, "value1")
				? Reflect.field(value, "value1")
				: null;

		var value2:Dynamic =
			Reflect.hasField(value, "value2")
				? Reflect.field(value, "value2")
				: null;

		if (value1 == null)
		{
			if (Std.isOfType(v, Array))
			{
				var values:Array<Dynamic> = cast v;

				value1 =
					values.length > 0
						? values[0]
						: null;

				value2 =
					values.length > 1
						? values[1]
						: null;
			}
			else
			{
				value1 = v;
			}
		}

		return [
			new EngineEvent(
				time,
				name,
				value1,
				value2,
				value
			)
		];
	}

	static function firstString(
		value:Dynamic,
		names:Array<String>,
		fallback:String
	):String
	{
		for (name in names)
		{
			if (
				Reflect.hasField(value, name) &&
				Reflect.field(value, name) != null
			)
			{
				return Std.string(
					Reflect.field(value, name)
				);
			}
		}

		return fallback;
	}

	static function firstNumber(
		value:Dynamic,
		names:Array<String>,
		fallback:Float
	):Float
	{
		for (name in names)
		{
			if (
				Reflect.hasField(value, name) &&
				Reflect.field(value, name) != null
			)
			{
				var result =
					toFloat(
						Reflect.field(value, name)
					);

				if (!Math.isNaN(result))
					return result;
			}
		}

		return fallback;
	}

	static function isNumber(value:Dynamic):Bool
	{
		if (
			Std.isOfType(value, Int) ||
			Std.isOfType(value, Float)
		)
			return true;

		return !Math.isNaN(
			Std.parseFloat(
				Std.string(value)
			)
		);
	}

	static function toFloat(value:Dynamic):Float
	{
		return Std.parseFloat(
			Std.string(value)
		);
	}
}