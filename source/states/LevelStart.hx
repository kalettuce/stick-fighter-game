package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxSave;

class LevelStart extends FlxSubState{

    public function new() {
        super(0x61000000);
    }

    override public function create() {
        super.create();

        // Make the background box
        final boundingBox = new FlxSprite();
        boundingBox.makeGraphic(460, 197, 0xff428BBF);
        boundingBox.screenCenter(XY);
        add(boundingBox);
        
        // Add text
        final level_1_text = new FlxText(0, boundingBox.y + 45, 0, "LEVEL START!!!", 36);
        level_1_text.screenCenter(X);
        add(level_1_text);

    }
}