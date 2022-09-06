package;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

class Subtitle extends FlxSpriteGroup
{
    public var bg:FlxSprite;
    public var charText:FlxText;
    public var subText:FlxText;
    public var charImage:FlxSprite;
    public function new()
    {
        super();

        this.alpha = 0;

        bg = new FlxSprite().makeGraphic(410, 94, FlxColor.WHITE);

        charImage = new FlxSprite(bg.x + 15, bg.y + 15);

        charText = new FlxText(charImage.x + 79, bg.y + 15, 0, "", 20);
        charText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.BLACK, LEFT);

        subText = new FlxText(charImage.x + 79, bg.y + 35, 0, "", 18);
        subText.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.BLACK, LEFT);

        antialiasing = ClientPrefs.globalAntialiasing;

        add(bg);
        add(charImage);
        add(charText);
        add(subText);
    }

    public function changeChar(newChar)
    {
        charImage.loadGraphic(Paths.image("subtitles/" + newChar), false, 150, 150);
        charImage.setGraphicSize(64, 64);
        charImage.updateHitbox();

        charText.text = formattedName(newChar);
    }

    public function changeSubtitle(newText)
    {
        subText.text = newText;
    }

    function formattedName(charName):String
    {
        switch(charName)
        {
            case "ecuadorean":
                return "Ecuadorean";
            case "derkerbluer":
                return "Derker Bluer";
            case "redbromer":
                return "Red Bromer";
            case "candel":
                return "Candel";
            case "donkamaron":
                return "Don Kamarón";
            case 'sanco':
                return 'Sanco - Dev';
        }
        return "";
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
    }

    public function show()
    {
        FlxTween.tween(this, {alpha: 1}, 0.5, {ease: FlxEase.linear});
    }

    public function hide()
    {
        FlxTween.tween(this, {alpha: 0}, 0.5, {ease: FlxEase.linear, onComplete: function(twn:FlxTween)
        {
            subText.text = "";
        }});
    }
}