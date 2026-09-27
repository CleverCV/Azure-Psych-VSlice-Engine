package scripting;

import polymod.Polymod;
import polymod.PolymodConfig;
import polymod.Polymod.Framework;

class PolymodHandler
{
    public static var initialized:Bool = false;

    public static function init(
        modsRoot:String = "mods",
        mods:Array<String> = null
    ):Void
    {
        if (initialized)
            return;

        var modList:Array<String> =
            mods == null ? [] : mods;

        try
        {
            // Polymod necesita saber dónde están los scripts .hxc.
            PolymodConfig.scriptClassExt = ".hxc";

            Polymod.init({
                modRoot: modsRoot,
                dirs: modList,

                framework: Framework.LIME,

                frameworkParams: {
                    assetLibraryPaths: [
                        "default" => "assets"
                    ]
                },

                useScriptedClasses: true,
                loadScriptsAsync: false,

                errorCallback: function(error)
                {
                    trace(
                        "Polymod: " +
                        Std.string(error)
                    );
                }
            });

            initialized = true;

            trace(
                "PolymodHandler: inicializado."
            );

            trace(
                "PolymodHandler: root = " +
                modsRoot
            );

            trace(
                "PolymodHandler: mods = " +
                Std.string(modList)
            );
        }
        catch (error:Dynamic)
        {
            trace(
                "PolymodHandler: ERROR: " +
                Std.string(error)
            );
        }
    }

    public static function addImportAlias(
        importAlias:String,
        importClass:Class<Dynamic>
    ):Void
    {
        try
        {
            Polymod.addImportAlias(
                importAlias,
                importClass
            );

            trace(
                "PolymodHandler: alias registrado: " +
                importAlias
            );
        }
        catch (error:Dynamic)
        {
            trace(
                "PolymodHandler: error registrando alias " +
                importAlias +
                ": " +
                Std.string(error)
            );
        }
    }

    public static function reload():Void
    {
        if (!initialized)
            return;

        try
        {
            Polymod.reload();

            trace(
                "PolymodHandler: mods recargados."
            );
        }
        catch (error:Dynamic)
        {
            trace(
                "PolymodHandler: error recargando: " +
                Std.string(error)
            );
        }
    }

    public static function clearScripts():Void
    {
        try
        {
            Polymod.clearScripts();

            trace(
                "PolymodHandler: scripts limpiados."
            );
        }
        catch (error:Dynamic)
        {
            trace(
                "PolymodHandler: error limpiando scripts: " +
                Std.string(error)
            );
        }
    }

    public static function destroy():Void
    {
        if (!initialized)
            return;

        try
        {
            Polymod.disable();
        }
        catch (error:Dynamic)
        {
            trace(
                "PolymodHandler: error desactivando: " +
                Std.string(error)
            );
        }

        initialized = false;
    }
}