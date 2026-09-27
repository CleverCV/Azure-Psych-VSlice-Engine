package objects;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;
import openfl.display.BitmapData;
import openfl.utils.Assets;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

/**
 * Sprite de personaje compatible con los JSON de Psych Engine y Funkin' V-Slice.
 */
class Character extends FlxSprite
{
	public var characterId(default, null):String;
	public var animationOffsets:Map<String, Array<Float>> = new Map();
	public var cameraOffset:Array<Float> = [0, 0];

	public function new(x:Float = 0, y:Float = 0, id:String = "bf")
	{
		super(x, y);
		characterId = id;
		loadCharacter(id);
	}

	public function loadCharacter(id:String):Bool
	{
		characterId = id;

		var jsonPath = findCharacterJson(id);

		if (jsonPath == null)
		{
			trace('Character: no se encontró JSON para "' + id + '".');
			makeGraphic(1, 1, 0x00FFFFFF);
			return false;
		}

		try
		{
			var data:Dynamic = Json.parse(readText(jsonPath));
			var imagePath = findImagePath(id, jsonPath, data);

			if (imagePath == null)
				throw 'No se encontró PNG/XML para "' + id + '".';

			loadSparrow(imagePath + ".png", imagePath + ".xml");

			readAnimations(data);
			applyCharacterProperties(data);

			if (animation.exists("idle"))
				playAnim("idle");
			else if (animation.getNameList().length > 0)
				playAnim(animation.getNameList()[0]);

			trace('Character: "' + id + '" cargado desde ' + jsonPath);

			return true;
		}
		catch (error:Dynamic)
		{
			trace('Character: error cargando "' + id + '": ' + error);
			makeGraphic(1, 1, 0x00FFFFFF);
			return false;
		}
	}

	public function playAnim(name:String, force:Bool = false):Void
	{
		var key = normalizeAnimationName(name);

		if (!animation.exists(key))
			key = name;

		animation.play(key, force);

		var values = animationOffsets.get(key);

		if (values != null)
			offset.set(values[0], values[1]);
		else
			offset.set();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (
			animation.curAnim != null &&
			animation.curAnim.finished &&
			animation.curAnim.name != "idle" &&
			animation.exists("idle")
		)
		{
			playAnim("idle");
		}
	}

	function readAnimations(data:Dynamic):Void
	{
		var animations:Dynamic = field(data, "animations");

		if (!Std.isOfType(animations, Array))
			return;

		for (entry in (cast animations:Array<Dynamic>))
		{
			if (entry == null)
				continue;

			var rawName = stringField(
				entry,
				"anim",
				stringField(entry, "name", "idle")
			);

			var prefix = stringField(
				entry,
				"prefix",
				stringField(entry, "name", rawName)
			);

			if (
				Reflect.hasField(entry, "anim") &&
				Reflect.hasField(entry, "name")
			)
			{
				prefix = stringField(entry, "name", rawName);
			}

			var name = normalizeAnimationName(rawName);

			var fps = intField(
				entry,
				"fps",
				intField(entry, "frameRate", 24)
			);

			var loop = boolField(
				entry,
				"loop",
				boolField(entry, "looped", name == "idle")
			);

			var flipX = boolField(entry, "flipX", false);
			var flipY = boolField(entry, "flipY", false);

			var indices:Dynamic = field(entry, "indices");

			if (indices == null)
				indices = field(entry, "frameIndices");

			if (
				Std.isOfType(indices, Array) &&
				(cast indices:Array<Dynamic>).length > 0
			)
			{
				var frames:Array<Int> = [];

				for (index in (cast indices:Array<Dynamic>))
					frames.push(Std.int(index));

				animation.addByIndices(
					name,
					prefix,
					frames,
					"",
					fps,
					loop,
					flipX,
					flipY
				);
			}
			else
			{
				animation.addByPrefix(
					name,
					prefix,
					fps,
					loop,
					flipX,
					flipY
				);
			}

			var offsets:Dynamic = field(entry, "offsets");

			if (
				Std.isOfType(offsets, Array) &&
				(cast offsets:Array<Dynamic>).length >= 2
			)
			{
				var offsetValues:Array<Dynamic> = cast offsets;

				animationOffsets.set(
					name,
					[
						toFloat(offsetValues[0]),
						toFloat(offsetValues[1])
					]
				);
			}
		}
	}

