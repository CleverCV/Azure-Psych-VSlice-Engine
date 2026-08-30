package parsers;

import haxe.Json;
import openfl.utils.Assets;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class VSliceParser
{
	public static var difficulty:String = "normal";

	/** Loads a V-Slice chart and normalizes it for VSlicePlayState. */
	public static function parseChart(songName:String):Dynamic
	{
		var songId = formatSongId(songName);
		var chartPath = findChartPath(songId);

		if (chartPath == null)
		{
			trace("VSliceParser: no se encontró un chart V-Slice para " + songId);
			return emptyChart(songName);
		}

		try
		{
			var rawChart:Dynamic = Json.parse(readChartText(chartPath));
			var rawNotes:Array<Dynamic> = selectDifficultyNotes(rawChart, difficulty);
			var notes:Array<Dynamic> = [];

			for (rawNote in rawNotes)
			{
				if (rawNote == null || !Reflect.hasField(rawNote, "t") || !Reflect.hasField(rawNote, "d"))
					continue;

				var direction:Int = Std.int(Reflect.field(rawNote, "d"));
				if (direction < 0 || direction > 7)
				{
					trace("VSliceParser: dirección inválida ignorada: " + direction);
					continue;
				}

				notes.push({
					strumTime: Std.parseFloat(Std.string(Reflect.field(rawNote, "t"))),
					noteData: direction % 4,
					// Invertido: mustHit debe ser true para notas del jugador. En V-Slice
					// las direcciones 0-3 suelen corresponder a un lado y 4-7 al otro,
					// pero aquí queremos que `mustHit == true` represente notas del jugador.
					mustHit: direction < 4,
					sustainLength: Reflect.hasField(rawNote, "l") ? Std.parseFloat(Std.string(Reflect.field(rawNote, "l"))) : 0
				});
			}

			notes.sort(function(a:Dynamic, b:Dynamic):Int return Reflect.compare(a.strumTime, b.strumTime));
			var selectedDifficulty = selectedDifficultyName(rawChart, difficulty);
			trace("VSliceParser: " + notes.length + " notas cargadas de " + chartPath + " (" + selectedDifficulty + ")");

			// Try to detect a base folder for song audio (Inst/Voices)
			var audioBase:Null<String> = findSongAudioPath(songId, chartPath);
			if (audioBase == null)
			{
				// fallback: use chartPath folder if possible
				var idx = chartPath.lastIndexOf("/");
				if (idx >= 0) audioBase = chartPath.substr(0, idx);
			}

			return {
				song: songName,
				speed: getScrollSpeed(rawChart, selectedDifficulty),
				notes: notes,
				events: Reflect.hasField(rawChart, "events") ? Reflect.field(rawChart, "events") : [],
				basePath: audioBase
			};
		}
		catch (error:Dynamic)
		{
			trace("VSliceParser: error al leer " + chartPath + ": " + error);
			return emptyChart(songName);
		}
	}

	static function findChartPath(songId:String):Null<String>
	{
		#if android
		// En Android, solo buscar en almacenamiento de la app
		var appStoragePath = lime.system.System.applicationStorageDirectory;
		if (appStoragePath != null && appStoragePath.length > 0)
		{
			var candidates = [
				appStoragePath + "data/songs/" + songId + "/" + songId + "-chart.json",
				appStoragePath + "data/songs/" + songId + "/" + songId + ".json",
				appStoragePath + "data/" + songId + "/" + songId + "-chart.json",
				appStoragePath + "data/shared/data/" + songId + "/" + songId + "-chart.json",
				appStoragePath + "data/shared/data/" + songId + "/" + songId + ".json"
			];

			for (p in candidates)
				if (chartExists(p)) return p;

			// Buscar en mods de Android
			var modsPath = appStoragePath + "mods";
			if (FileSystem.exists(modsPath) && FileSystem.isDirectory(modsPath))
			{
				for (modId in FileSystem.readDirectory(modsPath))
				{
					var tryPaths = [
						modsPath + "/" + modId + "/data/songs/" + songId + "/" + songId + "-chart.json",
						modsPath + "/" + modId + "/data/songs/" + songId + "/" + songId + ".json",
						modsPath + "/" + modId + "/songs/" + songId + "/" + songId + "-chart.json",
						modsPath + "/" + modId + "/songs/" + songId + "/" + songId + ".json",
						modsPath + "/" + modId + "/data/" + songId + "/" + songId + "-chart.json",
						modsPath + "/" + modId + "/assets/data/songs/" + songId + "/" + songId + "-chart.json",
						modsPath + "/" + modId + "/assets/data/songs/" + songId + "/" + songId + ".json",
						modsPath + "/" + modId + "/assets/data/" + songId + "/" + songId + "-chart.json",
						modsPath + "/" + modId + "/assets/songs/" + songId + "/" + songId + "-chart.json",
						modsPath + "/" + modId + "/assets/songs/" + songId + "/" + songId + ".json"
					];

					for (mp in tryPaths)
					{
						if (chartExists(mp)) return mp;
					}
				}
			}
		}
		#else
		// Candidate locations in vanilla assets (common V-Slice layouts)
		var candidates = [
			"assets/data/songs/" + songId + "/" + songId + "-chart.json",
			"assets/data/songs/" + songId + "/" + songId + ".json",
			"assets/data/" + songId + "/" + songId + "-chart.json",
			"assets/shared/data/" + songId + "/" + songId + "-chart.json",
			"assets/shared/data/" + songId + "/" + songId + ".json",
			"assets/songs/" + songId + "/" + songId + "-chart.json",
			"assets/shared/songs/" + songId + "/" + songId + "-chart.json"
		];

		for (p in candidates)
			if (chartExists(p)) return p;

		// Also check mods folders for V-Slice style charts
		#if sys
		var modsPaths:Array<String> = ["mods"];
		
		for (modsPath in modsPaths)
		{
			if (FileSystem.exists(modsPath) && FileSystem.isDirectory(modsPath))
			{
				for (modId in FileSystem.readDirectory(modsPath))
				{
					var tryPaths = [
						modsPath + "/" + modId + "/data/songs/" + songId + "/" + songId + "-chart.json",
						modsPath + "/" + modId + "/data/songs/" + songId + "/" + songId + ".json",
						modsPath + "/" + modId + "/songs/" + songId + "/" + songId + "-chart.json",
						modsPath + "/" + modId + "/songs/" + songId + "/" + songId + ".json",
						modsPath + "/" + modId + "/data/" + songId + "/" + songId + "-chart.json",
						modsPath + "/" + modId + "/assets/data/songs/" + songId + "/" + songId + "-chart.json",
						modsPath + "/" + modId + "/assets/data/songs/" + songId + "/" + songId + ".json",
						modsPath + "/" + modId + "/assets/data/" + songId + "/" + songId + "-chart.json",
						modsPath + "/" + modId + "/assets/songs/" + songId + "/" + songId + "-chart.json",
						modsPath + "/" + modId + "/assets/songs/" + songId + "/" + songId + ".json"
					];

					for (mp in tryPaths)
					{
						if (chartExists(mp)) return mp;
					}
				}
			}
		}
		#end
		#end

		return null;
	}

	static function chartExists(path:String):Bool
	{
		if (Assets.exists(path)) return true;
		#if sys
		return FileSystem.exists(path);
		#else
		return false;
		#end
	}

	static function readChartText(path:String):String
	{
		if (Assets.exists(path)) return Assets.getText(path);
		#if sys
		return File.getContent(path);
		#else
		throw "El chart no está incluido en los assets: " + path;
		#end
	}

	static function selectDifficultyNotes(chart:Dynamic, requestedDifficulty:String):Array<Dynamic>
	{
		if (chart == null || !Reflect.hasField(chart, "notes")) return [];
		var notesByDifficulty:Dynamic = Reflect.field(chart, "notes");
		var notes:Dynamic = Reflect.field(notesByDifficulty, selectedDifficultyName(chart, requestedDifficulty));
		return Std.isOfType(notes, Array) ? cast notes : [];
	}

	static function selectedDifficultyName(chart:Dynamic, requestedDifficulty:String):String
	{
		var notesByDifficulty:Dynamic = chart != null && Reflect.hasField(chart, "notes") ? Reflect.field(chart, "notes") : null;
		if (notesByDifficulty == null) return requestedDifficulty;
		if (Reflect.hasField(notesByDifficulty, requestedDifficulty)) return requestedDifficulty;
		for (fallback in ["normal", "hard", "easy"])
			if (Reflect.hasField(notesByDifficulty, fallback)) return fallback;
		var available = Reflect.fields(notesByDifficulty);
		return available.length > 0 ? available[0] : requestedDifficulty;
	}

	static function getScrollSpeed(chart:Dynamic, selectedDifficulty:String):Float
	{
		if (chart != null && Reflect.hasField(chart, "scrollSpeed"))
		{
			var speeds:Dynamic = Reflect.field(chart, "scrollSpeed");
			if (speeds != null && Reflect.hasField(speeds, selectedDifficulty))
				return Std.parseFloat(Std.string(Reflect.field(speeds, selectedDifficulty)));
		}
		return 2.8;
	}

	/** Try to find a song folder containing Inst.ogg or Voices.ogg in assets or mods. */
	static function findSongAudioPath(songId:String, chartPath:Null<String> = null):Null<String>
	{
		#if android
		// En Android, solo buscar en almacenamiento de la app
		var appStoragePath = lime.system.System.applicationStorageDirectory;
		if (appStoragePath != null && appStoragePath.length > 0)
		{
			var candidates = [
				appStoragePath + "data/songs/" + songId,
				appStoragePath + "data/" + songId,
				appStoragePath + "data/shared/songs/" + songId
			];

			for (c in candidates)
			{
				if (hasAudioFile(c)) return c;
			}

			// Buscar en mods de Android
			var modsPath = appStoragePath + "mods";
			if (FileSystem.exists(modsPath) && FileSystem.isDirectory(modsPath))
			{
				for (modId in FileSystem.readDirectory(modsPath))
				{
					var tryPaths = [
						modsPath + "/" + modId + "/songs/" + songId,
						modsPath + "/" + modId + "/data/songs/" + songId,
						modsPath + "/" + modId + "/data/" + songId,
						modsPath + "/" + modId + "/assets/songs/" + songId,
						modsPath + "/" + modId + "/assets/data/songs/" + songId,
						modsPath + "/" + modId + "/assets/data/" + songId,
						modsPath + "/" + modId + "/assets/" + songId
					];

					for (p in tryPaths)
					{
						if (hasAudioFile(p)) return p;
					}
				}
			}
		}
		#else
		var candidates = [
			"assets/shared/songs/" + songId,
			"assets/songs/" + songId,
			"assets/data/songs/" + songId,
			"assets/data/" + songId,
			"assets/shared/data/" + songId
		];

		if (chartPath != null)
		{
			var idx = chartPath.lastIndexOf("/");
			if (idx >= 0)
			{
				var dir = chartPath.substring(0, idx);
				candidates.push(dir);
				candidates.push(dir + "/../songs/" + songId);
			}
		}

		for (c in candidates)
		{
			if (hasAudioFile(c)) return c;
		}

		#if sys
		var modsPaths:Array<String> = ["mods"];
		
		for (modsPath in modsPaths)
		{
			if (FileSystem.exists(modsPath) && FileSystem.isDirectory(modsPath))
			{
				for (modId in FileSystem.readDirectory(modsPath))
				{
					var tryPaths = [
						modsPath + "/" + modId + "/songs/" + songId,
						modsPath + "/" + modId + "/data/songs/" + songId,
						modsPath + "/" + modId + "/data/" + songId,
						modsPath + "/" + modId + "/assets/songs/" + songId,
						modsPath + "/" + modId + "/assets/data/songs/" + songId,
						modsPath + "/" + modId + "/assets/data/" + songId,
						modsPath + "/" + modId + "/assets/" + songId
					];

					for (p in tryPaths)
					{
						if (hasAudioFile(p)) return p;
					}
				}
			}
		}
		#end
		#end

		return null;
	}

	static function hasAudioFile(folder:String):Bool
	{
		if (folder == null || folder.length == 0) return false;
		var names = ["Inst.ogg", "Inst.mp3", "Inst.wav", "Voices.ogg", "Voices.mp3", "Voices.wav"];
		for (name in names)
		{
			if (chartExists(folder + "/" + name)) return true;
		}
		return false;
	}

	static function formatSongId(songName:String):String return songName.toLowerCase().split(" ").join("-");
	static function emptyChart(songName:String):Dynamic return {song: songName, speed: 2.8, notes: [], events: []};
}
