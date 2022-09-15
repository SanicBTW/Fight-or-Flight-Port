package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import FlxVideo;

class EXEIntro extends MusicBeatState
{
    public static var leftState:Bool = false;
    var video:FlxVideo;

    override function create()
    {
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

        video = new FlxVideo(Paths.video('HaxeFlixelIntro'));
        video.finishCallback = () -> skipvideo();

        super.create();
    }

    function skipvideo() 
    {
        video.kill();
        video.destroy();
        leftState = true;
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;
        MusicBeatState.switchState(new TitleState());
    }
}