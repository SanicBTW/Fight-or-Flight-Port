package;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets
	public static var fpsVar:FPS;
	public static var memoryVar:MemoryCounter;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		#if !debug
		initialState = TitleState;
		#end

		addChild(new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen));

		fpsVar = new FPS(10, 5, 0xFFFFFF);
		addChild(fpsVar);
		if(fpsVar != null) {
			fpsVar.visible = ClientPrefs.showFPS;
			fpsVar.alpha = 0;
		}

		memoryVar = new MemoryCounter(10, 18);
		addChild(memoryVar);
		if(memoryVar != null){
			memoryVar.visible = ClientPrefs.showMemory;
			memoryVar.alpha = 0;
		}

		FlxG.mouse.useSystemCursor = true;
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
	}

	//god im so fucking dumb, too lazy to do proper tweens :skull:
	public static function tweenFPS(show:Bool = true)
	{
		if(ClientPrefs.showFPS && fpsVar != null)
		{
			if(show)
			{
				FlxTween.tween(fpsVar, {alpha: 1}, 1);
			}
			else
			{
				FlxTween.tween(fpsVar, {alpha: 0}, 1);
			}
		}
	}

	public static function tweenMemory(show:Bool = true)
	{
		if(ClientPrefs.showMemory && memoryVar != null)
		{
			if(show)
			{
				FlxTween.tween(memoryVar, {alpha: 1}, 1);
			}
			else
			{
				FlxTween.tween(memoryVar, {alpha: 0}, 1);
			}
		}
	}
}
