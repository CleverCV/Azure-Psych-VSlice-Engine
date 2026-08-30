package states;

import PlayState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import utils.Alphabet; // Importamos tu clase Alphabet

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if mobile
import flixel.ui.FlxVirtualPad;
#end

class FreePlayState extends FlxState
{
    var _bg:FlxSprite;

	static inline var SONG_DATA_PATH:String = "assets/shared/data";
	static inline var SONG_LIST_PATH:String = SONG_DATA_PATH + "/freeplaySongList.txt";
	var songs:Array<String> = [];
	var songChartTypes:Map<String, String> = new Map<String, String>();

	var grpSongs:FlxTypedGroup<Alphabet>;
    var curSelected:Int = 0;

	#if mobile
	var _virtualPad:FlxVirtualPad;
	#end

    override public function create():Void
    {
        super.create();

        songs = loadSongList();

        _bg = new FlxSprite(0, 0, "assets/shared/images/backgrounds/bg_yellow.png");
        add(_bg);

		var titleText = new Alphabet(0, 20, "FREEPLAY MENU", true, 1.0);
		titleText.screenCenter(X);
        add(titleText);

		grpSongs = new FlxTypedGroup<Alphabet>();
        add(grpSongs);

		for (i in 0...songs.length)
		{
			var alphb:Alphabet = new Alphabet(120, 160 + (i * 135), songs[i], true, 0.9);
			alphb.ID = i; 
			grpSongs.add(alphb);
        }

        if (songs.length > 0)
            changeSelection(0);
		else
		{
			var noSongsText = new Alphabet(0, 180, "NO SONGS FOUND", true, 0.8);
			noSongsText.screenCenter(X);
			add(noSongsText);
		}

		#if mobile
		_virtualPad = new FlxVirtualPad(flixel.ui.FlxVirtualPad.FlxDPadMode.UP_DOWN, flixel.ui.FlxVirtualPad.FlxActionMode.A_B);
		_virtualPad.alpha = 0.75;

		var scaleFactor:Float = 1.5; 
		if (_virtualPad.dPad != null)
		{
			_virtualPad.dPad.forEach(function(btn:flixel.ui.FlxButton)
			{
				btn.scale.set(scaleFactor, scaleFactor);
				btn.updateHitbox(); 
			});
		}

		if (_virtualPad.actions != null)
		{
			_virtualPad.actions.forEach(function(btn:flixel.ui.FlxButton)
			{
				btn.scale.set(scaleFactor, scaleFactor);
				btn.updateHitbox();
			});
		}

		_virtualPad.dPad.x += 15;
		_virtualPad.dPad.y -= 35;

		_virtualPad.actions.x -= 55;
		_virtualPad.actions.y -= 35;

		_virtualPad.cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		add(_virtualPad);
		#end
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

		var upPressed:Bool = false;
		var downPressed:Bool = false;
		var backPressed:Bool = false;
		var acceptPressed:Bool = false;

		#if mobile
		upPressed = FlxG.keys.anyJustPressed([UP, W]) || _virtualPad.getButton(UP).justPressed;
		downPressed = FlxG.keys.anyJustPressed([DOWN, S]) || _virtualPad.getButton(DOWN).justPressed;
		backPressed = FlxG.keys.anyJustPressed([ESCAPE, BACKSPACE]) || _virtualPad.getButton(B).justPressed;
		acceptPressed = FlxG.keys.anyJustPressed([ENTER, SPACE]) || _virtualPad.getButton(A).justPressed;
		#else
		upPressed = FlxG.keys.anyJustPressed([UP, W]);
		downPressed = FlxG.keys.anyJustPressed([DOWN, S]);
		backPressed = FlxG.keys.anyJustPressed([ESCAPE, BACKSPACE]);
		acceptPressed = FlxG.keys.anyJustPressed([ENTER, SPACE]);
		#end

		if (upPressed)
        {
            changeSelection(-1);
        }
		if (downPressed)
        {
            changeSelection(1);
        }

		if (backPressed)
        {
			#if mobile
			if (_virtualPad != null)
				_virtualPad = flixel.util.FlxDestroyUtil.destroy(_virtualPad);
			#end
            FlxG.switchState(new MainMenu());
        }

		if (acceptPressed && songs.length > 0)
        {
			#if mobile
			if (_virtualPad != null)
				_virtualPad = flixel.util.FlxDestroyUtil.destroy(_virtualPad);
			#end

            var selectedSongName = songs[curSelected];
            trace("Cargando chart para: " + selectedSongName);

			PlayState.chartType = songChartTypes.exists(selectedSongName) ? songChartTypes.get(selectedSongName) : "psych";
			PlayState.currentSong = selectedSongName; 
            
            FlxG.switchState(new PlayState());
        }
    }

