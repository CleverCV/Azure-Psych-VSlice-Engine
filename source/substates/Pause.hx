package substates;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import states.FreePlayState;

class Pause extends FlxSubState
{
    var grpMenuShit:FlxTypedGroup<FlxText>;
    var menuItems:Array<String> = ['RESUME', 'RESTART', 'EXIT'];
    var curSelected:Int = 0;

    var bg:FlxSprite;

    public function new(camera:FlxCamera)
    {
        super();

        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        bg.alpha = 0.6;
		bg.cameras = [camera];
        add(bg);

        grpMenuShit = new FlxTypedGroup<FlxText>();
		grpMenuShit.cameras = [camera];
        add(grpMenuShit);

        for (i in 0...menuItems.length)
        {
            var item = new FlxText(80, 200 + (i * 120), 0, menuItems[i], 48);
            item.setFormat('assets/fonts/vcr.ttf', 48, 0xFFFFFFFF);
            item.ID = i;
            grpMenuShit.add(item);
        }

        changeSelection(0);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (FlxG.keys.anyJustPressed([UP, W]))
        {
            changeSelection(-1);
        }
        if (FlxG.keys.anyJustPressed([DOWN, S]))
        {
            changeSelection(1);
        }

        if (FlxG.keys.anyJustPressed([ENTER, SPACE]))
        {
            var daSelected:String = menuItems[curSelected];

            switch (daSelected)
            {
                case "RESUME":
                    close(); 
                case "RESTART":
                    FlxG.resetState();
                case "EXIT":
                    FlxG.sound.music.stop();
                    FlxG.switchState(new FreePlayState());
            }
        }
    }

    function changeSelection(change:Int = 0):Void
    {
        curSelected += change;

        if (curSelected < 0)
            curSelected = menuItems.length - 1;
        if (curSelected >= menuItems.length)
            curSelected = 0;

        grpMenuShit.forEach(function(item:FlxText)
        {
            if (item.ID == curSelected)
            {
                item.color = 0xFFFFFF00; 
                item.alpha = 1.0;
                item.x = 110; 
            }
            else
            {
                item.color = 0xFFFFFFFF; 
                item.alpha = 0.6;
                item.x = 80;
            }
        });
    }
}
