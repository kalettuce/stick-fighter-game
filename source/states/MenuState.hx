package states;

// Update imports
import flixel.FlxG;
import flixel.FlxState;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

class MenuState extends FlxState
{

    var playButton:FlxButton;
    var levelsButton:FlxButton;

    override public function create():Void
    {
        // Play Button
        playButton = new FlxButton(0, 0, "Play", clickPlay);
        playButton.scale.set(4, 4);
        playButton.updateHitbox();
        playButton.label.setFormat(null, 18, FlxColor.BLACK);
        playButton.label.fieldWidth = playButton.width;
        playButton.label.alignment = "center";
        playButton.label.offset.y -= 25;
        playButton.screenCenter(X);
        playButton.y = (FlxG.height / 2) - 50;
        add(playButton);

        levelsButton = new FlxButton(0, 0, "Select Level", selectLevel);
        levelsButton.scale.set(4, 4);
        levelsButton.updateHitbox();
        levelsButton.label.setFormat(null, 18, FlxColor.BLACK);
        levelsButton.label.fieldWidth = levelsButton.width;
        levelsButton.label.alignment = "center";
        levelsButton.label.offset.y -= 25;
        levelsButton.screenCenter(X);
        levelsButton.y = (FlxG.height / 2) + 50;
        add(levelsButton);

        bgColor = FlxColor.BLACK;
        super.create();
    }

    //Play button is clicked
    function clickPlay():Void
    {
        //Switched state from current to Level1


        // Log clicking "Play" button
        Main.LOGGER.logActionWithNoLevel(LoggingActions.CLICK_PLAY);

        // Log start of Level 1
        Main.LOGGER.logLevelStart(1);
        FlxG.switchState(new Level1());
    }

    // Select Levels button is clicked
    function selectLevel():Void
    {

        // Log clicking "Select Levels" button
        Main.LOGGER.logActionWithNoLevel(LoggingActions.CLICK_LEVELS_MENU);
        FlxG.switchState(new LevelsState());
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
    }
}