package events;

class EngineEvent
{
	public var time:Float;
	public var name:String;
	public var value1:Dynamic;
	public var value2:Dynamic;
	public var raw:Dynamic;

	public function new(
		time:Float,
		name:String,
		value1:Dynamic = null,
		value2:Dynamic = null,
		raw:Dynamic = null
	)
	{
		this.time = time;
		this.name = name;
		this.value1 = value1;
		this.value2 = value2;
		this.raw = raw;
	}

	public function boolValue(value:Dynamic, fallback:Bool = false):Bool
	{
		if (value == null)
			return fallback;

		if (Std.isOfType(value, Bool))
			return cast value;
        
var text = StringTools.trim(Std.string(value).toLowerCase());

		switch (text)
		{
			case "true", "1", "yes", "on":
				return true;

			case "false", "0", "no", "off":
				return false;

			default:
				return fallback;
		}
	}

	public function floatValue(value:Dynamic, fallback:Float = 0):Float
	{
		if (value == null)
			return fallback;

		var result = Std.parseFloat(Std.string(value));

		return Math.isNaN(result) ? fallback : result;
	}

	public function stringValue(value:Dynamic, fallback:String = ""):String
	{
		return value == null ? fallback : Std.string(value);
	}

	public function field(name:String, fallback:Dynamic = null):Dynamic
	{
		if (value1 != null && Reflect.hasField(value1, name))
			return Reflect.field(value1, name);

		return fallback;
	}
}