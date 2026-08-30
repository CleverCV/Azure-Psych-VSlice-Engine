package states;

import Note;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.media.Sound;
import substates.Pause;
#if mobile
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxButton;
#end

class VSlicePlayState extends FlxState
{
	var chartData:Dynamic;

	var playerStrums:FlxTypedGroup<FlxSprite>;
	var enemyStrums:FlxTypedGroup<FlxSprite>;
	var grpNotes:FlxTypedGroup<Note>;

	var songTime:Float = 0;
	var scrollSpeed:Float = 2.8;

	var strumsData:Array<String> = ['arrowLEFT', 'arrowDOWN', 'arrowUP', 'arrowRIGHT'];
	var pressAnims:Array<String> = ['left press', 'down press', 'up press', 'right press'];

	var psychparsr:FlxText;
	var vocals:FlxSound;

	#if mobile
	var hitboxGroup:FlxSpriteGroup;
	var mobileInputState:Array<Bool> = [false, false, false, false];
	var mobileLastInputState:Array<Bool> = [false, false, false, false];
	var pauseButton:FlxButton;
	#end

	public function new(parsedData:Dynamic)
	{
		super();
		this.chartData = parsedData;
		if (chartData != null && chartData.speed != null)
			scrollSpeed = chartData.speed;
	}

	override public function create():Void
	{
		super.create();

		psychparsr = new FlxText(10, FlxG.height - 54, 0, "VSlice Parser Indev 1.7", 16);
		psychparsr.font = "assets/fonts/vcr.ttf";
		psychparsr.color = FlxColor.WHITE;
		psychparsr.setFormat(psychparsr.font, 18, FlxColor.WHITE, LEFT);
		psychparsr.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1.5);
		psychparsr.antialiasing = true;
		add(psychparsr);

		playerStrums = new FlxTypedGroup<FlxSprite>();
		enemyStrums = new FlxTypedGroup<FlxSprite>();
		grpNotes = new FlxTypedGroup<Note>();

		for (i in 0...4)
		{
			var enemyArrow = new FlxSprite(100 + (i * 110), 50);
			enemyArrow.frames = FlxAtlasFrames.fromSparrow("assets/shared/images/notes/NOTE_assets.png", "assets/shared/images/notes/NOTE_assets.xml");
			enemyArrow.animation.addByPrefix('static', strumsData[i] + '0');
			enemyArrow.animation.play('static');
			enemyArrow.setGraphicSize(Std.int(enemyArrow.width * 0.7));
			enemyArrow.updateHitbox();
			enemyArrow.antialiasing = true;
			enemyStrums.add(enemyArrow);

			var playerArrow = new FlxSprite(700 + (i * 110), 50);
			playerArrow.frames = FlxAtlasFrames.fromSparrow("assets/shared/images/notes/NOTE_assets.png", "assets/shared/images/notes/NOTE_assets.xml");
			playerArrow.animation.addByPrefix('static', strumsData[i] + '0');
			playerArrow.animation.addByPrefix('press', pressAnims[i]);
			playerArrow.animation.play('static');
			playerArrow.setGraphicSize(Std.int(playerArrow.width * 0.7));
			playerArrow.updateHitbox();
			playerArrow.antialiasing = true;
			playerStrums.add(playerArrow);
		}

		add(enemyStrums);
		add(playerStrums);
		add(grpNotes);

		loadNotesFromChart();

		var nombreCancion:String = StringTools.replace(PlayState.currentSong.toLowerCase(), " ", "-");
		var rutaInst:String = resolveAudioPath(nombreCancion, "Inst");
		var rutaVoces:String = resolveAudioPath(nombreCancion, "Voices");
		trace("Ruta de la Inst: " + rutaInst);
		trace("Ruta de las Voces: " + rutaVoces);

		// Try to play the instrumentation music. If the file exists on disk (mods or assets)
		// load it directly from the file system instead of using an asset ID.
		var musicLoaded:Bool = false;
		#if sys
		if (sys.FileSystem.exists(rutaInst))
		{
			try
			{
				var music:FlxSound = new FlxSound();
				music.loadEmbedded(Sound.fromFile(rutaInst));
				music.volume = 1.0;
				FlxG.sound.list.add(music);
				FlxG.sound.music = music;
				musicLoaded = true;
			}
			catch (error:Dynamic)
			{
				trace("VSlicePlayState: no se pudo cargar la música desde disco: " + rutaInst + " -> " + error);
			}
		}
		#end

		if (!musicLoaded)
		{
			FlxG.sound.playMusic(rutaInst, 1.0, false);
		}