	function applyCharacterProperties(data:Dynamic):Void
	{
		/*
		 * IMPORTANTE:
		 *
		 * La posición del personaje NO se toma del JSON del personaje.
		 * V-Slice ya proporciona la posición mediante:
		 *
		 * stageData.characters.bf.position
		 * stageData.characters.dad.position
		 *
		 * Por eso no sumamos aquí "position".
		 */

		flipX = boolField(
			data,
			"flip_x",
			boolField(data, "flipX", false)
		);

		antialiasing = boolField(
			data,
			"antialiasing",
			true
		);

		var scaleValue:Dynamic = field(data, "scale");

		if (
			scaleValue != null &&
			!Std.isOfType(scaleValue, Array)
		)
		{
			var scaleNumber = toFloat(scaleValue);
			scale.set(scaleNumber, scaleNumber);
		}
		else if (Std.isOfType(scaleValue, Array))
		{
			var values:Array<Dynamic> = cast scaleValue;

			if (values.length >= 2)
			{
				scale.set(
					toFloat(values[0]),
					toFloat(values[1])
				);
			}
		}

		var cameraPosition:Dynamic =
			field(data, "camera_position");

		if (cameraPosition == null)
			cameraPosition = field(data, "cameraOffsets");

		if (
			Std.isOfType(cameraPosition, Array) &&
			(cast cameraPosition:Array<Dynamic>).length >= 2
		)
		{
			var cameraValues:Array<Dynamic> = cast cameraPosition;

			cameraOffset = [
				toFloat(cameraValues[0]),
				toFloat(cameraValues[1])
			];
		}

		updateHitbox();
	}

	function loadSparrow(png:String, xml:String):Void
	{
		#if sys
		if (
			FileSystem.exists(png) &&
			FileSystem.exists(xml)
		)
		{
			frames = FlxAtlasFrames.fromSparrow(
				BitmapData.fromFile(png),
				Xml.parse(File.getContent(xml))
			);

			return;
		}
		#end

		frames = FlxAtlasFrames.fromSparrow(
			png,
			xml
		);
	}

	static function findCharacterJson(id:String):Null<String>
	{
		var slug = formatId(id);
		var ids = [id, slug];

		var roots = contentRoots();

		var folders = [
			"characters",
			"data/characters",
			"shared/data/characters",
			"shared/characters"
		];

		for (root in roots)
		{
			for (folder in folders)
			{
				for (name in ids)
				{
					var path =
						root +
						"/" +
						folder +
						"/" +
						name +
						".json";

					if (assetExists(path))
						return path;
				}
			}
		}

		return null;
	}

	static function findImagePath(
		id:String,
		jsonPath:String,
		data:Dynamic
	):Null<String>
	{
		var declared =
			stringField(
				data,
				"image",
				stringField(data, "assetPath", "")
			);

		var values = [
			declared,
			id,
			formatId(id)
		];

		var roots = contentRoots();

		var folders = [
			"images/characters",
			"characters",
			"shared/images/characters",
			"images"
		];

		for (value in values)
		{
			if (
				value == null ||
				value.length == 0
			)
				continue;

			value = removeExtension(value);

			if (
				assetExists(value + ".png") &&
				assetExists(value + ".xml")
			)
			{
				return value;
			}

			for (root in roots)
			{
				var directPath =
					root +
					"/" +
					value;

				if (
					assetExists(directPath + ".png") &&
					assetExists(directPath + ".xml")
				)
				{
					return directPath;
				}

				for (
					imageRoot in [
						root + "/images",
						root + "/shared/images"
					]
				)
				{
					var declaredPath =
						imageRoot +
						"/" +
						value;

					if (
						assetExists(declaredPath + ".png") &&
						assetExists(declaredPath + ".xml")
					)
					{
						return declaredPath;
					}
				}

				for (folder in folders)
				{
					var path =
						root +
						"/" +
						folder +
						"/" +
						value;

					if (
						assetExists(path + ".png") &&
						assetExists(path + ".xml")
					)
					{
						return path;
					}
				}
			}
		}

		return null;
	}

