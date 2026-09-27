package scripting;

#if hscript
import hscript.Interp;
import hscript.Parser;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

/**
 * Cargador de scripts HScript.
 *
 * Los eventos nativos del engine se ejecutan primero.
 * Este sistema queda como fallback para eventos personalizados
 * definidos por mods.
 */
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

	if (context != null)
	{
		set("game", context);
		set("state", context);
	}
	#end
}

	/**
	 * Expone una variable a todos los scripts cargados.
	 */
	public function set(name:String, value:Dynamic):Void
	{
		#if hscript
		for (interp in scripts)
		{
			interp.variables.set(name, value);
		}
		#end
	}

	/**
	 * Busca scripts dentro de:
	 *
	 * scripts/events
	 * scripts/songs
	 * scripts/characters
	 */
	public function loadMod(modRoot:String):Void
	{
		#if sys
		if (modRoot == null || modRoot.length == 0)
			return;

		for (folder in [
			"scripts/events",
			"scripts/songs",
			"scripts/characters"
		])
		{
			var directory = modRoot + "/" + folder;

			if (FileSystem.exists(directory) && FileSystem.isDirectory(directory))
			{
				loadDirectory(directory);
			}
		}
		#end
	}

	/**
	 * Carga recursivamente todos los .hx/.hxc.
	 */
	public function loadDirectory(directory:String):Void
	{
		#if sys
		if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory))
			return;

		for (entry in FileSystem.readDirectory(directory))
		{
			var path = directory + "/" + entry;

			if (FileSystem.isDirectory(path))
			{
				loadDirectory(path);
			}
			else
			{
				var lower = entry.toLowerCase();

				if (
					StringTools.endsWith(lower, ".hx") ||
					StringTools.endsWith(lower, ".hxc")
				)
				{
					loadFile(path);
				}
			}
		}
		#end
	}

	/**
	 * Carga un archivo HScript individual.
	 */
	public function loadFile(path:String):Bool
	{
		#if hscript
		#if sys
		try
		{
			if (!FileSystem.exists(path))
				return false;

var interp = new Interp();

var program = parser.parseString(File.getContent(path));

interp.execute(program);

scripts.push(interp);
loadedFiles.push(path);

return true;
		}
		catch (error:Dynamic)
		{
			trace(
				"HScriptLoader: error cargando " +
				path +
				": " +
				error
			);
		}
		#end
		#end

		return false;
	}

	/**
	 * Comprueba si al menos un script tiene una función.
	 */
	public function hasFunction(name:String):Bool
	{
		#if hscript
		for (interp in scripts)
		{
			var callback:Dynamic = interp.variables.get(name);

			if (callback != null && Reflect.isFunction(callback))
				return true;
		}
		#end

		return false;
	}

	/**
	 * Ejecuta una función en todos los scripts que la tengan.
	 *
	 * Devuelve true si al menos un script manejó la función.
	 */
	public function call(
		name:String,
		args:Array<Dynamic> = null
	):Bool
	{
		var handled:Bool = false;

		#if hscript
		var parameters:Array<Dynamic> =
			args == null ? [] : args;

		for (interp in scripts)
		{
			var callback:Dynamic =
				interp.variables.get(name);

			if (
				callback != null &&
				Reflect.isFunction(callback)
			)
			{
				handled = true;

				try
				{
					Reflect.callMethod(
						null,
						callback,
						parameters
					);
				}
				catch (error:Dynamic)
				{
					trace(
						"HScriptLoader: error en " +
						name +
						": " +
						error
					);
				}
			}
		}
		#end

		return handled;
	}

	/**
	 * Evento genérico.
	 *
	 * Los scripts pueden implementar:
	 *
	 * function onEvent(name, value, time)
	 * {
	 *     ...
	 * }
	 */
	public function callEvent(
		eventName:String,
		value:Dynamic,
		time:Float
	):Bool
	{
		return call(
			"onEvent",
			[
				eventName,
				value,
				time
			]
		);
	}

	/**
	 * Callback por frame.
	 */
	public function update(elapsed:Float):Void
	{
		call(
			"onUpdate",
			[elapsed]
		);
	}

	/**
	 * Limpia todos los scripts.
	 */
	public function destroy():Void
	{
		#if hscript
		for (interp in scripts)
		{
			var callback:Dynamic =
				interp.variables.get("onDestroy");

			if (
				callback != null &&
				Reflect.isFunction(callback)
			)
			{
				try
				{
					Reflect.callMethod(
						null,
						callback,
						[]
					);
				}
				catch (error:Dynamic)
				{
					trace(
						"HScriptLoader: error en onDestroy: " +
						error
					);
				}
			}
		}

		scripts = [];
		#end

		loadedFiles = [];
	}
}