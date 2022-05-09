package;

// Update imports
import flixel.FlxG;
import flixel.FlxState;
import flixel.ui.FlxButton;

class MenuState extends FlxState
{
	
	var playButton:FlxButton;
    var levelsButton:FlxButton;
	
	override public function create():Void
	{
		// Play Button
		playButton = new FlxButton(0, 0, "Play", clickPlay);
        playButton.screenCenter(X);
        playButton.y = (FlxG.height / 2) - 20;
        playButton.setSize(200.00, 50.00);
 		add(playButton);

        levelsButton = new FlxButton(0, 0, "Select Level", selectLevel);
        levelsButton.screenCenter(X);
        levelsButton.y = (FlxG.height / 2) + 20;
        add(levelsButton);

		super.create();
	}

	//Play button is clicked
	function clickPlay():Void
 	{
		//Switched state from current to PlayState
    		FlxG.switchState(new Level1());
 	}
    
    // Select Levels button is clicked
	function selectLevel():Void
 	{
    	FlxG.switchState(new LevelsState());
 	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}