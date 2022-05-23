package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxSave;

class GameWin extends FlxSubState{

    
    public function new() {
        super(0x61000000);
    }

    override public function create() {
        super.create();

        final boundingBox = new FlxSprite();

        boundingBox.makeGraphic(460, 197, 0xff428BBF);
        boundingBox.screenCenter(XY);
        boundingBox.scrollFactor.set(0, 0);
        add(boundingBox);
        

        final level_won = new FlxText(0, boundingBox.y + 45, 0, "YOU WON THE GAME!!!", 36);
        level_won.screenCenter(X);
        level_won.scrollFactor.set(0, 0);
        add(level_won);

        final supCompleteText = new FlxText(0, boundingBox.y + 135, "Press SPACE to return to main menu", 18);
        supCompleteText.screenCenter(X);
        supCompleteText.scrollFactor.set(0, 0);
        add(supCompleteText);
    }

   override public function update(elapsed) {

        super.update(elapsed);
        if(FlxG.keys.justPressed.SPACE) {
            
            FlxG.switchState(new MenuState());
            close();
        } 
   }

}