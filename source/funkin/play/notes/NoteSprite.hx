package funkin.play.notes;

class NoteSprite
{
    public function new() {}

    public function setupNoteGraphic(?frames:Dynamic):Void {}

    public function playNoteAnimation():Void {}

    public function get_isHoldNote():Bool
    {
        return false;
    }

    public var holdNoteSprite:Dynamic;
}