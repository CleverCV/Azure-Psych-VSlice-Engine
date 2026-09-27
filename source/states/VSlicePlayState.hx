package states;

import Note;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import objects.Character;
import objects.Enemy;
import objects.Player;
import openfl.display.BitmapData;
import openfl.media.Sound;
import substates.Pause;
import events.EngineEvent;
import events.EventDispatcher;
import events.EventParser;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
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
	var player:Null<Player>;
	var enemy:Null<Enemy>;
	var cameraTarget:FlxObject;
	var camGame:FlxCamera;
	var camHUD:FlxCamera;
	var noteFrames:FlxAtlasFrames;
	var chartEvents:Array<Dynamic> = [];
	var nextEvent:Int = 0;

	

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
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		psychparsr = new FlxText(10, FlxG.height - 54, 0, "VSlice Parser Indev 1.7", 16);
		psychparsr.font = "assets/fonts/vcr.ttf";
		psychparsr.color = FlxColor.WHITE;
		psychparsr.setFormat(psychparsr.font, 18, FlxColor.WHITE, LEFT);
		psychparsr.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1.5);
		psychparsr.antialiasing = true;
		psychparsr.cameras = [camHUD];
		add(psychparsr);
		loadStageProps();

		// scriptLoader = new HScriptLoader(this);