	static function normalizeAnimationName(value:String):String
	{
		var key = value.toLowerCase();
		var first = key.split("_")[0];

		return switch (first)
		{
			case "idle", "danceleft", "danceright":
				first;

			case "left", "singleft":
				"singLEFT";

			case "down", "singdown":
				"singDOWN";

			case "up", "singup":
				"singUP";

			case "right", "singright":
				"singRIGHT";

			case "missleft":
				"singLEFTmiss";

			case "missdown":
				"singDOWNmiss";

			case "missup":
				"singUPmiss";

			case "missright":
				"singRIGHTmiss";

			default:
				value;
		};
	}

	static function assetExists(path:String):Bool
	{
		if (Assets.exists(path))
			return true;

		#if sys
		return FileSystem.exists(path);
		#else
		return false;
		#end
	}

	static function contentRoots():Array<String>
	{
		var roots = [
			"mods",
			"assets",
			"assets/shared"
		];

		#if sys
		var modFolders = ["mods"];

		#if android
		var storage =
			lime.system.System.applicationStorageDirectory;

		if (
			storage != null &&
			storage.length > 0
		)
		{
			modFolders.unshift(
				storage + "mods"
			);
		}
		#end

		for (modsRoot in modFolders)
		{
			if (
				!FileSystem.exists(modsRoot) ||
				!FileSystem.isDirectory(modsRoot)
			)
				continue;

			if (roots.indexOf(modsRoot) == -1)
				roots.unshift(modsRoot);

			for (entry in FileSystem.readDirectory(modsRoot))
			{
				var path =
					modsRoot +
					"/" +
					entry;

				if (FileSystem.isDirectory(path))
					roots.unshift(path);
			}
		}
		#end

		return roots;
	}

	static function readText(path:String):String
	{
		if (Assets.exists(path))
			return Assets.getText(path);

		#if sys
		return File.getContent(path);
		#else
		throw "Asset no incluido: " + path;
		#end
	}

	static function formatId(value:String):String
	{
		return value
			.toLowerCase()
			.split(" ")
			.join("-");
	}

	static function removeExtension(value:String):String
	{
		return StringTools.endsWith(
			value.toLowerCase(),
			".png"
		)
			? value.substr(0, value.length - 4)
			: value;
	}

	static function field(
		value:Dynamic,
		name:String
	):Dynamic
	{
		return value != null &&
			Reflect.hasField(value, name)
			? Reflect.field(value, name)
			: null;
	}

	static function stringField(
		value:Dynamic,
		name:String,
		fallback:String
	):String
	{
		var result = field(value, name);

		return result == null
			? fallback
			: Std.string(result);
	}

	static function intField(
		value:Dynamic,
		name:String,
		fallback:Int
	):Int
	{
		var result = field(value, name);

		return result == null
			? fallback
			: Std.int(result);
	}

	static function boolField(
		value:Dynamic,
		name:String,
		fallback:Bool
	):Bool
	{
		var result = field(value, name);

		return result == null
			? fallback
			: result == true ||
			  Std.string(result).toLowerCase() == "true";
	}

	static function toFloat(value:Dynamic):Float
	{
		var parsed =
			Std.parseFloat(
				Std.string(value)
			);

		return Math.isNaN(parsed)
			? 0
			: parsed;
	}
}