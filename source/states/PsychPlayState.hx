package states;

import Note;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import objects.Enemy;
import objects.Character;
import objects.Player;
import substates.Pause;
#if mobile
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxButton;
#end

class PsychPlayState extends FlxState
{
    var chartData:Dynamic;
    
    var playerStrums:FlxTypedGroup<FlxSprite>;
    var enemyStrums:FlxTypedGroup<FlxSprite>;
    var grpNotes:FlxTypedGroup<Note>;

    var songTime:Float = 0;
    var scrollSpeed:Float = 2.5;

    var strumsData:Array<String> = ['arrowLEFT', 'arrowDOWN', 'arrowUP', 'arrowRIGHT'];
    var pressAnims:Array<String> = ['left press', 'down press', 'up press', 'right press'];

	var psychparsr:FlxText;


    var vocals:FlxSound;
	var player:Null<Player>;
	var enemy:Null<Enemy>;
	var cameraTarget:FlxObject;
	var camGame:FlxCamera;
	var camHUD:FlxCamera;

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
        if (chartData.speed != null) scrollSpeed = chartData.speed;
    }

    override public function create():Void
    {
		super.create();
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		psychparsr = new FlxText(10, FlxG.height - 54, 0, "PsychEngine Parser Indev 1.7", 16);
		psychparsr.font = "assets/fonts/vcr.ttf";
		psychparsr.color = FlxColor.WHITE;
		psychparsr.setFormat(psychparsr.font, 18, FlxColor.WHITE, LEFT);
		psychparsr.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1.5);
		psychparsr.antialiasing = true;
		psychparsr.cameras = [camHUD];
		add(psychparsr);

		// Psych define los IDs de personaje directamente en el chart.
		if (chartData != null && Reflect.hasField(chartData, "player1"))
		{
			player = new Player(0, 0, Std.string(Reflect.field(chartData, "player1")));
			add(player);
		}
		if (chartData != null && Reflect.hasField(chartData, "player2"))
		{
			enemy = new Enemy(0, 0, Std.string(Reflect.field(chartData, "player2")));
			add(enemy);
		}
		cameraTarget = new FlxObject();
		camGame.follow(cameraTarget, LOCKON, 0.04);
		if (enemy != null) focusCamera(enemy) else if (player != null) focusCamera(player);


        playerStrums = new FlxTypedGroup<FlxSprite>();
        enemyStrums = new FlxTypedGroup<FlxSprite>();
        grpNotes = new FlxTypedGroup<Note>();
		playerStrums.cameras = [camHUD];
		enemyStrums.cameras = [camHUD];
		grpNotes.cameras = [camHUD];

        for (i in 0...4) {
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
		var rutaInst:String = "assets/shared/songs/" + nombreCancion + "/Inst.ogg";
		var rutaVoces:String = "assets/shared/songs/" + nombreCancion + "/Voices.ogg";
		trace("Ruta de la Inst: " + rutaInst);
		trace("Ruta de las Voces: " + rutaVoces);

		FlxG.sound.playMusic(rutaInst, 1.0, false);
		FlxG.sound.music.pause();

		vocals = new FlxSound();
		#if sys
		if (sys.FileSystem.exists(rutaVoces))
		{
			vocals.loadEmbedded(rutaVoces);
			vocals.volume = 1.0;
			FlxG.sound.list.add(vocals);
		}
		#end

		FlxG.sound.music.time = 0;
		@:privateAccess
		if (vocals != null && vocals._sound != null)
		{
			vocals.time = 0;
			vocals.play();
		}

		FlxG.sound.music.play();
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

        grpNotes.forEachAlive(function(daNote:Note) {
			var targetStrumX:Float = 0;
            if (daNote.mustHit) {
                targetStrumX = 700 + (daNote.noteData * 110);
            } else {
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
						if (enemy != null) { enemy.playAnim(['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'][daNote.noteData], true); focusCamera(enemy); }

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
                
                grpNotes.forEachAlive(function(daNote:Note) {
					if (daNote.mustHit && daNote.noteData == i && !daNote.isSustainNote)
					{
                        if (Math.abs(daNote.strumTime - songTime) < 150) {
							if (player != null) { player.playAnim(['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'][i], true); focusCamera(player); }
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

        var sections:Array<Dynamic> = chartData.notes;

        for (section in sections)
        {
            if (section.sectionNotes == null) continue;

			var notesArray:Array<Dynamic> = section.sectionNotes;
            var sectionMustHit:Bool = section.mustHitSection; 

            for (noteData in notesArray)
            {
                var strumTime:Float = noteData[0];
                var noteType:Int = Std.int(noteData[1]);

				var sustainLength:Float = 0;
				if (noteData.length > 2)
				{
					sustainLength = noteData[2];
				}

                var actualLane:Int = noteType % 4; 

                var isPlayerNote:Bool = sectionMustHit;
                if (noteType > 3) {
                    isPlayerNote = !sectionMustHit;
                }

				var parentNote = new Note(strumTime, actualLane, isPlayerNote);
				parentNote.sustainLength = sustainLength;

				if (sustainLength > 0)
				{
					var stepGap:Float = 45;
					var segments:Int = Math.floor(sustainLength / stepGap);
					if (segments < 1)
						segments = 1;

					for (sus in 0...segments)
					{
						var isLast:Bool = (sus == segments - 1);
						var susTime:Float = strumTime + (sus * stepGap);

						var sustainNote = new Note(susTime, actualLane, isPlayerNote, true, isLast);
						sustainNote.parentNote = parentNote;
						grpNotes.add(sustainNote);
					}
				}

				grpNotes.add(parentNote);
            }
        }

		grpNotes.sort(function(order:Int, Obj1:Note, Obj2:Note):Int
		{
			if (Obj1.strumTime < Obj2.strumTime)
				return -1 * order;
			else if (Obj1.strumTime > Obj2.strumTime)
				return 1 * order;
            return 0;
		});
	}

	function focusCamera(character:Character):Void
	{
		if (cameraTarget == null) return;
		cameraTarget.setPosition(
			character.x + character.width / 2 + character.cameraOffset[0],
			character.y + character.height / 2 + character.cameraOffset[1]
		);
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
}
