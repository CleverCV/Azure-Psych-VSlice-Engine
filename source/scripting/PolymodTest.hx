package scripting;

import polymod.Polymod;
import polymod.Polymod.Framework;

import funkin.play.PlayState;
import funkin.play.event.SongEvent;
import funkin.modding.module.ModuleHandler;
import funkin.modding.events.SongLoadScriptEvent;

import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.audio.FunkinSound;
import funkin.play.character.MultiSparrowCharacter;
import funkin.play.GameOverSubState;
import funkin.Preferences;
import funkin.util.Constants;

class PolymodTest
{
    public static function run():Void
    {
        trace("=== POLYMOD TEST ===");

trace("=== TYPE RESOLUTION TEST ===");

// FORCE LINK: todas las clases usadas por los HScript deben entrar al binario.
var _forceCharacterDataParser:Class<Dynamic> = funkin.play.character.CharacterDataParser;
var _forceSparrowCharacter:Class<Dynamic> = funkin.play.character.SparrowCharacter;
var _forceCharacterType:Enum<Dynamic> = funkin.play.character.CharacterType;

var _forceHealthIcon:Class<Dynamic> = funkin.play.components.HealthIcon;
var _forceNoteStyleRegistry:Class<Dynamic> = funkin.data.notestyle.NoteStyleRegistry;
var _forceNoteStyle:Class<Dynamic> = funkin.play.notes.notestyle.NoteStyle;
var _forceNoteKindManager:Class<Dynamic> = funkin.play.notes.notekind.NoteKindManager;
var _forceStrumline:Class<Dynamic> = funkin.play.notes.Strumline;
var _forceStrumlineNote:Class<Dynamic> = funkin.play.notes.StrumlineNote;
var _forceNoteSprite:Class<Dynamic> = funkin.play.notes.NoteSprite;
var _forceNoteHoldCover:Class<Dynamic> = funkin.play.notes.NoteHoldCover;
var _forceSong:Class<Dynamic> = funkin.play.song.Song;
var _forceVideoCutscene:Class<Dynamic> = funkin.play.cutscene.VideoCutscene;
var _forcePlayStatePlaylist:Class<Dynamic> = funkin.PlayStatePlaylist;
var _forceCharacterDataParser:Class<Dynamic> = funkin.play.character.CharacterDataParser;
var _forceSparrowCharacter:Class<Dynamic> = funkin.play.character.SparrowCharacter;
var _forceCharacterType:Enum<Dynamic> = funkin.play.character.CharacterType;

var resolvedCharacterDataParser = Type.resolveClass("funkin.play.character.CharacterDataParser");
trace(
    "CharacterDataParser: " +
    (resolvedCharacterDataParser != null ? "OK" : "NULL")
);

var resolvedSparrowCharacter = Type.resolveClass("funkin.play.character.SparrowCharacter");
trace(
    "SparrowCharacter: " +
    (resolvedSparrowCharacter != null ? "OK" : "NULL")
);

var resolvedCharacterType = Type.resolveEnum("funkin.play.character.CharacterType");
trace(
    "CharacterType: " +
    (resolvedCharacterType != null ? "OK" : "NULL")
);

        Polymod.addImportAlias("funkin.play.PlayState", PlayState);
        Polymod.addImportAlias("funkin.play.event.SongEvent", SongEvent);

        Polymod.addImportAlias(
            "funkin.modding.module.ModuleHandler",
            ModuleHandler
        );

        Polymod.addImportAlias(
            "funkin.modding.events.SongLoadScriptEvent",
            SongLoadScriptEvent
        );

        Polymod.addImportAlias(
            "funkin.graphics.adobeanimate.FlxAtlasSprite",
            FlxAtlasSprite
        );

        Polymod.addImportAlias(
            "funkin.audio.FunkinSound",
            FunkinSound
        );

        Polymod.addImportAlias(
            "funkin.play.character.MultiSparrowCharacter",
            MultiSparrowCharacter
        );

        Polymod.addImportAlias(
            "funkin.play.GameOverSubState",
            GameOverSubState
        );

        Polymod.addImportAlias(
            "funkin.Preferences",
            Preferences
        );

        Polymod.addImportAlias(
            "funkin.util.Constants",
            Constants
        );

        Polymod.init({
            modRoot: "mods",
            dirs: ["FRIDAY NIGHT SYMPHONY"],
            framework: Framework.LIME,

            useScriptedClasses: true,
            loadScriptsAsync: false,

            errorCallback: function(error)
            {
                trace("========== POLYMOD ERROR ==========");
                trace("SEVERITY: " + Std.string(error.severity));
                trace("CODE: " + Std.string(error.code));
                trace("MESSAGE: " + error.message);
                trace("ORIGIN: " + Std.string(error.origin));
            }
        });

        trace(
            "Mods cargados: " +
            Std.string(Polymod.getLoadedModIds())
        );

        trace(
            "Archivos .hxc detectables: " +
            Std.string(Polymod.listModFiles())
        );
    }
}
