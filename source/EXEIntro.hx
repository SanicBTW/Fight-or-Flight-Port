package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import FlxVideo;

class EXEIntro extends MusicBeatState
{
    public static var leftState:Bool = false;
    var vid:FlxVideo;

    override function create()
    {
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

        vid = new FlxVideo(Paths.video('HaxeFlixelIntro'));
        vid.finishCallback = () -> skipvideo();
        super.create();
    }

    function skipvideo() 
    {
        vid.kill();
        vid.destroy();
        leftState = true;
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;
        MusicBeatState.switchState(new TitleState());
    }
}