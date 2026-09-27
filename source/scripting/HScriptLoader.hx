package scripting;

#if hscript
import hscript.Interp;
import hscript.Parser;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

/** Carga y ejecuta scripts HScript de un mod sin acoplarlos a un PlayState. */
class HScriptLoader
{
	#if hscript
	var parser:Parser;
	var scripts:Array<Interp> = [];
	#end
	public var loadedFiles:Array<String> = [];

	public function new(context:Dynamic = null)
	{
		#if hscript
		parser = new Parser();
		if (context != null) set("game", context);
		set("trace", trace);
		#end
	}

	public function set(name:String, value:Dynamic):Void
	{
		#if hscript
		for (interp in scripts) interp.variables.set(name, value);
		#end
	}

	/** Busca scripts de evento/canción/personaje dentro de la raíz del mod. */
	public function loadMod(modRoot:String):Void
	{
		#if sys
		for (folder in ["scripts/events", "scripts/songs", "scripts/characters"])
		{
			var directory = modRoot + "/" + folder;
			if (FileSystem.exists(directory)) loadDirectory(directory);
		}
		#end
	}

	public function loadDirectory(directory:String):Void
	{
		#if sys
		if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory)) return;
		for (entry in FileSystem.readDirectory(directory))
		{
			var path = directory + "/" + entry;
			if (FileSystem.isDirectory(path)) loadDirectory(path);
			else if (StringTools.endsWith(entry.toLowerCase(), ".hx") || StringTools.endsWith(entry.toLowerCase(), ".hxc")) loadFile(path);
		}
		#end
	}

	public function loadFile(path:String):Bool
	{
		#if hscript
		try
		{
			var interp = new Interp();
			interp.variables.set("trace", trace);
			var program = parser.parseString(File.getContent(path));
			interp.execute(program);
			scripts.push(interp);
			loadedFiles.push(path);
			return true;
		}
		catch (error:Dynamic)
		{
			trace("HScriptLoader: error en " + path + ": " + error);
		}
		#end
		return false;
	}

	/** Llama una función exportada por cada script, si existe. */
	public function call(name:String, args:Array<Dynamic> = null):Void
	{
		#if hscript
		var parameters = args == null ? [] : args;
		for (interp in scripts)
		{
			var callback:Dynamic = interp.variables.get(name);
			if (callback != null && Reflect.isFunction(callback))
			{
				try Reflect.callMethod(null, callback, parameters)
				catch (error:Dynamic) trace("HScriptLoader: error en " + name + ": " + error);
			}
		}
		#end
	}

	public function callEvent(eventName:String, value:Dynamic, time:Float):Void
	{
		call("onEvent", [eventName, value, time]);
	}

	public function update(elapsed:Float):Void call("onUpdate", [elapsed]);
	public function destroy():Void
	{
		#if hscript
		for (interp in scripts)
		{
			var callback:Dynamic = interp.variables.get("onDestroy");
			if (callback != null && Reflect.isFunction(callback)) Reflect.callMethod(null, callback, []);
		}
		scripts = [];
		#end
	}
}
