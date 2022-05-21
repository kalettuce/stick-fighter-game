package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

class LevelsState extends FlxState
{

    var level1:FlxButton;
    var level2:FlxButton;
    var level3:FlxButton;
    var level4:FlxButton;
    var level5:FlxButton;
    var level6:FlxButton;
    var mainMenu:FlxButton;

    var removedTwo:Bool = false;

    override public function create():Void
    {
        level4 = new FlxButton(0, 0, "Level 4", selectLevel4);
        if (!FlxG.save.data.unlockedFour) level4.loadGraphic("assets/images/dark_buttons.png", true, 80, 20);
        level4.scale.set(4, 4);
        level4.updateHitbox();
        level4.label.setFormat(null, 18, FlxColor.BLACK);
        level4.label.fieldWidth = level4.width;
        level4.label.alignment = "center";
        level4.label.offset.y -= 25;
        level4.screenCenter(XY);
        add(level4);

        level3 = new FlxButton(0, 0, "Level 3", selectLevel3);
        if (!FlxG.save.data.unlockedThree) level3.loadGraphic("assets/images/dark_buttons.png", true, 80, 20);
        level3.scale.set(4, 4);
        level3.updateHitbox();
        level3.label.setFormat(null, 18, FlxColor.BLACK);
        level3.label.fieldWidth = level3.width;
        level3.label.alignment = "center";
        level3.label.offset.y -= 25;
        level3.screenCenter(X);
        level3.y = level4.y - level3.height - 15;
        add(level3);

        level2 = new FlxButton(0, 0, "Level 2", selectLevel2);
        if (!FlxG.save.data.unlockedTwo) level2.loadGraphic("assets/images/dark_buttons.png", true, 80, 20);
        level2.scale.set(4, 4);
        level2.updateHitbox();
        level2.label.setFormat(null, 18, FlxColor.BLACK);
        level2.label.fieldWidth = level2.width;
        level2.label.alignment = "center";
        level2.label.offset.y -= 25;
        level2.screenCenter(X);
        level2.y = level3.y - level2.height - 15;
        add(level2);

        level1 = new FlxButton(0, 0, "Level 1", selectLevel1);
        level1.scale.set(4, 4);
        level1.updateHitbox();
        level1.label.setFormat(null, 18, FlxColor.BLACK);
        level1.label.fieldWidth = level1.width;
        level1.label.alignment = "center";
        level1.label.offset.y -= 25;
        level1.screenCenter(X);
        level1.y = level2.y - level1.height - 15;
        add(level1);

        level5 = new FlxButton(0, 0, "Level 5", selectLevel5);
        if (!FlxG.save.data.unlockedFive) level5.loadGraphic("assets/images/dark_buttons.png", true, 80, 20);
        level5.scale.set(4, 4);
        level5.updateHitbox();
        level5.label.setFormat(null, 18, FlxColor.BLACK);
        level5.label.fieldWidth = level5.width;
        level5.label.alignment = "center";
        level5.label.offset.y -= 25;
        level5.screenCenter(X);
        level5.y = level4.y + level5.height + 15;
        add(level5);

        level6 = new FlxButton(0, 0, "Level 6", selectLevel6);
        if (!FlxG.save.data.unlockedSix) level6.loadGraphic("assets/images/dark_buttons.png", true, 80, 20);
        level6.scale.set(4, 4);
        level6.updateHitbox();
        level6.label.setFormat(null, 18, FlxColor.BLACK);
        level6.label.fieldWidth = level6.width;
        level6.label.alignment = "center";
        level6.label.offset.y -= 25;
        level6.screenCenter(X);
        level6.y = level5.y + level6.height + 15;
        add(level6);

        mainMenu = new FlxButton(0, 0, "Main Menu", selectMainMenu);
        mainMenu.scale.set(4, 4);
        mainMenu.updateHitbox();
        mainMenu.label.setFormat(null, 18, FlxColor.BLACK);
        mainMenu.label.fieldWidth = mainMenu.width;
        mainMenu.label.alignment = "center";
        mainMenu.label.offset.y -= 25;
        mainMenu.screenCenter(X);
        mainMenu.y = level6.y + mainMenu.height + 15;
        add(mainMenu);

        super.create();
    }

    function selectLevel1():Void
    {
        // Log start of Level 1
        Main.LOGGER.logLevelStart(1);
        FlxG.switchState(new Level1());
    }

    function selectLevel2():Void
    {
        if (FlxG.save.data.unlockedTwo) {
            // Log start of Level 2
            Main.LOGGER.logLevelStart(2);
            FlxG.switchState(new Level2());
        }
    }

    function selectLevel3():Void
    {
        if (FlxG.save.data.unlockedThree) {
            // Log start of Level 3
            Main.LOGGER.logLevelStart(3);
            FlxG.switchState(new Level3());
        }
    }

    function selectLevel4():Void
    {
        if (FlxG.save.data.unlockedFour) {
            // Log start of Level 4
            Main.LOGGER.logLevelStart(4);
            FlxG.switchState(new Level4());
        }
    }

    function selectLevel5():Void
    {
        if (FlxG.save.data.unlockedFive) {
            // Log start of Level 5
            Main.LOGGER.logLevelStart(5);
            FlxG.switchState(new Level5());
        }
    }

    function selectLevel6():Void
    {
        if (FlxG.save.data.unlockedSix) {
            // Log start of Level 6
            Main.LOGGER.logLevelStart(6);
            FlxG.switchState(new Level6());
        }
    }

    function selectMainMenu():Void
    {
        // Log clicking "Main Menu" button
        Main.LOGGER.logActionWithNoLevel(LoggingActions.CLICK_MAIN_MENU);
        FlxG.switchState(new MenuState());
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
    }
}