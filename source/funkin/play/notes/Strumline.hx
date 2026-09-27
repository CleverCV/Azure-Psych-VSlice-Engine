package funkin.play.notes;

class Strumline
{
    public static inline var KEY_COUNT:Int = 4;
    public static var DIRECTIONS:Array<String> = ["left", "down", "up", "right"];
    public static inline var INITIAL_OFFSET:Float = 0;
    public static inline var STRUMLINE_SIZE:Float = 1;

    public var noteStyle:Dynamic;
    public var noteSplashes:Dynamic;
    public var noteHoldCovers:Dynamic;
    public var strumlineNotes:Dynamic;
    public var notes:Dynamic;
    public var isPlayer:Bool = false;
    public var scrollSpeed:Float = 1;

    public function new() {}
}