package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.ui.FlxButton;

class LevelsState extends FlxState
{
	
	var level1:FlxButton;
    var level2:FlxButton;
    var level3:FlxButton;
    var level4:FlxButton;
    var level5:FlxButton;
    var level6:FlxButton;
    var mainMenu:FlxButton;
	
	override public function create():Void
	{
		
        level4 = new FlxButton(0, 0, "Level 4", selectLevel4);
        level4.screenCenter(XY);
        add(level4);

        level3 = new FlxButton(0, 0, "Level 3", selectLevel3);
 		level3.screenCenter(X);
        level3.y = level4.y - level3.height - 2;
        add(level3);

        level2 = new FlxButton(0, 0, "Level 2", selectLevel2);
        level2.screenCenter(X);
        level2.y = level3.y - level2.height - 2;
        add(level2);

		level1 = new FlxButton(0, 0, "Level 1", selectLevel1);
 		level1.screenCenter(X);
        level1.y = level2.y - level1.height - 2;
        add(level1);
    

        level5 = new FlxButton(0, 0, "Level 5", selectLevel5);
 		level5.screenCenter(X);
        level5.y = level4.y + level5.height + 2;
        add(level5);

        level6 = new FlxButton(0, 0, "Level 6", selectLevel6);
        level6.screenCenter(X);
        level6.y = level5.y + level6.height + 2;
        add(level6);

        mainMenu = new FlxButton(0, 0, "Main Menu", selectMainMenu);
        mainMenu.screenCenter(X);
        mainMenu.y = level6.y + mainMenu.height + 2;
 		add(mainMenu);

		super.create();
	}

	function selectLevel1():Void
 	{
	    FlxG.switchState(new Level1());
 	}
    
    function selectLevel2():Void
 	{
	    FlxG.switchState(new Level2());
 	}
    
    function selectLevel3():Void
 	{
	    FlxG.switchState(new Level3());
 	}
    
    function selectLevel4():Void
 	{
	    FlxG.switchState(new Level4());
 	}
    
    function selectLevel5():Void
 	{
	    FlxG.switchState(new Level5());
 	}
    
    function selectLevel6():Void
 	{
	    FlxG.switchState(new Level6());
 	}
    
    function selectMainMenu():Void
 	{
	    FlxG.switchState(new MenuState());
 	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}