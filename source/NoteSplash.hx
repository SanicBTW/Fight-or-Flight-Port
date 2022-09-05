package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class NoteSplash extends FlxSprite
{
	private var idleAnim:String;
	private var lastNoteType:Int = -1;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0) {
		super(x, y);

		var skin:String = 'BloodSplash';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		loadAnims(skin);
		
		setupNoteSplash(x, y, note);
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, noteType:Int = 0) {
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		alpha = 0.6;

		if(lastNoteType != noteType) {
			var skin:String = 'BloodSplash';
			if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

			switch(noteType) {
				default:
					loadAnims(skin);
			}
			lastNoteType = noteType;
		}

		offset.set(-45, -70);

		animation.play('a', true);
		animation.curAnim.frameRate = 24;
	}

	function loadAnims(skin:String) {
		frames = Paths.getSparrowAtlas(skin);
		animation.addByPrefix("a", "Squirt", 24, false); //bruh
	}

	override function update(elapsed:Float) {
		if(animation.curAnim.finished) kill();

		super.update(elapsed);
	}
}