    function changeSelection(change:Int = 0):Void
    {
		if (songs.length == 0)
			return;

        curSelected += change;

        if (curSelected < 0)
            curSelected = songs.length - 1;
        if (curSelected >= songs.length)
            curSelected = 0;

		grpSongs.forEach(function(alphb:Alphabet)
		{
			if (alphb.ID == curSelected)
			{
				alphb.color = 0xFFFFFF00;
				alphb.alpha = 1.0;
				alphb.x = 150; 
            }
            else
            {
				alphb.color = 0xFFFFFFFF;
				alphb.alpha = 0.6;
				alphb.x = 120; 
            }
        });
    }

    /**
     * Finds Psych charts stored as `assets/shared/data/<song>/<song>.json`.
     * The generated text file is useful to inspect or reuse the same Freeplay
     * list without editing this state by hand.
     */
    function loadSongList():Array<String>
    {
		#if sys
		var detectedSongs:Array<String> = [];

		#if android
		// En Android, solo buscar en el almacenamiento de la app
		var appStoragePath = lime.system.System.applicationStorageDirectory;
		if (appStoragePath != null && appStoragePath.length > 0)
		{
			var androidDataPath = appStoragePath + "data/shared/data";
			var androidVSlicePath = appStoragePath + "data/songs";
			var androidModsPath = appStoragePath + "mods";
			
			findVSliceSongs(detectedSongs, androidDataPath, "psych");
			findVSliceSongs(detectedSongs, androidVSlicePath, "vslice");
			
			if (FileSystem.exists(androidModsPath) && FileSystem.isDirectory(androidModsPath))
			{
				for (modId in FileSystem.readDirectory(androidModsPath))
				{
					findVSliceSongsInMod(androidModsPath + "/" + modId, detectedSongs);
				}
			}
		}
		#else
		// Desktop: buscar en assets
		if (FileSystem.exists(SONG_DATA_PATH) && FileSystem.isDirectory(SONG_DATA_PATH))
		{
			for (entry in FileSystem.readDirectory(SONG_DATA_PATH))
			{
				var songDirectory = SONG_DATA_PATH + "/" + entry;
				var chartPath = songDirectory + "/" + entry + ".json";

				if (FileSystem.isDirectory(songDirectory) && FileSystem.exists(chartPath))
					addDetectedSong(detectedSongs, entry, "psych");
			}
		}

		// Official V-Slice location in the base assets folder.
		var vsliceSongsPath = "assets/data/songs";
		findVSliceSongs(detectedSongs, vsliceSongsPath, "vslice");

		// Mod layouts: mods/<mod-id>/data/songs/<song-id>/<song-id>-chart.json
		var modsPaths:Array<String> = ["mods"];
		
		for (modsPath in modsPaths)
		{
			if (FileSystem.exists(modsPath) && FileSystem.isDirectory(modsPath))
			{
				for (modId in FileSystem.readDirectory(modsPath))
				{
					findVSliceSongsInMod(modsPath + "/" + modId, detectedSongs);
				}
			}
		}
		#end

		detectedSongs.sort(function(a:String, b:String):Int
		{
			return Reflect.compare(a.toLowerCase(), b.toLowerCase());
		});

		try
		{
			File.saveContent(SONG_LIST_PATH, detectedSongs.join("\n") + (detectedSongs.length > 0 ? "\n" : ""));
		}
		catch (error:Dynamic)
		{
			trace("Freeplay: no se pudo escribir " + SONG_LIST_PATH + ": " + error);
		}

		return detectedSongs;
		#else
		return [];
		#end
    }

	#if sys
	function findVSliceSongs(detectedSongs:Array<String>, songsPath:String, chartType:String):Void
	{
		if (!FileSystem.exists(songsPath) || !FileSystem.isDirectory(songsPath)) return;

		for (songId in FileSystem.readDirectory(songsPath))
		{
			var songDirectory = songsPath + "/" + songId;
			var chartPath = songDirectory + "/" + songId + "-chart.json";
			if (FileSystem.isDirectory(songDirectory) && FileSystem.exists(chartPath))
				addDetectedSong(detectedSongs, songId, chartType);
		}
	}

	function findVSliceSongsInMod(modRoot:String, detectedSongs:Array<String>):Void
	{
		var candidateRoots = [
			modRoot + "/data/songs",
			modRoot + "/songs",
			modRoot + "/assets/data/songs",
			modRoot + "/assets/songs"
		];

		for (songsPath in candidateRoots)
		{
			findVSliceSongs(detectedSongs, songsPath, "vslice");
		}
	}

	function addDetectedSong(detectedSongs:Array<String>, songId:String, chartType:String):Void
	{
		if (detectedSongs.indexOf(songId) == -1)
			detectedSongs.push(songId);
		songChartTypes.set(songId, chartType);
	}
	#end
}