/*
if (
	chartData != null &&
	chartData.assetRoot != null
)
{
	scriptLoader.loadMod(
		Std.string(
			chartData.assetRoot
		)
	);
}
*/
		// El parser coloca aquí los personajes de playData.characters del metadata V-Slice.
		if (chartData != null && chartData.characters != null && chartData.characters.player != null)
		{
			var position = stagePosition("bf");

player = new Player(
	position[0],
	position[1],
	Std.string(chartData.characters.player)
);

player.updateHitbox();

// V-Slice usa la posición del stage como punto de apoyo inferior.
player.y -= player.height;

add(player);
		}
		if (chartData != null && chartData.characters != null && chartData.characters.opponent != null)
		{
			var position = stagePosition("dad");

enemy = new Enemy(
	position[0],
	position[1],
	Std.string(chartData.characters.opponent)
);

enemy.updateHitbox();

// Ajuste vertical del punto de apoyo del personaje.
enemy.y -= enemy.height;

add(enemy);
		}
		cameraTarget = new FlxObject();
		if (chartData != null && chartData.stageData != null && chartData.stageData.cameraZoom != null)
			camGame.zoom = Std.parseFloat(Std.string(chartData.stageData.cameraZoom));
		camGame.follow(cameraTarget, LOCKON, 0.04);
		if (enemy != null) focusCamera(enemy, "dad") else if (player != null) focusCamera(player, "bf");

		playerStrums = new FlxTypedGroup<FlxSprite>();
		enemyStrums = new FlxTypedGroup<FlxSprite>();
		grpNotes = new FlxTypedGroup<Note>();
		playerStrums.cameras = [camHUD];
		enemyStrums.cameras = [camHUD];
		grpNotes.cameras = [camHUD];
		noteFrames = loadNoteFrames();
		if (chartData != null && chartData.events != null)
		{
			chartEvents = cast chartData.events;
			chartEvents.sort(function(a:Dynamic, b:Dynamic):Int return Reflect.compare(eventTime(a), eventTime(b)));
		}

		for (i in 0...4)
		{
			var enemyArrow = new FlxSprite(100 + (i * 110), 50);
			enemyArrow.frames = noteFrames;
			enemyArrow.animation.addByPrefix('static', strumsData[i] + '0');
			enemyArrow.animation.play('static');
			enemyArrow.setGraphicSize(Std.int(enemyArrow.width * 0.7));
			enemyArrow.updateHitbox();
			enemyArrow.antialiasing = true;
			enemyStrums.add(enemyArrow);

			var playerArrow = new FlxSprite(700 + (i * 110), 50);
			playerArrow.frames = noteFrames;
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
		var rutaVoces:String = resolveVoiceAudioPath(nombreCancion);
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
		hitboxGroup.cameras = [camHUD];

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
		pauseButton.cameras = [camHUD];
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
		processChartEvents();

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
						if (enemy != null) { enemy.playAnim(['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'][daNote.noteData], true); focusCamera(enemy, "dad"); }

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
							if (player != null) { player.playAnim(['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'][i], true); focusCamera(player, "bf"); }
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

		openSubState(new Pause(camHUD));
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

			var parentNote = new Note(strumTime, lane, mustHit, false, false, noteFrames);
			parentNote.sustainLength = sustainLength;
			grpNotes.add(parentNote);

			if (sustainLength > 0)
			{
				var segmentLength:Float = 45;
				var segments:Int = Std.int(Math.ceil(sustainLength / segmentLength));
				for (segment in 1...(segments + 1))
				{
					var sustain = new Note(strumTime + (segment * segmentLength), lane, mustHit, true, segment == segments, noteFrames);
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

	function loadNoteFrames():FlxAtlasFrames
	{
		var style:String = chartData != null && chartData.noteStyle != null ? Std.string(chartData.noteStyle) : "funkin";
		var root:String = chartData != null && chartData.assetRoot != null ? Std.string(chartData.assetRoot) : "assets";
		var names = style == "funkin" ? ["NOTE_assets"] : [style, style + "_assets", "NOTE_assets"];
		var candidates:Array<String> = [];
		for (name in names)
		{
			candidates.push(root + "/images/notes/" + name);
			candidates.push(root + "/shared/images/notes/" + name);
			candidates.push("assets/images/notes/" + name);
			candidates.push("assets/shared/images/notes/" + name);
		}
		for (base in candidates)
		{
			var png = base + ".png";
			var xml = base + ".xml";
			#if sys
			if (FileSystem.exists(png) && FileSystem.exists(xml))
				return FlxAtlasFrames.fromSparrow(BitmapData.fromFile(png), Xml.parse(File.getContent(xml)));
			#end
			if (openfl.utils.Assets.exists(png) && openfl.utils.Assets.exists(xml))
				return FlxAtlasFrames.fromSparrow(png, xml);
		}
		return FlxAtlasFrames.fromSparrow("assets/shared/images/notes/NOTE_assets.png", "assets/shared/images/notes/NOTE_assets.xml");
	}

	function stagePosition(role:String):Array<Float>
	{
		var stage = chartData != null ? chartData.stageData : null;
		if (stage != null && stage.characters != null && Reflect.hasField(stage.characters, role))
		{
			var definition:Dynamic = Reflect.field(stage.characters, role);
			if (definition.position != null && Std.isOfType(definition.position, Array))
			{
				var position:Array<Dynamic> = cast definition.position;
				if (position.length >= 2) return [Std.parseFloat(Std.string(position[0])), Std.parseFloat(Std.string(position[1]))];
			}
		}
		return [0, 0];
	}

	function loadStageProps():Void
	{
		var stage:Dynamic = chartData != null ? chartData.stageData : null;
		if (stage == null || stage.props == null || !Std.isOfType(stage.props, Array)) return;
		var props:Array<Dynamic> = cast stage.props;
		props.sort(function(a:Dynamic, b:Dynamic):Int return Reflect.compare(fieldNumber(a, "zIndex", 0), fieldNumber(b, "zIndex", 0)));
		for (prop in props)
		{
			var assetPath = prop != null && prop.assetPath != null ? Std.string(prop.assetPath) : null;
			var imagePath = assetPath != null ? resolveStageImage(assetPath) : null;
			if (imagePath == null)
			{
				trace("VSlicePlayState: no se encontró background " + assetPath);
				continue;
			}
			var position:Array<Float> = arrayPosition(prop.position);
			var background = new FlxSprite(position[0], position[1]);
			#if sys
			background.loadGraphic(BitmapData.fromFile(imagePath));
			#else
			background.loadGraphic(imagePath);
			#end
			var scale:Array<Float> = arrayPosition(prop.scale, 1, 1);
			background.scale.set(scale[0], scale[1]);
			background.updateHitbox();
			add(background);
		}
	}

	function resolveStageImage(assetPath:String):Null<String>
	{
		var root:String = chartData != null && chartData.assetRoot != null ? Std.string(chartData.assetRoot) : "assets";
		var candidates = [root + "/images/" + assetPath + ".png", root + "/shared/images/" + assetPath + ".png", "assets/images/" + assetPath + ".png", "assets/shared/images/" + assetPath + ".png"];
		for (path in candidates)
		{
			#if sys
			if (FileSystem.exists(path)) return path;
			#end
			if (openfl.utils.Assets.exists(path)) return path;
		}
		return null;
	}

	function processChartEvents():Void
	{
		while (nextEvent < chartEvents.length && eventTime(chartEvents[nextEvent]) <= songTime)
		{
			runChartEvent(chartEvents[nextEvent]);
			nextEvent++;
		}
	}
function runChartEvent(
	rawEvent:Dynamic
):Void
{
	var events:Array<EngineEvent> =
		EventParser.parse(rawEvent);

	for (event in events)
	{
		if (
			EventDispatcher.dispatch(
				event,
				this
			)
		)
		{
			continue;
		}

	
		
	}
}

	function eventTime(
	event:Dynamic
):Float
{
	if (event == null)
		return 0;

	if (
		Reflect.hasField(
			event,
			"t"
		)
	)
	{
		return Std.parseFloat(
			Std.string(
				Reflect.field(
					event,
					"t"
				)
			)
		);
	}

	if (
		Reflect.hasField(
			event,
			"time"
		)
	)
	{
		return Std.parseFloat(
			Std.string(
				Reflect.field(
					event,
					"time"
				)
			)
		);
	}

	return 0;
}
	function arrayPosition(value:Dynamic, defaultX:Float = 0, defaultY:Float = 0):Array<Float>
	{
		if (Std.isOfType(value, Array) && (cast value:Array<Dynamic>).length >= 2)
		{
			var values:Array<Dynamic> = cast value;
			return [Std.parseFloat(Std.string(values[0])), Std.parseFloat(Std.string(values[1]))];
		}
		return [defaultX, defaultY];
	}
	function fieldNumber(value:Dynamic, name:String, fallback:Float):Float return value != null && Reflect.hasField(value, name) ? Std.parseFloat(Std.string(Reflect.field(value, name))) : fallback;

	function focusCamera(character:Character, role:String):Void
	{
		if (cameraTarget == null || character == null)
			return;

		var cameraX:Float = character.x + (character.width * 0.5);

		var cameraY:Float = character.y + (character.height * 0.5);

		/*
		 * Primero usamos el camera offset definido por el
		 * propio personaje.
		 */
		var offsetX:Float = 0;
		var offsetY:Float = 0;

		if (character.cameraOffset != null && character.cameraOffset.length >= 2)
		{
			offsetX = character.cameraOffset[0];
			offsetY = character.cameraOffset[1];
		}

		/*
		 * Después comprobamos los offsets definidos por el
		 * stage V-Slice.
		 *
		 * Esto permite que el stage tenga la última palabra
		 * sobre dónde mira la cámara.
		 */
		var stage:Dynamic = chartData != null ? chartData.stageData : null;

		if (stage != null && stage.characters != null && Reflect.hasField(stage.characters, role))
		{
			var definition:Dynamic = Reflect.field(stage.characters, role);

			if (definition.cameraOffsets != null && Std.isOfType(definition.cameraOffsets, Array))
			{
				var values:Array<Dynamic> = cast definition.cameraOffsets;

				if (values.length >= 2)
			{
					offsetX = Std.parseFloat(Std.string(values[0]));

					offsetY = Std.parseFloat(Std.string(values[1]));
			}
		}
		}

		cameraTarget.setPosition(cameraX + offsetX, cameraY + offsetY);
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
	

	private function resolveVoiceAudioPath(songId:String):String
	{
		var names:Array<String> = [];
		var variations:Array<String> = chartData != null && chartData.variations != null ? cast chartData.variations : [];
		var characterIds:Array<String> = [];
		if (chartData != null && chartData.characters != null)
		{
			if (chartData.characters.player != null) characterIds.push(Std.string(chartData.characters.player));
			if (chartData.characters.opponent != null) characterIds.push(Std.string(chartData.characters.opponent));
		}
		for (character in characterIds) for (variation in variations) names.push("Voices-" + character + "-" + variation);
		for (character in characterIds) names.push("Voices-" + character);
		for (variation in variations) names.push("Voices-" + variation);
		names.push("Voices");
		for (name in names)
		{
			var path = resolveAudioPath(songId, name);
			#if sys
			if (sys.FileSystem.exists(path)) return path;
			#end
			if (openfl.utils.Assets.exists(path)) return path;
		}
		return resolveAudioPath(songId, "Voices");
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
