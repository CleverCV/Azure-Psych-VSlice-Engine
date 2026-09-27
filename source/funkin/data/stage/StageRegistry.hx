package funkin.data.stage;

class StageRegistry
{
    public static var instance:StageRegistry = new StageRegistry();

    public function new() {}

    public function listEntryIds():Array<String>
    {
        return [];
    }

    public function parseEntryDataWithMigration(id:String):Dynamic
    {
        return null;
    }

    public function fetchEntryVersion(id:String):Dynamic
    {
        return null;
    }
}