		// Vocals (separate sound) - prefer disk load when available
		vocals = new FlxSound();
		#if sys
		if (sys.FileSystem.exists(rutaVoces))
		{
			try
			{
				vocals.loadEmbedded(Sound.fromFile(rutaVoces));
				vocals.volume = 1.0;
				FlxG.sound.list.add(vocals);
			}
			catch (error:Dynamic)
			{
				trace("VSlicePlayState: no se pudo cargar las voces desde disco: " + rutaVoces + " -> " + error);
			}
		}
		#end

		// Ensure music time starts at 0 and vocals sync if present
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.time = 0;
			FlxG.sound.music.pause();
		}
		@:privateAccess
		if (vocals != null && vocals._sound != null)
		{
			vocals.time = 0;
			vocals.play();
		}

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.play();
		}
		#if mobile
		createHitboxes();
		#end
	}

	#if mobile
	function createHitboxes():Void
	{
		hitboxGroup = new FlxSpriteGroup();
		hitboxGroup.scrollFactor.set();

		var widthButton:Int = Std.int(FlxG.width / 4);
		var heightButton:Int = FlxG.height;

		for (i in 0...4)
		{
			var hitboxBtn = new FlxButton(i * widthButton, 0);
			hitboxBtn.makeGraphic(widthButton, heightButton, 0x00FFFFFF);

			hitboxBtn.onDown.callback = function()
			{
				mobileInputState[i] = true;
			};
			hitboxBtn.onUp.callback = function()
			{
				mobileInputState[i] = false;
			};
			hitboxBtn.onOut.callback = function()
			{
				mobileInputState[i] = false;
			};

			hitboxGroup.add(hitboxBtn);
		}

		add(hitboxGroup);

		pauseButton = new FlxButton(FlxG.width - 100, 15);
		pauseButton.makeGraphic(80, 80, 0xAA000000);

		var pauseText = new FlxText(0, 15, 80, "||", 32);
		pauseText.alignment = CENTER;
		pauseText.color = FlxColor.WHITE;
		pauseButton.label = pauseText;

		pauseButton.onDown.callback = function()
		{
			openPauseMenu();
		};
		pauseButton.scrollFactor.set();
		add(pauseButton);
	}
	#end

	override public function update(elapsed:Float):Void
	{
		if (subState != null)
		{
			super.update(elapsed);
			return;
		}

		super.update(elapsed);

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			songTime = FlxG.sound.music.time;
		}
		else
		{
			songTime += elapsed * 1000;
		}

		grpNotes.forEachAlive(function(daNote:Note)
		{
			var targetStrumX:Float = 0;
			if (daNote.mustHit)
			{
				targetStrumX = 700 + (daNote.noteData * 110);
			}
			else
			{
				targetStrumX = 100 + (daNote.noteData * 110);
			}

			if (daNote.isSustainNote && daNote.parentNote != null)
			{
				daNote.x = targetStrumX + (daNote.parentNote.width / 2) - (daNote.width / 2);
			}
			else
			{
				daNote.x = targetStrumX;
			}

			if (daNote.isSustainNote)
			{
				var parentHeight:Float = 110 * 0.7;
				var parentPressed:Bool = false;

				if (daNote.parentNote != null)
				{
					parentHeight = daNote.parentNote.height;
					parentPressed = daNote.parentNote.wasPressed;
				}

				daNote.y = 50 + ((daNote.strumTime - songTime) * (scrollSpeed * 0.45)) + (parentHeight / 2) - (daNote.height * 0.5);

				if (daNote.animation.curAnim != null && !StringTools.endsWith(daNote.animation.curAnim.name, 'end'))
				{
					daNote.scale.y = (scrollSpeed * 0.45) * (130 / 120);
					daNote.updateHitbox();
				}

				if (parentPressed)
				{
					daNote.alpha = 0.6;
				}
			}
			else
			{
				daNote.y = 50 + ((daNote.strumTime - songTime) * (scrollSpeed * 0.45));
			}

			if (!daNote.mustHit)
			{
				if (songTime >= daNote.strumTime)
				{
					if (!daNote.isSustainNote)
					{
						var enemyStrum = enemyStrums.members[daNote.noteData];
						if (enemyStrum != null)
						{
							enemyStrum.animation.play('static', true);
						}

						if (daNote.sustainLength > 0)
						{
							daNote.wasPressed = true;
							daNote.visible = false;
						}
						else
						{
							daNote.kill();
							grpNotes.remove(daNote, true);
						}
					}
					else
					{
						if (daNote.parentNote != null && daNote.parentNote.wasPressed)
						{
							daNote.kill();
							grpNotes.remove(daNote, true);
						}
					}
				}
			}

			if (daNote.mustHit && songTime > daNote.strumTime + 160 && !daNote.wasPressed)
			{
				daNote.kill();
				grpNotes.remove(daNote, true);
			}

			if (daNote.y < -150)
			{
				daNote.kill();
				grpNotes.remove(daNote, true);
			}
		});

		if (FlxG.keys.anyJustPressed([ENTER, P]))
		{
			openPauseMenu();
		}

		handleInputs();
	}

	function handleInputs():Void
	{
		var keyboardPressed = [
			FlxG.keys.anyPressed([LEFT, A]),
			FlxG.keys.anyPressed([DOWN, S]),
			FlxG.keys.anyPressed([UP, W]),
			FlxG.keys.anyPressed([RIGHT, D])
		];
		var keyboardJustPressed = [
			FlxG.keys.anyJustPressed([LEFT, A]),
			FlxG.keys.anyJustPressed([DOWN, S]),
			FlxG.keys.anyJustPressed([UP, W]),
			FlxG.keys.anyJustPressed([RIGHT, D])
		];

		var keysPressed = [false, false, false, false];
		var keysJustPressed = [false, false, false, false];

		for (i in 0...4)
		{
			#if mobile
			var mobilePressed = mobileInputState[i];
			var mobileJustPressed = mobileInputState[i] && !mobileLastInputState[i];

			keysPressed[i] = keyboardPressed[i] || mobilePressed;
			keysJustPressed[i] = keyboardJustPressed[i] || mobileJustPressed;
			#else
			keysPressed[i] = keyboardPressed[i];
			keysJustPressed[i] = keyboardJustPressed[i];
			#end
		}

		for (i in 0...4)
		{
			var strum = playerStrums.members[i];

			if (keysJustPressed[i])
			{
				strum.animation.play('press', true);

				grpNotes.forEachAlive(function(daNote:Note)
				{
					if (daNote.mustHit && daNote.noteData == i && !daNote.isSustainNote)
					{
						if (Math.abs(daNote.strumTime - songTime) < 150)
						{
							if (daNote.sustainLength > 0)
							{
								daNote.wasPressed = true;
								daNote.visible = false;
							}
							else
							{
								daNote.kill();
								grpNotes.remove(daNote, true);
							}
						}
					}
				});
			}

			if (keysPressed[i])
			{
				grpNotes.forEachAlive(function(daNote:Note)
				{
					if (daNote.mustHit && daNote.noteData == i && daNote.isSustainNote)
					{
						if (daNote.parentNote != null && daNote.parentNote.wasPressed)
						{
							if (songTime >= daNote.strumTime)
							{
								daNote.kill();
								grpNotes.remove(daNote, true);
							}
						}
					}
				});
			}

			if (!keysPressed[i] && strum.animation.curAnim != null && strum.animation.curAnim.name == 'press')
			{
				strum.animation.play('static');
			}
		}
		#if mobile
		for (i in 0...4)
		{
			mobileLastInputState[i] = mobileInputState[i];
		}
		#end
	}

	function openPauseMenu():Void
	{
		if (FlxG.sound.music != null)
			FlxG.sound.music.pause();
		if (vocals != null)
			vocals.pause();

		openSubState(new Pause());
	}

	override public function closeSubState():Void
	{
		super.closeSubState();

		if (FlxG.keys != null)
		{
			FlxG.keys.reset();
		}

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.resume();
		}

		if (vocals != null)
		{
			vocals.resume();
			vocals.time = FlxG.sound.music.time;
		}
	}

	function loadNotesFromChart():Void
	{
		if (chartData == null || chartData.notes == null) return;

		var notes:Array<Dynamic> = chartData.notes;
		for (noteData in notes)
		{
			var strumTime:Float = noteData.strumTime;
			var lane:Int = Std.int(noteData.noteData);
			var mustHit:Bool = noteData.mustHit;
			var sustainLength:Float = noteData.sustainLength != null ? noteData.sustainLength : 0;

			var parentNote = new Note(strumTime, lane, mustHit);
			parentNote.sustainLength = sustainLength;
			grpNotes.add(parentNote);

			if (sustainLength > 0)
			{
				var segmentLength:Float = 45;
				var segments:Int = Std.int(Math.ceil(sustainLength / segmentLength));
				for (segment in 1...(segments + 1))
				{
					var sustain = new Note(strumTime + (segment * segmentLength), lane, mustHit, true, segment == segments);
					sustain.parentNote = parentNote;
					grpNotes.add(sustain);
				}
			}
		}

		grpNotes.sort(function(order:Int, first:Note, second:Note):Int
		{
			if (first.strumTime < second.strumTime)
				return -1 * order;
			else if (first.strumTime > second.strumTime)
				return 1 * order;
			return 0;
		});
	}

	override public function destroy():Void
	{
		if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}
		super.destroy();
	}

	private static function resolveAudioPath(songId:String, baseName:String):String
	{
		var candidates:Array<String> = [];

		#if android
		// En Android, solo buscar en almacenamiento de la app
		var appStoragePath = lime.system.System.applicationStorageDirectory;
		if (appStoragePath != null && appStoragePath.length > 0)
		{
			if (PlayState.currentSong != null)
			{
				var currentId:String = StringTools.replace(PlayState.currentSong.toLowerCase(), " ", "-");
				if (currentId != null && currentId.length > 0)
				{
					candidates.push(appStoragePath + "data/songs/" + currentId + "/" + baseName + ".ogg");
					candidates.push(appStoragePath + "data/songs/" + currentId + "/" + baseName + ".mp3");
					candidates.push(appStoragePath + "data/songs/" + currentId + "/" + baseName + ".wav");
				}
			}
			if (songId != null && songId.length > 0)
			{
				candidates.push(appStoragePath + "data/songs/" + songId + "/" + baseName + ".ogg");
				candidates.push(appStoragePath + "data/songs/" + songId + "/" + baseName + ".mp3");
				candidates.push(appStoragePath + "data/songs/" + songId + "/" + baseName + ".wav");
				candidates.push(appStoragePath + "data/" + songId + "/" + baseName + ".ogg");
				candidates.push(appStoragePath + "data/shared/songs/" + songId + "/" + baseName + ".ogg");
			}

			// Buscar en mods de Android
			var modsPath = appStoragePath + "mods";
			if (sys.FileSystem.exists(modsPath) && sys.FileSystem.isDirectory(modsPath))
			{
				for (modId in sys.FileSystem.readDirectory(modsPath))
				{
					var modRoots = [
						modsPath + "/" + modId + "/songs/" + songId,
						modsPath + "/" + modId + "/data/songs/" + songId,
						modsPath + "/" + modId + "/assets/songs/" + songId,
						modsPath + "/" + modId + "/assets/data/songs/" + songId,
						modsPath + "/" + modId + "/data/" + songId,
						modsPath + "/" + modId + "/assets/data/" + songId
					];
					for (folder in modRoots)
					{
						for (ext in [".ogg", ".mp3", ".wav"])
							candidates.push(folder + "/" + baseName + ext);
					}
				}
			}
		}
		#else
		if (PlayState.currentSong != null)
		{
			var currentId:String = StringTools.replace(PlayState.currentSong.toLowerCase(), " ", "-");
			if (currentId != null && currentId.length > 0)
			{
				candidates.push("assets/data/songs/" + currentId + "/" + baseName + ".ogg");
				candidates.push("assets/data/songs/" + currentId + "/" + baseName + ".mp3");
				candidates.push("assets/songs/" + currentId + "/" + baseName + ".ogg");
				candidates.push("assets/shared/songs/" + currentId + "/" + baseName + ".ogg");
				candidates.push("assets/shared/data/" + currentId + "/" + baseName + ".ogg");
			}
		}
		if (songId != null && songId.length > 0)
		{
			candidates.push("assets/data/songs/" + songId + "/" + baseName + ".ogg");
			candidates.push("assets/songs/" + songId + "/" + baseName + ".ogg");
			candidates.push("assets/shared/songs/" + songId + "/" + baseName + ".ogg");
			candidates.push("assets/data/" + songId + "/" + baseName + ".ogg");
			candidates.push("assets/shared/data/" + songId + "/" + baseName + ".ogg");
		}

		#if sys
		var modsPaths:Array<String> = ["mods"];
		
		for (modsPath in modsPaths)
		{
			if (sys.FileSystem.exists(modsPath) && sys.FileSystem.isDirectory(modsPath))
			{
				for (modId in sys.FileSystem.readDirectory(modsPath))
				{
					var modRoots = [
						modsPath + "/" + modId + "/songs/" + songId,
						modsPath + "/" + modId + "/data/songs/" + songId,
						modsPath + "/" + modId + "/assets/songs/" + songId,
						modsPath + "/" + modId + "/assets/data/songs/" + songId,
						modsPath + "/" + modId + "/data/" + songId,
						modsPath + "/" + modId + "/assets/data/" + songId
					];
					for (folder in modRoots)
					{
						for (ext in [".ogg", ".mp3", ".wav"])
							candidates.push(folder + "/" + baseName + ext);
					}
				}
			}
		}
		#end
		#end

		for (candidate in candidates)
		{
			#if sys
			if (sys.FileSystem.exists(candidate)) return candidate;
			#end
			if (openfl.utils.Assets.exists(candidate)) return candidate;
		}

		return "assets/shared/songs/" + songId + "/" + baseName + ".ogg";
	}
}
