package;

import flixel.ui.FlxButton;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.media.Video;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	]; 

	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 366.5;
	public var BF_Y:Float = 400;
	public var DAD_X:Float = 672.5;
	public var DAD_Y:Float = 171.3; //shit was printing a bunch of numbers, 171.3349514563107
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var boyfriendGroup:FlxTypedGroup<Boyfriend>;
	public var dadGroup:FlxTypedGroup<Character>;
	public var gfGroup:FlxTypedGroup<Character>;

	public static var curStage:String = '';
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<Dynamic> = [];

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	private var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	private var camZooming:Bool = true;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var combo:Int = 0;

	var songPercent:Float = 0;

	private var timeBarBG:FlxSprite;
	private var timeBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var endingSong:Bool = false;
	private var startingSong:Bool = false;
	private var updateTime:Bool = false;
	public static var practiceMode:Bool = false;
	public static var usedPractice:Bool = false;
	public static var changedDifficulty:Bool = false;
	public static var cpuControlled:Bool = false;

	var botplaySine:Float = 0;
	var botplayTxt:FlxText;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 0.85;

	public var inCutscene:Bool = false;
	var songLength:Float = 0;
	public static var displaySongName:String = "";

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
    public var shits:Int = 0;

	public static var inst:Dynamic;
	public static var voices:Dynamic;
	var campointX:Float = 0;
	var campointY:Float = 0;
	var bfturn:Bool = false;

	public static var startedSong = false;

	var singAnims = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];
	var zoomshit:Float = 0;
	var fearBarMain:FlxSprite;
	var fearBar:FlxBar;
	var fearBarBG:AttachedSprite;
	var starvedFear:Float = 0;
	var fofStage:FlxSprite;
    var cityBG:FlxSprite;
    var lightBG:FlxSprite;
    var sonicDead:FlxSprite;
    var towerBG:FlxSprite;
	var starvedDrop:Bool = false;
	var subtitles:Subtitle;
	var startCircle:FlxSprite;
	var startText:FlxSprite;
	var blackFuck:FlxSprite;

	override public function create()
	{
		if(Main.fpsVar.alpha == 0)
			Main.tweenFPS();
		if(Main.memoryVar.alpha == 0)
			Main.tweenMemory();

		PauseSubState.songName = null; //Reset to default

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		practiceMode = false;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		var songName:String = SONG.song;
		displaySongName = StringTools.replace(songName, '-', ' ');

		#if desktop
		storyDifficultyText = '' + CoolUtil.difficultyStuff[storyDifficulty][0];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		blackFuck = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		startCircle = new FlxSprite();
		startText = new FlxSprite();

		GameOverSubstate.resetVariables();

		switch(SONG.song.toLowerCase())
		{
			case "fight or flight":
				curStage = "starved";

				defaultCamZoom = 0.85;
				ClientPrefs.middleScroll = true;
				ClientPrefs.cameraMovOnNoteP = true;

				GameOverSubstate.characterName = "bf-starved-die";
				GameOverSubstate.deathSoundName = "starved-death";
				GameOverSubstate.loopSoundName = "starved-loop";
				GameOverSubstate.endSoundName = "starved-retry";

				cityBG = new FlxSprite(-117, -65, Paths.image('starved/city'));
				cityBG.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
				cityBG.scale.set(1.25, 1.25);
				cityBG.antialiasing = ClientPrefs.globalAntialiasing;
				cityBG.updateHitbox();
				cityBG.scrollFactor.set(0.5);
				add(cityBG);

				towerBG = new FlxSprite(-117, -65, Paths.image('starved/towers'));
				towerBG.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
				towerBG.scale.set(1.25, 1.25);
				towerBG.antialiasing = ClientPrefs.globalAntialiasing;
				towerBG.updateHitbox();
				towerBG.scrollFactor.set(0.5);
				add(towerBG);

				fofStage = new FlxSprite(-117, -65, Paths.image('starved/stage'));
				fofStage.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
				fofStage.scale.set(1.25, 1.25);
				fofStage.antialiasing = ClientPrefs.globalAntialiasing;
				fofStage.updateHitbox();
				fofStage.scrollFactor.set(0.5);
				add(fofStage);

				sonicDead = new FlxSprite(325, 250, Paths.image('starved/sonicisfuckingdead'));
				sonicDead.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
				sonicDead.scale.set(0.5, 0.5);
				sonicDead.antialiasing = ClientPrefs.globalAntialiasing;
				sonicDead.updateHitbox();
				sonicDead.scrollFactor.set(0.5);
				add(sonicDead);

				lightBG = new FlxSprite(-117, -65, Paths.image('starved/light'));
				lightBG.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
				lightBG.scale.set(1.25, 1.25);
				lightBG.antialiasing = ClientPrefs.globalAntialiasing;
				lightBG.updateHitbox();
				lightBG.scrollFactor.set(0.5);
				add(lightBG);
			
			case "lucha or funa":
				curStage = "luchafuna";

				defaultCamZoom = 0.85;
				ClientPrefs.middleScroll = true;
				ClientPrefs.cameraMovOnNoteP = true;

				/*
				BF_X += 150;
				DAD_X -= 225;
				DAD_Y -= 100;*/

				GameOverSubstate.characterName = "bf-starved-die";
				GameOverSubstate.deathSoundName = "starved-death";
				GameOverSubstate.loopSoundName = "starved-loop";
				GameOverSubstate.endSoundName = "starved-retry";

				fofStage = new FlxSprite(-117, -65, Paths.image('luchafuna/stage'));
				fofStage.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
				fofStage.scale.set(1.25, 1.25);
				fofStage.antialiasing = ClientPrefs.globalAntialiasing;
				fofStage.updateHitbox();
				fofStage.scrollFactor.set(0.5);
				add(fofStage);

				sonicDead = new FlxSprite(310, 250, Paths.image('luchafuna/sonicisfuckingdead'));
				sonicDead.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
				sonicDead.scale.set(0.5, 0.5);
				sonicDead.antialiasing = ClientPrefs.globalAntialiasing;
				sonicDead.updateHitbox();
				sonicDead.scrollFactor.set(0.5);
				add(sonicDead);

				lightBG = new FlxSprite(-117, -65, Paths.image('starved/light'));
				lightBG.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
				lightBG.scale.set(1.25, 1.25);
				lightBG.antialiasing = ClientPrefs.globalAntialiasing;
				lightBG.updateHitbox();
				lightBG.scrollFactor.set(0.5);
				add(lightBG);
		}

		boyfriendGroup = new FlxTypedGroup<Boyfriend>();
		dadGroup = new FlxTypedGroup<Character>();
		gfGroup = new FlxTypedGroup<Character>();

		gf = new Character(GF_X, GF_Y, "gf");
		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
		gf.scrollFactor.set(0.95, 0.95);
		gfGroup.add(gf);

		dad = new Character(DAD_X, DAD_Y, SONG.player2);
		dadGroup.add(dad);

		boyfriend = new Boyfriend(BF_X, BF_Y, SONG.player1);
		boyfriendGroup.add(boyfriend);

		add(dadGroup);
		add(boyfriendGroup);

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 5).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 115;
		strumLine.scrollFactor.set();

		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 20, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = !ClientPrefs.hideTime;
		timeTxt.y = FlxG.height - 95;
		if(ClientPrefs.downScroll) timeTxt.y = 5;

		timeBarBG = new FlxSprite(timeTxt.x, timeTxt.y + (timeTxt.height / 4)).loadGraphic(Paths.image('timeBar'));
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = !ClientPrefs.hideTime;
		timeBarBG.color = FlxColor.BLACK;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(FlxColor.RED, FlxColor.BLACK);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = !ClientPrefs.hideTime;
		add(timeBar);
		add(timeTxt);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y, 1, 1);

		snapCamFollowToPos(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		scoreTxt = new FlxText(0, (FlxG.height - 45) - 5, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		add(scoreTxt);
		if(ClientPrefs.downScroll){
			scoreTxt.y = 45;
		}

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		fearBarMain = new FlxSprite(FlxG.width - 100 , FlxG.height * 0.23).loadGraphic(curStage == "starved" ? Paths.image("fearbar") : Paths.image("fearbarfuna"));
		fearBarMain.scrollFactor.set();
		fearBarMain.visible = true;
		add(fearBarMain);

		fearBarBG = new AttachedSprite('fearbarBG');
		fearBarBG.x = fearBarMain.x + 16;
		fearBarBG.y = fearBarMain.y;
		fearBarBG.angle = 0;
		fearBarBG.scrollFactor.set();
		fearBarBG.visible = true;
		fearBarBG.scale.set(0.60, 1);
		fearBarBG.updateHitbox();
		add(fearBarBG);

		fearBar = new FlxBar(fearBarMain.x + 29, fearBarMain.y + 16, BOTTOM_TO_TOP, Std.int(fearBarBG.width), Std.int(fearBarBG.height), this,
		'starvedFear', 0, 100);
		fearBar.angle = 0;
		fearBar.scrollFactor.set();
		fearBar.visible = true;
		fearBar.createFilledBar(FlxColor.TRANSPARENT, FlxColor.RED);
		fearBar.numDivisions = 800;
		fearBar.alpha = 1;
		fearBar.scale.set(0.56, 0.90);
		fearBar.updateHitbox();
		add(fearBar);

		if(curStage == "luchafuna")
		{
			subtitles = new Subtitle();
			subtitles.screenCenter();
			subtitles.x -= 420;
			subtitles.scrollFactor.set();
			add(subtitles);
		}

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		fearBarMain.cameras = [camHUD];
		fearBarBG.cameras = [camHUD];
		fearBar.cameras = [camHUD];
		startCircle.cameras = [camHUD];
		startText.cameras = [camHUD];
		blackFuck.cameras = [camHUD];

		if(curStage == "luchafuna")
		{
			subtitles.cameras = [camHUD];
		}

		#if android
		addAndroidControls();
		androidControls.visible = true;
		addPadCamera();
		#end

		startingSong = true;
		updateTime = true;

		startCountdown();
		add(blackFuck);
		startCircle.loadGraphic(Paths.image('Circle-fight-or-flight'));
		startCircle.screenCenter();
		startCircle.scale.set(1.5, 1.5);
		startCircle.x += 777;
		add(startCircle);
		startText.loadGraphic(curStage == "starved" ? Paths.image("Text-fight-or-flight") : Paths.image("Text-lucha-or-funa"));
		startText.screenCenter();
		if(curStage == "starved")
		{
			startText.scale.set(1.5, 1.5);
		}
		startText.x -= 1200;
		add(startText);

		new FlxTimer().start(0.6, function(tmr:FlxTimer)
		{
			FlxTween.tween(startCircle, {x: 250}, 0.5);
			FlxTween.tween(startText, {x: 250}, 0.5);
		});

		new FlxTimer().start(1.9, function(tmr:FlxTimer)
		{
			//we tryna clean memory ig
			FlxTween.tween(startCircle, {alpha: 0}, 1, {onComplete: function(twn:FlxTween)
			{
				remove(startCircle);
			}});
			FlxTween.tween(startText, {alpha: 0}, 1, {onComplete: function(twn:FlxTween)
			{
				remove(startText);
			}});
			FlxTween.tween(blackFuck, {alpha: 0}, 1, {onComplete: function(twn:FlxTween)
			{
				remove(blackFuck);
			}});
		});

		RecalculateRating();

		//precache if vol higher than 0
		if(ClientPrefs.missVolume > 0)
		{
			CoolUtil.precacheSound('missnote1');
			CoolUtil.precacheSound('missnote2');
			CoolUtil.precacheSound('missnote3');
		}

		if(ClientPrefs.hitsoundVolume > 0)
		{
			CoolUtil.precacheSound('hitsound');
		}

		if(PauseSubState.songName != null){
			CoolUtil.precacheMusic(PauseSubState.songName);
		} else if(ClientPrefs.pauseMusic != null) {
			CoolUtil.precacheMusic(ClientPrefs.pauseMusic.toLowerCase().replace(" ", "-"));
		}
		
		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", "starved");
		#end

		super.create();

		System.gc();

		CustomFadeTransition.nextCamera = camOther;

		lime.app.Application.current.window.title = displaySongName;

		beatHit(); //lmfao easiest fix of my life
	}

	//to do, fix coords of the new char
	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(BF_X, BF_Y, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.visible = false;
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(DAD_X, DAD_Y, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad);
					newDad.visible = false;
				}

			case 2:
				if(!gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(GF_X, GF_Y, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.visible = false;
				}
		}
	}
	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;
	var perfectMode:Bool = false;

	public function startCountdown():Void
	{
		if(startedCountdown) {
			return;
		}

		inCutscene = false;
		generateStaticArrows(0);
		generateStaticArrows(1);
		for (i in 0...playerStrums.length) {
		}
		for (i in 0...opponentStrums.length) {
			if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
		}

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
			{
				gf.dance();
			}
			if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
			{
				boyfriend.dance();
			}
			if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
			{
				dad.dance();
			}

			if (generatedMusic)
			{
				notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
			}

			swagCounter += 1;
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		System.gc();

		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(inst, 1, false);
		FlxG.sound.music.onComplete = finishSong;
		vocals.play();

		if(paused) {
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBarBG, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", "starved", true, songLength);
		#end

		startedSong = true;
		canPause = true;
	}

	private function generateSong(dataPath:String):Void
	{
		System.gc();

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(voices);
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(inst));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = SONG.song.toLowerCase();
		var file:String = Paths.json(songName + '/events');
		if (OpenFlAssets.exists(file)) {
			var eventsData:Array<SwagSection> = Song.loadFromJson('events', songName).notes;
			for (section in eventsData)
			{
				for (songNotes in section.sectionNotes)
				{
					if(songNotes[1] < 0) {
						eventNotes.push(songNotes);
						eventPushed(songNotes);
					}
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				if(songNotes[1] > -1) { //Real notes
					var daStrumTime:Float = songNotes[0];
					var daNoteData:Int = Std.int(songNotes[1] % 4);

					var gottaHitNote:Bool = section.mustHitSection;

					if (songNotes[1] > 3)
					{
						gottaHitNote = !section.mustHitSection;
					}

					var oldNote:Note;
					if (unspawnNotes.length > 0)
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					else
						oldNote = null;

					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
					swagNote.mustPress = gottaHitNote;
					swagNote.sustainLength = songNotes[2];
					swagNote.noteType = songNotes[3];
					if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]];

					var susLength:Float = swagNote.sustainLength;

					susLength = susLength / Conductor.stepCrochet;
					unspawnNotes.push(swagNote);

					var floorSus:Int = Math.floor(susLength);
					if(floorSus > 0) {
						for (susNote in 0...floorSus+1)
						{
							oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

							var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(SONG.speed, 2)), daNoteData, oldNote, true);
							sustainNote.mustPress = gottaHitNote;
							sustainNote.noteType = swagNote.noteType;
							sustainNote.scrollFactor.set();
							unspawnNotes.push(sustainNote);

							sustainNote.mustPress = gottaHitNote;

							if (sustainNote.mustPress)
							{
								sustainNote.x += FlxG.width / 2; // general offset
							}
						}
					}

					swagNote.mustPress = gottaHitNote;

					if (swagNote.mustPress)
					{
						swagNote.x += FlxG.width / 2; // general offset
					}
					else {}
				} else { //Event Notes
					eventNotes.push(songNotes);
					eventPushed(songNotes);
				}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}

		generatedMusic = true;
	}

	function eventPushed(event:Array<Dynamic>) {
		switch(event[2]) {
			case 'Change Character':
				var charType:Int = Std.parseInt(event[3]);
				if(Math.isNaN(charType)) charType = 0;

				var newCharacter:String = event[4];
				addCharacterToList(newCharacter, charType);
		}
	}

	function eventNoteEarlyTrigger(event:Array<Dynamic>):Float {
		switch(event[2]) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		var earlyTime1:Float = eventNoteEarlyTrigger(Obj1);
		var earlyTime2:Float = eventNoteEarlyTrigger(Obj2);
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0] - earlyTime1, Obj2[0] - earlyTime2);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i);

			var skin:String = "NOTE_assets";
			if(PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;

			babyArrow.frames = Paths.getSparrowAtlas(skin);
			babyArrow.animation.addByPrefix('green', 'arrowUP');
			babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
			babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
			babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

			babyArrow.antialiasing = ClientPrefs.globalAntialiasing;
			babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

			switch (Math.abs(i))
			{
				case 0:
					babyArrow.x += Note.swagWidth * 0;
					babyArrow.animation.addByPrefix('static', 'arrowLEFT');
					babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					babyArrow.x += Note.swagWidth * 1;
					babyArrow.animation.addByPrefix('static', 'arrowDOWN');
					babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					babyArrow.x += Note.swagWidth * 2;
					babyArrow.animation.addByPrefix('static', 'arrowUP');
					babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					babyArrow.x += Note.swagWidth * 3;
					babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
					babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			babyArrow.y -= 10;
			babyArrow.alpha = 1;
			FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			babyArrow.ID = i;

			switch(player)
			{
				case 0:
					opponentStrums.add(babyArrow);
				case 1:
					playerStrums.add(babyArrow);
			}

			babyArrow.playAnim('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = false;
				}
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = true;
				}
			}
			paused = false;

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", "starved", true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", "starved");
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (starvedFear > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", "starved", true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, displaySongName + " (" + storyDifficultyText + ")", "starved");
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (starvedFear > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, displaySongName + " (" + storyDifficultyText + ")", "starved");
		}
		#end

		if(!paused)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;
			if(FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				vocals.pause();
			}
			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = false;

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		super.update(elapsed);

		if(ratingString == 'N/A') {
			scoreTxt.text = 'Sacrifices: ' + songMisses + ' | Accuracy: N/A';
		} else {
			scoreTxt.text = 'Sacrifices: ' + songMisses + ' | Accuracy: ' + Highscore.floorDecimal(ratingPercent * 100, 2) + '% [' + ratingFC + ']';
		}

		if(cpuControlled) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}
		botplayTxt.visible = cpuControlled;

		if (FlxG.keys.justPressed.ENTER #if android || FlxG.android.justReleased.BACK #end && startedCountdown && canPause)
		{
			if(!FlxG.random.bool(0.1))
			{
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;
				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			
				#if desktop
				DiscordClient.changePresence(detailsPausedText, displaySongName + " (" + storyDifficultyText + ")", "starved");
				#end
			}
			else
			{
				trace("Bromita :P");
			}
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}

				if(updateTime) {
					var curTime:Float = FlxG.sound.music.time - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var secondsTotal:Int = Math.floor((songLength - curTime) / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					var minutesRemaining:Int = Math.floor(secondsTotal / 60);
					var secondsRemaining:String = '' + secondsTotal % 60;
					if(secondsRemaining.length < 2) secondsRemaining = '0' + secondsRemaining; //Dunno how to make it display a zero first in Haxe lol
					timeTxt.text = minutesRemaining + ':' + secondsRemaining;
				}
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		zoomshit = camGame.zoom / 0.75;
		boyfriend.scale.set(zoomshit, zoomshit);

		if(startedSong && !endingSong)
		{
			//make an update that modifies the method of increasing fear
			if(starvedFear <= 0) starvedFear = 0;
			starvedFear += 0.475 * elapsed;
		}

		doDeathCheck();

		// RESET = Quick Game Over Screen
		if (controls.RESET && !inCutscene && !endingSong)
		{
			starvedFear = 100;
		}

		var roundedSpeed:Float = FlxMath.roundDecimal(SONG.speed, 2);
		if (unspawnNotes[0] != null)
		{
			var time:Float = 1500;
			if(roundedSpeed < 1) time /= roundedSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				if(!daNote.mustPress && ClientPrefs.middleScroll)
				{
					daNote.active = true;
					daNote.visible = false;
				}
				else if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				// i am so fucking sorry for this if condition
				var strumY:Float = 0;
				if(daNote.mustPress) {
					strumY = playerStrums.members[daNote.noteData].y;
				} else {
					strumY = opponentStrums.members[daNote.noteData].y;
				}
				var center:Float = strumY + Note.swagWidth / 2;

				if (ClientPrefs.downScroll) {
					daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);
					if (daNote.isSustainNote) {
						//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
						if (daNote.animation.curAnim.name.endsWith('end')) {
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * roundedSpeed + (46 * (roundedSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * roundedSpeed;
							if(curStage == 'school' || curStage == 'schoolEvil') {
								daNote.y += 8;
							}
						} 
						daNote.y += (Note.swagWidth / 2) - (60.5 * (roundedSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (roundedSpeed - 1);

						if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
							&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
				} else {
					daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * roundedSpeed);

					if (daNote.isSustainNote
						&& daNote.y + daNote.offset.y * daNote.scale.y <= center
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
					{
						var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
						swagRect.y = (center - daNote.y) / daNote.scale.y;
						swagRect.height -= swagRect.y;

						daNote.clipRect = swagRect;
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					opponentNoteHit(daNote);
				}

				if(daNote.mustPress && cpuControlled) {
					if(daNote.isSustainNote) {
						if(daNote.canBeHit) {
							goodNoteHit(daNote);
						}
					} else if(daNote.strumTime <= Conductor.songPosition) {
						goodNoteHit(daNote);
					}
				}

				var doKill:Bool = daNote.y < -daNote.height;
				if(ClientPrefs.downScroll) doKill = daNote.y > FlxG.height;

				if (doKill)
				{
					if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}


		while(eventNotes.length > 0) {
			var early:Float = eventNoteEarlyTrigger(eventNotes[0]);
			var leStrumTime:Float = eventNotes[0][0];
			if(Conductor.songPosition < leStrumTime - early) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0][3] != null)
				value1 = eventNotes[0][3];

			var value2:String = '';
			if(eventNotes[0][4] != null)
				value2 = eventNotes[0][4];

			triggerEventNote(eventNotes[0][2], value1, value2);
			eventNotes.shift();
		}

		if (!inCutscene) {
			if(!cpuControlled) {
				keyShit();
			} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE)
				FlxG.sound.music.onComplete();
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				FlxG.sound.music.pause();
				vocals.pause();
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if(daNote.strumTime + 800 < Conductor.songPosition) {
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
				for (i in 0...unspawnNotes.length) {
					var daNote:Note = unspawnNotes[0];
					if(daNote.strumTime + 800 >= Conductor.songPosition) {
						break;
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					unspawnNotes.splice(unspawnNotes.indexOf(daNote), 1);
					daNote.destroy();
				}

				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.play();

				vocals.time = Conductor.songPosition;
				vocals.play();
			}
		}
		#end
	}

	public var isDead:Bool = false;
	function doDeathCheck(?skipFearCheck:Bool = false)
	{
		if((skipFearCheck || Math.round(starvedFear) == 100) && !practiceMode && !isDead) 
		{
			Main.tweenFPS(false);
			Main.tweenMemory(false);
			boyfriend.stunned = true;
			deathCounter++;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, camFollowPos.x, camFollowPos.y));
			
			#if desktop
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, displaySongName + " (" + storyDifficultyText + ")", "starved");
			#end
			isDead = true;
			return true;
		}
		return false;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String, ?onLua:Bool = false) {
		switch(eventName) {
			case 'Hey!':
				var value:Int = Std.parseInt(value1);
				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter == 'gf') { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value)) value = 1;
				gfSpeed = value;

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Play Animation':
				trace('Anim to play: ' + value1);
				var val2:Int = Std.parseInt(value2);
				if(Math.isNaN(val2)) val2 = 0;

				var char:Character = dad;
				switch(val2) {
					case 1: char = boyfriend;
					case 2: char = gf;
				}
				char.playAnim(value1, true);
				char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var val:Int = Std.parseInt(value1);
				if(Math.isNaN(val)) val = 0;

				var char:Character = dad;
				switch(val) {
					case 1: char = boyfriend;
					case 2: char = gf;
				}
				char.idleSuffix = value2;
				char.recalculateDanceIdle();

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = Std.parseFloat(split[0].trim());
					var intensity:Float = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = Std.parseInt(value1);
				if(Math.isNaN(charType)) charType = 0;

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							boyfriend.visible = false;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.visible = true;
						}

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							dad.visible = false;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf) {
									gf.visible = true;
								}
							} else {
								gf.visible = false;
							}
							dad.visible = true;
						}

					case 2:
						if(gf.curCharacter != value2) {
							if(!gfMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var isGfVisible:Bool = gf.visible;
							gf.visible = false;
							gf = gfMap.get(value2);
							gf.visible = isGfVisible;
						}

				}
		}
	}

	function moveCameraSection(?id:Int = 0):Void {
		if (SONG.notes[id] != null && camFollow.x != dad.getMidpoint().x + 150 && !SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			defaultCamZoom = 1;
			for(i in 0...playerStrums.length)
			{
				FlxTween.tween(playerStrums.members[i], {alpha: 0.25}, 0.1, { ease: FlxEase.linear});
			}
			campointX = camFollow.x;
			campointY = camFollow.y;
			bfturn = false;
		}

		if (SONG.notes[id] != null && SONG.notes[id].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
		{
			moveCamera(false);
			defaultCamZoom = 0.85;
			for(i in 0...playerStrums.length)
			{
				FlxTween.tween(playerStrums.members[i], {alpha: 1}, 0.1, { ease: FlxEase.linear});
			}
			campointX = camFollow.x;
			campointY = camFollow.y;
			bfturn = true;
		}
	}

	public function moveCamera(isDad:Bool) {
		if(isDad) {
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 175);
			camFollow.x -= boyfriend.cameraPosition[0];
			camFollow.y += boyfriend.cameraPosition[1];
		} else {
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0];
			camFollow.y += boyfriend.cameraPosition[1];
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function finishSong():Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.noteOffset <= 0) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}

	function endSong():Void
	{
		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;
		KillNotes();

		if (SONG.validScore && !cpuControlled)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			#end
		}

		trace('WENT BACK TO FREEPLAY??');
		if(FlxTransitionableState.skipNextTransIn) {
			CustomFadeTransition.nextCamera = null;
		}
		MusicBeatState.switchState(new FreeplayState());
		FlxG.sound.playMusic(Paths.music('freakyMenu'));
		usedPractice = false;
		changedDifficulty = false;
		cpuControlled = false;
		lime.app.Application.current.window.title = "Fight or Flight";
	}

	private function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = -(note.strumTime - Conductor.songPosition);
		vocals.volume = 1;

		var coolText:FlxText = new FlxText(0, 0, 0, "", 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		coolText.cameras = [camHUD];

		var rating:FlxSprite = new FlxSprite();
		var score:Float = 350;

		var daRating:String = "sick";

		if (noteDiff > Conductor.safeZoneOffset * 0.9)
		{
			daRating = 'shit';
			score = 50;
			shits++;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			daRating = 'bad';
			score = 100;
			bads++;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.25)
		{
			daRating = 'good';
			score = 200;
			goods++;
		}

		if (daRating != 'shit' || daRating != 'bad')
		{
			spawnNoteSplashOnNote(note);
			sicks++;
			songScore += Math.round(score);
			songHits++;

			if (ClientPrefs.optScoreZoom)
			{
				if(!cpuControlled)
				{
					if(scoreTxtTween != null) {
						scoreTxtTween.cancel();
					}
					scoreTxt.scale.x = 1.075;
					scoreTxt.scale.y = 1.075;
					scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
						onComplete: function(twn:FlxTween) {
							scoreTxtTween = null;
						}
					});
				}
			}

			var pixelShitPart1:String = "";
			var pixelShitPart2:String = '';

			rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
			rating.cameras = [camHUD];
			rating.screenCenter();
			rating.x = coolText.x - 40;
			rating.y -= 60;
			rating.acceleration.y = 550;
			rating.velocity.y -= FlxG.random.int(140, 175);
			rating.velocity.x -= FlxG.random.int(0, 10);
			rating.visible = (!ClientPrefs.hideHud);
			rating.x += ClientPrefs.comboOffset[0];
			rating.y -= ClientPrefs.comboOffset[1];

			insert(members.indexOf(strumLineNotes), rating);

			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;

			rating.updateHitbox();

			var seperatedScore:Array<Int> = [];

			if(combo >= 1000) {
				seperatedScore.push(Math.floor(combo / 1000) % 10);
			}
			seperatedScore.push(Math.floor(combo / 100) % 10);
			seperatedScore.push(Math.floor(combo / 10) % 10);
			seperatedScore.push(combo % 10);

			rating.cameras = [camHUD];

			var daLoop:Int = 0;
			for (i in seperatedScore)
			{
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
				numScore.cameras = [camHUD];
				numScore.screenCenter();
				numScore.x = coolText.x + (43 * daLoop) - 90;
				numScore.y += 80;

				numScore.x += ClientPrefs.comboOffset[2];
				numScore.y -= ClientPrefs.comboOffset[3];

				rating.setGraphicSize(Std.int(rating.width * 0.7));
				rating.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));

				numScore.updateHitbox();

				numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);
				numScore.visible = !ClientPrefs.hideHud;
				
				insert(members.indexOf(strumLineNotes), numScore);

				FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.001
				});

				daLoop++;
			}

			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					coolText.destroy();
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.001
			});	
		}
	}

	//bruh
	private function keyShit():Void
	{
		if(ClientPrefs.inputType == "Kade")
		{
			// control arrays, order L D R U
			var holdArray:Array<Bool> = [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
			var pressArray:Array<Bool> = [
				controls.NOTE_LEFT_P,
				controls.NOTE_DOWN_P,
				controls.NOTE_UP_P,
				controls.NOTE_RIGHT_P
			];
			var releaseArray:Array<Bool> = [
				controls.NOTE_LEFT_R,
				controls.NOTE_DOWN_R,
				controls.NOTE_UP_R,
				controls.NOTE_RIGHT_R
			];

			// Prevent player input if botplay is on
			if(cpuControlled)
			{
				holdArray = [false, false, false, false];
				pressArray = [false, false, false, false];
				releaseArray = [false, false, false, false];
			} 
			// HOLDS, check for sustain notes
			if (holdArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
			{
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.noteData])
						goodNoteHit(daNote);
				});
			}

			// PRESSES, check for note hits
			if (pressArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
			{
				boyfriend.holdTimer = 0;

				var possibleNotes:Array<Note> = []; // notes that can be hit
				var directionList:Array<Int> = []; // directions that can be hit
				var dumbNotes:Array<Note> = []; // notes to kill later

				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
					{
						if (directionList.contains(daNote.noteData))
						{
							for (coolNote in possibleNotes)
							{
								if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
								{ // if it's the same note twice at < 10ms distance, just delete it
									// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
									dumbNotes.push(daNote);
									break;
								}
								else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
								{ // if daNote is earlier than existing note (coolNote), replace
									possibleNotes.remove(coolNote);
									possibleNotes.push(daNote);
									break;
								}
							}
						}
						else
						{
							possibleNotes.push(daNote);
							directionList.push(daNote.noteData);
						}
					}
				});
				for (note in dumbNotes)
				{
					FlxG.log.add("killing dumb ass note at " + note.strumTime);
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}

				var dontCheck = false;
				for (i in 0...pressArray.length)
				{
					if (pressArray[i] && !directionList.contains(i))
						dontCheck = true;
				}
				if (possibleNotes.length > 0 && !dontCheck)
				{
					if (!ClientPrefs.ghostTapping)
					{
						for (shit in 0...pressArray.length)
							{ // if a direction is hit that shouldn't be
								if (pressArray[shit] && !directionList.contains(shit))
									noteMiss(shit, null);
							}
					}
					for (coolNote in possibleNotes)
					{
						if (pressArray[coolNote.noteData])
						{
							goodNoteHit(coolNote);
						}
					}
				}
				else if(!ClientPrefs.ghostTapping)
				{
					for (shit in 0...pressArray.length)
					{ // if a direction is hit that shouldn't be
						if (pressArray[shit] && !directionList.contains(shit))
							noteMissPress(shit);
					}
				}
			}

			notes.forEachAlive(function(daNote:Note)
			{
				if(ClientPrefs.downScroll && daNote.y > strumLine.y ||
				!ClientPrefs.downScroll && daNote.y < strumLine.y)
				{
					// Force good note hit regardless if it's too late to hit it or not as a fail safe
					if(cpuControlled && daNote.canBeHit && daNote.mustPress ||
					cpuControlled && daNote.tooLate && daNote.mustPress)
					{
						goodNoteHit(daNote);
						boyfriend.holdTimer = daNote.sustainLength;
					}
				}
			});

			if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && (!holdArray.contains(true) || cpuControlled))
			{
				if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
					boyfriend.playAnim('idle');
			}

			playerStrums.forEach(function(spr:StrumNote)
			{
				if(pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm') {
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}
				if(releaseArray[spr.ID]) {
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			});
		}
		else
		{
			// HOLDING
			var up = controls.NOTE_UP;
			var right = controls.NOTE_RIGHT;
			var down = controls.NOTE_DOWN;
			var left = controls.NOTE_LEFT;

			var upP = controls.NOTE_UP_P;
			var rightP = controls.NOTE_RIGHT_P;
			var downP = controls.NOTE_DOWN_P;
			var leftP = controls.NOTE_LEFT_P;

			var upR = controls.NOTE_UP_R;
			var rightR = controls.NOTE_RIGHT_R;
			var downR = controls.NOTE_DOWN_R;
			var leftR = controls.NOTE_LEFT_R;

			var controlArray:Array<Bool> = [leftP, downP, upP, rightP];
			var controlReleaseArray:Array<Bool> = [leftR, downR, upR, rightR];
			var controlHoldArray:Array<Bool> = [left, down, up, right];

			if (!boyfriend.stunned && generatedMusic)
			{
				// rewritten inputs???
				notes.forEachAlive(function(daNote:Note)
				{
					// hold note functions
					if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
					&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
						goodNoteHit(daNote);
					}
				});

				if ((controlHoldArray.contains(true) || controlArray.contains(true)) && !endingSong) {
					var canMiss:Bool = !ClientPrefs.ghostTapping;
					if (controlArray.contains(true)) {
						for (i in 0...controlArray.length) {
							// heavily based on my own code LOL if it aint broke dont fix it
							var pressNotes:Array<Note> = [];
							var notesDatas:Array<Int> = [];
							var notesStopped:Bool = false;

							var sortedNotesList:Array<Note> = [];
							notes.forEachAlive(function(daNote:Note)
							{
								if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate 
								&& !daNote.wasGoodHit && daNote.noteData == i) {
									sortedNotesList.push(daNote);
									notesDatas.push(daNote.noteData);
									canMiss = true;
								}
							});
							sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

							if (sortedNotesList.length > 0) {
								for (epicNote in sortedNotesList)
								{
									for (doubleNote in pressNotes) {
										if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 10) {
											doubleNote.kill();
											notes.remove(doubleNote, true);
											doubleNote.destroy();
										} else
											notesStopped = true;
									}

									// eee jack detection before was not super good
									if (controlArray[epicNote.noteData] && !notesStopped) {
										goodNoteHit(epicNote);
										pressNotes.push(epicNote);
									}

								}
							}
							else if (canMiss)
							{
								if(controlArray[i])
								{
									noteMissPress(i);
								}
							}
						}
					}

				} else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing')
				&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				{
					boyfriend.dance();
				}
			}

			playerStrums.forEach(function(spr:StrumNote)
			{
				if(controlArray[spr.ID] && spr.animation.curAnim.name != 'confirm') {
					spr.playAnim('pressed');
					spr.resetAnim = 0;
				}
				if(controlReleaseArray[spr.ID]) {
					spr.playAnim('static');
					spr.resetAnim = 0;
				}
			});
		}
	}

	function noteMiss(direction:Int = 0, daNote:Note):Void
	{
		if (!boyfriend.stunned)
		{
			notes.forEachAlive(function(note:Note) {
				if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 10) {
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
			});

			switch(daNote.noteType)
			{
				default:
					combo = 0;
					starvedFear += 0.500;
					if(!practiceMode) songScore -= 10;
					if(!endingSong){
						songMisses++;
					}
					vocals.volume = 0;
					RecalculateRating();

					var char:Character = boyfriend;
					if(daNote.gfNote) { char = gf; }

					if(char != null && curStage != "luchafuna")
					{
						var daAlt = '';
						if(daNote.noteType == "Alt Animation") daAlt = '-alt';
		
						char.playAnim(singAnims[Std.int(Math.abs(daNote.noteData)) % 4] + "miss" + daAlt, true);
					}
		
					if(ClientPrefs.missVolume > 0)
					{
						FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), ClientPrefs.missVolume);
					}
			}
		}
	}

	function noteMissPress(direction:Int = 1):Void
	{
		if (!boyfriend.stunned)
		{
			starvedFear += 0.500;
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			RecalculateRating();

			var char:Character = boyfriend;

			if(char != null && curStage != "luchafuna")
			{
				char.playAnim(singAnims[direction] + "miss", true);
			}

			vocals.volume = 0;
			if(ClientPrefs.missVolume > 0)
			{
				FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), ClientPrefs.missVolume);
			}
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if(combo > 9999) combo = 9999;
			}

			if(!note.isSustainNote)
			{
				starvedFear -= 0.030;
			}

			if(!note.noAnimation)
			{
				var char:Character = boyfriend;
				var daAlt = '';
				if(note.noteType == "Alt Animation") daAlt = '-alt';

				if(note.gfNote){ char = gf; }

				if(char != null)
				{
					cameraShit(singAnims[Std.int(Math.abs(note.noteData)) % 4], false);
					char.playAnim(singAnims[Std.int(Math.abs(note.noteData)) % 4] + daAlt, true);
					char.holdTimer = 0;
				}

				if(note.noteType == "Hey!") 
				{
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}
	
					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			} else {
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				if(cpuControlled) {
					boyfriend.holdTimer = 0;
				}
				note.kill();
				notes.remove(note, true);
				note.destroy();
			} else if(cpuControlled) {
				var targetHold:Float = Conductor.stepCrochet * 0.001 * boyfriend.singDuration;
				if(boyfriend.holdTimer + 0.2 > targetHold) {
					boyfriend.holdTimer = targetHold - 0.2;
				}
			}
			RecalculateRating();
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(note.noteType == 'Hey!' && boyfriend.animOffsets.exists('hey')) {
			boyfriend.playAnim('hey', true);
			boyfriend.specialAnim = true;
			boyfriend.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;

			if(note.gfNote) { char = gf; }

			if(char != null)
			{
				cameraShit(singAnims[Std.int(Math.abs(note.noteData)) % 4], true);
				char.playAnim(singAnims[Std.int(Math.abs(note.noteData)) % 4] + altAnim, true);
				char.holdTimer = 0;
			}
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % 4, time);
		note.hitByOpponent = true;

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function spawnNoteSplashOnNote(note:Note, isDad:Bool = false) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = null;
			if(isDad){
				strum = opponentStrums.members[note.noteData];
			} else {
				strum = playerStrums.members[note.noteData];
			}
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, 0);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, type:Int) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, type);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		super.destroy();
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}

		if(curStage == "luchafuna")
		{
			//lyrics oficiales del video: https://www.youtube.com/watch?v=Z1h4DWllk4k
			switch(curStep)
			{
				case 1:
					subtitles.show();
					subtitles.changeChar("ecuadorean");
					subtitles.changeSubtitle("Nya");
				case 5:
					subtitles.changeSubtitle("Ecuadorean GOD");
				case 17:
					subtitles.changeSubtitle("Nya");
				case 19:
					subtitles.changeSubtitle("Nya x2");
				case 21:
					subtitles.changeSubtitle("Redbromer ZZZ");
				case 32:
					subtitles.changeSubtitle("Nya");
				case 35:
					subtitles.hide();
				case 83:
					subtitles.show();
				case 84:
					subtitles.changeSubtitle("Nya");
				case 86:
					subtitles.hide();
				case 119:
					subtitles.show();
				case 120:
					subtitles.changeSubtitle("Lemon Demon");
				case 128:
					subtitles.hide();
				case 179:
					subtitles.show();
				case 180:
					subtitles.changeSubtitle("Oli amor te amo <3");
				case 190:
					subtitles.hide();
				case 354:
					subtitles.show();
				case 355:
					subtitles.changeSubtitle("Busqueen tweets");
				case 363:
					subtitles.changeSubtitle("de este pana y");
				case 368:
					subtitles.changeSubtitle("pasenmelos");
				//dumb ass
				case 374:
					subtitles.hide();
				case 375:
					subtitles.show();
				case 376:
					subtitles.changeSubtitle("Le");
				case 377:
					subtitles.changeSubtitle("Le x2");
				case 379:
					subtitles.changeSubtitle("Lemon Demon");
				case 384:
					subtitles.hide();
				case 450:
					addCharacterToList("derki", 0);
				case 458:
					changeChar(0, "derki");
					subtitles.changeChar("derkerbluer");
					subtitles.show();
				case 460:
					subtitles.changeSubtitle("??Se acuerdan");
				case 468:
					subtitles.changeSubtitle("de ");
				case 470:
					subtitles.changeSubtitle("de x2");
				case 472:
					subtitles.changeSubtitle("de x3");
				case 473:
					subtitles.changeSubtitle("de Ecuadorean?");
				case 480:
					subtitles.hide();
				case 543:
					subtitles.changeChar("ecuadorean");
					subtitles.show();
				case 545:
					subtitles.changeSubtitle("Pinches idiotas");
				case 556:
					subtitles.changeSubtitle("cabron...");
				case 560:
					subtitles.hide();
				case 650:
					addCharacterToList("candel", 0);
				case 658:
					changeChar(0, "candel");
					subtitles.changeChar("candel");
					subtitles.show();
				case 657:
					subtitles.changeSubtitle("Yo soy...");
				case 665:
					subtitles.changeSubtitle("Candel!");
				case 672:
					subtitles.hide();
				case 873:
					subtitles.changeChar("ecuadorean");
					subtitles.show();
				case 875:
					subtitles.changeSubtitle("??C??llate el");
				case 880:
					subtitles.changeSubtitle("hocico");
				case 884:
					subtitles.changeSubtitle("conchetumadre");
				case 892:
					subtitles.changeSubtitle("un rato!");
				case 895:
					subtitles.hide();
				case 970:
					addCharacterToList("dk", 0);
				case 978:
					changeChar(0, "dk");
					subtitles.changeChar("donkamaron");
					subtitles.show();
				case 980:
					subtitles.changeSubtitle("En...");
				case 983:
					subtitles.changeSubtitle("Don");
				case 987:
					subtitles.changeSubtitle("Kamar??n");
				case 993:
					subtitles.hide();
				case 1166:
					subtitles.changeChar("ecuadorean");
					subtitles.show();
				case 1168:
					subtitles.changeSubtitle("Jajaja...");
				case 1183: //mf was saying case unused
					FlxTween.color(sonicDead, 0.5, FlxColor.WHITE, 0xfff96d63, {ease: FlxEase.quadInOut});
					
					FlxTween.tween(fofStage, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut});
					boyfriend.colorTween = FlxTween.color(boyfriend, 0.5, FlxColor.WHITE, 0xfff96d63, {onComplete: function(twn:FlxTween) {
						boyfriend.colorTween = null;
					}, ease: FlxEase.quadInOut});
					dad.colorTween = FlxTween.color(dad, 0.5, FlxColor.WHITE, 0xfff96d63, {onComplete: function(twn:FlxTween) {
						dad.colorTween = null;
					}, ease: FlxEase.quadInOut});
					starvedDrop = true;
					subtitles.changeSubtitle("El d??a de hoy");
				case 1190:
					subtitles.changeSubtitle("continuamos con la saga");
				case 1200:
					subtitles.changeSubtitle("de videos del Redbromer");
				case 1210:
					subtitles.changeSubtitle("Web??n");
				case 1215:
					subtitles.changeSubtitle("??Por qu?? no me encaras a mi?");
				case 1230:
					subtitles.changeSubtitle("Nya");
				case 1240:
					subtitles.changeSubtitle("Nya x2");
				case 1244:
					subtitles.changeSubtitle("Nya x3");
					addCharacterToList("red", 0);
				case 1247:
					changeChar(0, "red");
					subtitles.changeChar("redbromer");
				case 1248:
					subtitles.changeSubtitle("Es m??s o menos");
				case 1255:
					subtitles.changeSubtitle("como esa pol??mica");
				case 1265:
					subtitles.changeSubtitle("que tuve con el pendejo");
				case 1280:
					subtitles.changeSubtitle("que le hace la voz");
				case 1288:
					subtitles.changeSubtitle("a Lemon Demon");
				case 1294:
					subtitles.changeChar("ecuadorean");
				case 1295:
					subtitles.changeSubtitle("Nya");
				case 1303:
					subtitles.changeSubtitle("Nya x2");
				case 1307:
					subtitles.changeSubtitle("Nya x3");
				case 1312:
					subtitles.hide();
				case 1442:
					subtitles.show();
				case 1443:
					subtitles.changeSubtitle("Pinches idiotas cabr??n...");
				case 1459:
					subtitles.hide();
				case 1549:
					subtitles.show();
				case 1550:
					subtitles.changeSubtitle("El pendejo que");
				case 1558:
					subtitles.changeSubtitle("le hace la voz");
				case 1562:
					subtitles.changeSubtitle("a Lemon Demon...");
				case 1568:
					subtitles.hide();
				case 1711:
					subtitles.show();
				case 1712:
					subtitles.changeSubtitle("Jajaja...");
				case 1727:
					subtitles.hide();
				case 1773:
					subtitles.show();
				case 1774:
					subtitles.changeChar("ecuadorean");
				case 1775:
					subtitles.changeSubtitle("Nya");
				case 1783:
					subtitles.changeSubtitle("Nya x2");
				case 1787:
					subtitles.changeSubtitle("Nya x3");
				case 1792:
					subtitles.hide();
				case 2015:
					subtitles.show();
				case 2016:
					subtitles.changeSubtitle("Nya");
				case 2018:
					subtitles.changeSubtitle("Nya x2");
				case 2021:
					subtitles.changeSubtitle("Ecuadorean GOD");
				case 2030:
					subtitles.changeSubtitle("Nya");
				case 2033:
					subtitles.changeSubtitle("Nya x2");
				case 2036:
					subtitles.changeSubtitle("RedBromer ZZZ");
				case 2047:
					subtitles.changeSubtitle("Nya");
				case 2048:
					subtitles.hide();
				case 2098:
					subtitles.show();
				case 2099:
					subtitles.changeSubtitle("Nya");
				case 2102:
					subtitles.hide();
				case 2119:
					subtitles.show();
				case 2120:
					trace("se me escapo un lemon demon por aqui pero na");
					subtitles.changeChar("sanco");
					subtitles.changeSubtitle("Gracias por jugar!");
				case 2140:
					subtitles.hide();

				//no need to be in order right?
				case 1437:
					FlxTween.color(sonicDead, 0.5, 0xfff96d63, FlxColor.WHITE, {ease: FlxEase.quadInOut});
					
					FlxTween.tween(fofStage, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
					boyfriend.colorTween = FlxTween.color(boyfriend, 0.5, 0xfff96d63, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
						boyfriend.colorTween = null;
					}, ease: FlxEase.quadInOut});
					dad.colorTween = FlxTween.color(dad, 0.5, 0xfff96d63, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
						dad.colorTween = null;
					}, ease: FlxEase.quadInOut});
					starvedDrop = false;
				case 1472:
					FlxTween.color(sonicDead, 0.5, FlxColor.WHITE, 0xfff96d63, {ease: FlxEase.quadInOut});
					
					FlxTween.tween(fofStage, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut});
					boyfriend.colorTween = FlxTween.color(boyfriend, 0.5, FlxColor.WHITE, 0xfff96d63, {onComplete: function(twn:FlxTween) {
						boyfriend.colorTween = null;
					}, ease: FlxEase.quadInOut});
					dad.colorTween = FlxTween.color(dad, 0.5, FlxColor.WHITE, 0xfff96d63, {onComplete: function(twn:FlxTween) {
						dad.colorTween = null;
					}, ease: FlxEase.quadInOut});
					starvedDrop = true;
				case 1982:
					FlxTween.color(sonicDead, 0.5, 0xfff96d63, FlxColor.WHITE, {ease: FlxEase.quadInOut});
					
					FlxTween.tween(fofStage, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
					boyfriend.colorTween = FlxTween.color(boyfriend, 0.5, 0xfff96d63, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
						boyfriend.colorTween = null;
					}, ease: FlxEase.quadInOut});
					dad.colorTween = FlxTween.color(dad, 0.5, 0xfff96d63, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
						dad.colorTween = null;
					}, ease: FlxEase.quadInOut});
					starvedDrop = false;
			}
		}

		if(curStage == "starved")
		{
			switch(curStep)
			{
				case 1183:
					FlxTween.color(sonicDead, 0.5, FlxColor.WHITE, 0xfff96d63, {ease: FlxEase.quadInOut});
					
					FlxTween.tween(cityBG, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut});
					FlxTween.tween(towerBG, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut});
					FlxTween.tween(fofStage, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut});
					boyfriend.colorTween = FlxTween.color(boyfriend, 0.5, FlxColor.WHITE, 0xfff96d63, {onComplete: function(twn:FlxTween) {
						boyfriend.colorTween = null;
					}, ease: FlxEase.quadInOut});
					dad.colorTween = FlxTween.color(dad, 0.5, FlxColor.WHITE, 0xfff96d63, {onComplete: function(twn:FlxTween) {
						dad.colorTween = null;
					}, ease: FlxEase.quadInOut});
					starvedDrop = true;
				case 1437:
					FlxTween.color(sonicDead, 0.5, 0xfff96d63, FlxColor.WHITE, {ease: FlxEase.quadInOut});
					
					FlxTween.tween(cityBG, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
					FlxTween.tween(towerBG, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
					FlxTween.tween(fofStage, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
					boyfriend.colorTween = FlxTween.color(boyfriend, 0.5, 0xfff96d63, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
						boyfriend.colorTween = null;
					}, ease: FlxEase.quadInOut});
					dad.colorTween = FlxTween.color(dad, 0.5, 0xfff96d63, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
						dad.colorTween = null;
					}, ease: FlxEase.quadInOut});
					starvedDrop = false;
				case 1472:
					FlxTween.color(sonicDead, 0.5, FlxColor.WHITE, 0xfff96d63, {ease: FlxEase.quadInOut});
					
					FlxTween.tween(cityBG, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut});
					FlxTween.tween(towerBG, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut});
					FlxTween.tween(fofStage, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut});
					boyfriend.colorTween = FlxTween.color(boyfriend, 0.5, FlxColor.WHITE, 0xfff96d63, {onComplete: function(twn:FlxTween) {
						boyfriend.colorTween = null;
					}, ease: FlxEase.quadInOut});
					dad.colorTween = FlxTween.color(dad, 0.5, FlxColor.WHITE, 0xfff96d63, {onComplete: function(twn:FlxTween) {
						dad.colorTween = null;
					}, ease: FlxEase.quadInOut});
					starvedDrop = true;
				case 1982:
					FlxTween.color(sonicDead, 0.5, 0xfff96d63, FlxColor.WHITE, {ease: FlxEase.quadInOut});
					
					FlxTween.tween(cityBG, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
					FlxTween.tween(towerBG, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
					FlxTween.tween(fofStage, {alpha: 1}, 0.5, {ease: FlxEase.quadInOut});
					boyfriend.colorTween = FlxTween.color(boyfriend, 0.5, 0xfff96d63, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
						boyfriend.colorTween = null;
					}, ease: FlxEase.quadInOut});
					dad.colorTween = FlxTween.color(dad, 0.5, 0xfff96d63, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
						dad.colorTween = null;
					}, ease: FlxEase.quadInOut});
					starvedDrop = false;
			}
		}

		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			System.gc();
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
			}
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(Std.int(curStep / 16));
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}
		lastBeatHit = curBeat;
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = opponentStrums.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingString:String;
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating() {
		ratingPercent = songScore / ((songHits + songMisses) * 350);
		if(!Math.isNaN(ratingPercent) && ratingPercent < 0) ratingPercent = 0;

		if(Math.isNaN(ratingPercent)) {
			ratingString = 'N/A';
		} else if(ratingPercent >= 1) {
			ratingPercent = 1;
			ratingString = ratingStuff[ratingStuff.length-1][0];
		} else {
			for (i in 0...ratingStuff.length-1) {
				if(ratingPercent < ratingStuff[i][1]) {
					ratingString = ratingStuff[i][0];
					break;
				}
			}
		}
		ratingFC = "";
		if (sicks > 0) ratingFC = "SFC";
		if (goods > 0) ratingFC = "GFC";
		if (bads > 0 || shits > 0) ratingFC = "FC";
		if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
		else if (songMisses >= 10) ratingFC = "Clear";
	}

	var mult = 5;
	function cameraShit(animToPlay, isDad)
	{
		switch(animToPlay)
		{
			case 'singLEFT':
				if(((!bfturn && isDad) || (bfturn && !isDad)) && ClientPrefs.cameraMovOnNoteP)
				{
					camFollow.x = campointX - mult;
					camFollow.y = campointY;
				}
			case "singDOWN":
				if(((!bfturn && isDad) || (bfturn && !isDad)) && ClientPrefs.cameraMovOnNoteP)
				{
					camFollow.x = campointX;
					camFollow.y = campointY + mult;
				}
			case "singUP":
				if(((!bfturn && isDad) || (bfturn && !isDad)) && ClientPrefs.cameraMovOnNoteP)
				{
					camFollow.x = campointX;
					camFollow.y = campointY - mult;
				}
			case "singRIGHT":
				if(((!bfturn && isDad) || (bfturn && !isDad)) && ClientPrefs.cameraMovOnNoteP)
				{
					camFollow.x = campointX + mult;
					camFollow.y = campointY;
				}
		}
	}

	function changeChar(charType = 0, character:String)
	{
		var value2 = character; //mf im lazy
		switch(charType) 
		{
			case 0:
				if(boyfriend.curCharacter != value2) 
				{
					if(!boyfriendMap.exists(value2)) 
					{
						addCharacterToList(value2, charType);
					}
					boyfriend.visible = false;
					boyfriend = boyfriendMap.get(value2);
					boyfriend.visible = true;
				}
			case 1:
				if(dad.curCharacter != value2) 
				{
					if(!dadMap.exists(value2)) 
					{
						addCharacterToList(value2, charType);
					}
					var wasGf:Bool = dad.curCharacter.startsWith('gf');
					dad.visible = false;
					dad = dadMap.get(value2);
					if(!dad.curCharacter.startsWith('gf')) {
						if(wasGf) {
							gf.visible = true;
						}
					} else {
						gf.visible = false;
					}
					dad.visible = true;
				}
		}
	}
}
