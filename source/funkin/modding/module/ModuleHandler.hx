package funkin.modding.module;

class ModuleHandler
{
    static var modules:Map<String, Module> = new Map();

    public static function register(module:Module):Void
    {
        modules.set(module.id, module);
    }

    public static function getModule(id:String):Module
    {
        return modules.get(id);
    }
}