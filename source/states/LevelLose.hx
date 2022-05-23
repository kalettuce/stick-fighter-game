package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxSave;
import openfl.utils.AssetManifest;

class LevelLose extends FlxSubState{

    var restart:Class<FlxState>;
    public function new(curLevel:Class<FlxState>) {
        super(0x61000000);
        restart = curLevel;

    }

    override public function create() {
        super.create();

        final boundingBox = new FlxSprite();

        boundingBox.makeGraphic(460, 197, 0xff428BBF);
        boundingBox.screenCenter(XY);
        add(boundingBox);
        

        final lose_text = new FlxText(0, boundingBox.y + 45, 0, "YOU DIED!!!", 36);
        lose_text.screenCenter(X);
        add(lose_text);

        final restart_text = new FlxText(0, boundingBox.y + 105, "Press SPACE to restart level", 18);
        restart_text.screenCenter(X);
        add(restart_text);

        final return_text = new FlxText(0, boundingBox.y + 155, "Press ESCAPE to return to main menu", 18);
        return_text.screenCenter(X);
        add(return_text);
        
    }

   override public function update(elapsed) {

        super.update(elapsed);
        if(FlxG.keys.justPressed.SPACE) {
            
            FlxG.switchState(Type.createInstance(restart, []));
            close();
        } 

        if(FlxG.keys.justPressed.ESCAPE) {
            
            FlxG.switchState(new MenuState());
            close();
        } 
   }

}