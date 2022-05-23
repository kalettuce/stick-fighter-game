package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxSave;

class LevelComplete extends FlxSubState{

    var _nextLevel:Class<FlxState>;
    public function new(nextLevel:Class<FlxState>) {
        super(0x61000000);
        _nextLevel = nextLevel;

    }

    override public function create() {
        super.create();

        // Make the background box
        final boundingBox = new FlxSprite();
        boundingBox.makeGraphic(460, 197, 0xff428BBF);
        boundingBox.screenCenter(XY);
        add(boundingBox);
        
        // Add text
        final level_1_text = new FlxText(0, boundingBox.y + 45, 0, "LEVEL COMPLETE!!!", 36);
        level_1_text.screenCenter(X);
        add(level_1_text);

        final supCompleteText = new FlxText(0, boundingBox.y + 135, "Press SPACE to continue", 18);
        supCompleteText.screenCenter(X);
        add(supCompleteText);
    }

   override public function update(elapsed) {
        super.update(elapsed);

        // Switch state if button is pressed
        // Close substate
        if(FlxG.keys.justPressed.SPACE) {
            FlxG.switchState(Type.createInstance(_nextLevel, []));
            close();
        } 
   }
}