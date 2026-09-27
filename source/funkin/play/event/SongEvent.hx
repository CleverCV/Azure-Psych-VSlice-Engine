package funkin.play.event;

class SongEvent
{
    public var eventName:String;

    public function new(eventName:String = "")
    {
        this.eventName = eventName;
    }

    public function handleEvent(data:SongEventData):Void
    {
    }

    public function getEventSchema():Dynamic
    {
        return null;
    }

    public function getTitle():String
    {
        return eventName;
    }
}

class SongEventData
{
    public var value:Dynamic;

    public function new(?value:Dynamic)
    {
        this.value = value;
    }
}