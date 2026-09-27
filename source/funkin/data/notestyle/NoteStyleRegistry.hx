package funkin.data.notestyle;

import funkin.play.notes.notestyle.NoteStyle;

class NoteStyleRegistry
{
    public static var instance:NoteStyleRegistry = new NoteStyleRegistry();

    public function new() {}

    public function listEntryIds():Array<String>
    {
        return [];
    }

    public function fetchEntry(id:String):NoteStyle
    {
        return null;
    }
}